__precompile__()

module LocalSearch
using Classes
using Decoder

export LocalSearchPopulation!, isLocalOptimum

function LocalSearchPopulation!( population::Array{Bool}, problem_index::Int64)
  for i = 1:length(population[:,1])
    sol = population[i,:]
    bestImprovementLocalSearch!( sol, problem_index)
    population[i,:] = sol
  end
  return nothing
end

function bestImprovementLocalSearch!( parameters::Array{Bool}, problem_index::Int64)

  const blocks = initializeBlocks(parameters, problem_index)

  LocalSearch!( parameters, blocks, problem_index)
  return nothing
end

function LocalSearch!( parameters::Array{Bool}, blocks::Array{Block}, problem_index::Int64)
  best_improvement = 0.0
  best_index       = 0
  block_nr         = 0
  for i = 1:length(blocks)
    for var in blocks[i].indexes
      parameters[var] = !parameters[var]
      fitness = evaluateBlock(parameters, blocks[i].indexes, problem_index)
      if fitness > blocks[i].fitness && fitness > best_improvement
        best_improvement = fitness
        best_index = var
        block_nr = i
      end
      parameters[var] = !parameters[var]
    end
  end
  if best_index != 0
    parameters[best_index] = !parameters[best_index]
    blocks[block_nr].fitness = best_improvement
    LocalSearch!( parameters, blocks, problem_index)
  end
  return nothing
end

function isLocalOptimum( solution::Array{Bool}, problem_index)
  const backup = copy(solution)
  bestImprovementLocalSearch!(solution, problem_index)
  if solution == backup
    res = true
  else
    res = false
  end
  solution .= backup
  return res
end

end
