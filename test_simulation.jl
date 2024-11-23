# Import your main file with all functions
using Agents
include("almacen.jl")

# Python 3D bin-packing setup
Packer = pyimport("py3dbp").Packer
Bin = pyimport("py3dbp").Bin
Item = pyimport("py3dbp").Item

# Create the packing scenario
packer = Packer()
packer.add_bin(Bin("large-box", 40.0, 40.0, 40.0, 100.0))  # Define a large bin

# Add five items
packer.add_item(Item("box_1", 10.0, 5.0, 5.0, 1.0))
packer.add_item(Item("box_2", 8.0, 4.0, 4.0, 1.0))
packer.add_item(Item("box_3", 7.0, 3.0, 3.0, 1.0))
packer.add_item(Item("box_4", 6.0, 3.0, 2.0, 1.0))
packer.add_item(Item("box_5", 5.0, 2.0, 2.0, 1.0))

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
box_agents = filter(x -> x isa Box, collect(values(allagents(model))))

if !isempty(box_agents)
    for box in box_agents
        println("Box ID: ", box.box_id)
        # println("Box Dimensions: ", box.dimensions)
        # println("Box Volume: ", box.volume)
    end
end

println("Starting simulation...")
max_steps = 400  # Limit simulation to 100 steps
for step in 1:max_steps
    # println("Step $step")

    # println("Current Box Queue: ", model.box_queue)

    for agent in allagents(model)
        if agent isa Robot
            println("step---------------------")
            println("current pos: ", agent.pos)
            println("target: ", agent.target_pos)
            println("holding: ", agent.carrying)
            println("mode: ", agent.moving_to)
            println("-------------------------")
        end
    end

    # for agent in allagents(model)
    #     println("Agent ID: ", agent.id)
    #     if agent isa Box
    #         println("  Type: Box")
    #         println("  Status: ", agent.status)
    #         # println("  Dimensions: ", agent.dimensions)
    #         # println("  Volume: ", agent.volume)
    #         # println("  Truck Coords: ", agent.truck_coords)
    #         println("  Current Position: ", agent.pos)
    #     elseif agent isa Robot
    #         println("  Type: Robot")
    #         println("  Current Task: ", agent.current_task)
    #         println("  Carrying: ", agent.carrying)
    #         println("  Target Position: ", agent.target_pos)
    #         # println("  Truck Position: ", agent.truck_pos)
    #         println("  Moving To: ", agent.moving_to)
    #         println("  Current Position: ", agent.pos)
    #     else
    #         println("  Unknown agent type!")
    #     end
    #     println("----------------------")
    # end

    # Perform a single step for all agents
    step!(model, 1)

    # Check if all boxes are delivered
    box_agents = filter(x -> x isa Box, collect(values(allagents(model))))
    if all(box.status == :delivered for box in box_agents)
        println("All boxes delivered in $step steps.")
        break
    end
end
println("Simulation finished.")