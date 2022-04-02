struct Game

    b::Float64      # benefit
    c::Float64      # cost
    w::Float64      # selection strength
    u_s::Float64    # mutation rate
    u_p::Float64    # performance error
    u_a::Float64    # assignment error
    α::Float64      # cost for using individual reputation

    function Game(
        b::Float64,
        c::Float64,
        w::Float64,
        u_s::Float64,
        u_p::Float64,
        u_a::Float64,
        α::Float64
        )
        return new(b, c, w, u_s, u_p, u_a, α)
    end
end

mutable struct Tracker

    freq_strategies::Array{Float64,1}
    fitn_strategies::Array{Float64,1}
    pres_strategies::Array{Int64,1}

    freq_probabilities::Array{Float64,1}
    fitn_probabilities::Array{Float64,1}
    pres_probabilities::Array{Int64,1}

    cooperation::Array{Float64,2}
    reps_grp::Array{Float64, 2}
    reps_ind::Array{Float64, 2}
    global_cooperation::Float64
    agreement_ind::Float64
    agreement_grp::Float64

end

mutable struct Population
    # Size
    N::Int64                            # number of individuals
    # Interactions
    game::Game                          # game parameters
    norm::String                        # social norm for reps updating
    # Strategies
    initial_strategies::Array{Int64,1}      # array of allowed strategies
    evolving_strategies::Array{Int64,1}     # array of evolving strategies
    num_strategies::Int64                   # number of strategies
    # Probabilities
    all_probs::Array{Float64,1}             # array of possible values of p
    num_probabilities::Int64                # number of probabilities
    # Groups
    group_sizes::Array{Float64, 1}      # array of relative group sizes         #NOTE: ternary plots, simulations
    num_groups::Int64                   # number of groups                      #NOTE: explore all
    # Mutation type
    mutation::String
    # Individual reputations
    ind_reps_scale::Int32               # individual reputation type: public or private
    # Group reputations
    grp_reps_scale::Int32               # group reputation type: public or private
    # Storage
    strategies::Array{Int64, 1}         # array of strategies
    membership::Array{Int64, 1}         # array of group memberships
    reps_ind::Array{Int64, 2}           # matrix of individual reputations
    reps_grp::Array{Int64, 2}           # matrix of group reputations
    prev_reps_ind::Array{Int64, 2}      # matrix of previous individual reputations
    prev_reps_grp::Array{Int64, 2}      # matrix of previous group reputations
    fitness::Array{Float64, 1}          # array of fitness
    actions::Array{Int64, 2}            # matrix of actions
    probs::Array{Float64, 1}            # array of probs of acting using group reps     #NOTE: MAIN
    # Current generation
    generation::Int64
    tracker::Tracker
end
