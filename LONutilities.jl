function extractAllOptima(dim::Int64, k::Int64 )
  parts = Int(dim / k)
  localOptima = BitMatrix(2^parts, dim)
  notChecked = trues((2^dim))

  counter = 0
  for i = 0 : (2^dim)-1
    solution = bin(i,16)
    if (notChecked[indexOf(solution)])
      notChecked[indexOf(solution)] = false
      optimum = localSearch(solution)

    end
  end
end

function indexOf(strSolution::String)
  return parse(Int,strSolution,2)+1 # 0 sits at position 1 in julia
end

function localSearch(solution::String,  )

end

x= BitArray(10)
@time extractAllOptima(36,4)
trues(2^36)

m = BitMatrix(10,10)

size(m)



function main()
  population = 10
  dimensionality = 16
  deceptiveTrap_K = 4

  instance = generateArrayInstance(population , dimensionality)

  localOptima = extractAllOptima(dimensionality, deceptiveTrap_K)

  return localOptima
end

function deceptiveTrapKTightEncodingFunctionProblemEvaluation( parameters::Array{ Integer } , k::Int64)::Float64
    dim = length(parameters)
    if dim % k != 0
      return error("Error in fitness evaluation: number of parameters not a multiple of k")
    end
    m = Int(dim / k)
    result = 0.0
    for i = 0:m-1
      ones = 0
      for j = 1:k
        ones += (parameters[i*k + j] == true) ? 1 : 0
      end
        if (ones == k)
          result += 1.0
          else
          result += (k-1-ones) / k
        end
      end
    return result / m
end

function generateRandomInstance(population::Int64, dimensionality::Int64)::Array{Bool}
    randomInstance = rand(Bool, population, dimensionality)
end
