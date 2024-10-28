using Agents, Random, Distributions, Agents.Pathfinding
using Random: MersenneTwister

# especifica los estados que va a tener el robot
# green es que el depósito tiene capacidad para mas cajas
# burning es que ese espacio ya esta lleno (5 cajas)
# burnt no se ocupó
@enum TreeStatus green burning burnt

# crea el agente y le asigno el estado por default
@agent struct BoxAgent(GridAgent{2})
    status::TreeStatus = green # todas las cajas tienen espacio para almacenar mas cajas al principio, despiues se llega a 5 y ya no
    num::Integer = 1
end

@agent struct RobotAgent(GridAgent{2})
    min_x::Integer = 1
    max_x::Integer = 8
    linea::Integer = 3
    regreso::Integer = 0
    x_carga::Integer = 1
    cajasLinea::Vector{Any} = [] # todas las cajar por recoger
    trabajando::Integer = 1
    who::Integer = 1
    previous_pos::Tuple{Int, Int} = (0, 0)
    rotation_direction::String = ""
end

# la caja no se mueve, por ende no hay funcion de movimiento
function forest_step(tree::BoxAgent, model)
		
end

function forest_step(robot::RobotAgent, model)

    pathfinder = model.paths[robot.who] # selecciona el pathfinding correspondiente al robot (who indica que pathfinding utilizar)
    if robot.previous_pos != (0, 0) && robot.pos != robot.previous_pos
        delta_x, delta_y = robot.pos[1] - robot.previous_pos[1], robot.pos[2] - robot.previous_pos[2]
        if delta_x == 1 && delta_y == 0
            robot.rotation_direction = "LEFT"
        elseif delta_x == -1 && delta_y == 0
            robot.rotation_direction = "RIGHT"
        elseif delta_x == 0 && delta_y == 1
            robot.rotation_direction = "UP"
        elseif delta_x == 0 && delta_y == -1
            robot.rotation_direction = "DOWN"
        else
            robot.rotation_direction = "DIAGONAL"
        end
        println("Rotation detected: $(robot.rotation_direction)")
        robot.previous_pos = robot.pos
    end
    
    if !isempty(robot.cajasLinea)
        caja_x =robot.cajasLinea[1].pos[1] # obtener posicion de la caja en x
        caja_y =robot.cajasLinea[1].pos[2]-1 # obtener posicion de la caja en y
        if robot.pos == (caja_x,caja_y) && !isempty(robot.cajasLinea) # si el robot esta justo arriba de la caja
            robot.regreso = 1
            
            # actualizamos la matriz para que la casilla de la caja recojida ahora aparezca disponible (43-48)
            matrix = model.matrix
            matrix[robot.cajasLinea[1].pos[1],robot.cajasLinea[1].pos[2]] = 1
            model.matrix = matrix

            maze = BitArray(map(x -> x > 0, matrix))
            pathfinder = AStar(GridSpace((40,40); periodic = false, metric = :chebyshev); walkmap=maze, diagonal_movement=false)
            model.paths[robot.who] = pathfinder # se asigna el nuevo pathfinding dependiendo el indice del robot (who)
            #eliminamos la caja recojida de la lista y del modelo (50-52)
            popcaja = robot.cajasLinea[1] # se guarda para eliminar posterioemtne del modelo
            popfirst!(robot.cajasLinea) # se elimina del arreglo cajasLinea
            remove_agent!(popcaja, model) # se elimina del modelo
            plan_route!(robot, (robot.x_carga,2), pathfinder) # regreso a la zona de descarga
            move_along_route!(robot, model, pathfinder) # se comeinza a mover a la siguiente caja
        elseif robot.pos == (robot.x_carga, 2) && robot.regreso == 1 && !isempty(robot.cajasLinea) # cuando esta en el deposito y va a la siguiente caja
            robot.regreso = 0 # 0 igual a ida, para evitar dejar cajas cuando no tiene, pero pasa por la zona de descarga
            deposito = collect(agents_in_position((robot.x_carga,1),model)) # caja correspondiente al area de carga actual
            if !isempty(deposito)
                print("entra a sumar")
                deposito[1].num = deposito[1].num + 1 # se van sumando cuantas cajas se han depositado
                if deposito[1].num == 5
                    
                    deposito[1].status = burning # cambia el estado a lleno
                    robot.x_carga = robot.x_carga + 1 # se va a la siguiente coordenada del deposito (una unidad a la derecha)
                end
            else
                print("agregar caja") # agregar una caja a la zona de descarga correspondiente (linea 53)
                add_agent!(BoxAgent, pos = (robot.x_carga,1), model)
            end
            plan_route!(robot, (robot.cajasLinea[1].pos[1],robot.cajasLinea[1].pos[2]-1), pathfinder) # se va por la siguiente caja, sin importar si se esta agregando una caja a un deposito viejo o nuevo
            move_along_route!(robot, model, pathfinder) # avanza un paso en la dirección correspondiente
        else # si no está en la caja o en el depósito, esta llegando a su destino, que siga su ruta
            move_along_route!(robot, model, pathfinder) 
        end
    else
        if robot.trabajando == 0
            print("robot ha terminado de acomodar las cajas en su respectivo carril")
            # se agrega la ultima caja antes de terminar de trabajar
        elseif robot.pos == (robot.x_carga, 2)
            robot.trabajando = 0
            deposito = collect(agents_in_position((robot.x_carga,1),model)) # 
            if !isempty(deposito)
                print("entra a sumar")
                deposito[1].num = deposito[1].num + 1 # se agrega 1 al numero de cajas acumuladas
                if deposito[1].num == 5
                    
                    deposito[1].status = burning # pila de cajas llena, burning = llena
                    robot.x_carga = robot.x_carga + 1 # se mueve una posicion a la derecha
                end
            else
                print("agregar caja")
                add_agent!(BoxAgent, pos = (robot.x_carga,1), model) # se agrega la siguiente pila de cajas
            end
        else
            move_along_route!(robot, model, pathfinder)
        end
        
    end
end

# se inicializa el modelo
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

        #se crean las cajas en posiciones aleatorias (a excepcion del area de depósito y de robots)
		for i in 1:100
            empty = collect(empty_positions(model))
            pos = rand(empty)
            x = pos[1]
            y = pos[2]
            while (y == 1 || y == 2) # evita la zona de descarga y robot
                pos = rand(empty)
                x = pos[1]
                y = pos[2]
            end
            matrix[x,y] = 0 # 0 donde hay caja
            add_agent!(BoxAgent, pos = pos, model)
		end

        # la matriz se transforma a bitarray
        maze = BitArray(map(x -> x > 0, matrix))
        model.paths = [] # se guardan los 5 pathfinders (linea 174)

        # [coordenada en x, coordenada en y, limite izquierdo en x, limite derecho en x]
        #         x y x1 x2
        cords = [[4,2,1,8],[13,2,9,16],[20,2,17,24],[28,2,25,32],[36,2,33,40]]

        # num y who son los mismos, indice del robot y su pathfinding (linea 30)
        for num in 1:1 # x_carga posición inicial de la zona de descarga, who le asigna un pathfinding personal a cada robot
            robot = add_agent!(RobotAgent, pos = (cords[num][1],cords[num][2]), model,
                min_x = cords[num][3], 
                max_x = cords[num][4], 
                x_carga = cords[num][3], who = num
            )
            robot.previous_pos = robot.pos
            for linea in 3:40 # zona de cajas
                for i in robot.min_x:robot.max_x # robot en su carril
                    agente = collect(agents_in_position((i,linea),model))
                    if !isempty(agente)
                        robot.cajasLinea = vcat(robot.cajasLinea,agente) # si hay una caja en la posición se agrega, si no, va a la siguiente posición
                    end
                end
            end
            pathfinder = AStar(space; walkmap=maze, diagonal_movement=false) # generación de pathfinding
            push!(model.paths,pathfinder) # agrega un pathfinding por robot
            plan_route!(robot, (robot.cajasLinea[1].pos[1], robot.cajasLinea[1].pos[2]-1), pathfinder) # genera la nueva ruta de la siguiente caja
        end
		model.matrix = matrix # guarda la nueva matriz en el modelo

    return model
end
