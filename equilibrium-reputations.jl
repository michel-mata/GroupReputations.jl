begin
    using Pkg
    Pkg.activate(".")
    using Revise
    using GroupReputations
    using DelimitedFiles, JLD, SharedArrays
    using Plots
    using Statistics
end

begin
    simulation = "equilibrium-reputations"
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
    c1,c2,c3,c4,r1,r2 = palette(:tab10)[[1,end,3,end-1,2,5]]
end


for ir in [ind_reps_scale...], sr in [grp_reps_scale...]
    data = []
    for p1 in [invaders...], p0 in [residents...]
        "running -- reps$ir stpyes$sr -- res $p0 inv $p1"|>println
        all_probs = [p0,p1]

        # Path of results
        path  = "$simulation/"*
                "$norm-$ir$sr/"*
                "pr$p0-pi$p1-"*
                "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"
        !ispath("results/"*path) && mkpath("results/"*path)

        for r in 1:repetitions

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

            reputations = SharedArray{Float64,2}(gens,pop.num_groups)
            stereotypes = SharedArray{Float64,2}(gens,pop.num_groups)
            fitness = SharedArray{Float64,2}(gens,pop.num_probabilities)

            # Dynamics
            for gen in 1:generations
                play!(pop)
                track!(pop)
                # Save states
                reputations[gen,:] = pop.tracker.reps_ind[:][[1,4,2,3]]
                stereotypes[gen,:] pop.tracker.reps_grp[:][[5,8,6,7]]
                fitness[gen,:] = pop.tracker.fitn_probabilities
            end
            # Save trajectories
            writedlm("results/"*path*"reputations_$r.csv",reputations,',')
            writedlm("results/"*path*"stereotypes_$r.csv",stereotypes,',')
            writedlm("results/"*path*"fitness_$r.csv",fitness,',')

            # Save Plots
            p_r = plot(reputations[:,1:4],label=["r11" "r22" "r12" "r21"],yrange=(0,1),
                    title="reputations",frame=:box,w=2,
                    line=[:solid :dash :solid :dash],
                    color=[c1 c2 c3 c4],legend=:outerright)
            savefig(p_r,"data/"*path*"reputations_$r.pdf")

            p_s = plot(reputations[:,5:end], label=["s11" "s22" "s12" "s21"],yrange=(0,1),
                    title="stereotypes",frame=:box,w=2,
                    line=[:solid :dash :solid :dash],
                    color=[c1 c2 c3 c4],legend=:outerright)
            savefig(p_r,"data/"*path*"stereotypes_$r.pdf")

            p_f = plot(fitness, label=["res" "inv"],
                    title="fitness",frame=:box,w=2,
                    color=[r1 r2],legend=:outerright)
            savefig(p_r,"data/"*path*"fitness_$r.pdf")


            "$r done!"|>println
        end
    end
end
