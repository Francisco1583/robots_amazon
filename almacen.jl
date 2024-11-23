using PyCall
using Agents, Random, Distributions, Agents.Pathfinding

struct BoxData
    box_id::String
    dimensions::Tuple{Float64, Float64, Float64}
    weight::Float64
    volume::Float64
    truck_coords::Tuple{Float64, Float64, Float64}
end

@agent struct Box(GridAgent{2}) 
    box_id::String
    dimensions::Tuple{Float64, Float64, Float64}
    weight::Float64
    status::Symbol           # :available, :retrieved, :delivered
    volume::Float64
    truck_coords::Tuple{Float64, Float64, Float64}
end

@agent struct Robot(GridAgent{2}) 
    current_task::Union{Nothing, String} = nothing
    carrying::Union{Nothing, Box} = nothing
    pathfinder::Any
    target_pos::Tuple{Int, Int}
    truck_pos::Tuple{Int, Int}
    moving_to::Symbol
end

function find_box_by_id(box_id::String, model)
    for agent in allagents(model)
        if agent isa Box && agent.box_id == box_id
            return agent  # Return the matching Box agent
        end
    end
    return nothing  # Return nothing if no match is found
end

function initialize_robot_pathfinder!(robot::Robot, model)
    # pasar robot para iniciar pathfinder individual
    maze = BitArray(map(x -> x > 0, model.matrix))
    robot.pathfinder = AStar(GridSpace((40, 40); periodic = false, metric = :chebyshev); walkmap=maze, diagonal_movement=true)
end

# function check_collision!(robot::Robot, model)
#     # toda matriz a 1
#     model.matrix .= 1  

#     # todas las posiciones con agente marcar como 0
#     # al ser 0 pathfinder ignora
#     for other_robot in allagents(model)
#         if other_robot isa Robot && other_robot != robot
#             model.matrix[other_robot.pos...] = 0  
#         end
#     end
# end

function compute_path!(robot::Robot, target_pos, model)
    # evitamos colisiones
    # check_collision!(robot, model)

    # actualizar matriz con colisiones evitadas
    maze = BitArray(map(x -> x > 0, model.matrix))
    robot.pathfinder = AStar(GridSpace((40, 40); periodic = false, metric = :chebyshev); walkmap=maze, diagonal_movement=true)

    # planear ruta de acuerdo con nueva matriz
    plan_route!(robot, target_pos, robot.pathfinder)
end

function assign_next_task!(robot::Robot, model)
    # Check if there are boxes in the queue
    if !isempty(model.box_queue)
        
        next_box_id = model.box_queue[1]
        model.box_queue = model.box_queue[2:end]

        # Find the corresponding box agent in the model
        box = find_box_by_id(next_box_id, model)
        if box === nothing
            println("Error: No box with ID $(next_box_id) found in model!")
            return
        else
            println("Box found: ", box)
        end

        # Assign the box to the robot
        robot.current_task = next_box_id
        robot.target_pos = box.pos
        box.status = :retrieved
        robot.moving_to = :retrieve

        # Debug prints for robot assignment
        println("Robot ID: ", robot.id, " assigned to box ID: ", robot.current_task)
        println("Target position set to: ", robot.target_pos)
        println("Box status updated to :retrieved for box ID: ", box.box_id)

    else
        # No more boxes to assign
        println("Box queue is empty. Robot awaiting new tasks.")
        robot.current_task = nothing
        robot.moving_to = :await
    end
end


function robot_step!(robot::Robot, model)
    if robot.moving_to == :retrieve # recuperando
        # ir hacia caja asignada
        if robot.pos == robot.target_pos
            # al llegar a caja, recuperamos de modelo
            all_agents = collect(values(allagents(model)))
            box = find_box_by_id(robot.current_task, model)  # Get the assigned box
            if box !== nothing
                # add box to agent
                robot.carrying = box
                box.status = :retrieved  # Mark the box as retrieved
                robot.moving_to = :deliver  # Change robot state to delivering
                robot.target_pos = robot.truck_pos  # Update the target position
            else
                println("Error: Box with ID $(robot.current_task) not found in agents!")
            end
        else
            # Si no se ha llegado a destino seguir moviendo
            compute_path!(robot, robot.target_pos, model)
            move_along_route!(robot, model, robot.pathfinder)
        end
    elseif robot.moving_to == :deliver #entregando
        # ir hacia camion
        if robot.pos == robot.truck_pos
            # entregar caja
            if robot.carrying !== nothing
                box = robot.carrying # extraer caja
                box.status = :delivered # cambiar estado de caja a entregada
                robot.carrying = nothing # cambiar espacio de robot para cargar nada
                assign_next_task!(robot, model)  # Asignar siguiente caja
            end
        else
            # seguir moviendo
            compute_path!(robot, robot.target_pos, model)
            move_along_route!(robot, model, robot.pathfinder)
        end
    elseif robot.moving_to == :await # Waiting for tasks
        # Check if there are tasks available
        if !isempty(model.box_queue)
            assign_next_task!(robot, model)  # Assign a new task
        end
    end
end

function agent_step!(agent, model)
    if agent isa Robot
        robot_step!(agent, model)  # Call the robot's step logic
    elseif agent isa Box
        # Boxes are static, no action needed
    end
end

function almacen_init(pycall_boxes::Vector{BoxData}, grid_dims, num_robots, truck_position)
    space = GridSpace(grid_dims; periodic = false, metric = :chebyshev) # Define grid space
    model = StandardABM(
        Union{Robot, Box}, 
        space; 
        properties=Dict{Symbol, Any}(
            :box_queue => Vector{String}(),
            :matrix => ones(Int, grid_dims...)
        ),
        agent_step! = agent_step!
    )
    
    # Add Robot agents to the model
    for i in 1:num_robots
        empty = collect(empty_positions(model))
        pos = rand(empty)

        robot = add_agent!(Robot, model; 
            pos=pos, 
            current_task=nothing, 
            carrying=nothing, 
            pathfinder=nothing, 
            target_pos=pos, 
            truck_pos=(40, 40), 
            moving_to=:await
        )
        # Add the preconstructed agent to the model
        # add_agent!(robot, model)
        initialize_robot_pathfinder!(robot, model)
    end

    # Populate the box queue
    for box_data in pycall_boxes
        push!(model.box_queue, box_data.box_id)  # Add box IDs to the queue
    end 

    # Add Box agents to the model
    for (i, box_data) in enumerate(pycall_boxes)
        empty = collect(empty_positions(model))
        pos = rand(empty)  # Get a random position
        box = add_agent!(Box, model; 
            pos=pos, 
            box_id=box_data.box_id, 
            dimensions=box_data.dimensions, 
            weight=box_data.weight, 
            status=:available, 
            volume=box_data.volume, 
            truck_coords=box_data.truck_coords
        )

        # add_agent!(box, model)
    end

    return model
end
