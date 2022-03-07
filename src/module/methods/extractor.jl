# Methods for extracting data from simulations
"""
Extract all data from several simulations
"""
function extract_data(simulation_title::String)

    data =  "data/$simulation_title/"
    !ispath(data) && mkpath(data)

    colnames = [:N, :norm, :all_strategies, :num_groups, :group_sizes, :generation,
                :ind_scale, :grp_scale, :ind_recip, :grp_recip, :ind_base, :grp_base,
                :ind_src_ind, :grp_src_grp, :ind_assume, :grp_assume,
                :bias, :prob, :rate, :cost,
                :agree_ind, :agree_grp, :cooperation, :coop_11, :coop_12, :coop_21, :coop_22,
                :reps_ind_11, :reps_ind_12, :reps_ind_21, :reps_ind_22,
                :reps_grp_11, :reps_grp_12, :reps_grp_21, :reps_grp_22,
                :freq1_ALLC, :freq1_ALLD, :freq1_DISC,
                :freq2_ALLC, :freq2_ALLD, :freq2_DISC,
                :fitness1_ALLC, :fitness1_ALLD, :fitness1_DISC,
                :fitness2_ALLC, :fitness2_ALLD, :fitness2_DISC]

    parameters = readdir("results/"*simulation_title*"/",join=true)
    num_parameters = length(parameters)

    @sync @distributed for parameter in parameters
        "summarizing --- $parameter" |> println
        files = readdir(parameter, join=false)
        pops = filter( (file)->contains(file,"pop") , files )
        trackers = filter( (file)->contains(file,"tracker") , files )

        reps_pop = parse.(Int,first.(split.(last.(split.(pops,"_")),"."))) |> sort!
        reps_trck = parse.(Int,first.(split.(last.(split.(trackers,"_")),"."))) |> sort!
        any(reps_pop .!== reps_trck) && @error("Not all Populations have Tracker!\nCheck: $parameter")
        reps = collect(1:length(reps_pop))

        results = Array{Any}(undef,length(reps),length(colnames))
        results_file = parameter*"/results.jld"

        for r in reps
            tracker = load(parameter*"/"*trackers[r],"tracker")
            pop = load(parameter*"/"*pops[r],"pop")
            results[r,:] = [
                pop.N, pop.norm, pop.all_strategies, pop.num_groups,
                pop.group_sizes, pop.generation,
                mean(Int.(pop.ind_reps_scale)),
                mean(Int.(pop.grp_reps_scale)),
                mean(Int.(pop.ind_recipient_membership)),
                mean(Int.(pop.grp_recipient_membership)),
                mean(Int.(pop.ind_reps_base)),
                mean(Int.(pop.grp_reps_base)),
                mean(Int.(pop.ind_reps_src_ind)),
                mean(Int.(pop.grp_reps_src_grp)),
                mean(Int.(pop.ind_reps_assume)),
                mean(Int.(pop.grp_reps_assume)),
                pop.out_bias,
                sort(unique(pop.probs)),
                sort(unique(pop.rates)),
                sort(unique(pop.costs)),
                tracker.avg_agreement_ind, tracker.avg_agreement_grp,
                tracker.avg_global_cooperation,
                tracker.avg_cooperation[1,1], tracker.avg_cooperation[1,2],
                tracker.avg_cooperation[2,1], tracker.avg_cooperation[2,2],
                tracker.avg_reps_ind[1,1], tracker.avg_reps_ind[1,2],
                tracker.avg_reps_ind[2,1], tracker.avg_reps_ind[2,2],
                tracker.avg_reps_grp[1,1], tracker.avg_reps_grp[1,2],
                tracker.avg_reps_grp[2,1], tracker.avg_reps_grp[2,2],
                tracker.avg_frequencies[1,1], tracker.avg_frequencies[1,2], tracker.avg_frequencies[1,3],
                tracker.avg_frequencies[2,1], tracker.avg_frequencies[2,2], tracker.avg_frequencies[2,3],
                tracker.avg_fitness[1,1], tracker.avg_fitness[1,2], tracker.avg_fitness[1,3],
                tracker.avg_fitness[2,1], tracker.avg_fitness[2,2], tracker.avg_fitness[2,3]
            ]
            #println("Hello5")
        end
        save(results_file,"results",results)
    end

    "aggregating results..." |> println
    dfs = [ DataFrame(load(parameter*"/results.jld", "results"),colnames) for parameter in parameters]
    df = vcat(dfs...)
    "writing results..." |> println
    CSV.write(data*"data.csv",df)
    "DONE!" |> println

end

# Methods for extracting data from simulations
"""
Extract all data from several simulations
"""
# TODO: generalize this function!!!!!
function extract_data_DISC(simulation_title::String)

    data =  "data/$simulation_title/"
    !ispath(data) && mkpath(data)

    colnames = [:N, :norm, :all_strategies, :num_groups, :group_sizes, :generation,
                :ind_scale, :grp_scale, :ind_recip, :grp_recip, :ind_base, :grp_base,
                :ind_src_ind, :grp_src_grp, :ind_assume, :grp_assume,
                :bias, :prob, :rate, :cost,
                :agree_ind, :agree_grp, :cooperation, :coop_11, :coop_12, :coop_21, :coop_22,
                :reps_ind_11, :reps_ind_12, :reps_ind_21, :reps_ind_22,
                :reps_grp_11, :reps_grp_12, :reps_grp_21, :reps_grp_22,
                :freq1_DISC,
                :freq2_DISC,
                :fitness1_DISC,
                :fitness2_DISC]

    parameters = readdir("results/"*simulation_title*"/",join=true)
    num_parameters = length(parameters)

    @sync @distributed for parameter in parameters
        "summarizing --- $parameter" |> println
        files = readdir(parameter, join=false)
        pops = filter( (file)->contains(file,"pop") , files )
        trackers = filter( (file)->contains(file,"tracker") , files )

        reps_pop = parse.(Int,first.(split.(last.(split.(pops,"_")),"."))) |> sort!
        reps_trck = parse.(Int,first.(split.(last.(split.(trackers,"_")),"."))) |> sort!
        any(reps_pop .!== reps_trck) && @error("Not all Populations have Tracker!\nCheck: $parameter")
        reps = collect(1:length(reps_pop))

        results = Array{Any}(undef,length(reps),length(colnames))
        results_file = parameter*"/results.jld"
        for r in reps
            tracker = load(parameter*"/"*trackers[r],"tracker")
            pop = load(parameter*"/"*pops[r],"pop")
            results[r,:] = [
                pop.N, pop.norm, pop.all_strategies, pop.num_groups,
                pop.group_sizes, pop.generation,
                mean(Int.(pop.ind_reps_scale)),
                mean(Int.(pop.grp_reps_scale)),
                mean(Int.(pop.ind_recipient_membership)),
                mean(Int.(pop.grp_recipient_membership)),
                mean(Int.(pop.ind_reps_base)),
                mean(Int.(pop.grp_reps_base)),
                mean(Int.(pop.ind_reps_src_ind)),
                mean(Int.(pop.grp_reps_src_grp)),
                mean(Int.(pop.ind_reps_assume)),
                mean(Int.(pop.grp_reps_assume)),
                pop.out_bias,
                sort(unique(pop.probs)),
                sort(unique(pop.rates)),
                sort(unique(pop.costs)),
                tracker.avg_agreement_ind, tracker.avg_agreement_grp,
                tracker.avg_global_cooperation,
                tracker.avg_cooperation[1,1], tracker.avg_cooperation[1,2],
                tracker.avg_cooperation[2,1], tracker.avg_cooperation[2,2],
                tracker.avg_reps_ind[1,1], tracker.avg_reps_ind[1,2],
                tracker.avg_reps_ind[2,1], tracker.avg_reps_ind[2,2],
                tracker.avg_reps_grp[1,1], tracker.avg_reps_grp[1,2],
                tracker.avg_reps_grp[2,1], tracker.avg_reps_grp[2,2],
                tracker.avg_frequencies[1,:]...,
                tracker.avg_frequencies[2,:]...,
                tracker.avg_fitness[1,:]...,
                tracker.avg_fitness[2,:]...
            ]
        end
        save(results_file,"results",results)
    end

    "aggregating results..." |> println
    dfs = [ DataFrame(load(parameter*"/results.jld", "results"),colnames) for parameter in parameters]
    df = vcat(dfs...)
    "writing results..." |> println
    CSV.write(data*"data.csv",df)
    "DONE!" |> println

end
