using Gallium
include("LTGA.jl")
using LTGA

@time for i = 1:1
    runGA(1, 12, 16, "lt", 1000000, 3.0 , 0.0 )
    resetGA()
end



# TODO: think of a way to correctly initialize ltga
# TODO: fix types
# TODO: fix LON utilities
