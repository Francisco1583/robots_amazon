include("forest.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs

instances = Dict()

route("/simulations", method = POST) do
    payload = jsonpayload()

    den = payload["den"]
    model = forest_fire(density = den)
    #model = forest_fire()
    id = string(uuid1())
    instances[id] = model

    trees = []
    robots = []
    for tree in allagents(model)
        #push!(trees, tree)
        if tree isa BoxAgent
            push!(trees, tree)
        else
            push!(robots,tree)
        end
    end
    
    json(Dict(:msg => "Hola", "Location" => "/simulations/$id", "trees" => trees, "robots" => robots))
end

route("/simulations/:id") do
    model = instances[payload(:id)]
    run!(model, 1)
    trees = []
    robots = []

    simulation_done = all([robot.trabajando == 0 for robot in allagents(model) if robot isa RobotAgent])


    for tree in allagents(model)
        #push!(trees, tree)
        if tree isa BoxAgent
            push!(trees, tree)
        else
            push!(robots,tree)
        end
    end
    
    json(Dict(:msg => "Adios", "trees" => trees, "robots" => robots, "simulation_done" => simulation_done))
end

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS" 
Genie.config.cors_allowed_origins = ["*"]

up()
