using Gallium
include("LTGA.jl")

function randomPopulation(popSize, nParams)
    population = Array{Bool}(popSize, nParams)
    for i = 1:popSize
        for j = 1:nParams
            population[ i , j ] = rand(Bool)
        end
    end
    return population
end

function initializeProblemInstance(index, nParams, population_size)
    population = randomPopulation(population_size, nParams)
    offspring = Array{Bool}(population_size, nParams)
    obj = Array{Float64}(population_size)
    con = Array{Float64}(population_size)
    obj_off = Array{Float64}(population_size)
    con_off = Array{Float64}(population_size)

    # initialize LTGA globals
    LTGA.setGlobals(index, nParams, population_size)

    # evaluate initial population
    LTGA.initializeFitnessValues(population, obj, con)

    # generate fixed model
    model = LTGA.generateModelForProblemIndex(index, nParams)

    return (population, offspring, obj, con, obj_off, con_off, model)
end

pop, off, obj, con, obj_off, con_off, model = initializeProblemInstance(1, 20, 10)


LTGA.updateBestPrevGenSolution(pop, obj, con)

LTGA.generateAndEvaluateNewSolutionsToFillOffspring!(pop, off, obj, con, obj_off, con_off, model)
LTGA.selectFinalSurvivors!( pop, off, obj, con, obj_off, con_off)


end
