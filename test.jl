
for i in LightGraphs.edges(LONutility.LON)
    println(i)
end

MAX_SAFE_PROBLEM_SIZE = 68


g = LONutility.LON
nodelabel = [get_prop(g, i, :optimum) for i = LightGraphs.vertices(g)]
draw(SVG("metagraph1.svg", 30cm, 30cm), gplot(g, nodelabel = nodelabel))

for i in edges(g)
    println(i)
end

rem_vertex!(g,LONutility.findInGraph(g, "894")
