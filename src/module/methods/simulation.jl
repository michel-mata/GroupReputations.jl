# Methods for the main simulation

"""
Sample vector of `size` parameters from `values` proportional to `weights`.
Or sample uniformly if `weights` not given.
"""
function sample_parameters(
    size,
    values = [0,1],
    weights = [0.5,0.5]
    )
    # Given weights
    if length(values) == length(weights)
        result = sample([values...], Weights([weights...]),size)
    # Sample uniformly
    else
        result = sample([values...],size)
    end

    return result
end

"""
Assign group membership given relative sizes of the groups
"""
function assign_membership(
        N::Int64,
        group_sizes::Array{Float64, 1},
        num_groups::Int64
    )
    # Allocate memory
    membership = ones(Int64, N)
    # Index
    group_index = Int.(floor.(group_sizes./sum(group_sizes)*N)) |> cumsum
    # Assignment
    for i in 2:num_groups
        membership[group_index[i-1]+1:group_index[i]] .= i
    end

    return membership
end

"""
Function to generate an instance of Population
with randomized strategies and reputations
"""
function random_population(
    N::Int64,
    game::Game,
    norm = "SJ",
    initial_strategies = [0],
    evolving_strategies = [0],
    possible_mutations = [0],
    prob_values = 0.5,
    prob_weights = [0.5, 0.5],
    ind_reps_scale = 0,
    grp_reps_scale = 0,
    group_sizes = [0.5, 0.5]
    )
    # Strategies
    strategies          = sample_parameters( N, initial_strategies)
    # Groups
    num_groups          = length(group_sizes)
    membership          = assign_membership( N, group_sizes, num_groups)
    # Probabilities of using group reputations
    probs               = sample_parameters( N, prob_values, prob_weights)
    all_probs           = [prob_values...]
    # Unconditional strategies use assumed group reputations
    if sum(strategies .!= 0)>0
        probs[strategies .!= 0] .= 1.0
    end
    # Initial conditions
    reps_ind            = sample_parameters((N, N))
    prev_reps_ind       = reps_ind |> deepcopy
    reps_grp            = sample_parameters((N, num_groups))
    prev_reps_grp       = reps_grp |> deepcopy
    actions             = sample_parameters((N, N))
    interactions        = sample_parameters((N, N))
    fitness             = sample_parameters( N, 0.0)
    # Set generation count
    generation = 0

    return Population(
        N, game, norm,
        initial_strategies,
        evolving_strategies,
        possible_mutations,
        all_probs,
        num_groups, group_sizes,
        ind_reps_scale,
        grp_reps_scale,
        strategies, membership,
        reps_ind, reps_grp,
        prev_reps_ind, prev_reps_grp,
        fitness, actions, interactions,
        probs, generation
        )
end

"""
Run simulations in parallel.
Sweeping parameters:
    - social norms
    - reputation public or private
    - reputation based or nor on behavior
    - probability of using individual over group reputations
    - rate of reputation updating
"""
function run_simulations(
            N::Int64,
            game_pars::Vector,
            generations::Int64,
            repetitions::Int64,
            initial_repetition::Int64,
            simulation_title::String,
            social_norms = "SJ",
            initial_strategies=[0],
            evolving_strategies=[0],
            possible_mutations=[0],
            prob_values = 0.5,
            ind_reps_scale = 0,
            grp_reps_scale = 0,
            prob_weights = [0.5, 0.5],
            group_sizes = [0.5, 0.5],
            burn_in = 5_000,
            report = Inf
        )


    reps = initial_repetition:(initial_repetition+repetitions-1)
    index = [ (r,norm,ir,gr) for  r in reps,
                                  norm in [social_norms...],
                                  ir in [ind_reps_scale...],
                                  gr in [grp_reps_scale...]][:]

    @sync @distributed for i in index
        (r,norm,ir,gr) = i
        # Parameters path
        path  = "results/"*
                "$simulation_title/"*
                "norm$norm-"*
                "type$(Int(ir))$(Int(gr))-"*
                "prob$prob_values-cost$(game_pars[end])"
        !ispath(path) && mkpath(path)
        # Files
        pop_file = path * "/pop_$r.jld"
        tracker_file = path * "/tracker_$r.jld"
        # Get population and tracker
        if !isfile(pop_file)
            # Get Game
            game = Game(game_pars...)
            # Get Population
            pop  = random_population( N, game, norm,
                                    initial_strategies,
                                    evolving_strategies,
                                    possible_mutations,
                                    prob_values, prob_weights,
                                    ir, gr, group_sizes)
            # Burn in generations
            [ evolve!(pop) for _ in burn_in ]
            pop.generation = 0
            # Get Tracker
            tracker = init_tracker(pop)
        else
            # if population exists, load it
            pop = load(pop_file,"pop")
            # load tracker for expanding simulation
            tracker = load(tracker_file,"tracker")
        end
        # Relate population with tracker
        tracker.population_path = pop_file
        # if generations not reached
        if pop.generation < generations
            # Run generations
            for gen in 1:(generations-pop.generation)
                # evolve
                evolve!(pop)
                # update tracker
                track!(tracker,pop)
                # report
                (gen % report == 0) && _report(tracker,pop)
            end
        end
        # Save Population
        save(pop_file, "pop", pop)
        # Save Tracker
        save(tracker_file, "tracker", tracker)
        # Report finish
        types = ["public ","groupal","private"]
        ">>  $norm  |  "*
        "ind : $(types[Int(ir)+1])"*
        "grp : $(types[Int(gr)+1])"*
        "prob : $(prob_values)  |  cost : $(game_pars[end])" |> println
    end
end
