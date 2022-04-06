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
        group_sizes::Array{Float64, 1}
    )
    # Allocate memory
    membership = ones(Int64, N)
    # Index
    group_index = Int.(floor.(group_sizes./sum(group_sizes)*N)) |> cumsum
    # Assignment
    for i in 2:length(group_sizes)
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
    game_pars::Array{Float64,1},
    norm::String,
    interaction_steps::Int64,
    imitation_steps::Int64,
    initial_strategies::Array{Int64,1},
    evolving_strategies::Array{Int64,1},
    all_probs::Array{Float64,1},
    mutation::String,
    ind_reps_scale::Int64,
    grp_reps_scale::Int64,
    strats_weights::Array{Float64,1},
    prob_weights::Array{Float64,1},
    group_sizes::Array{Float64,1}
    )
    # Get Game
    game = Game(game_pars...)
    # Strategies
    strategies          = sample_parameters( N, initial_strategies, strats_weights )
    # Groups
    num_groups          = length(group_sizes)
    membership          = assign_membership( N, group_sizes )
    # Probabilities of using group reputations
    probs               = sample_parameters( N, all_probs, prob_weights)
    all_probs           = [all_probs...]
    # Unconditional strategies use assumed group reputations
    sum(strategies .!= 0)>0 && (probs[strategies .!= 0] .= 1.0)
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
    # Get tracker
    num_strategies = length(initial_strategies)
    num_probabilities = length(all_probs)
    tracker = Tracker(
                    zeros(Float64, num_strategies),
                    zeros(Float64, num_strategies),
                    zeros(Int64, num_strategies),
                    zeros(Float64, num_probabilities),
                    zeros(Float64, num_probabilities),
                    zeros(Int64, num_probabilities),
                    zeros(Float64, num_groups, num_groups),
                    zeros(Float64, num_groups, num_groups),
                    zeros(Float64, num_groups, num_groups),
                    0.0, 0.0, 0.0
                    )
    # Get population
    pop = Population( N, game, norm, interaction_steps, imitation_steps,
                initial_strategies, evolving_strategies, num_strategies,
                all_probs, num_probabilities, group_sizes, num_groups,
                mutation, ind_reps_scale, grp_reps_scale,
                strategies, membership,
                reps_ind, reps_grp, prev_reps_ind, prev_reps_grp,
                fitness, actions, probs, generation,tracker
                )

    pop.generation = 0

    return pop
end


"""
Function to generate an instance of Population
with a resident population and one invader
"""
function random_population_invasion(
    N::Int64,
    game_pars::Array{Float64,1},
    norm::String,
    interaction_steps::Int64,
    imitation_steps::Int64,
    initial_strategies::Array{Int64,1},
    evolving_strategies::Array{Int64,1},
    all_probs::Array{Float64,1},
    mutation::String,
    ind_reps_scale::Int64,
    grp_reps_scale::Int64,
    strats_weights::Array{Float64,1},
    prob_weights::Array{Float64,1},
    group_sizes::Array{Float64,1}
    )
    # Get Game
    game = Game(game_pars...)
    # Strategies
    strategies          = sample_parameters( N, initial_strategies, strats_weights )
    # Groups
    num_groups          = length(group_sizes)
    membership          = assign_membership( N, group_sizes )
    # Probabilities of using group reputations
    all_probs           = [all_probs...]
    # Resident population
    probs = [ all_probs[1] for _ in 1:N ]
    # Single Mutant
    probs[end] = all_probs[2]

    # Unconditional strategies use assumed group reputations
    sum(strategies .!= 0)>0 && (probs[strategies .!= 0] .= 1.0)
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
    # Get tracker
    num_strategies = length(initial_strategies)
    num_probabilities = length(all_probs)
    tracker = Tracker(
                    zeros(Float64, num_strategies),
                    zeros(Float64, num_strategies),
                    zeros(Int64, num_strategies),
                    zeros(Float64, num_probabilities),
                    zeros(Float64, num_probabilities),
                    zeros(Int64, num_probabilities),
                    zeros(Float64, num_groups, num_groups),
                    zeros(Float64, num_groups, num_groups),
                    zeros(Float64, num_groups, num_groups),
                    0.0, 0.0, 0.0
                    )
    # Get population
    pop = Population( N, game, norm, interaction_steps, imitation_steps,
                initial_strategies, evolving_strategies, num_strategies,
                all_probs, num_probabilities, group_sizes, num_groups,
                mutation, ind_reps_scale, grp_reps_scale,
                strategies, membership,
                reps_ind, reps_grp, prev_reps_ind, prev_reps_grp,
                fitness, actions, probs, generation,tracker
                )

    pop.generation = 0

    return pop
end

"""
Function to simulate the evolution of a population
with multiple strategies or multiple probabilities
"""
function simulate!(
            pop_file::String,
            generations::Int64,
            N::Int64,
            game_pars::Array{Float64,1},
            norm::String,
            type::String,
            initial_strategies::Array{Int64,1},
            evolving_strategies::Array{Int64,1},
            p,
            mutation,
            ir,
            gr,
            strats_weights = 1.0,
            prob_weights = 1.0,
            group_sizes = [0.5,0.5]
    )

    # Check if population exists
    if !isfile(pop_file)
        # If not, create it
        pop  = random_population( N, game_pars, norm,
                    interaction_steps,
                    imitation_steps,
                    [initial_strategies...],
                    [evolving_strategies...],
                    [p...],
                    mutation,
                    ir, gr,
                    [strats_weights...],
                    [prob_weights...],
                    group_sizes)
    else
        # If yes, with less generations than asked, load it
        pop = load(pop_file,"pop")
        if pop.generation >= generations
            return nothing
        end
    end
    # Evolve
    for gen in 1:(generations-pop.generation)
        evolve!(pop)
        track!(pop)
    end
    # Save Population
    save(pop_file, "pop", pop)
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
            simulation::String,
            generations::Int64,
            repetitions::Int64,
            N::Int64,
            game_pars::Array{Float64,1},
            social_norms::Array{String,1},
            type::String,
            initial_strategies::Array{Int64,1},
            evolving_strategies::Array{Int64,1},
            all_probs,
            mutation,
            ind_reps_scale,
            grp_reps_scale,
            strats_weights = 1.0,
            prob_weights = 1.0,
            group_sizes = [0.5,0.5]
        )

    if type == "strategies"
        index = [ (r,norm,ir,gr,p) for  r in 1:repetitions,
                                  norm in [social_norms...],
                                  ir in [ind_reps_scale...],
                                  gr in [grp_reps_scale...],
                                  p in [all_probs...]][:]

        @sync @distributed for i in index
            (r,norm,ir,gr,p) = i

            path  = "results/$simulation/"*
                    "$norm-$ir$gr/"*
                    "s$(join(initial_strategies))-"*
                    "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"*
                    "p$p/"
            !ispath(path) && mkpath(path)
            pop_file = path * "pop_$r.jld"

            simulate!(pop_file,generations, N, game_pars, norm,
                initial_strategies, evolving_strategies,
                p, mutation, ir, gr,
                strats_weights, prob_weights, burn_in, group_sizes
            )
        end
    elseif type == "probabilities"
        index = [ (r,norm,ir,gr) for  r in 1:repetitions,
                                  norm in [social_norms...],
                                  ir in [ind_reps_scale...],
                                  gr in [grp_reps_scale...]][:]

        @sync @distributed for i in index
            (r,norm,ir,gr) = i

            path  = "results/$simulation/"*
                    "$norm-$ir$gr/"*
                    "s$(join(initial_strategies))-"*
                    "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"
            !ispath(path) && mkpath(path)
            pop_file = path * "pop_$r.jld"

            simulate!(pop_file,generations, N, game_pars, norm,
                initial_strategies, evolving_strategies,
                all_probs, mutation, ir, gr,
                strats_weights, prob_weights, burn_in, group_sizes
            )
        end
    end

end


"""
Function for extracting data in parallel
of a simulation with multiple repetitions
"""
function extract(
            simulation::String,
            repetitions::Int64,
            game_pars::Array{Float64,1},
            type::String,
            initial_strategies::Array{Int64,1},
            norm, p, all_probs,
            ir, gr, group_sizes
        )

    num_groups = length(group_sizes)

    num_strategies = length(initial_strategies)
    num_probabilities = length(all_probs)

    path  = "results/$simulation/"*
            "$norm-$ir$gr/"*
            "s$(join(initial_strategies))-"*
            "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"
    # Path for results
    if type == "strategies"
        path *= "p$p/"
        num_probabilities = 1
    end

    freq_strategies = SharedArray{Float64,3}(repetitions,num_groups,num_strategies)
    fitn_strategies = SharedArray{Float64,3}(repetitions,num_groups,num_strategies)
    freq_probabilities = SharedArray{Float64,3}(repetitions,num_groups,num_probabilities)
    fitn_probabilities = SharedArray{Float64,3}(repetitions,num_groups,num_probabilities)
    cooperation = SharedArray{Float64,3}(repetitions,num_groups,num_groups)
    reputations = SharedArray{Float64,3}(repetitions,num_groups,num_groups)
    stereotypes = SharedArray{Float64,3}(repetitions,num_groups,num_groups)
    agree_reputations = SharedArray{Float64,1}(repetitions)
    agree_stereotypes = SharedArray{Float64,1}(repetitions)

    @time @sync @distributed  for r in 1:repetitions
        pop_file = path*"pop_$r.jld"
        tracker = load(pop_file,"pop").tracker
        freq_strategies[r,:,:] = tracker.freq_strategies
        fitn_strategies[r,:,:] = tracker.fitn_strategies
        freq_probabilities[r,:,:] = tracker.freq_probabilities
        fitn_probabilities[r,:,:] = tracker.fitn_probabilities
        cooperation[r,:,:] = tracker.cooperation
        reputations[r,:,:] = tracker.reps_ind
        stereotypes[r,:,:] = tracker.reps_grp
        agree_reputations[r] = tracker.agreement_ind
        agree_stereotypes[r] = tracker.agreement_grp
    end

    freq_strats = mean(mean(freq_strategies,dims=1),dims=2)[:]
    fitn_strats = mean(mean(fitn_strategies,dims=1),dims=2)[:]
    freq_probs = mean(mean(freq_probabilities,dims=1),dims=2)[:]
    fitn_probs = mean(mean(fitn_probabilities,dims=1),dims=2)[:]

    coop = mean(cooperation,dims=1)[1,:,:]
    in_coop = mean([coop[i,j] for i in 1:num_groups, j in 1:num_groups if i==j])
    out_coop = mean([coop[i,j] for i in 1:num_groups, j in 1:num_groups if i!=j])

    reps = mean(reputations,dims=1)[1,:,:]
    in_reps = mean([reps[i,j] for i in 1:num_groups, j in 1:num_groups if i==j])
    out_reps = mean([reps[i,j] for i in 1:num_groups, j in 1:num_groups if i!=j])

    stypes = mean(stereotypes,dims=1)[1,:,:]
    in_stypes = mean([stypes[i,j] for i in 1:num_groups, j in 1:num_groups if i==j])
    out_stypes = mean([stypes[i,j] for i in 1:num_groups, j in 1:num_groups if i!=j])

    agree_reps = mean(agree_reputations)
    agree_stypes = mean(agree_stereotypes)


    return [norm, ir, gr, num_strategies, num_probabilities, p,
            freq_strats...,fitn_strats...,
            freq_probs...,fitn_probs...,
            in_coop, out_coop,
            in_reps, out_reps,
            agree_reps, agree_stypes]
end


"""
Function for summarizing results across
parameters and repetitions
"""
function summarize(
            simulation::String,
            repetitions::Int64,
            game_pars::Array{Float64,1},
            social_norms::Array{String,1},
            type::String,
            initial_strategies::Array{Int64,1},
            evolving_strategies::Array{Int64,1},
            all_probs,
            ind_reps_scale,
            grp_reps_scale,
            group_sizes = [0.5,0.5]
    )

    if type == "strategies"
        index = [ (p,norm,ir,gr) for  norm in [social_norms...],
                                ir in [ind_reps_scale...],
                                gr in [grp_reps_scale...],
                                p in all_probs][:]
        V = []
        for i in index
            (p,norm,ir,gr) = i

            push!(V, extract( simulation, repetitions, game_pars,
            type, initial_strategies, norm, p,
            all_probs, ir, gr, group_sizes)
            )
        end
    elseif type == "probabilities"
        index = [ (norm,ir,gr) for  norm in [social_norms...],
                                ir in [ind_reps_scale...],
                                gr in [grp_reps_scale...]][:]
        V = []
        for i in index
            (norm,ir,gr) = i

            push!(V, extract( simulation, repetitions, game_pars,
            type, initial_strategies, norm, "all",
            all_probs, ir, gr, group_sizes)
            )
        end
    end


    path  = "data/$simulation/"

    !ispath(path) && mkpath(path)
    writedlm(path*"data.csv",V,',')
end
