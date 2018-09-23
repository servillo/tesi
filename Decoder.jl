__precompile__()

module Decoder
using Classes

export setupIndexes, decodeOptimum, codeOptimum, initializeBlocks,
       evaluateBlock, getIndexesForDeceptiveProblem, getKforProblemIndex,
       getAllOptimaIndexes, destroy

isInitialized = false
indexes = 0

"""
(index::Int64, size::Int64)::Void
Sets global variable indexes for problem params
"""
function setupIndexes(index::Int64, size::Int64)::Void
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


# function decodeAllOptima(codedOptima::Int64, problem_index::Int64, problem_size::Int64)::Void
#   indexes = setupIndexes(problem_index, problem_size)
# end

"""
(base_10_optimum::Int64, problem_size::Int64, problem_index::Int64)::Array{Bool}
Returns full boolean representation given an optimum
"""
function decodeOptimum( base_10_optimum::Int64, problem_size::Int64, problem_index::Int64)::Array{Bool}
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

"""
(optimum::Array{Bool}, problem_index::Int64 )::Int64
Returns base10 representation of an optimum
"""
function codeOptimum( optimum::Array{Bool}, problem_index::Int64 )::Int64
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

"""
(parameters::Array{Bool},  problem_index::Int64 )::Array{Block}
Given a full boolean solution it returns the blocks with fitness and indexes according to problem index
"""
function initializeBlocks( parameters::Array{Bool},  problem_index::Int64 )::Array{Block}
  if problem_index == 0
    # const blocks = Array{Block}(1)
    # blocks[1] = Block([i for i = 1:length(parameters)], sum(Float64, parameters))
    # return blocks
    return error("Problem 0 has been eliminated")
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

"""
(parameters::Array{Bool}, indexes::Int64, problem_index::Int64)::Float64
Returns the fitness of a single block given parameters and problem index
"""
function evaluateBlock(parameters::Array{Bool}, indexes::Int64, problem_index::Int64)::Float64
  if problem_index == 0
    return sum(parameters)
  else
    k = getKforProblemIndex(problem_index)
    ones = sum(parameters[indexes])
    penalty = ones == k ? 0 : ones + 1
    return 1.0 - penalty / k
  end
end

"""
( problem_index::Int64, problem_size::Int64, i::Int64)::Array{Int64}
Returns an array of indexes representing the structure of the problem
"""
function getIndexesForDeceptiveProblem( problem_index::Int64, problem_size::Int64, i::Int64)::Array{Int64}
  k = getKforProblemIndex(problem_index)
  if problem_index == 0
      return error("Problem 0 has been eliminated")
  end
  if problem_index == 1 || problem_index == 2
    return [(i-1)*k + j for j = 1:k  ]
  elseif problem_index == 3 || problem_index == 4
    step = Int(problem_size / k)
    return [i + j*step for j = 0:k-1]
  end
end

"""
(problem_index::Int64 )::Int64
Returns value of k according to problem index
"""
function getKforProblemIndex( problem_index::Int64 )::Int64
  return k = problem_index % 2 == 0 ? 5 : 4
end

"""
(strSolution::String)::Int64
Returns a base 10 number given a binary string
"""
function base10(strSolution::String)::Int64
  return parse(Int,strSolution,2)
end

"""
( problem_index::Int64, problem_size::Int64 )::UnitRange{Int64}
Returns the optima's search space in form of range given problem parameters
"""
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
