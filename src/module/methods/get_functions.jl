# Methods to compute quantities using struct Population
"""
Function to extract strategy frequencies
    Returns a num_groups-by-num_strategies matrix
    with entry (g,s) = frequency of strat s in group g
"""
function get_frequencies(
    pop::Population
    )
    return [ proportions(pop.strategies[ pop.membership .== g ],s:s) |> first for g in 1:pop.num_groups, s in pop.initial_strategies ]
end

function get_p_frequencies(
    pop::Population
    )
    return [ proportions(pop.probs[ pop.membership .== g ],s:s) |> first for g in 1:pop.num_groups, s in pop.all_probs ]
end


"""
Function to extract cooperation
    Returns a num_groups-by-num_groups matrix
    with entry (g1,g2) = fraction of g1-g2 interactions that are cooperative
"""
function get_cooperation(
    pop::Population
    )
    return [ sum(pop.actions[ pop.membership .== g1, pop.membership .== g2]) / (pop.group_sizes[g1] * pop.group_sizes[g2] * pop.N * pop.N) for g1 in 1:pop.num_groups, g2 in 1:pop.num_groups ]
end

"""
Function to extract average fitness
    Returns a num_groups-by-num_strategies matrix
    with entry (g,s) = average fitness of strat s in group g
"""
function get_avg_fitness(
    pop::Population
    )
    return [ mean(pop.fitness[ (pop.membership .== g) .& (pop.strategies .== s) ]) for g in 1:pop.num_groups, s in pop.initial_strategies ]
end

"""
Function to extract average individual and group reputations
    Returns a num_groups-by-num_groups matrix
    with entry (g1,g2) = average reputation (ind/grp) of g2 as viewd by g1
"""
function get_reps_ind(
    pop::Population
    )
    return [ mean(pop.reps_ind[ pop.membership .== g1, pop.membership .== g2 ]) for g1 in 1:pop.num_groups, g2 in 1:pop.num_groups ]
end

function get_reps_grp(
    pop::Population
    )
    return [ mean(pop.reps_grp[ pop.membership .== g1, g2 ]) for g1 in 1:pop.num_groups, g2 in 1:pop.num_groups ]
end

"""
Function to measure the average agreement of the individual reputations
within the population
    Returns a float
"""
function get_agreement_ind(
    pop::Population
    )
    return mean(1 .- pairwise(Hamming(), pop.reps_ind, dims=1)./pop.N)
end
function get_agreement_grp(
    pop::Population
    )
    return mean(1 .- pairwise(Hamming(), pop.reps_grp, dims=1)./pop.num_groups)
end
