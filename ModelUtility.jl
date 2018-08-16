__precompile__()

module ModelUtility

export generateModelForTypeAndProblemIndex

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

end
