using Pumas
using PumasUtilities
using PharmaDatasets
using PumasPlots

# Read data
pkdata = dataset("iv_sd_3")

# Coverting the DataFrame to a collection of Subjects (Population)
population = read_pumas(pkdata, covariates = [:dosegrp])

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

    @covariates dosegrp

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
    end
end

params = (tvcl = 1.0, tvvc = 10.0, Ω = Diagonal([0.09, 0.09]), σ = 3.16)

fit_results = fit(model, population, params, Pumas.FOCE())
inspect_results = inspect(fit_results)
inspect_df = DataFrame(inspect_results)
# observations_vs_time
observations_vs_time(inspect_results)

# subject_fits
subject_fits(inspect_results)
sf = subject_fits(inspect_results, separate = true, paginate = true, facet = true)
sf[1]
sf[2]

report(sf, output = "subject_fits.pdf", title ="Subject fits")


# Empirical Bayes distribution
empirical_bayes_dist(inspect_results)

## Goodness of fit plots 
goodness_of_fit(inspect_results)

# observations_vs_ipredictions
interactive(observations_vs_ipredictions(inspect_results))

# observations_vs_predictions
interactive(observations_vs_predictions(inspect_results))

# wresiduals_vs_time
wresiduals_vs_time(inspect_results)

# wresiduals_vs_predictions
wresiduals_vs_predictions(inspect_results)

## iwresiduals

#iwresiduals_vs_ipredictions
iwresiduals_vs_ipredictions(inspect_results)

#iwresiduals_vs_time
iwresiduals_vs_time(inspect_results)

# simulation plots
sim_plot(inspect_results)

## Covariate plots
covariates_check(inspect_results)

#empirical_bayes_vs_covariates
empirical_bayes_vs_covariates(inspect_results)

#wresiduals_vs_covariates
wresiduals_vs_covariates(inspect_results)

#convergence_trace
convergence_trace(inspect_results)

#VPCs
vpc_df = vpc(fit_results)
plt = vpc_plot(vpc_df)