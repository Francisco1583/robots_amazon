# include("forest.jl")
include("almacen.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs
using PyCall

Packer = pyimport("py3dbp").Packer
Bin = pyimport("py3dbp").Bin
Item = pyimport("py3dbp").Item

instances = Dict()

route("/simulations", method = POST) do
    payload = jsonpayload()

    
    # Create the packing scenario
    packer = Packer()
    packer.add_bin(Bin("large-box", 40.0, 40.0, 40.0, 100.0))  # Define a large bin

    # Add five items
    packer.add_item(Item("box_1", 10.0, 5.0, 5.0, 0.0))
    packer.add_item(Item("box_2", 8.0, 4.0, 4.0, 0.0))
    packer.add_item(Item("box_3", 7.0, 3.0, 3.0, 0.0))
    packer.add_item(Item("box_4", 6.0, 3.0, 2.0, 0.0))
    packer.add_item(Item("box_5", 5.0, 2.0, 2.0, 0.0))

    # Perform packing
    packer.pack()

    # Prepare the list of Box agents
    pycall_boxes = Vector{BoxData}()

    for bin in packer[:bins]
        for item in bin[:items]
            boxid = item[:name]
            width = item[:width]
            height = item[:height]
            depth = item[:depth]
            weight = item[:weight]
            vol = width * height * depth
            x = item[:position][1]
            y = item[:position][2]
            z = item[:position][3]
            depth = item[:depth]
            push!(pycall_boxes, BoxData(
                boxid,
                (width, height, depth),
                weight,
                vol,
                (x, y, z),
            ))
        end
    end

    # Initialize the simulation using almacen_init
    grid_dims = (40, 40)  # Define a 40x40 grid
    num_robots = 1  # Only one robot
    truck_position = (40, 40)  # Truck is at the top-right corner

    model = almacen_init(pycall_boxes, grid_dims, num_robots, truck_position)

    id = string(uuid1())
    instances[id] = model

    boxes = []
    robots = []
    for agent in allagents(model)
        if agent isa Box
            push!(boxes, agent)
        else
            push!(robots,agent)
        end
    end
    
    json(Dict(:msg => "Hola", "Location" => "/simulations/$id", "boxes" => boxes, "robots" => robots))
end

route("/simulations/:id") do
    model = instances[payload(:id)]
    run!(model, 1)

    # simulation_done = all([robot.trabajando == 0 for robot in allagents(model) if robot isa RobotAgent])


    boxes = []
    robots = []
    for agent in allagents(model)
        if agent isa Box
            push!(boxes, agent)
        else
            push!(robots,agent)
        end
    end
    
    json(Dict(:msg => "Adios", "boxes" => boxes, "robots" => robots))
end

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS" 
Genie.config.cors_allowed_origins = ["*"]

up()
