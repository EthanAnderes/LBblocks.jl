using Documenter, LBblocks

makedocs(;
    modules=[LBblocks],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/EthanAnderes/LBblocks.jl/blob/{commit}{path}#L{line}",
    sitename="LBblocks.jl",
    authors="Ethan Anderes",
    assets=String[],
)

deploydocs(;
    repo="github.com/EthanAnderes/LBblocks.jl",
)
