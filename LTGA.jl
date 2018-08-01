############## Globals Section
const problem_index             = 0

number_of_evaluations           = 0
number_of_generations           = 0
no_improvement_stretch          = 0
# number_of_parameters          = 20
# population_size               = 10
#
# selection_size                = population_size
# offspring_size                = population_size
#
# population                    = BitArray(population_size, number_of_parameters)
# objective_values              = Array{Float64}(population_size)
# constraint_values             = Array{Float64}(population_size)
# selection                     = BitArray(population_size, number_of_parameters)
# offspring                     = BitArray(offspring_size, number_of_parameters)
# objective_values_offspring    = Array{Float64}(population_size)
# constraint_values_offspring   = Array{Float64}(population_size)
best_prevgen_solution           = Array{Bool}(number_of_parameters)
best_prevgen_objective_value    = 0.0
best_prevgen_constraint_value   = 0.0
# best_ever_evaluated_solution  = BitArray(number_of_parameters)
# MI_matrix                     = Array{Float64}(number_of_parameters, number_of_parameters)






######## Section Initialize
function initializePopulationAndFitnessValues( population::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64} )
  population_size, number_of_parameters = size(population)

  for i = 1:population_size
    for j = 1:number_of_parameters
      population[ i , j ] = rand(Bool)
    end

    obj, con = installedProblemEvaluation( problem_index, population[ i , 1:number_of_parameters ] )
    objective_values[i]   = obj
    constraint_values[i]  = con
  end

  # TODO: useless to return the population, it gets modified in place
  return population
end
#########

######### Section Evaluation
function installedProblemEvaluation( index::Int64, parameters::Array{Bool} )
  global number_of_evaluations += 1

  objective_value = 0.0
  constraint_value = 0.0

  fitnessEvaluation = switchProblemEvaluation( index )

  (objective_value, constraint_value) = fitnessEvaluation( parameters )

  # TODO: if vtr hit has happened

  # TODO: save stats for best solution and running time

  return (objective_value, constraint_value)
end

function switchProblemEvaluation( index::Int64 )
  if index == 0
    return onemaxFunctionProblemEvaluation
  elseif index == 1
    return deceptiveTrap4TightEncodingFunctionProblemEvaluation
  end
end

function onemaxFunctionProblemEvaluation( parameters::Array{Bool} )
  result = 0.0
  for i = 1:length(parameters)
    result += (parameters[i] == true) ? 1 : 0
  end
  return (result, 0)
end

function deceptiveTrap4TightEncodingFunctionProblemEvaluation( parameters::Array{Bool})
  return deceptiveTrapKTightEncodingFunctionProblemEvaluation( parameters, 4)
end

function deceptiveTrapKTightEncodingFunctionProblemEvaluation( parameters::Array{Bool}, k::Int64)::Float64
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
    return (result , 0)
end

function deceptiveTrapKLooseEncodingFunctionProblemEvaluation( parameters::Array{Bool}, k::Int64)::Float64
    dim = length(parameters)
    if dim % k != 0
      return error("Error in fitness evaluation: number of parameters not a multiple of k")
    end
    m = Int(dim / k)
    result = 0.0
    for i = 1:m
      ones = 0
      for j = 0:k-1
        println(i+m*j)
        ones += (parameters[i+m*j] == true) ? 1 : 0  # Considers blocks each m = N/k bits apart from each other
      end
        if ones == k
          result += 1.0
          else
          result += (k-1-ones) / k
        end
      end
    return (result, 0)
end
############################

############# Section Crossover

function generateAndEvaluateNewSolutionsToFillOffspring(population::Array{Bool}, offspring::Array{Bool},  objective_values::Array{Float64}, constraint_values::Array{Float64}, objective_values_offspring::Array{Float64}, constraint_values_offspring::Array{Float64} ))
  population_size, number_of_parameters = size(population)
  offspring_size, number_of_parameters  = size(offspring)

  objective_value = 0.0
  constraint_value = 0.0

  for i = 1:offspring_size
    (solution, obj, con ) = generateNewSolution(population, i % population_size, objective_values, constraint_values)

    for j = 1:number_of_parameters
      offspring[i,j] = solution[j]
    end
    objective_values_offspring[i] = obj
    constraint_values_offspring[i] = con
  end
end


function generateNewSolution(population::Array{Bool}, which::Int64,  objective_values::Array{Float64}, constraint_values::Array{Float64}, model::Array{Array{Int64}} )
  population_size, number_of_parameters = size(population)
  model_length = length(model)
  solution_has_changed = false
  is_unchanged = true
  result = Array{Bool}(number_of_parameters)
  backup = Array{Bool}(number_of_parameters)

  result = population[ which , 1:number_of_parameters]
  obj = objective_values[ which ]
  con = constraint_values[ which ]

  backup = result
  obj_backup = obj
  con_backup = con

  # optimal mixing with random donors
  for i = (model_length - 1):-1:1
    donor_index = rand(1:population_size)

    number_of_indices = length(model[ i ])
    result = population[ donor_index , model[ i , 1:number_of_indices ] ]

    is_unchanged = true
    for j = 1:number_of_indices
      if backup[ model[ i, j ] ] != result[ model[ i, j]]
        is_unchanged = false
        break
      end
    end

    if is_unchanged == false

      obj, con = installedProblemEvaluation( problem_index, result)
      if betterFitness( obj, con, obj_backup, con_backup) || equalFitness( obj, con, obj_backup, con_backup)
        for j = 1:number_of_indices
          backup[ model[ i, j ] ] = result[ model[ i, j ] ]
        end

        obj_backup = obj
        con_backup = con

        solution_has_changed = true
      end
    else
      for j = 1:number_of_indices
        result[ model[ i, j ] ] = backup[ model[ i, j ] ]
      end
        obj = obj_backup
        con = con_backup
    end
  end
  # TODO: FORCED IMPROVEMENTS PART
  if (!solution_has_changed || (no_improvement_stretch > (1 + log(population_size) / log(10))))
    solution_has_changed = false
    for i = model_length-1 : -1 : 1
      number_of_indices = length(model[ i ])
      for j = 1:number_of_indices
        result[ model[ i, j ] ] = best_prevgen_solution[ model[ i, j ] ]
      end

      is_unchanged = true
      for j = 1:number_of_indices
        if backup[ model[ i, j ] ] != result[ model[ i, j]]
          is_unchanged = false
          break
        end
      end

      if is_unchanged == false
        obj, con = installedProblemEvaluation( problem_index, result)
        if betterFitness( obj, con, obj_backup, con_backup)
          for j = 1:number_of_indices
            backup[ model[ i, j ] ] = result[ model[ i, j ] ]
          end

          obj_backup = obj
          con_backup = con

          solution_has_changed = true
        end
      else
        for j = 1:number_of_indices
          result[ model[ i, j ] ] = backup[ model[ i, j ] ]
        end
          obj = obj_backup
          con = con_backup
      end
    end
    if solution_has_changed != true
      if betterFitness( best_prevgen_objective_value, best_prevgen_constraint_value, obj, con)
        solution_has_changed = true
      end

      result = best_prevgen_solution
      obj = best_prevgen_objective_value
      con = best_prevgen_constraint_value
    end
  end
  return solution, objective_value, constraint_value
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




########################### snippets section
population = Array{Bool}(10,20)
con = Array{Float64}(20)
obj = Array{Float64}(20)

initializedPopulation = initializePopulationAndFitnessValues(population, obj, con)
