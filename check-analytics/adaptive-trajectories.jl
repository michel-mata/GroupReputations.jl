# begin
#     using Pkg
#     using Pkg
#     Pkg.activate(".")
#     using Revise
#     using GroupReputations
#     using Statistics, StatsBase
#     using DelimitedFiles, JLD, SharedArrays
#     using Plots
# end

begin
    num_workers = 5
    include("./setup.jl")
end

@everywhere  begin
    using DelimitedFiles, JLD, SharedArrays
    using Statistics, Plots
end


begin
    simulation = "trajectories"
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
    initial_p = 0.1#:0.2:1.0
    # Sweep parameters
    ind_reps_scale = [2,1,0]
    grp_reps_scale = [2,1,0]
    # Simulation parameters
    mutation = "local"
    interaction_steps = N^2
    imitation_steps = 5
    generations = 1_500
    repetitions = 5
    norm = social_norms[1]
    c1,c2,c3,c4,r1,r2 = palette(:tab10)[[1,end,3,end-1,2,5]]
    index = [ (ir,sr,p0)  for ir in [ind_reps_scale...],
                              sr in [grp_reps_scale...],
                              p0 in [initial_p...]][:]
end


for i in index
    (ir,sr,p0) = i
    "running -- reps$ir stpyes$sr -- ic $p0"|>println
    all_probs = [p0]

    # Path of results
    path  = "$simulation/"*
            "$norm-$ir$sr/"*
            "pr$p0-"*
            "a$(game_pars[end])-"*
            "bc$(game_pars[1]/game_pars[2])/"
    !ispath("results/"*path) && mkpath("results/"*path)
    !ispath("data/"*path) && mkpath("data/"*path)

    probs = SharedArray{Float64,2}(generations,repetitions)

    @sync @distributed for r in 1:repetitions
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
                continue
                "error"|>println
            end

            # Less gens, load old probabilities
            old_probs = readdlm("results/"*path*"probabilities_$r.csv",',')
            g0 = pop.generation
            probabilities[1:g0] = old_probs

            # Same gens, save and break
            if pop.generation == generations
                "$ir-$sr-$p0-$r done! -- "|>println
                probs[:,r] = old_probs
                continue
                "error"|>println
            end
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

        probs[:,r] = probabilities

        p_f = plot(probabilities, label="",
                xlabel="generations",ylabel="p",
                title="$p0",
                yrange=(0,1), frame=:box, w=1.5, color=r1)
        savefig(p_f,"data/"*path*"probs_$r.pdf")

        # p_r |> display
        # p_s |> display
        # p_f |> display
        "$ir-$sr-$p0-$r done! -- "|>println
    end

    writedlm("results/"*path*"probabilities.csv",probs,',')
    p_f = plot(mean(probs,dims=2), ribbon=std(probs,dims=2)/sqrt(num_workers),
            label="",
            xlabel="generations",ylabel="p",
            title="$p0",
            yrange=(0,1), frame=:box, w=1.5, color=r1)
    savefig(p_f,"data/"*path*"probs.pdf")
end

begin
    probs = SharedArray{Float64,2}(generations,repetitions)

    p0 = 0.1
    ir = 0
    sr = 2
    # Path of results
    path  = "$simulation/"*
            "$norm-$ir$sr/"*
            "pr$p0-"*
            "a$(game_pars[end])-"*
            "bc$(game_pars[1]/game_pars[2])/"
    #probs = readdlm("results/"*path*"probabilities.csv")
    for r in 1:repetitions
        probs[:,r] = readdlm("results/"*path*"probabilities_$r.csv",',')
    end
    writedlm("results/"*path*"probabilities.csv",probs,',')

    p_f = plot(mean(probs,dims=2), ribbon=std(probs,dims=2)/sqrt(num_workers),
            label="",
            xlabel="generations",ylabel="p",
            title="$p0",
            yrange=(0,1), frame=:box, w=1.5, color=r1)
    savefig(p_f,"data/"*path*"probs.pdf")
end

p_f
