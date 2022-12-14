# Developing a population PK model for iv dosing with covariates using Pumas

# Load the necessary Libraries
using Pumas
using PumasUtilities
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
    end

    # here we define compartments and dynamics
    @dynamics Central1 # same as Central' = -(CL/Vc)*Central (see Pumas documentation)

    @derived begin
        # here is where we calculate concentration and add residual variability
        # tilde (~) means "distributed as"
        cp = @. 1000 * Central / Vc # ipred = A1/V
        dv ~ @. Normal(cp, σ)
        # dv ~ @. Normal(cp, sqrt(cp^2 * σ_prop^2 + σ_add^2))
    end
end

# Parameter values
params = (tvcl = 1.0, tvvc = 10.0, Ω = Diagonal([0.09, 0.09]), σ = 3.16)
params2 = (tvcl = 1.0, tvvc = 8.0, Ω = Diagonal([0.5, 0.5]), σ = 4.16)
params3 = (
    tvcl = 1.001,
    tvvc = 1.001,
    Ω = Diagonal([1.0 0.0; 0.0 1.0]),
    σ = 1.001
)

# Fit a base model
fit_results = fit(model, population, params3, Pumas.FOCE())
fit_results2 = fit(model, population, params, Pumas.NaivePooled(); omegas = (:Ω,))
fit_results3 = fit(model, population, params2, Pumas.LaplaceI())
fit_results4 = fit(model, population, params2, Pumas.FOCE(); constantcoef=(tvcl = 1.0,))

fit_compare = compare_estimates(;
    FOCE = fit_results,
    LaplaceI = fit_results3,
    NaivePooled = fit_results2,
    FOCE_constantcoef = fit_results4
)

# Confidence Intervals
fit_infer = infer(fit_results)
coeftable(fit_infer)  # DataFrame

# Confidence Intervals using bootstrap
fit_infer_bs = infer(fit_results, Pumas.Bootstrap(samples = 100))
coeftable(fit_infer_bs)

#SIR
fit_infer_sir = infer(fit_results, Pumas.SIR(samples=10, resamples=10))
coeftable(fit_infer_sir)

# Inspect the models
fit_inspect = inspect(fit_results)
fit_inspect2 = inspect(fit_results2)
fit_inspect3 = inspect(fit_results3)
fit_diagnostics = evaluate_diagnostics((;
    FOCE = fit_inspect,
    NaivePooled = fit_inspect2,
    LaplaceI = fit_inspect3,
))

# VPCs
fit_vpc = vpc(fit_results) # Single-Threaded
fit_vpc = vpc(
    fit_results; # Multi-Threaded
    ensemblealg = EnsembleThreads(),
)

vpc_plot(fit_vpc)

# Generate a report for all of our fitted models
report(
    (;
        FOCE = (fit_results, fit_inspect, fit_vpc),
        LaplaceI = fit_results3,
        NaivePooled = fit_results2,
        FOCE_constantcoef = fit_results4
    ); clean=false
)

# Pumas Apps
fit_diagnostics = evaluate_diagnostics((fit_inspect, fit_vpc),)

model_explore = explore_estimates(model, population, params)
coef(model_explore)