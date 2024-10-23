using Agents, Random, Distributions, Agents.Pathfinding
using Random: MersenneTwister
#especifica los estados que va a tener el arbol
@enum TreeStatus green burning burnt

#crea el agente y le asigno alguno de los estados
@agent struct BoxAgent(GridAgent{2})
    status::TreeStatus = green
    num::Integer = 1
end

@agent struct RobotAgent(GridAgent{2})
    min_x::Integer = 1
    max_x::Integer = 8
    linea::Integer = 3
    regreso::Integer = 0
    x_carga::Integer = 1
    cajasLinea::Vector{Any} = []
    trabajando::Integer = 1
    who::Integer = 1
end
#funcion bastate intuitiva por lo mismo no la explico
function forest_step(tree::BoxAgent, model)
		
end

function forest_step(robot::RobotAgent, model)

    pathfinder = model.paths[robot.who]
    
    if !isempty(robot.cajasLinea)
        caja_x =robot.cajasLinea[1].pos[1]
        caja_y =robot.cajasLinea[1].pos[2]-1
        if robot.pos == (caja_x,caja_y) && !isempty(robot.cajasLinea)
            robot.regreso = 1
            #actualizamos la matriz para que la casilla de la caja recojida ahora aparezca disponible (43-48)
            matrix = model.matrix
            matrix[robot.cajasLinea[1].pos[1],robot.cajasLinea[1].pos[2]] = 1
            model.matrix = matrix
            maze = BitArray(map(x -> x > 0, matrix))
            pathfinder = AStar(GridSpace((40,40); periodic = false, metric = :chebyshev); walkmap=maze, diagonal_movement=false)
            model.paths[robot.who] = pathfinder 
            #eliminamos la caja recojida de la lista y del modelo (50-52)
            popcaja = robot.cajasLinea[1]
            popfirst!(robot.cajasLinea)
            remove_agent!(popcaja, model)
            plan_route!(robot, (robot.x_carga,2), pathfinder)
            move_along_route!(robot, model, pathfinder)
        elseif robot.pos == (robot.x_carga, 2) && robot.regreso == 1 && !isempty(robot.cajasLinea)
            robot.regreso = 0
            deposito = collect(agents_in_position((robot.x_carga,1),model))
            if !isempty(deposito)
                print("entra a sumar")
                deposito[1].num = deposito[1].num + 1
                if deposito[1].num == 5
                    
                    deposito[1].status = burning
                    robot.x_carga = robot.x_carga + 1
                end
            else
                print("agregar caja")
                add_agent!(BoxAgent, pos = (robot.x_carga,1), model)
            end
            plan_route!(robot, (robot.cajasLinea[1].pos[1],robot.cajasLinea[1].pos[2]-1), pathfinder)
            move_along_route!(robot, model, pathfinder)
        else
            move_along_route!(robot, model, pathfinder)
        end
    else
        if robot.trabajando == 0
            print("robot ha terminado de acomodar las cajas en su respectivo carril")
        elseif robot.pos == (robot.x_carga, 2)
            robot.trabajando = 0
            deposito = collect(agents_in_position((robot.x_carga,1),model))
            if !isempty(deposito)
                print("entra a sumar")
                deposito[1].num = deposito[1].num + 1
                if deposito[1].num == 5
                    
                    deposito[1].status = burning
                    robot.x_carga = robot.x_carga + 1
                end
            else
                print("agregar caja")
                add_agent!(BoxAgent, pos = (robot.x_carga,1), model)
            end
        else
            move_along_route!(robot, model, pathfinder)
        end
        
    end
end

function forest_fire(; density = 0.45, griddims = (50, 50), probability_of_spread = 50, south_wind_speed = 0, west_wind_speed = 0,big_jumps = true, big_probability = 100)
    space = GridSpace((40,40); periodic = false, metric = :chebyshev)
    model = StandardABM(Union{RobotAgent,BoxAgent}, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(),properties = Dict{Symbol, Any}(:probability_of_spread => probability_of_spread,:south_wind_speed => south_wind_speed,:west_wind_speed => west_wind_speed, :big_jumps => big_jumps, :big_probability => big_probability, :path => nothing, :matrix=> nothing,:path1 => nothing,:paths => nothing))
		matrix = [
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;
            1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1;																
						 ]

         #se crean las cajas en posiciones aleatorias (a excepcion del area de deposito y de robots)
		 for i in 1:100
            empty = collect(empty_positions(model))
            pos = rand(empty)
            x = pos[1]
            y = pos[2]
            while (y == 1 || y == 2) 
                pos = rand(empty)
                x = pos[1]
                y = pos[2]
            end
            matrix[x,y] = 0
            add_agent!(BoxAgent, pos = pos, model)
		 end

		 maze = BitArray(map(x -> x > 0, matrix))
		 model.paths = []

		 cords = [[4,2,1,8],[13,2,9,16],[20,2,17,24],[28,2,25,32],[36,2,33,40]]

		 for num in 1:5
            robot = add_agent!(RobotAgent, pos = (cords[num][1],cords[num][2]), model,min_x = cords[num][3], max_x = cords[num][4], x_carga = cords[num][3], who = num)
            for linea in 3:40
                for i in robot.min_x:robot.max_x
                    agente = collect(agents_in_position((i,linea),model))
                    if !isempty(agente)
                        robot.cajasLinea = vcat(robot.cajasLinea,agente)
                    end
                end
            end
            pathfinder = AStar(space; walkmap=maze, diagonal_movement=false)
            push!(model.paths,pathfinder)
            plan_route!(robot, (robot.cajasLinea[1].pos[1], robot.cajasLinea[1].pos[2]-1), pathfinder)
		 end
		 model.matrix = matrix
    return model
end
