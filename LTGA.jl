module LTGA
############## Globals Section

is_inited                       = false

"""
(index::Int64, nParams::Int64, popSize::Int64, modelType::String)::Void
To call only once when setting up the problem
"""
function setGlobals(index::Int64, nParams::Int64, popSize::Int64, modelType::String)::Void
    if is_inited
        return error("LTGA is already initialized. Call LTGA.destroy()")
    end
    println("LTGA initialized with parameters:\n",
    "model type:            ", modelType, "\n",
    "problem_index:         ", index, "\n",
    "number of parameters:  ", nParams, "\n",
    "population size:       ", popSize)

    global problem_index             = index
    global population_size           = popSize
    global offspring_size            = popSize
    global number_of_parameters      = nParams
    # global const model_length                    = length(generateModelForTypeAndProblemIndex(modelType, index, nParams))
    global limit_no_improvement      = (1 + log(population_size) / log(10))

    global best_prevgen_solution     = Array{Bool}(number_of_parameters)
    global is_inited                       = true
    global number_of_evaluations           = 0
    global number_of_generations           = 0
    global no_improvement_stretch          = 0
    global best_prevgen_objective_value    = 0.0
    global best_prevgen_constraint_value   = 0.0
    return nothing
end

function destroy()
    global problem_index                   = nothing
    global problem_index                   = nothing
    global population_size                 = nothing
    global offspring_size                  = nothing
    global number_of_parameters            = nothing
    # global const model_length                    = length(generateModelForTypeAndProblemIndex(modelType, index, nParams))
    global limit_no_improvement            = nothing

    global best_prevgen_solution           = nothing
    global is_inited                       = nothing
    global number_of_evaluations           = nothing
    global number_of_generations           = nothing
    global no_improvement_stretch          = nothing
    global best_prevgen_objective_value    = nothing
    global best_prevgen_constraint_value   = nothing
    global is_inited                       = false
    return nothing
end



######## Section Initialize
"""
(popSize::Int64, nParams::Int64)
"""
function randomPopulation(popSize::Int64, nParams::Int64)
    population = Array{Bool}(popSize, nParams)
    for i = 1:popSize
        for j = 1:nParams
            population[ i , j ] = rand(Bool)
        end
    end
    return population
end
"""
( population::Array, objective_values::Array, constraint_values::Array )::Void
Evaluates the initial population modifying in place obj and const arrays
"""
function initializeFitnessValues( population::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64} )::Void
  population_size, number_of_parameters = size(population)

  for i = 1:population_size
    obj, con = installedProblemEvaluation( problem_index, population[ i , : ] )
    objective_values[i]   = obj
    constraint_values[i]  = con
  end
  return
end
#########

######## Section Model
"""
(modelType::String, index::Int64, nParams::Int64)::Array{Array{Int64}}
modelType:: 'lt' | 'mp'
returns an array containing arrays of indexes of variables
"""
function generateModelForTypeAndProblemIndex(modelType::String, index::Int64, nParams::Int64)::Array{Array{Int64}}
    if index == 0
        return MPmodelForOneMax(nParams)
    else
        if modelType == "lt"
            if index == 1
                return LTmodeForDeceptive4Tight(nParams)
            # else if index == 2
            end
        elseif modelType == "mp"
            if index == 1
                return MPmodelForDeceptive4Tight(nParams)
            # elseif index == 2
            end
        end
    end
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns a 1 element array containing an array of indexes of every problem variable
"""
function MPmodelForOneMax(nparams::Int64)::Array{Array{Int64}}
    # model has 1 additional element at last position for compatibility with LT model
    model = Array{Array{Int64}}(nparams + 1)
    for i = 1:nparams
        model[i] = [i]
    end
    return model
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns a Marginal Product model for deceptive thight with k = 4
"""
function MPmodelForDeceptive4Tight(nparams::Int64)::Array{Array{Int64}}
    number_of_blocks = Int(nparams / 4)
    # model has 1 additional element at last position for compatibility with LT model
    model = Array{Array{Int64}}(number_of_blocks + 1)
    for i = 1:number_of_blocks
        model[i] = [j for j = 4(i-1) + 1: 4(i-1) + 4]
    end
    return model
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive tight with k = 4
"""
function LTmodeForDeceptive4Tight(nparams::Int64)::Array{Array{Int64}}
    nodes = Int(nparams + nparams/2 + nparams/4 + 1)
    model = Array{Array{Int64}}(nodes)
    for i = 1:nparams
        model[i] = [i]
    end
    for i = 1:Int(nparams / 2)
        model[i + nparams] = [j for j = (i*2) - 1:i*2]
    end
    for i = 1:Int(nparams / 4)
        model[i + Int(nparams + nparams/2)] = [j for j = 4(i-1) + 1: 4(i-1) + 4]
    end
    model[nodes] = [0]
    return model
end

##############################


######### Section Evaluation
"""
( index::Int64, parameters::Array{Bool} )::Tuple{Float64, Float64}
computes fitness evaluation according to problem index
returns obj, con
"""
function installedProblemEvaluation( index::Int64, parameters::Array{Bool} )::Tuple{Float64, Float64}
  global number_of_evaluations += 1

  # objective_value, constraint_value = 0.0, 0.0

  fitnessEvaluation = switchProblemEvaluation( index )

  # (objective_value, constraint_value) = fitnessEvaluation( parameters )

  # TODO: if vtr hit has happened

  # TODO: save stats for best solution and running time

  # return (objective_value, constraint_value)
  return fitnessEvaluation( parameters )
end

"""
( index::Int64 )::Function
"""
function switchProblemEvaluation( index::Int64 )::Function
  if index == 0
    return onemaxFunctionProblemEvaluation
  elseif index == 1
    return deceptiveTrap4TightEncodingFunctionProblemEvaluation
  end
end

"""
( parameters::Array{Bool} )::Tuple{Float64, Float64}
"""
function onemaxFunctionProblemEvaluation( parameters::Array{Bool} )::Tuple{Float64, Float64}
  result = 0.0
  for i = 1:length(parameters)
    result += (parameters[i] == true) ? 1 : 0
  end
  return (result, 0.0)
end

"""
( parameters::Array{Bool} )::Tuple{Float64, Float64}
"""
function deceptiveTrap4TightEncodingFunctionProblemEvaluation( parameters::Array{Bool})::Tuple{Float64,Float64}
  return deceptiveTrapKTightEncodingFunctionProblemEvaluation( parameters, 4)
end

"""
( parameters::Array{Bool} )::Tuple{Float64, Float64}
"""
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

"""
( parameters::Array{Bool} )::Tuple{Float64, Float64}
"""
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

"""
population::Array{Bool},
offspring::Array{Bool},
objective_values::Array{Float64},
constraint_values::Array{Float64},
objective_values_offspring::Array{Float64},
constraint_values_offspring::Array{Float64},
model::Array{Array{Int64}},
model_length::Int64)::Void
"""
function generateAndEvaluateNewSolutionsToFillOffspring!(
    population::Array{Bool},
    offspring::Array{Bool},
    objective_values::Array{Float64},
    constraint_values::Array{Float64},
    objective_values_offspring::Array{Float64},
    constraint_values_offspring::Array{Float64},
    model::Array{Array{Int64}},
    model_length::Int64)::Void

  const backup = Array{Bool}(number_of_parameters)
  const solution = Array{Bool}(number_of_parameters)
  for i = 1:offspring_size
    obj, con = generateNewSolution!(population, i, population_size,
                                    number_of_parameters,
                                    solution, backup,
                                    objective_values, constraint_values,
                                    model, model_length )

    objective_values_offspring[i] = obj
    constraint_values_offspring[i] = con

    offspring[i,:] .= solution
  end
  return
end

"""
( population::Array{Bool}, which::Int64,
population_size::Int64, number_of_parameters::Int64,
result::Array{Bool},
backup::Array{Bool},
objective_values::Array{Float64},
constraint_values::Array{Float64},
model::Array{Array{Int64}},
model_length::Int64 )::Tuple{Float64, Float64}
modifies a solution in place thru GOM and returns its objective value
"""
function generateNewSolution!(
    population::Array{Bool}, which::Int64,
    population_size::Int64, number_of_parameters::Int64,
    result::Array{Bool},
    backup::Array{Bool},
    objective_values::Array{Float64},
    constraint_values::Array{Float64},
    model::Array{Array{Int64}},
    model_length::Int64 )::Tuple{Float64, Float64}

  solution_has_changed = false
  is_unchanged = true

  result .= population[ which , :]
  obj = objective_values[ which ]
  con = constraint_values[ which ]

  # backup = copy(result)
  backup .= result
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

    result[model[i][:]] .= population[ donor_index , model[i][:] ]

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

        backup[ model[ i ][ : ] ] .= result[ model[ i ][ : ] ]

        obj_backup = obj
        con_backup = con

        solution_has_changed = true
      else

        result[ model[ i ][ : ] ] .= backup[ model[ i ][ : ] ]

        obj = obj_backup
        con = con_backup
      end
    end
  end
  # FORCED IMPROVEMENTS PART
  if (!solution_has_changed || (no_improvement_stretch > limit_no_improvement))
    solution_has_changed = false
    for i = model_length-1 : -1 : 1
      number_of_indices = length(model[ i ])

      result[ model[ i ][ : ] ] .= best_prevgen_solution[ model[ i ][ : ] ]

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

          backup[ model[ i ][ : ] ] .= result[ model[ i ][ : ] ]

          obj_backup = obj
          con_backup = con

          solution_has_changed = true
        end
      else
        result[ model[ i ][ : ] ] .= backup[ model[ i ][ : ] ]

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
#############

############# Section Selection

"""
(population::Array{Bool}, offspring::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64}, objective_values_offspring::Array{Float64}, constraint_values_offspring::Array{Float64})::Void
population modified in place
"""
function selectFinalSurvivors!(population::Array{Bool}, offspring::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64}, objective_values_offspring::Array{Float64}, constraint_values_offspring::Array{Float64})::Void
    population .= offspring
    objective_values .= objective_values_offspring
    constraint_values .= constraint_values_offspring
    return
end

"""
(population::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64})::Void
use of global best_prevgen_solution: modified in place
"""
function updateBestPrevGenSolution(population::Array{Bool}, objective_values::Array{Float64}, constraint_values::Array{Float64})::Void
    replace_best_prevgen = false

    individual_index_best = determineBestSolutionInCurrentPopulation(objective_values, constraint_values)

    if (number_of_generations == 0)
        replace_best_prevgen = true
    elseif betterFitness( objective_values[individual_index_best], constraint_values[individual_index_best]
                        , best_prevgen_objective_value, best_prevgen_constraint_value)
        replace_best_prevgen = true
    end
    if replace_best_prevgen == true
        global best_prevgen_solution .= population[individual_index_best, :]
        global best_prevgen_objective_value = objective_values[individual_index_best]
        global best_prevgen_constraint_value = constraint_values[individual_index_best]
        global no_improvement_stretch = 0
    else
        global no_improvement_stretch += 1
    end
    return
end

"""
(objective_values::Array{Float64}, constraint_values::Array{Float64})::Int64
returns index of best
"""
function determineBestSolutionInCurrentPopulation(objective_values::Array{Float64}, constraint_values::Array{Float64})::Int64
    # TODO GIVE AS INPUT
    population_size = length(objective_values)
    index_of_best = 1
    for i = 1:population_size
        if betterFitness( objective_values[i], constraint_values[i],
                        objective_values[index_of_best], constraint_values[index_of_best] )
            index_of_best = i
        end
    end
    return index_of_best
end

"""
(objective_value_x::Float64, constraint_value_x::Float64, objective_value_y::Float64, constraint_value_y::Float64 )::Bool
returns true if x is better than y
"""
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

"""
(objective_value_x::Float64, constraint_value_x::Float64, objective_value_y::Float64, constraint_value_y::Float64 )::Bool
returns true if x is equal to y
"""
function equalFitness(objective_value_x::Float64, constraint_value_x::Float64, objective_value_y::Float64, constraint_value_y::Float64 )::Bool
  result = false

  if (constraint_value_x == constraint_value_y && objective_value_x == objective_value_y)
    result = true
  end
  return result
end
########### Section Termination

"""
(max::Int64, vtr::Float64, tol::Float64, objective_values::Array{Float64})::Bool
returns true if eval > max; bestobj >= value to reach; fitness var <= tol
"""
function checkTerminationCondition(max::Int64, vtr::Float64, tol::Float64, objective_values::Array{Float64})::Bool
    if number_of_evaluations >= max
        println("max eval")
        return true
    end
    if vtr > zero(vtr)
        if best_prevgen_objective_value >= vtr
            println("vtr hit :", best_prevgen_objective_value)
            return true
        end
    end
    if var(objective_values, corrected = false) <= tol
        println("no variance. Best fitness: ", best_prevgen_objective_value)
        return true
    end
    return false
end

########### Section Main

"""
problem_index::Int64,
number_of_parameters::Int64,
population_size::Int64,
modelType::String,
maximum_number_of_evaluations::Int64,
vtr::Float64,
fitness_variance_tolerance::Float64
"""
function main(  problem_index::Int64,
                number_of_parameters::Int64,
                population_size::Int64,
                modelType::String,
                maximum_number_of_evaluations::Int64,
                vtr::Float64,
                fitness_variance_tolerance::Float64
                )
  ############## Options Section
            const write_generational_statistics = true
            const write_generational_solutions  = true
            const print_verbose_overview        = true
            const print_lt_contents             = true
   ############# Run
            const population = randomPopulation(population_size, number_of_parameters)
            const offspring = Array{Bool}(population_size, number_of_parameters)
            const objective_values = Array{Float64}(population_size)
            const constraint_values = Array{Float64}(population_size)
            const objective_values_offspring = Array{Float64}(population_size)
            const constraint_values_offspring = Array{Float64}(population_size)

            # set LTGA globals
            setGlobals(problem_index, number_of_parameters, population_size, modelType)

            # evaluate initial population
            initializeFitnessValues(population, objective_values, constraint_values)

            # generate a fixed model
            const model = generateModelForTypeAndProblemIndex(modelType, problem_index, number_of_parameters)

            const model_length = length(model)

            # update best initial solution
            updateBestPrevGenSolution(population, objective_values, constraint_values)

            while !checkTerminationCondition(maximum_number_of_evaluations, vtr, fitness_variance_tolerance, objective_values)

                generateAndEvaluateNewSolutionsToFillOffspring!( population,
                                                                offspring,
                                                                objective_values,
                                                                constraint_values,
                                                                objective_values_offspring,
                                                                constraint_values_offspring,
                                                                model,
                                                                model_length)


                # update best solution in generation
                # updateBestGenSolution(population, objective_values, constraint_values)

                # place edges
                # LONutilites.placeEdge( LON, best_gen_solution)

                selectFinalSurvivors!( population,
                                      offspring,
                                      objective_values,
                                      constraint_values,
                                      objective_values_offspring,
                                      constraint_values_offspring)

                updateBestPrevGenSolution( population, objective_values, constraint_values)
            end

        # runGA()
        end

        function runGA()
            # initializeFitnessValues
            # updateBestPrevGenSolution
            #
            # while termination
            #     makeOffspring
            #     selectFinalSurvivors
            #     updateBestPrevGenSolution
            # end
        end

end
