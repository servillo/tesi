module Classes

export Block

mutable struct Block
  indexes::Array{Int64}
  fitness::Float64
end

end
