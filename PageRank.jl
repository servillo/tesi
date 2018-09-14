using Gallium


function removeSelfLinks!(randgraph)
    rows, cols = size(randgraph)
    for i = 1:rows
        randgraph[i,i] = 0
    end
    return randgraph
end

function getProbabilityMatrix(graph::Array{Int64})
    rows, cols = dims = size(graph)
    matrix = Array{Float64}(dims)
    for i = 1:cols
        outgoing = sum(graph[i,:])
        for j = 1:rows
            matrix[i,j] = graph[i,j] / outgoing
        end
    end
    return matrix
end


g = removeSelfLinks!(rand(0:1, 8,8))

H = getProbabilityMatrix(g)

include("includes.jl")
using Gadfly # export plot to browser
using LightGraphs
using GraphPlot
using Compose
using Graphs
using SimpleWeightedGraphs

using LONutility
problem_index = 2
number_of_parameters = 20
population_size = 10


u = LONutility.unexplored
x = getUnexploredInitialPopulation(problem_index, population_size, number_of_parameters)
x2 = getUnexploredInitialPopulation(problem_index, population_size, number_of_parameters)
x3 = getUnexploredInitialPopulation(problem_index, population_size, number_of_parameters)
destroy()
o = []
for i = 1:10
    s = x2[i,:]
    push!(o, Decoder.codeOptimum(s,2))
end
sort(o)
using LTGA
@enter LTGA.runGA(1, 16, 20, "lt", 1000, 5.0, 0.0)
LTGA.resetGA()

for i = 1:1000
    LTGA.runGA(1, 16, 20, "lt", 1000, 5.0, 0.0)
end
x = copy(LONutility.LON)
# removeSelfLinks!(x)



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


a = weightedLON(x)
pagerank(a) .* 100
edges(a)
for i in LightGraphs.edges(a)
    println(i)
end
println('c')

draw(SVG("graph.svg", 30cm, 30cm), gplot(a))

g = a
nodesize = [v for v in vertices(g)]

nodelabel = [1:num_vertices(g)]


weight_matrix(g, weights(g))


G = SimpleWeightedDiGraph()

add_edge!(G, 1, 2, 0.5)
add_vertices!(G,10)

for i in edges(G)
    println(i)
end

)
