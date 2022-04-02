module GroupReputations

    using Distributed
    using StatsBase, Statistics, Distributions
    using JLD, SharedArrays, DelimitedFiles

    # Structures
    include("./module/structs.jl")
    export Game, Population, Tracker

    # Evolutionary dynamics
    include("./module/methods/evolution.jl")
    export update_individual_reputations!
    export update_group_reputations!
    export update_actions_and_fitness!
    export update_strategies!
    export evolve!
    export play!

    # Measuring functions
    include("./module/methods/get_functions.jl")
    export track!
    export get_reps_ind, get_reps_grp

    # Simulate conditions
    include("./module/methods/simulation.jl")
    export random_population
    export random_population_invasion
    export run_simulations
    export run_simulations_trajectories
    export summarize

    # Constant variables
    const social_norms = ["SJ", "SS", "SC", "SH"]
    export social_norms

end
