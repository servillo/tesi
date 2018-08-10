include("Classes.jl")
include("Decoder.jl")
using Decoder
using Classes
using Gallium

# mutable struct Block
#   indexes::Array{Int64}
#   fitness::Float64
# end
bestImprovementLocalSearch!([true,true,false,false,true,true,false,true],1)

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
