# Methods for struct Population
#
# Functions beginning with underscore calculate values
# Functions ending with exclamation mark mutate struct
#
"""
Norm
    Returns assessment given:
    - Donor's action
    - Recipient's reputation
"""
function _norm(
    action::Int64,
    reputation::Int64,
    norm_ID::String
    )
    # Select norm
    (norm_ID == "SJ") && (norm = [1 0; 0 1])
    (norm_ID == "SH") && (norm = [0 0; 0 1])
    (norm_ID == "SC") && (norm = [0 0; 1 1])
    (norm_ID == "SS") && (norm = [1 0; 1 1])
    # Assessment
    return norm[action+1, reputation+1]
end

"""
Individual Reputation
    1. Sample random recipient
    2. Observe action of donor
    3. Use previous reputation to assess
"""
function _ind_reputation(
    pop::Population,
    i::Int64,
    j::Int64
    )

    # Select recipient
    k = 1:pop.N |> sample
    # Action of the donor
    a = pop.actions[j,k]
    # Individual reputation of the recipient
    r = pop.prev_reps_ind[i,k]
    # Assessment
    return _norm( a, r, pop.norm)

end

"""
Group Reputation
    1. Sample member of group as donor
    2. Sample random recipient
    3. Observe action of donor
    4. Use previous reputation to assess
"""
function _grp_reputation(
    pop::Population,
    i::Int64,
    g_j::Int64
    )

    # Random donor from the group
    j = (pop.membership .== g_j) |> findall |> sample
    # Random recipient
    k = 1:pop.N |> sample
    # Action of the donor
    a = pop.actions[j,k]
    # Group reputation of the recipient
    l = pop.membership[k]
    r = pop.prev_reps_grp[i,l]
    # Assessment
    return _norm( a, r, pop.norm)
end

"""
Update Individual Reputations
    If private, every pair.
    If public, broadcast random observer.
    Implement assumption about reps of in-group and out-group members.
"""
function update_individual_reputations!(
    pop::Population
    )
    # Timestep
    pop.prev_reps_ind = pop.reps_ind |> deepcopy
    pop.reps_ind .= 0
    # Public
    if pop.ind_reps_scale == 2
        for j in 1:pop.N
            # Random observer
            i = sample(1:pop.N)
            # Individual reputation
            r = _ind_reputation(pop,i,j)
            # Assignment error
            rand() < pop.game.u_a && (r = 1-r)
            # Broadcast
            pop.reps_ind[:,j] .= r
        end
    # Groupal
    elseif pop.ind_reps_scale == 1
        for g in 1:pop.num_groups, j in 1:pop.N
            # Members of group g
            g_i =  (pop.membership .== g) |> findall
            # Sample observer
            i = g_i |> sample
            # Individual reputation
            r = _ind_reputation(pop,i,j)
            # Assignment error
            rand() < pop.game.u_a && (r = 1-r)
            # Update
            pop.reps_ind[g_i,j] .= r
        end
    # Private
    elseif pop.ind_reps_scale == 0
        for i in 1:pop.N, j in i:pop.N
            # Both views
            r_ij = _ind_reputation(pop,i,j)
            r_ji = _ind_reputation(pop,j,i)
            # Assignment error
            rand() < pop.game.u_a && (r_ij = 1-r_ij)
            rand() < pop.game.u_a && (r_ji = 1-r_ji)
            # Update
            pop.reps_ind[i,j] = r_ij
            pop.reps_ind[j,i] = r_ji
        end
    end
end

"""
Update Group Reputations
    If private, every individual assess every group.
    If public, broadcast random observer.
    Implement assumption about grp reps of in-group and out-group members.
"""
function update_group_reputations!(
    pop::Population
    )
    # Update timestep
    pop.prev_reps_grp = pop.reps_grp |> deepcopy
    pop.reps_grp .= 0
    # Public
    if pop.grp_reps_scale == 2
        for g_j in 1:pop.num_groups
            # Random observer
            i = 1:pop.N |> sample
            # Reputation of group
            r = _grp_reputation(pop,i,g_j)
            # Assignment error
            rand() < pop.game.u_a && (r = 1-r)
            # Update broadcast
            pop.reps_grp[:,g_j] .= r
        end
    # Groupal
    elseif pop.grp_reps_scale == 1
        for g in 1:pop.num_groups, g_j in 1:pop.num_groups
            # Members of group g
            g_i = (pop.membership .== g) |> findall
            # Sample observer
            i = g_i |> sample
            # Both views
            r = _grp_reputation(pop,i,g_j)
            # Assignment error
            rand() < pop.game.u_a && (r = 1-r)
            # Update
            pop.reps_grp[g_i,g_j] .= r
        end
    # Private
    elseif pop.grp_reps_scale == 0
        for i in 1:pop.N, g_j in 1:pop.num_groups
            # Reputation of group in eyes of i
            r = _grp_reputation(pop,i,g_j)
            # Assignment error
            rand() < pop.game.u_a && (r = 1-r)
            # Update
            pop.reps_grp[i,g_j] = r
        end
    end
    # Assume good or bad for unconditional or tag-based strategies
    # This strategies are using fixed biased stereotypes
    # Defectors
    ALLD = pop.strategies .== 1
    sum(ALLD)>0 && (pop.reps_grp[ALLD,:] .= 0)
    # Cooperators
    ALLC = pop.strategies .== 2
    sum(ALLC)>0 && (pop.reps_grp[ALLC,:] .= 1)
    # Tag-based: cooperate in-group, defect out-group
    TAG = pop.strategies .== 3
    if sum(TAG) > 0
        for g in unique(pop.membership[TAG])
            # In-group
            g_i = (pop.membership[TAG] .== g) |> findall
            # Out-group
            g_j = (collect(1:pop.num_groups) .!= g) |> findall
            # Assign assumption
            pop.reps_grp[g_i,[g]] .= 1
            pop.reps_grp[g_i,g_j] .= 0
        end
    end
end

"""
Update Actions
    Round of pairwise interactions
    Use individual reputations with some probability
"""
function update_actions_and_fitness!(
    pop::Population
    )
    # New fitness
    pop.fitness .= 0
    # Round of pairwise games
    for i in 1:pop.N, j in i:pop.N
        # Individual reputations
        r_ij = pop.reps_ind[i,j]
        r_ji = pop.reps_ind[j,i]
        # Group memberships
        g_i, g_j = pop.membership[[i,j]]
        # Group reputations
        g_ij = pop.reps_grp[i,g_j]
        g_ji = pop.reps_grp[j,g_i]
        # Determine the action of i towards j
        a_ij, c_ij = rand() < pop.probs[i] ? (g_ij,0) : (r_ij,1)
        a_ji, c_ji = rand() < pop.probs[j] ? (g_ji,0) : (r_ji,1)
        # Performance error
        rand() < pop.game.u_p && (a_ij = 0)
        rand() < pop.game.u_p && (a_ji = 0)
        # Save
        pop.actions[i,j] = a_ij
        pop.actions[j,i] = a_ji
        # Payoff of interaction
        pop.fitness[i] += pop.game.b * a_ji - pop.game.c * a_ij - pop.game.α * c_ij
        pop.fitness[j] += pop.game.b * a_ij - pop.game.c * a_ji - pop.game.α * c_ji
    end
    # Average fitness across interactions
    pop.fitness ./= pop.N
end


#TODO: mix this
"""
Update Strategies
"""
function update_strategies!(
    pop::Population
    )
    # Indexes of evolving strategies
    evolving = (s-> s ∈ pop.evolving_strategies).(pop.strategies) |> findall

    # Imitation
    # Select two individuals to compare
    i,j = sample(evolving,2)
    # Compute probability of imitation
    p = 1. / (1. + exp(-pop.game.w*(pop.fitness[j]-pop.fitness[i])))
    # Update strategy and probability of using stypes
    if rand() < p
        pop.strategies[i] = pop.strategies[j]
        pop.probs[i] = pop.probs[j]
    end


    # Innovation
    if rand() < pop.game.u_s
        # Select random strategy
        new_strategy = sample(pop.evolving_strategies)
        # Random global or local probability
        if pop.mutation == "global"
            new_prob = sample(pop.all_probs)
        elseif pop.mutation == "local"
            new_prob = pop.probs[i] + rand(Normal(0.0,0.05))
            (new_prob > 1.0) && (new_prob = 1.0)
            (new_prob < 0.0) && (new_prob = 0.0)
        end
        # Update
        pop.strategies[i] = new_strategy
        # If player is not pDISC, i.e.,
        # is ALLD,ALLC,or TAG
        # use their biased stereotypes
        pop.probs[i] = pop.strategies[i]==0 ? new_prob : 1.0
    end
end

"""
Generation of evolutionary process
"""
function evolve!(
    pop::Population
    )
    update_actions_and_fitness!(pop)
    update_individual_reputations!(pop)
    update_group_reputations!(pop)
    update_strategies!(pop)

    pop.generation += 1
end

"""
Dynamics without evolutionary process
"""
function play!(
    pop::Population
    )
    update_actions_and_fitness!(pop)
    update_individual_reputations!(pop)
    update_group_reputations!(pop)

    pop.generation += 1
end
