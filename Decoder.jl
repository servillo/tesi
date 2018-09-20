__precompile__()

module Decoder
using Classes

export setupIndexes, decodeOptimum, codeOptimum, initializeBlocks,
       evaluateBlock, getIndexesForDeceptiveProblem, getKforProblemIndex,
       getAllOptimaIndexes, destroy

isInitialized = false
indexes = 0

function setupIndexes(index, size)
  global isInitialized = true

  k = getKforProblemIndex( index )
  global indexes = Array{Array{Int64}}(Int(size / k))
  for i = 1:length(indexes)
    global indexes[i] = getIndexesForDeceptiveProblem(index, size, i)
  end
  return nothing
end

function destroy()
    global isInitialized = false
    global unexplored = 0
    println("LON reset...")
end


function decodeAllOptima(codedOptima, problem_index, problem_size)
  indexes = setupIndexes(problem_index, problem_size)
end

function decodeOptimum( base_10_optimum::Int64, problem_size::Int64, problem_index::Int64)
  if !isInitialized
    setupIndexes(problem_index, problem_size)
  end
  k = getKforProblemIndex(problem_index)
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

function codeOptimum( optimum, problem_index )
  blocks = initializeBlocks( optimum, problem_index)
  stringCodification = ""
  for i = 1:length(blocks)
    if sum(optimum[blocks[i].indexes]) == 0
      stringCodification *= "0"
    elseif blocks[i].fitness == 1.0
      stringCodification *= "1"
    else
      return error("The solution is not a LocalOptimum")
    end
  end
  return base10(stringCodification)
end

function initializeBlocks( parameters,  problem_index )::Array{Block}
  if problem_index == 0
    const blocks = Array{Block}(1)
    blocks[1] = Block([i for i = 1:length(parameters)], sum(Float64, parameters))
    return blocks
  end
  k = getKforProblemIndex(problem_index)
  number_of_blocks = Int(length(parameters) / k)
  const blocks = Array{Any}(number_of_blocks)

  for i = 1:number_of_blocks
    indexes = getIndexesForDeceptiveProblem(problem_index, length(parameters), i)
    blocks[i] = Block(indexes, evaluateBlock(parameters, indexes, problem_index))
  end
  return blocks
end

function evaluateBlock(parameters, indexes, problem_index)::Float64
  if problem_index == 0
    return sum(parameters)
  else
    k = getKforProblemIndex(problem_index)
    ones = sum(parameters[indexes])
    penalty = ones == k ? 0 : ones + 1
    return 1.0 - penalty / k
  end
end

function getIndexesForDeceptiveProblem( problem_index, problem_size, i)
  k = getKforProblemIndex(problem_index)
  if problem_index == 1 || problem_index == 2
    return [(i-1)*k + j for j = 1:k  ]
  elseif problem_index == 3 || problem_index == 4
    step = Int(problem_size / k)
    return [i + j*step for j = 0:k-1]
  end
end

function getKforProblemIndex( problem_index::Int64 )
  return k = problem_index % 2 == 0 ? 5 : 4
end


function base10(strSolution::String)
  return parse(Int,strSolution,2)
end

function getAllOptimaIndexes( problem_index::Int64, problem_size::Int64 )::UnitRange{Int64}
  if problem_index == 0
    return (2^problem_size - 1) < 0  ? error("problem too big") : (2^problem_size-1):(2^problem_size-1)
  elseif problem_index < 5
    k = getKforProblemIndex(problem_index)
    number_of_optima = 2^(Int(problem_size / k))
    return 0:number_of_optima-1
  elseif problem_index >= 5
    return error("not implemented yet for problem ", problem_index)
  end
end


end
