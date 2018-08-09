using Gallium

mutable struct Block
  indexes::Array{Int64}
  fitness::Float64
  # Block() = Block([],0.0)
end

function bestImprovementLocalSearch!( parameters::Array{Bool}, problem_index::Int64)

  const blocks = initializeBlocks(parameters, problem_index)

  LocalSearch!( parameters, blocks, problem_index)
  return parameters
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

function initializeBlocks( parameters,  problem_index )::Array{Block}
  if problem_index == 0
    const blocks = Array{Block}(1)
    blocks[1] = Block([i for i = 1:length(parameters)], sum(Float64, parameters))
    return blocks
  end
  k = problem_index % 2 == 0 ? 5 : 4
  number_of_blocks = Int(length(parameters) / k)
  const blocks = Array{Any}(number_of_blocks)

  for i = 1:number_of_blocks
    indexes = getIndexesForDeceptiveProblem(problem_index, length(parameters), k, i)
    blocks[i] = Block(indexes, evaluateBlock(parameters, indexes, problem_index))
  end
  return blocks
end

function evaluateBlock(parameters, indexes, problem_index)::Float64
  if problem_index == 0
    return sum(parameters)
  else
    k = problem_index % 2 == 0 ? 5 : 4
    ones = sum(parameters[indexes])
    penalty = ones == k ? 0 : ones + 1
    return 1.0 - penalty / k
  end
end

function getIndexesForDeceptiveProblem( problem_index, problem_size, k, i)
  if problem_index == 1 || problem_index == 2
    return [(i-1)*k + j for j = 1:k  ]
  elseif problem_index == 3 || problem_index == 4
    step = Int(problem_size / k)
    return [i + j*step for j = 0:k-1]
  end
end

function base10(strSolution::String)
  return parse(Int,strSolution,2)
end

function getAllOptimaIndexes( problem_size::Int64, problem_index::Int64 )::UnitRange{Int64}
  if problem_index == 0
    return (2^problem_size - 1) < 0  ? error("problem too big") : [(2^problem_size-1)]
  elseif problem_index < 5
    k = problem_index % 2 == 0 ? 5 : 4
    number_of_optima = 2^(Int(problem_size / k))
    return 0:number_of_optima-1
  elseif problem_index >= 5
    return error("not implemented yet for problem ", problem_index)
  end
end


function codeOptimum( optimum, problem_index )
  blocks = initializeBlocks( optimum, problem_index)
  stringCodification = ""
  for i = 1:length(blocks)
    if blocks[i].fitness < 1.0
      stringCodification *= "0"
    else
      stringCodification *= "1"
    end
  end
  return base10(stringCodification)
end


function decodeOptimum( base_10_optimum, problem_size, problem_index)
  k = problem_index % 2 == 0 ? 5 : 4
  stringCodification = bin(base_10_optimum, Int(problem_size / k))
  solution = Array{Bool}(problem_size)
  for block_nr = 1:length(stringCodification)
    if stringCodification[block_nr] == '1'
      solution[getIndexesForDeceptiveProblem(problem_index,problem_size, k, block_nr)] .= true
    else
      solution[getIndexesForDeceptiveProblem(problem_index,problem_size, k, block_nr)] .= false
    end
  end
  return solution
end

function decodeOptimum2( base_10_optimum::Int64, problem_size::Int64, problem_index::Int64, indexes)
  k = problem_index % 2 == 0 ? 5 : 4
  stringCodification = bin(base_10_optimum, Int(problem_size / k))
  solution = Array{Bool}(problem_size)
  for block_nr = 1:length(stringCodification)
    if stringCodification[block_nr] == '1'
      solution[indexes[block_nr]] .= true
    else
      solution[indexes[block_nr]] .= false
    end
  end
  return solution
end

function allCodedOptima( number_of_optima)
  return [i for i = 0:number_of_optima-1]
end



#
# population = rand(Bool, 10,20)
# popsize, dim = size(population)
# problem_index = 4
#  for i = 1:popsize
#    bestImprovementLocalSearch!(population[1,:], problem_index)
# end

problem_index = 4
dim = 15
k = problem_index % 2 == 0 ? 5 : 4
codedOptimas = getAllOptimaIndexes(dim, problem_index)


function f()
  indexes = Array{Array{Int64}}(Int(dim / k))
  for i = 1:length(indexes)
    indexes[i] = getIndexesForDeceptiveProblem(problem_index, dim, k, i)
  end
  for i = 1:length(codedOptimas)
   push!(decodedOptimas, decodeOptimum2(codedOptimas[i], dim,problem_index, indexes))
  end
end
