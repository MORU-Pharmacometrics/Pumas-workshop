using AlgebraOfGraphics
using CairoMakie
using DataFramesMeta
using CSV

df = CSV.read("data/iv_sd_demogs.csv", DataFrame; typemap=Dict(Int64 => String))

# ggplot( data=, aes=) + geom_*()

#data = 
data(df)

# aes()
mapping(:AGE, :eGFR)

# geom_*()
visual(Scatter)

# * will fuse two or more layers into one
# input: one or more layers
# output: ONE LAYER
plt = data(df) * mapping(:AGE, :eGFR) * visual(Scatter)
draw(plt)

# AoG Multiple Dispatch
plt_md = data(df) *
    mapping(
        :AGE => "Age in years",
        :eGFR => log => "eGFR (log scaled)"
        #:eGFR => log
    ) *
    visual(Scatter)
draw(plt_md)

# AoG keyword arguments inside mapping
plt_kw = data(df) *
    mapping(
        :AGE => "Age in years",
        :eGFR => log => "eGFR (log scaled)";
        color=:ISMALE => renamer(
            ["0" => "Female",
             "1" => "Male"]
        ) => "Sex"
    ) *
    visual(Scatter)
draw(plt_kw)

# Two ways of specifying kwargs
plt_1 = data(df) *
    mapping(
        :AGE => "Age in years",
        :eGFR => log => "eGFR (log scaled)";
        markersize=:WEIGHT => (x -> x / 7.5)
    ) *
    visual(Scatter)
draw(plt_1)

plt_2 = data(df) *
    mapping(
        :AGE => "Age in years",
        :eGFR => log => "eGFR (log scaled)"
    ) *
    # geom_point(size = X)
    visual(Scatter; markersize=15, color=:blue)
draw(
    plt_2;
    axis=(;
        ylabelsize=32,
        yticksize=18,
        yticklabelsize=24,
    )
)

# Faceting
# auto faceting is layout kwarg
plt_facet_auto = data(df) *
    mapping(
        :AGE,
        :eGFR;
        layout=:ISMALE => renamer(
            ["0" => "Female",
             "1" => "Male"],
        )
    ) *
    visual(Scatter)
draw(plt_facet_auto)

# row faceting is row kwarg
plt_facet_row = data(df) *
    mapping(
        :AGE,
        :eGFR;
        row=:ISMALE => renamer(
            ["0" => "Female",
             "1" => "Male"],
        )
    ) *
    visual(Scatter)
draw(plt_facet_row)

# column faceting is col kwarg
plt_facet_col = data(df) *
    mapping(
        :AGE,
        :eGFR;
        col=:ISMALE => renamer(
            ["0" => "Female",
             "1" => "Male"],
        ),
        color=:ISMALE => renamer(
            ["0" => "Female",
             "1" => "Male"],
        ),
    ) *
    visual(Scatter)
draw(plt_facet_col)

# Algebra over binary functions
# Associative property: a * (b * c) = (a * b) * c
# Distributive property: a * (b + c) = (a * b) + (a * c)

# Addition `+` SUPERIMPOSES LAYERS
mapping() + mapping()

# geom_smooth()
plt_linear = 
    data(df) *
    mapping(:AGE, :eGFR) *
    visual(Scatter) *
    AlgebraOfGraphics.linear()

draw(plt_linear)

# (a * b) + (a * c)
a = data(df) * mapping(:AGE, :eGFR)
b = visual(Scatter)
c = AlgebraOfGraphics.linear()

draw( (a * b) + (a * c) )

# a * (b + c)
draw(a * (b + c))

plt_algebra = 
    data(df) *
    mapping(:AGE,
            :eGFR;
            col=:ISMALE => renamer(
                ["0" => "Female",
                "1" => "Male"],
            ),
            color=:ISMALE => renamer(
                ["0" => "Female",
                "1" => "Male"],
            ),
    ) * # a
    # b + c
    (visual(Scatter) + AlgebraOfGraphics.linear())

draw(plt_algebra)