begin
    num_workers = 8
    include("./setup.jl")
end

@everywhere  begin
    using DelimitedFiles, JLD, SharedArrays
    using Statistics
end

begin
    simulation = "PIP"
    # Population size
    N    = 50
    # Payoff parameters
    b    = 3.0
    c    = 1.0
    # Selection strength
    w    = 1
    # Mutation rates
    u_s  = 0/N
    u_p  = 0.02
    u_a  = 0.02
    α    = 0.3
    # Game parameters
    game_pars = [b, c, w, u_s, u_p, u_a, α]
    game =  Game(game_pars...)
    # Population parameters
    strats_weights = 1.0
    prob_weights = 1.0
    burn_in = true
    group_sizes = [0.5,0.5]
    initial_strategies = [0]
    evolving_strategies = [0]
    # Strategies
    residents = 0.0:0.1:1.0
    invaders = 0.0:0.1:1.0
    # Sweep parameters
    ind_reps_scale = [0,1,2]
    grp_reps_scale = [0,1,2]
    # Simulation parameters
    mutation = "local"
    generations = 100N
    repetitions = 2num_workers
    norm = social_norms[1]
end


for ir in [ind_reps_scale...], sr in [grp_reps_scale...]
    data = []
    for p1 in [invaders...], p0 in [residents...]
        "running -- reps$ir stpyes$sr -- res $p0 inv $p1"|>println
        all_probs = [p0,p1]
        # Arrays for data
        Reps = SharedArray{Float64,2}(repetitions,8)
        Fitn = SharedArray{Float64,2}(repetitions,2)
        # Path of results
        path  = "$simulation/"*
                "$norm-$ir$sr/"*
                "pr$p0-pi$p1-"*
                "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"
        !ispath("results/"*path) && mkpath("results/"*path)

        @sync @distributed for r in 1:repetitions
            pop_file = "results/" * path * "pop_$r.jld"
            # If population doesn't exist, create it
            if !isfile(pop_file)
                pop  = random_population_invasion( N, game_pars, norm,
                                        [initial_strategies...],
                                        [evolving_strategies...],
                                        [all_probs...],
                                        mutation,
                                        ir, sr,
                                        [strats_weights...],
                                        [prob_weights...],
                                        burn_in,
                                        group_sizes)
                g0 = 0
                burn_in && [ play!(pop) for _ in 1:100N]
            else
                # If it exists, load, check gens, load prev states
                pop = load(pop_file,"pop")
                (pop.generation >= generations) && continue
                g0 = pop.generation
            end

            gens = generations-g0

            # Dynamics
            for gen in 1:gens
                play!(pop)
                track!(pop)
            end
            # Save Population
            save(pop_file, "pop", pop)

            # Save cumulative temporal averages
            Reps[r,:] = [pop.tracker.reps_ind...,pop.tracker.reps_grp...][[1,4,2,3,5,8,6,7]]
            Fitn[r,:] = pop.tracker.fitn_probabilities

            "$r done!"|>println
        end
        # Save trajectories
        res, inv = mean(Fitn,dims=1)
        push!(data,[p0,p1,inv-res,mean(Reps,dims=1)...])
    end
    path  = "$simulation/"*
            "$norm-$ir$sr/"
    !ispath("data/"*path) && mkpath("data/"*path)
    writedlm("data/"*path*"data.csv",hcat(data...)',',')
end
