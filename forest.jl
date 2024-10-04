using Agents, Random, Distributions
using Random: MersenneTwister
#especifica los estados que va a tener el arbol
@enum TreeStatus green burning burnt

#crea el agente y le asigno alguno de los estados
@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end
#funcion bastate intuitiva por lo mismo no la explico
function forest_step(tree::TreeAgent, model)
	#aleatorio = abmrng(model)
    if tree.status == burning
	   x = tree.pos[1] 
	   y = tree.pos[2]
	   big_neighbors = nearby_agents(tree, model,round(hypot(model.west_wind_speed/15,model.south_wind_speed/15)))
	   #big_neighbors = nearby_agents(tree,model,4)
	   verdes = []
	   for neighbor in big_neighbors 
		   if neighbor.status == green
			   push!(verdes,neighbor)
		   end
	   end
	   if !isempty(verdes)&& model.big_jumps && rand(Uniform(0,1)) < abs((model.big_probability))/100
	  # if !isempty(verdes)&& model.big_jumps
		   first_verde = first(verdes)
		   first_verde.status = burning
	   end

        for neighbor in nearby_agents(tree, model)
		if neighbor.status == green
			#posicion arriba
			if neighbor.pos[1] == x && neighbor.pos[2] < y && rand(Uniform(0,1)) < ((model.probability_of_spread/2) - model.south_wind_speed)/100
				neighbor.status = burning
			#psicion abajo
			elseif neighbor.pos[1] == x && neighbor.pos[2] > y && rand(Uniform(0,1)) < ((model.probability_of_spread/2) + model.south_wind_speed)/100
				neighbor.status = burning
			#posicion a la derecha
			elseif neighbor.pos[2] == y && neighbor.pos[1] > x && rand(Uniform(0,1)) < ((model.probability_of_spread/2) + model.west_wind_speed)/100 
				neighbor.status = burnin
			#posicion a la izquierda
			elseif neighbor.pos[2] == y && neighbor.pos[1] < x && rand(Uniform(0,1)) < ((model.probability_of_spread/2) - model.west_wind_speed)/100
				neighbor.status = burning
			#esquina inferior derecha
			#elseif neighbor.pos[1] > x && neighbor.pos[2] > y && rand(Uniform(0,1)) < abs((model.probability_of_spread/2))/100
                         #       neighbor.status = burning
			#esquin superior derecha
			#elseif neighbor.pos[1] > x && neighbor.pos[2] < y && rand(Uniform(0,1)) < abs((model.probability_of_spread/2))/100
                         #       neighbor.status = burning
			#esquina superior izquierda 
			#elseif neighbor.pos[1] < x && neighbor.pos[2] < y && rand(Uniform(0,1)) < abs((model.probability_of_spread/2))/100
                         #       neighbor.status = burning
			#esquina inferior izquierda
			#elseif neighbor.pos[1] < x && neighbor.pos[2] > y && rand(Uniform(0,1)) < abs((model.probability_of_spread/2))/100
                         #       neighbor.status = burning
			elseif rand(Uniform(0,1)) < abs((model.probability_of_spread/2))/100
				neighbor.status = burning

			end 
		end
            
        end
        tree.status = burnt
    end
end
#density es para definir la cantidad de arboles que hay en el bosque
#griddims es el tamaño del bosque por así decirlo
function forest_fire(; density = 0.45, griddims = (50, 50), probability_of_spread = 50, south_wind_speed = 0, west_wind_speed = 0,big_jumps = false, big_probability = 0)
    space = GridSpaceSingle(griddims; periodic = false, metric = :chebyshev)
    #forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(),rng = MersenneTwister(6998),properties = Dict(:probability_of_spread => probability_of_spread))
    #forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly())
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.Randomly(),properties = Dict(:probability_of_spread => probability_of_spread,:south_wind_speed => south_wind_speed,:west_wind_speed => west_wind_speed, :big_jumps => big_jumps, :big_probability => big_probability))

    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, forest)
	    #indica que si estamos en la primer columna cambie el estado del arbol a quemado
	    #en pos cuando ponemos 1 nos referimos a columna
	    #en pos cuando ponemos 2 nos referimos a renglon
            if pos[1] == 1
                tree.status = burning
            end
        end
    end
    #forest[:probability_of_spread] = probability_of_spread
    return forest
end
