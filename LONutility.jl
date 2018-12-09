__precompile__()

module LONutility

using Decoder, StatsBase, LightGraphs, MetaGraphs

export constructLON, placeEdges, destroy, getUnexploredInitialPopulation, findInGraph

isConstructed = false
prb_idx = nothing
prb_size = nothing
unexplored = 0

function destroy()
    global isConstructed = false
    global unexplored = 0
    # println("LON reset...")
end

"""
(problem_index::Int64, number_of_parameters::Int64)::Void
Constructs an empty LON
"""
function constructLON( problem_index::Int64, number_of_parameters::Int64 )::Void
    if !isConstructed
        range = getAllOptimaIndexes(problem_index, number_of_parameters)
        nodes = range[end] + 1
        # global LON = Array{Int64}(nodes,nodes)
        global LON = MetaDiGraph()
        global isConstructed = true
        global prb_idx = problem_index
        global prb_size = number_of_parameters
    elseif prb_idx == problem_index && prb_size == number_of_parameters
        # println("LON already constructed. Running LTGA will add edges to the existing LON...")
    else
        error("LON was alredy constructed with different parameters")
    end
    return nothing
end

# function placeEdges( best_prev_solution_indexes::Array{Int64}, best_solution_indexes::Array{Int64})::Void
#     for from in best_prev_solution_indexes
#         for  to in best_solution_indexes
#             LON[ from + 1 , to + 1 ] += 1
#         end
#     end
#     return nothing
# end


"""
( best_prev_solution_indexes::Array{Int64}, best_solution_indexes::Array{Int64})::Void
Sets edge from best prev to best sol to +1
"""

function placeEdges( best_prev_solution_indexes::Array{Int64}, best_solution_indexes::Array{Int64})::Void
    for from in best_prev_solution_indexes
        i = findInGraph(LON, "$from")
        if i < 1
            add_vertex!(LON)
            i = vertices(LON)[end]
            set_prop!(LON, i, :optimum, "$from")
        end
        for to in best_solution_indexes
            j = findInGraph(LON, "$to")
            if j < 1
                add_vertex!(LON)
                j = vertices(LON)[end]
                set_prop!(LON, j, :optimum, "$to")
            end
            if i != j
                if !add_edge!(LON, i, j)
                    w = get_prop(LON, i, j, :weight)
                    set_prop!(LON, i, j, :weight, w + 1)
                else
                    set_prop!(LON, i, j, :weight, 1)
                end
            end
        end
    end
    return nothing
end

function findInGraph( G, optimum::String )::Int64
    Gtmp = copy(G)
    keyContainer = props(G,1)
    if length(keyContainer) == 0
        return -1
    end
    symbol = collect(keyContainer)[1][1]
    set_indexing_prop!(Gtmp, symbol)
    i = try
        Gtmp[optimum, symbol]
    catch
        -1
    end
    Gtmp = nothing
    return i
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
            population[i,:] = decodeOptimum(rand(getAllOptimaIndexes(problem_index, number_of_parameters)), number_of_parameters, problem_index )
            # println("added ", codeOptimum(population[i,:], problem_index))
        end
    end
    for i = 1:toSample
        population[i,:] = decodeOptimum(initialOptimaCoded[i], number_of_parameters, problem_index )
        # println("added ", codeOptimum(population[i,:], problem_index))
    end
    return population
end

end
