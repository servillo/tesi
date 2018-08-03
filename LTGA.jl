module LTGA
############## Globals Section


function setGlobals(index::Int64, nParams::Int64, popSize::Int64)::Void
    println("LTGA initialized with parameters:\n",
    "problem_index:         ", index, "\n",
    "number of parameters:  ", nParams, "\n",
    "population size:       ", popSize)

    global problem_index = index
    global population_size = popSize
    global number_of_parameters = nParams

    global constraint_values_offspring     = Array{Float64}(population_size)
    global best_prevgen_solution           = Array{Bool}(number_of_parameters)
    return
end

is_inited                       = false

problem_index                   = 0
number_of_parameters            = 0
population_size                 = 0

number_of_evaluations           = 0
number_of_generations           = 0
no_improvement_stretch          = 0
# selection_size                = population_size
# offspring_size                = population_size
#
# population                    = BitArray(population_size, number_of_parameters)
# objective_values              = Array{Float64}(population_size)
# constraint_values             = Array{Float64}(population_size)
# selection                     = BitArray(population_size, number_of_parameters)
# offspring                     = BitArray(offspring_size, number_of_parameters)
# objective_values_offspring    = Array{Float64}(population_size)
best_prevgen_solution            = []
best_prevgen_objective_value    = 0.0
best_prevgen_constraint_value   = 0.0
# best_ever_evaluated_solution  = BitArray(number_of_parameters)



######## Section Initialize
function initializeFitnessValues( population::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64} )::Void
  population_size, number_of_parameters = size(population)

  for i = 1:population_size
    obj, con = installedProblemEvaluation( problem_index, population[ i , 1:number_of_parameters ] )
    objective_values[i]   = obj
    constraint_values[i]  = con
  end
  return
end
#########

######## Section Model

function generateModelForProblemIndex(index::Int64, nparams::Int64)::Array{Array{Int64}}
    if index == 0
        return modelForOneMax(nparams)
    elseif index == 1
        return modelForDeceptive4Tight(nparams)
    # elseif index == 2
    end
end

function modelForOneMax(nparams::Int64)::Array{Array{Int64}}
    # model has 1 additional element at last position for compatibility with LT model
    model = Array{Array{Int64}}(nparams + 1)
    for i = 1:nparams
        model[i] = [i]
    end
    return model
end

function modelForDeceptive4Tight(nparams::Int64)::Array{Array{Int64}}
    number_of_blocks = Int(nparams / 4)
    # model has 1 additional element at last position for compatibility with LT model
    model = Array{Array{Int64}}(number_of_blocks + 1)
    for i = 1:number_of_blocks
        model[i] = [j for j = 4(i-1) + 1: 4(i-1) + 4]
    end
    return model
end
##############################

######### Section Evaluation
function installedProblemEvaluation( index::Int64, parameters::Array{Bool} )::Tuple{Float64, Float64}
  global number_of_evaluations += 1

  objective_value, constraint_value = 0.0, 0.0

  fitnessEvaluation = switchProblemEvaluation( index )

  (objective_value, constraint_value) = fitnessEvaluation( parameters )

  # TODO: if vtr hit has happened

  # TODO: save stats for best solution and running time

  return (objective_value, constraint_value)
end

function switchProblemEvaluation( index::Int64 )::Function
  if index == 0
    return onemaxFunctionProblemEvaluation
  elseif index == 1
    return deceptiveTrap4TightEncodingFunctionProblemEvaluation
  end
end

function onemaxFunctionProblemEvaluation( parameters::Array{Bool} )::Tuple{Float64, Float64}
  result = 0.0
  for i = 1:length(parameters)
    result += (parameters[i] == true) ? 1 : 0
  end
  return (result, 0.0)
end

function deceptiveTrap4TightEncodingFunctionProblemEvaluation( parameters::Array{Bool})::Tuple{Float64,Float64}
  return deceptiveTrapKTightEncodingFunctionProblemEvaluation( parameters, 4)
end

function deceptiveTrapKTightEncodingFunctionProblemEvaluation( parameters::Array{Bool}, k::Int64)::Tuple{Float64,Float64}
    dim = length(parameters)
    if dim % k != 0
      return error("Error in fitness evaluation: number of parameters not a multiple of k")
    end
    m = Int(dim / k)
    result = 0.0
    for i = 0:m-1
      ones = 0
      for j = 1:k
        ones += (parameters[i*k + j] == true) ? 1 : 0  # Considers blocks of k adjacents bits
      end
        if (ones == k)
          result += 1.0
          else
          result += (k-1-ones) / k
        end
      end
    return (result , 0.0)
end

function deceptiveTrapKLooseEncodingFunctionProblemEvaluation( parameters::Array{Bool}, k::Int64)::Tuple{Float64,Float64}
    dim = length(parameters)
    if dim % k != 0
      return error("Error in fitness evaluation: number of parameters not a multiple of k")
    end
    m = Int(dim / k)
    result = 0.0
    for i = 1:m
      ones = 0
      for j = 0:k-1
        ones += (parameters[i+m*j] == true) ? 1 : 0  # Considers blocks each m = N/k bits apart from each other
      end
        if ones == k
          result += 1.0
          else
          result += (k-1-ones) / k
        end
      end
    return (result, 0.0)
end
############################

############# Section Crossover

function generateAndEvaluateNewSolutionsToFillOffspring!(population::Array{Bool}, offspring::Array{Bool},  objective_values::Array{Float64}, constraint_values::Array{Float64}, objective_values_offspring::Array{Float64}, constraint_values_offspring::Array{Float64} , model)::Void
  population_size, number_of_parameters = size(population)
  offspring_size, dummy  = size(offspring)

  solution = Array{Bool}(number_of_parameters)

  for i = 1:offspring_size
    obj, con = generateNewSolution!(population, i, solution, objective_values, constraint_values, model)

    objective_values_offspring[i] = obj
    constraint_values_offspring[i] = con

    offspring[i,1:number_of_parameters] .= solution
  end
  return
end

# modifies a solution in place thru GOM and returns its objective value
function generateNewSolution!(population::Array{Bool}, which::Int64, result::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64}, model::Array{Array{Int64}} )::Tuple{Float64, Float64}
  population_size, number_of_parameters = size(population)
  model_length = length(model)
  solution_has_changed = false
  is_unchanged = true
  # backup = Array{Bool}(number_of_parameters)

  result .= population[ which , 1:number_of_parameters]
  obj = objective_values[ which ]
  con = constraint_values[ which ]

  backup = copy(result)
  obj_backup = obj
  con_backup = con

  # optimal mixing with random donors
  for i = (model_length - 1):-1:1
    donor_index = rand(1:population_size)
    # repick if donor is solution undergoing crossover
    while donor_index == which
      donor_index = rand(1:population_size)
    end
    number_of_indices = length(model[i])

    result[model[i][1:number_of_indices]] .= population[ donor_index , model[i][1:number_of_indices] ]

    is_unchanged = true
    for j = 1:number_of_indices
      if backup[ model[i][j] ] != result[ model[i][j] ]
        is_unchanged = false
        break
      end
    end

    if is_unchanged == false

      obj, con = installedProblemEvaluation( problem_index, result)
      if betterFitness( obj, con, obj_backup, con_backup) || equalFitness( obj, con, obj_backup, con_backup)

        backup[ model[ i ][ 1:number_of_indices ] ] .= result[ model[ i ][ 1:number_of_indices ] ]

        obj_backup = obj
        con_backup = con

        solution_has_changed = true
      else

        result[ model[ i ][ 1:number_of_indices ] ] .= backup[ model[ i ][ 1:number_of_indices ] ]

        obj = obj_backup
        con = con_backup
      end
    end
  end
  # TODO: FORCED IMPROVEMENTS PART
  if (!solution_has_changed || (no_improvement_stretch > (1 + log(population_size) / log(10))))
    solution_has_changed = false
    for i = model_length-1 : -1 : 1
      number_of_indices = length(model[ i ])

      result[ model[ i ][ 1:number_of_indices ] ] .= best_prevgen_solution[ model[ i ][ 1:number_of_indices ] ]

      is_unchanged = true
      for j = 1:number_of_indices
        if backup[ model[ i ][ j ] ] != result[ model[ i ][ j ]]
          is_unchanged = false
          break
        end
      end

      if is_unchanged == false
        obj, con = installedProblemEvaluation( problem_index, result)
        if betterFitness( obj, con, obj_backup, con_backup)

          backup[ model[ i ][ 1:number_of_indices ] ] .= result[ model[ i ][ 1:number_of_indices ] ]

          obj_backup = obj
          con_backup = con

          solution_has_changed = true
        end
      else
        result[ model[ i ][ 1:number_of_indices ] ] .= backup[ model[ i ][ 1:number_of_indices ] ]

        obj = obj_backup
        con = con_backup
      end
    end
    if solution_has_changed != true
      if betterFitness( best_prevgen_objective_value, best_prevgen_constraint_value, obj, con)
        solution_has_changed = true
      end
      result .= best_prevgen_solution
      obj = best_prevgen_objective_value
      con = best_prevgen_constraint_value
    end
  end
  return obj, con
end

function betterFitness(objective_value_x::Float64, constraint_value_x::Float64, objective_value_y::Float64, constraint_value_y::Float64 )::Bool
  result = false
  if (constraint_value_x > 0)
    if (constraint_value_y > 0)
      if (constraint_value_x < constraint_value_y)
        result = true
      end
    end
  else
    if constraint_value_y > 0
      result = true
    else
      if (objective_value_x > objective_value_y)
        result = true
      end
    end
  end
  return result
end

function equalFitness(objective_value_x::Float64, constraint_value_x::Float64, objective_value_y::Float64, constraint_value_y::Float64 )::Bool
  result = false

  if (constraint_value_x == constraint_value_y && objective_value_x == objective_value_y)
    result = true
  end
  return result
end

function runGA()
end

function main(  problem_index,
                number_of_parameters,
                population_size,
                maximum_number_of_evaluations,
                vtr,
                fitness_variance_tolerance )
  ############## Options Section
               write_generational_statistics = true
               write_generational_solutions  = true
               print_verbose_overview        = true
               print_lt_contents             = true
               use_vtr                       = true
   ############# Run

              runGA();
            end

end
