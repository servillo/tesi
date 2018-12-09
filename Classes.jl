__precompile__()

module Classes

export Block, Stats

mutable struct Block
  indexes::Array{Int64}
  fitness::Float64
end

mutable struct Stats
    avgPath::Float64
    nodes::Int64
    avgInDegree::Float64
end

end
