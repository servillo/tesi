__precompile__()

module LONutility

using Decoder

export constructLON, placeEdges

function constructLON( problem_index, problem_size )
    range = getAllOptimaIndexes(problem_index, problem_size)
    nodes = range[end]
    global LON = Array{Int16}(nodes,nodes)
    LON .= 0
end


function placeEdges( best_prev_solution_indexes, best_solution_indexes)
    for from in best_prev_solution_indexes
        for  to in best_solution_indexes
            LON[ from , to ] += 1
        end
    end
    # LON[best_prev_solution_indexes, best_solution_indexes] = -1
end

end
