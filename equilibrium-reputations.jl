begin
    num_workers = 4
    include("./setup.jl")
end

@everywhere  begin
    using DelimitedFiles, JLD, SharedArrays
    using Plots
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
    u_s  = 1/N
    u_p  = 1/N
    u_a  = 1/N
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
    residents = 0.0:0.1:1.0
    invaders = 0.0:0.1:1.0
    # Sweep parameters
    ind_reps_scale = [0,1,2]
    grp_reps_scale = [0,1,2]
    # Simulation parameters
    mutation = "local"
    generations = 1_000N
    repetitions = 10
    norms = social_norms[1:1]
end


index = [ (norm,ir,gr,p0,p1) for norm in [norms...],
                          ir in [ind_reps_scale...],
                          gr in [grp_reps_scale...],
                          p0 in residents,
                          p1 in invaders][:]

for i in index
    (norm,ir,gr,p0,p1) = i
    # Array for trajectories
    ps = SharedArray{Float64,2}(repetitions,generations)
    # Path of results
    path  = "$simulation/"*
            "$norm-$ir$gr/"*
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
                                    ir, gr,
                                    [strats_weights...],
                                    [prob_weights...],
                                    burn_in,
                                    group_sizes)
            burn_in && [ play!(pop) for _ in 1:100N ]
            pop.generation = 0
        else
            # If it exists, load, check gens, load prev states
            pop = load(pop_file,"pop")
            (pop.generation >= generations) && continue
            # Load previous states if exist
            states = readdlm("data/"*path*"states.csv",',')
            ps[r,1:g0] = states[r,:]
        end


        # play
        for gen in 1:(generations-pop.generation)
            play!(pop)
            track!(pop)
            # Save state of trajectory
            ps[r,g0+gen] = mean(pop.probs)
        end
        # Save Population
        save(pop_file, "pop", pop)
    end
    # Save trajectories
    !ispath("data/"*path) && mkpath("data/"*path)
    writedlm("data/"*path*"states.csv",ps,',')
end


for p0 in residents, p1 in invaders
    all_probs = [p0,p1]
    ps = SharedArray{Float64,2}(repetitions,2)

    # Path for results
    path = "$simulation/$norm-$ir$gr/pr$p0-pi$p1-a$α-bc$(b/c)/"
    !ispath(path) && mkpath(path)

    @sync @distributed for r in 1:repetitions

        # Create or load population
        pop_file = path*"pop_$r.jld"
        # Check if population exists
        if !isfile(pop_file)
            pop = random_population_invasion(N,game_pars,norm,initial_strategies,evolving_strategies,all_probs,mutation,
                                    ir,gr,strats_weights,prob_weights,burn_in,group_sizes)
        g0 = pop.generation

        burn_in && [ play!(pop) for _ in 1:100N ]
        pop.generation = 0

        ind_res = SharedArray{Float64,1}(generations-g0)
        ind_inv = SharedArray{Float64,1}(generations-g0)
        grp_res = SharedArray{Float64,1}(generations-g0)
        grp_inv = SharedArray{Float64,1}(generations-g0)

        @time for g in 1:(generations-g0)
            update_actions_and_fitness!(pop)
            update_individual_reputations!(pop)
            update_group_reputations!(pop)

            pop.generation += 1

            f0[g] = mean(pop.reps_ind[:,1:end-1])
            f1[g] = mean(pop.reps_ind[:,end])
        end

        ps[r,1] = mean(f0)
        ps[r,2] = mean(f1)

        save(pop_file, "pop", pop)

        "$r done!"|>println
    end
    "saving..."|>println

    path = "data/$simulation/$norm-$ir$gr/pr$p0-pi$p1-a$α-bc$(b/c)/"
    !ispath(path) && mkpath(path)
    writedlm(path*"states.csv",ps,',')
    "done!"|>println

    plot(ps,label="",title="res $p0 , inv $p1")|>display
end
end
