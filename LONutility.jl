__precompile__()

module LONutility

using Decoder, StatsBase

export constructLON, placeEdges, destroy, getUnexploredInitialPopulation

isConstructed = false
prb_idx = nothing
prb_size = nothing
unexplored = 0

function destroy()
    isConstructed = false
    unexplored = 0
    return println("LON reset...")
end

"""
(problem_index::Int64, number_of_parameters::Int64)::Void
Constructs an empty LON
"""
function constructLON( problem_index::Int64, number_of_parameters::Int64 )::Void
    if !isConstructed
        range = getAllOptimaIndexes(problem_index, number_of_parameters)
        nodes = range[end]
        global LON = Array{Int64}(nodes,nodes)
        LON .= 0
        global isConstructed = true
        global prb_idx = problem_index
        global prb_size = number_of_parameters
    else
        println("LON already constructed. Running LTGA will add edges to the existing LON...")
    end
    return nothing
end

"""
( best_prev_solution_indexes::Array{Int64}, best_solution_indexes::Array{Int64})::Void
Sets edge from best prev to best sol to +1
"""
function placeEdges( best_prev_solution_indexes::Array{Int64}, best_solution_indexes::Array{Int64})::Void
    for from in best_prev_solution_indexes
        for  to in best_solution_indexes
            LON[ from , to ] += 1
        end
    end
    return nothing
end

"""
(problem_index::Int64, population_size::Int64, number_of_parameters::Int64)::Array{Bool}
Returns only unexplored initial population.. stores unexplored in global variable
"""
function getUnexploredInitialPopulation(problem_index::Int64, population_size::Int64, number_of_parameters::Int64)::Array{Bool}
    if unexplored == 0
        global unexplored = [i for i in getAllOptimaIndexes(problem_index, number_of_parameters)]
    end
    if length(unexplored) == 0
        return error("The whole search space has been explored")
    end
    toSample = length(unexplored) >= population_size ? population_size : length(unexplored)
    const initialOptimaCoded = sample(unexplored, toSample, replace = false)
    deleteat!(unexplored, findin(unexplored, initialOptimaCoded))
    const population = Array{Bool}(population_size, number_of_parameters)
    if toSample < population_size
        for i = toSample + 1: population_size
            population[i,:] = decodeOptimum(initialOptimaCoded[rand(1:toSample)], number_of_parameters, problem_index )
            println("added ", codeOptimum(population[i,:], problem_index))
        end
    end
    for i = 1:toSample
        population[i,:] = decodeOptimum(initialOptimaCoded[i], number_of_parameters, problem_index )
        println("added ", codeOptimum(population[i,:], problem_index))
    end
    return population
end

end
