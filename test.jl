using Gallium
include("LTGA.jl")
#
# function randomPopulation(popSize, nParams)
#     population = Array{Bool}(popSize, nParams)
#     for i = 1:popSize
#         for j = 1:nParams
#             population[ i , j ] = rand(Bool)
#         end
#     end
#     return population
# end
#
# function initializeProblemInstance(index, nParams, population_size, modelType)
#     population = randomPopulation(population_size, nParams)
#     offspring = Array{Bool}(population_size, nParams)
#     obj = Array{Float64}(population_size)
#     con = Array{Float64}(population_size)
#     obj_off = Array{Float64}(population_size)
#     con_off = Array{Float64}(population_size)
#
#     # initialize LTGA globals
#     LTGA.setGlobals(index, nParams, population_size, modelType)
#
#     # evaluate initial population
#     LTGA.initializeFitnessValues(population, obj, con)
#
#     # generate fixed model
#     model = LTGA.generateModelForTypeAndProblemIndex(modelType, index, nParams)
#
#     return (population, offspring, obj, con, obj_off, con_off, model)
# end
#
# pop, off, obj, con, obj_off, con_off, model = initializeProblemInstance(1, 32, 10, "lt")
#
#
# LTGA.updateBestPrevGenSolution(pop, obj, con)
# best = LTGA.best_prevgen_objective_value
# LTGA.generateAndEvaluateNewSolutionsToFillOffspring!(pop, off, obj, con, obj_off, con_off, model)
# LTGA.selectFinalSurvivors!( pop, off, obj, con, obj_off, con_off)
@time x = 0
LTGA.setGlobals(1, 20, 12, "lt")

@time LTGA.main(1, 20, 16, "lt", 1000000, 6.0 , 0.0 )
LTGA.best_prevgen_objective_value
LTGA.

const y = [1,2,3,4]

# TODO: think of a way to correctly initialize ltga
# TODO: fix types
# TODO: fix LON utilities

push!(y,0)
