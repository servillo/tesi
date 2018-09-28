include("includes.jl")

using LTGA
using LightGraphs, Graphs, SimpleWeightedGraphs
using DataFrames, GLM
# using Gadfly, Compose, GraphPlot

function exploreLandscape(problem_index::Int64)
    problem_index == 1 ? number_of_parameters = 40 : number_of_parameters = 50
    return exploreLandscape(problem_index, number_of_parameters, 50)
end

function exploreLandscape(problem_index::Int64, number_of_parameters::Int64, population_size::Int64)
    LONutility.constructLON(problem_index, number_of_parameters)
    vtr = number_of_parameters / 4
    meanFit = Float64[]
    runs = 0
    successes = 0
    while length(LONutility.unexplored) > 0
        obj, isSuccessful, m_f = runGA(1, number_of_parameters, population_size, "mp", 100000, vtr, 0.0)
        push!(meanFit, m_f)
        successes += isSuccessful ? 1 : 0
        runs += 1
    end
    resetGA()
    return (runs, sum(successes), mean(meanFit))
end


function getEdges(LON)
    dims, dummy = size(LON)
    str = ""
    for from = 1:dims
        for to = 1:dims
            if LON[from, to] > 0
                str *= "edges from $(string(from)) to $(string(to)) : $(string(LON[from, to])) \n"
            end
        end
    end
    return str
end

function weightedLON(LON)
    rows,cols = size(LON)
    G = SimpleWeightedDiGraph(rows)
    for i = 1:rows
        weight = 1
        if (weight > 1)
            weight = 0
        end
        for j = 1:cols
            if LON[i,j] != 0
                SimpleWeightedGraphs.add_edge!(G, i, j, LON[i,j] * weight)
            end
        end
    end
    return G
end

function simpleLON(LON)
    rows,cols = size(LON)
    G = SimpleDiGraph(rows)
    for i = 1:rows
        for j = 1:cols
            if LON[i,j] != 0
                LightGraphs.add_edge!(G, i, j)
            end
        end
    end
    return G
end

function createFitnessRowVector(idx, N)
    blocksize = idx == 1 ? 4 : 5
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

function removeIslands(LON)

end

i = 1
p = 10
N = 40

function runExperiment(idx, N, p, t)
    # create fitness vector F containing fitnesses of all local optima
    F = createFitnessRowVector(idx, N)

    Avg_f = Array{Float64}(t)
    Exp_f = Array{Float64}(t)
    P_opt = Array{Float64}(t)
    p_s = Array{Float64}(t)
    # run GA t times
    for i = 1:t
        runs, successes, mean_f = exploreLandscape(idx)
        # gather t pagerank vectors P and t percentages success p_s
        G = simpleLON(LONutility.LON)
        P = pagerank(G, 1.0, 1000) .* 100
        P_opt[i] = P[end]
        p_s[i] = successes / runs
        # println("opt ", P_opt[i], " sr ", p_s[i])
        # gather t average solution fitness achieved Avg_f
        Avg_f[i] = mean_f
        # multiply each pagerank vector P by the fitness vector F to obtain Exp_f vector of size t
        Exp_f[i] = (F * P)[1]
        # println("e ", Exp_f[i], " a ", Avg_f[i])
    end

    # At this point there are vectors of size t p_s[], Exp_f[] and Avg_f[]
    # compute R2 coefficient for p_s and P_opt
    # compute R2 coefficient for Exp_f and Avg_f
    return computeR2coefficients(P_opt, p_s), computeR2coefficients(Avg_f, Exp_f)
end

runExperiment(1, 40, 50, 50)

x = rand(Float64,100)
f = Float64[]

append!(f,x)

runs, successes, fit = exploreLandscape(1)
@time exploreLandscape(1)

deleteat!(Pmin, find( x -> x < 1, Pmin))
sum(LONutility.LON)
LONutility.LON

G = simpleLON(LONutility.LON)
Gw = weightedLON(LONutility.LON)
P = pagerank(G, 1.0) .* 100

draw(SVG("graph.svg", 30cm, 30cm), gplot(a))

for i in edges(m)
    println(i)
end

println(getEdges(LONutility.LON))

MAX_SAFE_PROBLEM_SIZE  = 68

# TODO: fix types
# TODO: fix calling convention (order of parameters)
# TODO: DONE LON utilities for all best and one best
# TODO: DONE think of a way to correctly initialize ltga
# TODO: DONE fix LON utilities

function asd(m)
    for c = reverse(vertices(m))
        if indegree(m,c) == 0 && outdegree(m,c) == 0
            rem_vertex!(m,c)
        end
    end
end


deleteat!(Pmin, find( x -> x < 1, Pmin))
deleteat!(Pm, find( x -> x < 1, Pm))
