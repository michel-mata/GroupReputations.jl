module GroupReputations

    using Distributed
    using StatsBase, Statistics, Distributions
    using JLD, SharedArrays, DelimitedFiles

    # functions
    include("./module/structs.jl")
    export Game, Population, Tracker

    include("./module/methods/evolution.jl")
    export update_individual_reputations!
    export update_group_reputations!
    export update_actions_and_fitness!
    export update_strategies!
    export evolve!
    export play!

    include("./module/methods/get_functions.jl")
    export track!

    include("./module/methods/simulation.jl")
    export random_population
    export random_population_invasion
    export run_simulations
    export run_simulations_trajectories
    export summarize
    #
    # include("./module/methods/extractor.jl")
    # export extract_data
    # export extract_data_DISC



    # variables
    const social_norms = ["SJ"]#, "SS", "SC", "SH"]
    export social_norms

end
