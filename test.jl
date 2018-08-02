include("LTGA.jl")
using Gallium

LTGA.isInited()
LTGA.init(1,20,10)

model = Array{Array{Int64}}(6)
for i = 1:5
    model[i] = [j for j = (i-1)*4 + 1:(i-1)*4 + 4]
end

population = Array{Bool}(10,20)
offspring = Array{Bool}(10,20)
obj = Array{Float64}(10)
con = Array{Float64}(10)
obj_off = Array{Float64}(10)
con_off = Array{Float64}(10)

initializedPopulation = LTGA.initializePopulationAndFitnessValues(population, obj, con)
LTGA.generateAndEvaluateNewSolutionsToFillOffspring(initializedPopulation, offspring, obj, con, obj_off, con_off, model)


sol, o, c = LTGA.generateNewSolution(population, 1, obj, con, model )

@enter LTGA.generateNewSolution(population, 1, obj, con, model)
