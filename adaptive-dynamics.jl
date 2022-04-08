"setting directory..." |> print
    (@__DIR__) == pwd() || cd(@__DIR__)
    any(LOAD_PATH .== pwd()) || push!(LOAD_PATH, pwd())
"done, set in \n\t'$(pwd())'!" |> println

"activating environment..." |> print
    using Pkg
    Pkg.activate(".")
"done!" |> println

"loading modules..." |> print
    using GroupReputations
    using DelimitedFiles, JLD, SharedArrays, Statistics
"done!" |> println

"declaring variables..." |> print
    const id = parse(Int64, ENV["SLURM_ARRAY_TASK_ID"])
    # Simulation
    simulation = "adaptive-dynamics"
    # Population size
    N    = 50
    # Payoff parameters
    b    = 3.0
    c    = 1.0
    # Selection strength
    w    = 1
    # Mutation rates
    u_s  = 10/N
    u_p  = 0.02
    u_a  = 0.02
    a    = 0.3
    # Game parameters
    game_pars = [b, c, w, u_s, u_p, u_a, a]
    game =  Game(game_pars...)
    # Population parameters
    strats_weights = 1.0
    prob_weights = 1.0
    group_sizes = [0.5,0.5]
    burn_in = false
    initial_strategies = [0]
    evolving_strategies = [0]
    # Strategies
    initial_p = 0.1:0.2:1.0
    # Sweep parameters
    ind_reps_scale = [2]
    grp_reps_scale = [2]
    # Simulation parameters
    mutation = "local"
    interaction_steps = N^2
    imitation_steps = 5
    generations = 12N^2
    repetitions = 100
    norm = social_norms[1]
    index = [ (r,ir,sr,p0)  for r in 1:repetitions,
                              ir in [ind_reps_scale...],
                              sr in [grp_reps_scale...],
                              p0 in [initial_p...]][:]
    (r,ir,sr,p0) = index[id]
"done!" |> println


"running -- reps$ir stpyes$sr -- ic $p0" |> println
    all_probs = [p0]

    # Path of results
    path  = "$simulation/"*
            "$norm-$ir$sr/"*
            "pr$p0-"*
            "a$(game_pars[end])-"*
            "bc$(game_pars[1]/game_pars[2])/"
    !ispath("results/"*path) && mkpath("results/"*path)
    !ispath("data/"*path) && mkpath("data/"*path)

    probabilities = SharedArray{Float64,1}(generations)

    pop_file = "results/" * path * "pop_$r.jld"
    # If population doesn't exist, create it
    if !isfile(pop_file)
        pop  = random_population( N, game_pars, norm,
                                interaction_steps,
                                imitation_steps,
                                [initial_strategies...],
                                [evolving_strategies...],
                                [all_probs...],
                                mutation,
                                ir, sr,
                                [strats_weights...],
                                [prob_weights...],
                                group_sizes)
        g0 = pop.generation
    else
        # If it exists, load
        pop = load(pop_file,"pop")
        # More gens than requested break
        if pop.generation > generations
            "$ir-$sr-$p0-$r done! -- "|>println
            exit()
            "error"|>println
        end
        # Less gens, load old probabilities
        old_probs = readdlm("results/"*path*"probabilities_$r.csv",',')
        g0 = pop.generation
        probabilities[1:g0] = old_probs
    end

    # Dynamics
    @time for gen in 1:(generations-g0)
        evolve!(pop)
        track!(pop)
        # Save states
        probabilities[gen+g0] = mean(pop.probs)
    end

    # Save population
    save("results/"*path*"pop_$r.jld", "pop", pop)
    # Save trajectories
    writedlm("results/"*path*"probabilities_$r.csv",probabilities,',')
"done!" |> println
