using PumasUtilities
using NCA
using NCAUtilities
using CairoMakie
using DataFramesMeta
using CSV
using Pumas

df = CSV.read("data/data4NCA_sad.csv", DataFrame)

pk_nca = read_nca(df,
                      id = :id,
                      time = :time,
                      amt = :amt,
                      observations = :concentration,
                      group = [:doselevel],
                      route = :route)


# Group check 
figures= groups_check(pk_nca, grouplabels = ["Dose (mg)"]) 

save("myfig.png", figures; pt_per_unit=3)

# observations_vs_time
figures =
    observations_vs_time(
        pk_nca;
        axis = (
            xlabel = "Time (hours)",
            ylabel = "CTMX Concentration (μg/mL)",
        ),
        paginate = true,
        facet = (combinelabels = true,),
    )

figures[1]
figures[2]

report(figures, output="obsvstime.png", title = "observations vs time")

# summary_observations_vs_time
summary_observations_vs_time(
    pk_nca,
    figure = (
        fontsize = 20,
    ),
    axis = (
        xlabel = "Time (hr)",
        ylabel = "CTMX Concentration (μg/mL)",
    ),
    facet = (combinelabels = true,),
)


pk_nca_report  = run_nca(pk_nca)

# parameters_vs_group
parameters_vs_group(pk_nca_report; parameter = :vz_f_obs)

# parameters_dist
parameters_dist(pk_nca_report; parameter = :aucinf_obs)

# subject_fits
figures = 
    subject_fits(
        pk_nca_report;
        paginate = true,
        separate = true,
        figure = (
            fontsize = 12,
        ),
        axis = (
            xlabel = "Time (hr)",
            ylabel = "CTMX Concentration (μg/mL)"
        ),
        facet = (combinelabels = true,),
    )

figures[1]
figures[2]
