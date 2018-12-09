include("includes.jl")

using LTGA, Classes
using MetaGraphs, LightGraphs, Graphs
using DataFrames, GLM, Plots
using Gadfly, Compose, GraphPlot

function exploreLandscape(problem_index::Int64)
    problem_index == 1 ? number_of_parameters = 40 : number_of_parameters = 50
    return exploreLandscape(problem_index, number_of_parameters, 10)
end

function exploreLandscape(problem_index::Int64, number_of_parameters::Int64, population_size::Int64)
    LONutility.constructLON(problem_index, number_of_parameters)
    vtr = number_of_parameters / 4
    meanFit = Float64[]
    runs = 0
    successes = 0
    while length(LONutility.unexplored) > 0
        obj, isSuccessful = runGA(problem_index, number_of_parameters, population_size, "lt", 100000, vtr, 0.0)
        append!(meanFit, obj)
        successes += isSuccessful ? 1 : 0
        # println("Run $runs completed. Best obj, : $(maximum(obj))")
        runs += 1
    end
    resetGA()
    return (runs, sum(successes), mean(meanFit))
end

function createFitnessRowVector(idx, N)
    blocksize = 4
    nOptimas = 2 ^ Int(N / blocksize)
    F = Array{Float64}(1,nOptimas)
    for i = 0:nOptimas-1
        optFitness, dummy = installedProblemEvaluation( idx, Decoder.decodeOptimum(i, N, idx))
        F[1,i+1] = optFitness
    end
    return F
end

function computeR2coefficients(arr1, arr2)
    data = DataFrame(X = arr1, Y = arr2)
    ols = lm(@formula(X ~ Y), data)
    return r2(ols)
end

function multiplyFitnessByPageRank(G,F,P)
    optimum = parse(get_prop(G, 1, :optimum))
    Ftmp = hcat(F[optimum])
    for i = 2:length(P)
        optimum = parse(get_prop(G, i, :optimum))
        Ftmp = hcat(Ftmp, F[optimum])
    end
    return (Ftmp * P)[1]
end

function getIndexOfOptimum(G, opt::String)
    return LONutility.findInGraph(G, opt)
end

function runExperiment(idx, N, p, t)
    global_optimum = "$((2^Int(N/4))-1)"
    # create fitness vector F containing fitnesses of all local optima
    F = createFitnessRowVector(idx, N)

    # Create image dir
    mkpath("images/$N vars/pop $p")
    Avg_f = Array{Float64}(t)
    Exp_f = Array{Float64}(t)
    P_opt = Array{Float64}(t)
    p_s = Array{Float64}(t)
    lonStats = Array{Stats}(t)
    # run GA t times
    for i = 1:t
        start = time()
        runs, successes, mean_f = exploreLandscape(idx, N, p)
        # gather t pagerank vectors P and t percentages success p_s
        G = LONutility.LON
        P = pagerank(G, 1.0, 10000)

        #adjust weights based on runs
        weights = finalizeWeights(G, runs)

        # # Draw LON
        # drawLON(G, N, p, P, weights, i)

        # Get LON stats
        lonStats[i] = getStats(G, global_optimum)

        opt_index = getIndexOfOptimum(G, global_optimum)

        if opt_index < 0
            error("Global optima was not explored by LTGA")
        end
        P_opt[i] = P[opt_index]

        p_s[i] = successes / runs
        # gather t average solution fitness achieved Avg_f
        Avg_f[i] = mean_f
        # multiply each pagerank vector P by the fitness vector F to obtain Exp_f vector of size t
        # Exp_f[i] = (F * P)[1]
        Exp_f[i] = multiplyFitnessByPageRank(G, F, P)
        finish = time()
        println("Run $i completed in $(finish - start) seconds")
        println("Exp Fitness : $(Exp_f[i]), Avg fitness : ", Avg_f[i])
        println("P_opt       : $(P_opt[i]), Success %   : ", p_s[i])
        gc()
    end

    # compute R2 coefficient for p_s and P_opt
    # compute R2 coefficient for Exp_f and Avg_f

    return (P_opt, p_s, Exp_f, Avg_f, lonStats)
end

function finalizeWeights(G, runs)
    weights = Float64[]
    for e in LightGraphs.edges(G)
        push!(weights, get_prop(G, e, :weight)/runs)
    end
    return weights
end

function getStats(G, optimum::String)::Stats
    stats = Stats(0.0, 0, 0.0)
    nodes = LightGraphs.vertices(G)
    opt =  LONutility.findInGraph(G , optimum )
    for i in nodes
        if i != opt
            d = LightGraphs.yen_k_shortest_paths(G, i , opt).dists
            if length(d) > 0
                stats.avgPath += d[1]
            end
        end
    end
    for i in nodes
        stats.avgInDegree += get_in_degree(G, i)
    end
    stats.avgInDegree /= nodes[end]
    stats.avgPath /= nodes[end]
    stats.nodes = nodes[end]
    return stats
end

function drawLON(G, N, p, P, weights, run)
    nodesize = [P[v] for v in LightGraphs.vertices(G)]
    alphas = nodesize/maximum(nodesize)
    nodelabelsize = 50 + nodesize
    nodefillc = [RGBA(0.0,0.8,0.8,maximum([.15, i])) for i in alphas]
    nodelabel = [get_prop(G, i, :optimum) for i = LightGraphs.vertices(G)]
    layout=(args...)->spring_layout(args...; C=18)
    draw(SVG("TEST-population-$p.svg", 40cm, 40cm), gplot(G, layout = layout, nodelabel = nodelabel, nodelabelsize=nodelabelsize, nodefillc=nodefillc, EDGELINEWIDTH = 2.0, edgelinewidth = weights ))
end

function runWithFixedSize(size)
    P = Float64[]
    ps = Float64[]
    E = Float64[]
    Avg = Float64[]
    stats = Stats[]
    pops = [3:12]
    for pop in pops
        a, b, c, d, s= runExperiment(1, size, pop, 50)
        stats = append!(stats, s)
        P = append!(P,a)
        ps = append!(ps,b)
        E = append!(E,c)
        Avg = append!(Avg,d)
    end
    return P, ps, E, Avg, stats
end

function runWithFixedPop(pop)
    P = Float64[]
    ps = Float64[]
    E = Float64[]
    Avg = Float64[]
    nvar = [28, 32, 36, 40, 44, 48]
    for n in nvar
        a, b, c, d = runExperiment(1, n, pop, 50)
        P = append!(P,a)
        ps = append!(ps,b)
        E = append!(E,c)
        Avg = append!(Avg,d)
    end
    return P, ps, E, Avg
end


function assessLTGAperformance(sizes::Array{Int64}, populations::Array{Int64})
    cd("C:\\Users\\Paolo\\Desktop\\tesi\\JULIA-LTGA")
    for size in sizes
        mkdir("$(pwd())\\$size vars")
        cd("$size vars")
        vtr = size / 4
        for pop in populations
            mkdir("$(pwd())\\population - $pop")
            cd("population - $pop")
            for i = 1:50
                obj, isSuccessful = runGA(1, size, pop, "lt", 100000, vtr, 0.0, i)
                resetGA()
                gc()
            end
            cd("..")
        end
        cd("..")
    end
end
