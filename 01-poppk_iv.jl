# Developing a population PK model for iv dosing with covariates using Pumas

# Load the necessary Libraries
using Pumas
using PumasUtilities
using Pumas.Latexify
using PharmaDatasets

# Read data
pkdata = dataset("iv_sd_3")

# Coverting the DataFrame to a collection of Subjects (Population)
population = read_pumas(pkdata)

# Model definition
model = @model begin

    @param begin
        # here we define the parameters of the model
        tvcl ∈ RealDomain(; lower = 0.001) # typical clearance 
        tvvc ∈ RealDomain(; lower = 0.001) # typical central volume of distribution
        Ω ∈ PDiagDomain(2)             # between-subject variability
        σ ∈ RealDomain(; lower = 0.001)    # residual error
    end

    @random begin
        # here we define random effects
        η ~ MvNormal(Ω) # multi-variate Normal with mean 0 and covariance matrix Ω
    end

    @pre begin
        # pre computations and other statistical transformations
        CL = tvcl * exp(η[1])
        Vc = tvvc * exp(η[2])
        # myvar = if t == 5 0 else 1 end
    end

    # here we define compartments and dynamics
    @dynamics Central1 # same as Central' = -(CL/Vc)*Central (see Pumas documentation)

    @derived begin
        # here is where we calculate concentration and add residual variability
        # tilde (~) means "distributed as"
        cp = @. 1000 * Central / Vc # ipred = A1/V
        dv ~ @. Normal(cp, σ)
        # CONC ~ @. Normal(cp, sqrt(cp^2 * σ_prop^2 + σ_add^2))
    end
end

# render
render(latexify(model, :param))

# Parameter values
params = (tvcl = 1.0, tvvc = 10.0, Ω = Diagonal([0.09, 0.09]), σ = 3.16)
params2 = (tvcl = 1.0, tvvc = 8.0, Ω = Diagonal([0.5, 0.5]), σ = 4.16)

# Fit a base model
fit_results = fit(model, population, params, Pumas.FOCE())             # using custom initial parameter values
fit_results2 = fit(model, population, params, Pumas.NaivePooled(); omegas = (:Ω,))             # using custom initial parameter values
fit_results3 = fit(model, population, init_params(model), Pumas.FOCE()) # using the model's initial parameter values

fit_compare = compare_estimates(;
    custom_params = fit_results,
    init_params = fit_results3,
    NaivePooled = fit_results2,
)

# Confidence Intervals
fit_infer = infer(fit_results)
coeftable(fit_infer)  # DataFrame

# Confidence Intervals using bootstrap
fit_infer_bs = infer(fit_results, Pumas.Bootstrap(samples = 100))
coeftable(fit_infer)

fit_inspect = inspect(fit_results)
fit_inspect2 = inspect(fit_results2)
fit_inspect3 = inspect(fit_results3)
fit_diagnostics = evaluate_diagnostics((;
    custom_params = fit_inspect,
    NaivePooled = fit_inspect2,
    init_params = fit_inspect3,
))

fit_vpc = vpc(fit_results) # Single-Threaded
fit_vpc = vpc(
    fit_results; # Multi-Threaded
    ensemblealg = EnsembleThreads(),
)

vpc_plot(fit_vpc)

fit_diagnostics = evaluate_diagnostics((fit_inspect, fit_vpc),)

model_explore = explore_estimates(model, population, params)
coef(model_explore)