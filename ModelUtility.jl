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
            elseif index == 2
                return LTmodelForDeceptive5Tight(nParams)
            elseif index == 3
                return LTmodelForDeceptive4Loose(nParams)
            elseif index == 4
                return LTmodelForDeceptive5Loose(nParams)
            end
        elseif modelType == "mp"
            if index == 1
                return MPmodelForDeceptive4Tight(nParams)
            elseif index == 2
                return MPmodelForDeceptive5Tight(nParams)
            elseif index == 3
                return MPmodelForDeceptive4Loose(nParams)
            elseif index == 4
                return MPmodelForDeceptive5Loose(nParams)
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
function MPmodelForDeceptive4Tight(nparams::Int64)
    return MPmodelForDeceptiveKTight(nparams, 4)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns a Marginal Product model for deceptive thight with k = 4
"""
function MPmodelForDeceptive5Tight(nparams::Int64)
    return MPmodelForDeceptiveKTight(nparams, 5)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns a Marginal Product model for deceptive Loose with k = 4
"""
function MPmodelForDeceptive4Loose(nparams::Int64)
    return MPmodelForDeceptiveKLoose(nparams, 4)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns a Marginal Product model for deceptive Loose with k = 4
"""
function MPmodelForDeceptive5Loose(nparams::Int64)
    return MPmodelForDeceptiveKLoose(nparams, 5)
end
"""
(nparams::Int64)::Array{Array{Int64}}
returns a Marginal Product model for deceptive thight for any k
"""
function MPmodelForDeceptiveKTight(nparams::Int64, k::Int64)::Array{Array{Int64}}
    number_of_blocks = Int(nparams / k)
    # model has 1 additional element at last position for compatibility with LT model
    model = Array{Array{Int64}}(number_of_blocks + 1)
    for i = 1:number_of_blocks
        model[i] = [j for j = k(i-1) + 1: k(i-1) + k]
    end
    return model
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns a Marginal Product model for deceptive loose for any k
"""
function MPmodelForDeceptiveKLoose(nparams::Int64, k::Int64)::Array{Array{Int64}}
    number_of_blocks = Int(nparams / k)
    # model has 1 additional element at last position for compatibility with LT model
    model = Array{Array{Int64}}(number_of_blocks + 1)
    for i = 1:number_of_blocks
        model[i] = [j for j = i:number_of_blocks:nparams]
    end
    return model
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive tight with k = 4
"""
function LTmodeForDeceptive4Tight(nparams::Int64, k::Int64)::Array{Array{Int64}}
    return LTmodeForDeceptiveKTight(nparams, 4)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive tight with k = 5
"""
function LTmodeForDeceptive5Tight(nparams::Int64, k::Int64)::Array{Array{Int64}}
    return LTmodeForDeceptiveKTight(nparams, 5)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive loose with k = 4
"""
function LTmodeForDeceptive4Loose(nparams::Int64, k::Int64)::Array{Array{Int64}}
    return LTmodeForDeceptiveKLoose(nparams, 4)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive loose with k = 5
"""
function LTmodeForDeceptive5Loose(nparams::Int64, k::Int64)::Array{Array{Int64}}
    return LTmodeForDeceptiveKLoose(nparams, 5)
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive tight for any k
"""
function LTmodeForDeceptiveKTight(nparams::Int64, k::Int64)::Array{Array{Int64}}
    const roundedHalf = round(Int, nparams/2, RoundDown)
    const blocks = Int(nparams / k)
    nodes = Int(nparams + roundedHalf + blocks + 1)
    model = Array{Array{Int64}}(nodes)
    for i = 1:nparams
        model[i] = [i]
    end
    for i = 1:roundedHalf
        model[i + nparams] = [j for j = (i*2) - 1:i*2]
    end
    for i = 1:blocks
        model[i + nparams + roundedHalf] = [j for j = (i-1)k + 1: (i-1)k + k]
    end
    model[nodes] = [0]
    return model
end

"""
(nparams::Int64)::Array{Array{Int64}}
returns LT model for deceptive loose for any k
"""
function LTmodelForDeceptiveKLoose(nparams::Int64, k::Int64)::Array{Array{Int64}}
    const roundedHalf = round(Int, nparams/2, RoundDown)
    const number_of_blocks = Int(nparams/k)
    nodes = Int(nparams + roundedHalf + number_of_blocks + 1)
    model = Array{Array{Int64}}(nodes)
    for i = 1:nparams
        model[i] = [i]
    end
    for i = 1:roundedHalf
        c = i
        if i % number_of_blocks == 0
            c += number_of_blocks
        end
        model[i + nparams] = [c, c + number_of_blocks]
    end
    # for i = 1:number_of_blocks
    filled = nparams + roundedHalf
    model[filled + 1 : filled + 1 + number_of_blocks] = MPmodelForDeceptiveKLoose(nparams, k)
    # end
    model[nodes] = [0]
    return model
end


end
