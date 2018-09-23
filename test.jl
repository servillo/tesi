include("includes.jl")

using Gallium
using LTGA

using LightGraphs
using Graphs
using SimpleWeightedGraphs

using Gadfly # export plot to browser
using Compose
using GraphPlot

function exploreLandscape(problem_index::Int64)
    problem_index == 1 ? number_of_parameters = 40 : number_of_parameters = 50
    return exploreLandscape(problem_index, number_of_parameters, 50)
end

function exploreLandscape(problem_index::Int64, number_of_parameters::Int64, population_size::Int64)
    LONutility.constructLON(problem_index, number_of_parameters)
    vtr = number_of_parameters / 4
    runs = 0
    fitness_achieved = []
    while length(LONutility.unexplored) > 0
        obj = runGA(1, number_of_parameters, population_size, "mp", 100000, vtr, 0.0)
        push!(fitness_achieved, maximum(obj))
        runs += 1
    end
    resetGA()
    return (runs,fitness_achieved)
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

function removeIslands(LON)

end
runs, fit = exploreLandscape(1, 40, 2)



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
