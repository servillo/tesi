include("includes.jl")

using Gallium
using LTGA

using LightGraphs
using Graphs
using SimpleWeightedGraphs

using Gadfly # export plot to browser
using Compose
using GraphPlot

runGA(1, 56, 20, "mp", 100000, 0.0, 0.0)


sum(LONutility.LON)

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


println(getEdges(LONutility.LON))


MAX_SAFE_PROBLEM_SIZE  = 68

# TODO: fix types
# TODO: fix calling convention (order of parameters)
# TODO: DONE LON utilities for all best and one best
# TODO: DONE think of a way to correctly initialize ltga
# TODO: DONE fix LON utilities






function weightedLON(LON)
    rows,cols = size(LON)
    G = SimpleWeightedDiGraph(rows)
    for i = 1:rows
        weight = 1/sum(LON[i,:])
        if (weight > 1)
            weight = 0
        end
        for j = 1:cols
            if LON[i,j] != 0
                add_edge!(G, i, j, LON[i,j] * weight)
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
                add_edge!(G, i, j)
            end
        end
    end
    return G
end

for i in edges(G)
    println(i)
end


draw(SVG("graph.svg", 30cm, 30cm), gplot(a))
