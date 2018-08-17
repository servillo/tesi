include("includes.jl")

using LocalSearch
using Decoder
using LTGA
using Gallium

runGA(1, 56, 20, "mp", 100000, 0.0, 0.0)

LTGA.number_of_generations

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


print(a)
println(getEdges(LONutility.LON))

decodeOptimum(16383, 56, 1) == trues(56)

MAX_SAFE_PROBLEM_SIZE  = 68

# TODO: fix types
# TODO: fix calling convention (order of parameters)
# TODO: DONE LON utilities for all best and one best
# TODO: DONE think of a way to correctly initialize ltga
# TODO: DONE fix LON utilities
