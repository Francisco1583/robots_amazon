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
    deposit_carga::Integer = 0
    carga::Integer = 1
    caja_id::Integer = 0
    min_x::Integer = 1
    max_x::Integer = 8
    min_y::Integer = 3
    max_y::Integer = 40
    linea::Integer = 3
    regreso::Integer = 0
    x_carga::Integer = 1
    reset::Integer = 0
    cajasLinea::Vector{Any} = []
    romper::Integer = 0
end
#funcion bastate intuitiva por lo mismo no la explico
function forest_step(tree::BoxAgent, model)
	pathfinder = model.path 
	move_along_route!(tree, model, pathfinder)
	#end
				
end

function forest_step(robot::RobotAgent, model)
    pathfinder = model.path 
    if robot.reset == 0
    print("primer_if")
        robot.reset = 1
        if isempty(robot.cajasLinea)
            for i in robot.min_x:robot.max_x
                agente = collect(agents_in_position((i,robot.linea),model))
                if !isempty(agente)
                    robot.cajasLinea = vcat(robot.cajasLinea,agente)
                end
            end
        end
        if !isempty(robot.cajasLinea)
            plan_route!(robot, (robot.cajasLinea[1].pos[1], robot.cajasLinea[1].pos[2]-1), pathfinder)
        end
    elseif !isempty(robot.cajasLinea)
        print("segundo_if")
        r_x = robot.pos[1]
        r_y = robot.pos[2]
        c_x = robot.cajasLinea[1].pos[1]
        c_y = robot.cajasLinea[1].pos[2]-1
        
        if ((r_x,r_y) == (c_x,c_y)) && robot.regreso == 0
            robot.regreso = 1
            #print("caso2")
            matrix = model.matrix
            matrix[robot.cajasLinea[1].pos[1],robot.cajasLinea[1].pos[2]] = 1
            model.matrix = matrix
            maze = BitArray(map(x -> x > 0, matrix))
            pathfinder = AStar(GridSpace((40,40); periodic = false, metric = :chebyshev); walkmap=maze, diagonal_movement=false)
            model.path = pathfinder
            popcaja = robot.cajasLinea[1]
            popfirst!(robot.cajasLinea)
            remove_agent!(popcaja, model)
            plan_route!(robot, (robot.x_carga,2), pathfinder)
        elseif ((r_x,r_y) == (robot.x_carga,2)) && robot.regreso == 1
            print("tercer_if")
            deposito = collect(agents_in_position((robot.x_carga,1),model))
            if !isempty(deposito)
                print("entra a sumar")
                deposito[1].num = deposito[1].num + 1
                if deposito[1].num == 5
                    robot.x_carga = robot.x_carga + 1
                end
            else
                print("agregar caja")
                add_agent!(BoxAgent, pos = (robot.x_carga,1), model)
            end
            robot.regreso = 0
            robot.reset = 0
        end
        move_along_route!(robot, model, pathfinder)
    else
        print("cuarto_if")
        move_along_route!(robot, model, pathfinder)
        r_x = robot.pos[1]
        r_y = robot.pos[2]
        #corregir logica aquí
        if ((r_x,r_y) == (robot.x_carga,2) || (r_x,r_y) == (4,2)) && robot.linea < 20
        print("quinto_if")
            robot.linea = robot.linea + 1 
            deposito = collect(agents_in_position((robot.x_carga,1),model))
            if !isempty(deposito)
                print("entra a sumar")
                deposito[1].num = deposito[1].num + 1
                if deposito[1].num == 5
                    robot.x_carga = robot.x_carga + 1
                end
            else
                print("agregar caja")
                add_agent!(BoxAgent, pos = (robot.x_carga,1), model)
            end
            robot.regreso = 0
            robot.reset = 0
        end
        #print("termina")
    end
	#pathfinder = model.path 
	#move_along_route!(robot, model, pathfinder)
end

function forest_fire(; density = 0.45, griddims = (50, 50), probability_of_spread = 50, south_wind_speed = 0, west_wind_speed = 0,big_jumps = true, big_probability = 100)
    space = GridSpace((40,40); periodic = false, metric = :chebyshev)
    model = StandardABM(Union{RobotAgent,BoxAgent}, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(),properties = Dict{Symbol, Any}(:probability_of_spread => probability_of_spread,:south_wind_speed => south_wind_speed,:west_wind_speed => west_wind_speed, :big_jumps => big_jumps, :big_probability => big_probability, :path => nothing, :matrix=> nothing))
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
            while (y == 1 || y == 2) || x > 8
                pos = rand(empty)
                x = pos[1]
                y = pos[2]
            end
            matrix[x,y] = 0
            add_agent!(BoxAgent, pos = pos, model)
		 end
		 
         #sea agrega a los robots
		 add_agent!(RobotAgent, pos = (4, 2), model)
		 #add_agent!(RobotAgent, pos = (13,2), model)
		 #add_agent!(RobotAgent, pos = (20,2), model)
		 #add_agent!(RobotAgent, pos = (28,2), model)
		 #add_agent!(RobotAgent, pos = (36,2), model)
		 #add_agent!(RobotAgent, pos = (28,2), model)

		 #area de pruebas
		 #add_agent!(BoxAgent, pos = (1, 4), model)
		 #add_agent!(BoxAgent, pos = (2, 4), model)
		 #add_agent!(BoxAgent, pos = (3, 4), model)
		 #add_agent!(BoxAgent, pos = (4, 4), model)
		 #add_agent!(BoxAgent, pos = (5, 4), model)
		 #add_agent!(BoxAgent, pos = (6, 4), model)
		 #add_agent!(BoxAgent, pos = (7, 4), model)
		 #add_agent!(BoxAgent, pos = (8, 4), model)

         #se crea el espacio por el que el path hará la ruta
         maze = BitArray(map(x -> x > 0, matrix))
		 pathfinder = AStar(space; walkmap=maze, diagonal_movement=false)
		 model.path = pathfinder
		 model.matrix = matrix
		 #plan_route!(a, (4, 6), pathfinder)
    return model
end
