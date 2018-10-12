include("includes.jl")

using LTGA
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
        obj, isSuccessful = runGA(problem_index, number_of_parameters, population_size, "mp", 100000, vtr, 0.0)
        append!(meanFit, obj)
        successes += isSuccessful ? 1 : 0
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
    const global_optimum = "$((2^Int(N/4))-1)"
    # create fitness vector F containing fitnesses of all local optima
    F = createFitnessRowVector(idx, N)

    Avg_f = Array{Float64}(t)
    Exp_f = Array{Float64}(t)
    P_opt = Array{Float64}(t)
    p_s = Array{Float64}(t)
    # run GA t times
    for i = 1:t
        start = time()
        runs, successes, mean_f = exploreLandscape(idx, N, p)
        # gather t pagerank vectors P and t percentages success p_s
        G = LONutility.LON
        P = pagerank(G, 1.0, 10000)

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
    end

    # At this point there are vectors of size t p_s[], Exp_f[] and Avg_f[]
    # compute R2 coefficient for p_s and P_opt
    # compute R2 coefficient for Exp_f and Avg_f
    # if (p_s == ones(t))
    #     p_s[1] -= 0.01
    # end
    return (P_opt, p_s, Exp_f, Avg_f)
end

function runWithFixedSize(size)
    P = Float64[]
    ps = Float64[]
    E = Float64[]
    Avg = Float64[]
    pops = [2, 4, 8, 12, 20, 40]
    for pop in pops
        a, b, c, d = runExperiment(1, size, pop, 50)
        P = append!(P,a)
        ps = append!(ps,b)
        E = append!(E,c)
        Avg = append!(Avg,d)
    end
    return P, ps, E, Avg
end

function runWithFixedPop(pop)
    P = Float64[]
    ps = Float64[]
    E = Float64[]
    Avg = Float64[]
    nvar = [28, 32, 36, 40]
    for n in nvar
        a, b, c, d = runExperiment(1, n, pop, 50)
        P = append!(P,a)
        ps = append!(ps,b)
        E = append!(E,c)
        Avg = append!(Avg,d)
    end
    return P, ps, E, Avg
end




P, ps = runWithFixedSize(40)
computeR2coefficients(P, ps)

dummy, dummy2, E, Avg = runWithFixedPop(40)
computeR2coefficients( E, Avg)
