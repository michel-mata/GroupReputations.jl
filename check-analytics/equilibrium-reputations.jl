begin
    num_workers = 8
    include("./setup.jl")
end

@everywhere begin
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
    burn_in = false
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
    repetitions = num_workers
    norm = social_norms[1]
    c1,c2,c3,c4,r1,r2 = palette(:tab10)[[1,end,3,end-1,2,5]]
end


index = [ (ir,sr,p1,p0)  for ir in [ind_reps_scale...],
                    sr in [grp_reps_scale...],
                    p1 in [invaders...],
                    p0 in [residents...]][:]

@sync @distributed for i in index
    (ir,sr,p1,p0) = i
    "running -- reps$ir stpyes$sr -- res $p0 inv $p1"|>println
    all_probs = [p0,p1]

    # Path of results
    path  = "$simulation/"*
            "$norm-$ir$sr/"*
            "pr$p0-pi$p1-"*
            "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"
    !ispath("results/"*path) && mkpath("results/"*path)
    !ispath("data/"*path) && mkpath("data/"*path)

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

        reputations = SharedArray{Float64,2}(generations,2pop.num_groups)
        stereotypes = SharedArray{Float64,2}(generations,2pop.num_groups)
        fitness = SharedArray{Float64,2}(generations,pop.num_probabilities)

        # Dynamics
        for gen in 1:generations
            play!(pop)
            track!(pop)
            # Save states
            reputations[gen,:] = pop.tracker.reps_ind[:][[1,4,2,3]]
            stereotypes[gen,:] = pop.tracker.reps_grp[:][[1,4,2,3]]
            fitness[gen,:] = pop.tracker.fitn_probabilities
        end
        # Save trajectories
        writedlm("results/"*path*"reputations_$r.csv",reputations,',')
        writedlm("results/"*path*"stereotypes_$r.csv",stereotypes,',')
        writedlm("results/"*path*"fitness_$r.csv",fitness,',')

        # Save Plots
        p_r = plot(reputations[:,1:4],
                label=["r11" "r22" "r12" "r21"],
                xlabel="generations",ylabel="reputations",
                title="res $p0, inv $p1",
                yrange=(0,1), frame=:box, w=1.2,
                line=[:solid :dash :solid :dash],
                color=[c1 c2 c3 c4],legend=:outerright)
        savefig(p_r,"data/"*path*"reputations_$r.pdf")

        p_s = plot(stereotypes[:,1:4],
                label=["s11" "s22" "s12" "s21"],
                xlabel="generations",ylabel="stereotypes",
                title="res $p0, inv $p1",
                yrange=(0,1), frame=:box, w=1.2,
                line=[:solid :dash :solid :dash],
                color=[c1 c2 c3 c4],legend=:outerright)
        savefig(p_s,"data/"*path*"stereotypes_$r.pdf")

        p_f = plot(fitness, label=["res" "inv"],
                xlabel="generations",ylabel="fitness",
                title="res $p0, inv $p1",
                yrange=(0,2), frame=:box,w=1.2,color=[r1 r2],
                legend=:outerright)
        savefig(p_f,"data/"*path*"fitness_$r.pdf")

        # p_r |> display
        # p_s |> display
        # p_f |> display
        "$r done!"|>println
    end
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
        reputations = mean([readdlm("results/"*path*"reputations_$r.csv",',') for r in 1:repetitions])
        stereotypes = mean([readdlm("results/"*path*"stereotypes_$r.csv",',') for r in 1:repetitions])
        fitness = mean([readdlm("results/"*path*"fitness_$r.csv",',') for r in 1:repetitions])
        res, inv = mean(fitness[end-1_000:end,:],dims=1)
        push!(data,[p0,p1,inv-res])
        # Save Plots
        p_r = plot(reputations[:,1:4],
                label=["r11" "r22" "r12" "r21"],
                xlabel="generations",ylabel="reputations",
                title="res $p0, inv $p1",
                yrange=(0,1), frame=:box, w=1.2,
                line=[:solid :dash :solid :dash],
                color=[c1 c2 c3 c4],legend=:outerright)
        savefig(p_r,"data/"*path*"reputations.pdf")

        p_s = plot(stereotypes[:,1:4],
                label=["s11" "s22" "s12" "s21"],
                xlabel="generations",ylabel="stereotypes",
                title="res $p0, inv $p1",
                yrange=(0,1), frame=:box, w=1.2,
                line=[:solid :dash :solid :dash],
                color=[c1 c2 c3 c4],legend=:outerright)
        savefig(p_s,"data/"*path*"stereotypes.pdf")

        p_f = plot(fitness, label=["res" "inv"],
                xlabel="generations",ylabel="fitness",
                title="res $p0, inv $p1",
                yrange=(0,2), frame=:box,w=1.2,color=[r1 r2],
                legend=:outerright)
        savefig(p_f,"data/"*path*"fitness.pdf")
    end
    path  = "$simulation/"*
            "$norm-$ir$sr/"
    !ispath("data/"*path) && mkpath("data/"*path)
    writedlm("data/"*path*"data.csv",hcat(data...)',',')
end

@sync @distributed for i in index
    (ir,sr,p1,p0) = i
        "running -- reps$ir stpyes$sr -- res $p0 inv $p1"|>println
        all_probs = [p0,p1]

        # Path of results
        path  = "$simulation/"*
                "$norm-$ir$sr/"*
                "pr$p0-pi$p1-"*
                "a$(game_pars[end])-bc$(game_pars[1]/game_pars[2])/"
        !ispath("results/"*path) && mkpath("results/"*path)
        !ispath("data/"*path) && mkpath("data/"*path)

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

            reputations = SharedArray{Float64,2}(generations,2pop.num_groups)
            stereotypes = SharedArray{Float64,2}(generations,2pop.num_groups)
            fitness = SharedArray{Float64,2}(generations,pop.num_probabilities)

            # Dynamics
            for gen in 1:generations
                play!(pop)
                track!(pop)
                # Save states
                reputations[gen,:] = pop.reps_ind[:][[1,4,2,3]]
                stereotypes[gen,:] = pop.reps_grp[:][[1,4,2,3]]
                fitness[gen,:] = [ mean(pop.fitness[pop.probs .== p]) for p in pop.all_probs]
            end
            # Save trajectories
            writedlm("results/"*path*"reputations_time_$r.csv",reputations,',')
            writedlm("results/"*path*"stereotypes_time_$r.csv",stereotypes,',')
            writedlm("results/"*path*"fitness_time_$r.csv",fitness,',')

            # Save Plots
            p_r = plot(reputations[:,1:4],
                    label=["r11" "r22" "r12" "r21"],
                    xlabel="generations",ylabel="reputations",
                    title="res $p0, inv $p1",
                    yrange=(0,1), frame=:box, w=1.2,
                    line=[:solid :dash :solid :dash],
                    color=[c1 c2 c3 c4],legend=:outerright)
            savefig(p_r,"data/"*path*"reputations_time_$r.pdf")

            p_s = plot(stereotypes[:,1:4],
                    label=["s11" "s22" "s12" "s21"],
                    xlabel="generations",ylabel="stereotypes",
                    title="res $p0, inv $p1",
                    yrange=(0,1), frame=:box, w=1.2,
                    line=[:solid :dash :solid :dash],
                    color=[c1 c2 c3 c4],legend=:outerright)
            savefig(p_s,"data/"*path*"stereotypes_time_$r.pdf")

            p_f = plot(fitness, label=["res" "inv"],
                    xlabel="generations",ylabel="fitness",
                    title="res $p0, inv $p1",
                    yrange=(0,2), frame=:box,w=1.2,color=[r1 r2],
                    legend=:outerright)
            savefig(p_f,"data/"*path*"fitness_time_$r.pdf")

            # p_r |> display
            # p_s |> display
            # p_f |> display
            "$r done!"|>println
        end
    end
