# Methods to compute quantities using struct Population
"""
Function to extract strategy frequencies
    Returns a num_groups-by-num_strategies matrix
    with entry (g,s) = frequency of strat s in group g
"""
function get_frequencies(
    pop::Population
    )
    return [ mean(pop.strategies[pop.membership.==g].==s) for g in 1:pop.num_groups, s in pop.initial_strategies ]
end

function get_probabilities(
    pop::Population
    )
    return [ mean(pop.probs[pop.membership.==g].==p) for g in 1:pop.num_groups, p in pop.all_probs ]
end


"""
Function to extract cooperation
    Returns a num_groups-by-num_groups matrix
    with entry (g1,g2) = fraction of g1-g2 interactions that are cooperative
"""
function get_cooperation(
    pop::Population
    )
    return [ mean(pop.actions[pop.membership.==g1, pop.membership.==g2]) for g1 in 1:pop.num_groups, g2 in 1:pop.num_groups ]
end

"""
Function to extract average individual and group reputations
    Returns a num_groups-by-num_groups matrix
    with entry (g1,g2) = average reputation (ind/grp) of g2 as viewd by g1
"""
function get_reps_ind(
    pop::Population
    )
    return [ mean(pop.reps_ind[pop.membership.==g1, pop.membership.==g2]) for g1 in 1:pop.num_groups, g2 in 1:pop.num_groups ]
end

function get_reps_grp(
    pop::Population
    )
    return [ mean(pop.reps_grp[pop.membership.==g1, g2]) for g1 in 1:pop.num_groups, g2 in 1:pop.num_groups ]
end

"""
Function to measure the average agreement of the individual reputations
within the population
    Returns a float
"""
function get_agreement_ind(
    pop::Population
    )
    return mean([ mean( pop.reps_ind[i,:] .== pop.reps_ind[j,:] ) for i in 1:pop.N for j in 1:pop.N ])
end

function get_agreement_grp(
    pop::Population
    )
    return mean([ mean( pop.reps_grp[i,:] .== pop.reps_grp[j,:] ) for i in 1:pop.N for j in 1:pop.N ])
end


"""
Update tracker during simulations
"""
function track!(
    pop::Population
    )

    pop.tracker.freq_strategies     += (get_frequencies(pop) - pop.tracker.freq_strategies) / pop.generation

    for (i,s) in enumerate(pop.initial_strategies)
        if sum(pop.strategies.==s) > 0
            pop.tracker.pres_strategies[i] += 1
            fitn = [ mean((pop.membership .== g) .& (pop.strategies .== s)) for g in 1:pop.num_groups ]
            pop.tracker.fitn_strategies[:,i] += (fitn - pop.tracker.fitn_strategies[:,i] ) / pop.tracker.pres_strategies[i]
        end
    end

    pop.tracker.freq_probabilities  += (get_probabilities(pop) - pop.tracker.freq_probabilities) / pop.generation

    for (i,p) in enumerate(pop.all_probs)
        if sum(pop.probs.==p) > 0
            pop.tracker.pres_probabilities[i] += 1
            fitn = [ mean((pop.membership .== g) .& (pop.probs .== p)) for g in 1:pop.num_groups ]
            pop.tracker.fitn_probabilities[:,i] += (fitn - pop.tracker.fitn_probabilities[:,i] ) / pop.tracker.pres_probabilities[i]
        end
    end

    pop.tracker.cooperation         += (get_cooperation(pop)-pop.tracker.cooperation) / pop.generation
    pop.tracker.reps_grp            += (get_reps_grp(pop)-pop.tracker.reps_grp) / pop.generation
    pop.tracker.reps_ind            += (get_reps_ind(pop)-pop.tracker.reps_ind) / pop.generation
    pop.tracker.global_cooperation  += (mean(pop.actions)-pop.tracker.global_cooperation) / pop.generation
    pop.tracker.agreement_ind       += (get_agreement_ind(pop)-pop.tracker.agreement_ind) / pop.generation
    pop.tracker.agreement_grp       += (get_agreement_grp(pop)-pop.tracker.agreement_grp) / pop.generation

end
