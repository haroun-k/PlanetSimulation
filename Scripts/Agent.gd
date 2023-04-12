class_name Agent extends SpringArm3D

@export var selfData : AgentData
@onready var worldNode=get_parent().get_node("WorldMesh")
@onready var world: WorldResource = worldNode.worldResource
@onready var atmosphere = get_parent().get_node("Atmosphere")

var true_agent # L'agent qui se trouve a la fin du spring arm

# Charge les modeles 3D des differentes especes
func paths_to_objs_array(path):
	var arr=[]
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			arr.push_back(String(path+file_name))
			file_name = dir.get_next()
			file_name = dir.get_next()
	return arr

# L'agent entre dans le monde
func _ready():

	selfData.agentScene.rotate(Vector3(1,0,0),-90)
	
	selfData.directionMesh = MeshInstance3D.new()
	selfData.directionMesh.mesh=BoxMesh.new()
	selfData.directionMesh.set_scale(Vector3(0.5, 1, 0.5))
	margin=0.03
	spring_length=3000
	true_agent.add_child(selfData.directionMesh)
	look_at(global_position*2)
	
	update_position()
	take_random_direction()

# Instancie un nouvel agent
func _init(world : Node3D, initialCenterPosition : Vector3, specieNumber : int, copy : Agent=null):
	
	# Initialisation des données de l'agent
	selfData = AgentData.new()
	selfData.currentPosition=initialCenterPosition
	selfData.currentPath.push_back(selfData.currentPosition)
	selfData.world = world
	position=initialCenterPosition*10
	world.speciesDictionary[self]=specieNumber
	selfData.appareancesArray = paths_to_objs_array("res://Objects/glTF/")
	selfData.specie = specieNumber

	# Mutation des genes de l'agent ou initialisation aléatoire
	if copy==null : 
		selfData.randomize_genes()
	else :
		selfData.age=0
		selfData.baby=true
		selfData.maxAge=copy.selfData.maxAge + (copy.selfData.maxAge/2*copy.selfData.reproductionVariations)
		selfData.adultAge=copy.selfData.adultAge + (copy.selfData.adultAge/2*copy.selfData.reproductionVariations)
		selfData.hunger=0
		selfData.maxHunger=copy.selfData.maxHunger + (copy.selfData.maxHunger/2*copy.selfData.reproductionVariations)
		selfData.toleratedHunger=copy.selfData.toleratedHunger + (copy.selfData.toleratedHunger/2*copy.selfData.reproductionVariations)
		selfData.size=copy.selfData.size + (copy.selfData.size/2*copy.selfData.reproductionVariations)
		selfData.view_distance=copy.selfData.view_distance + (copy.selfData.view_distance/2*copy.selfData.reproductionVariations)
		selfData.speed=copy.selfData.speed + (randi_range(-1,1) if randf()<copy.selfData.reproductionVariations else 0)
		selfData.fear=(copy.selfData.fear if randf()<copy.selfData.reproductionVariations else not copy.selfData.fear )
		selfData.fearFire=(copy.selfData.fearFire if randf()<copy.selfData.reproductionVariations else not copy.selfData.fearFire )
		selfData.reproductionVariations=copy.selfData.reproductionVariations
		selfData.metabolismSpeed=copy.selfData.metabolismSpeed
		selfData.carnivor=(copy.selfData.carnivor if randf()>copy.selfData.reproductionVariations else not copy.selfData.carnivor )
		selfData.ateOnce=false
		selfData.killed=false
		selfData.agressivity=copy.selfData.agressivity
		selfData.lookForEntityCooldown=0
		selfData.ticksSinceReproduced=0
		selfData.agentScene=ResourceLoader.load(selfData.appareancesArray[selfData.specie%selfData.appareancesArray.size()]).instantiate()
		var half_size = selfData.size/2
		selfData.agentScene.scale=Vector3(half_size,half_size,half_size)

	add_child(selfData.agentScene)
	
	true_agent = get_child(0) # L'agent qui se trouve a la fin du spring arm


func is_dead() -> bool:
	return ( is_nan(global_position.x) or # Agent qui bug
		selfData.killed or # Agent meurtri 
		world.tilesData[world.find_point_centersDict(selfData.currentPosition)].is_water() or # Agent qui se noie 
		selfData.age>selfData.maxAge or # Agent trop vieux 
		selfData.hunger>selfData.maxHunger) # Agent qui a trop faim
		
	
# Reproduction asexuee de l'agent
func reproduce() -> Agent:

	# Modifications sur le parent
	force_animation("Dance")
	selfData.ticksSinceReproduced=0

	# Creation du nouvel agent
	var new = Agent.new(selfData.world, selfData.currentPosition, selfData.specie, self)
	selfData.world.add_child(new)
	selfData.world.agents.append(new)

	return new
	
# Fonctions pour les distances ------
func distance_to_entity(entity : Entity) -> float:
	return entity.entityResource.position.distance_squared_to(self.true_agent.global_position)
	
func distance_to_point(vec : Vector3) -> float:
	return vec.distance_squared_to(self.true_agent.global_position)

func distance_to_agent(agent : Agent) -> float:
	return agent.true_agent.global_position.distance_squared_to(self.true_agent.global_position)
# ------


# Recherche d'une entitee a proximite
func get_nearest_entity_position():

	var nearest : Vector3 = selfData.currentPosition*10

	# Recherche de la position de l'entitee la plus proche
	for i in world.centersDictionary.keys():
		var ents = world.get_entities_on_tile(i)
		for j in ents :
			if ( ((not j.is_steak() and not selfData.carnivor) or (j.is_steak() and selfData.carnivor)) # Si ca correspond a son regime alimentaire
				and (nearest==selfData.currentPosition*10 or (j.entityResource!=null and distance_to_entity(j) < distance_to_point(nearest))) # Si c'est la premiere entitee trouvee ou si c'est la plus proche
				and distance_to_entity(j)<selfData.view_distance ) : # Si l'entite est dans la portee de l'agent
					nearest=i

	if nearest != selfData.currentPosition*10 :
		return nearest
	#else:
	return selfData.currentPosition

# Fonctions pour les animations
func force_animation(animationName : String) :
	true_agent.get_child(1).play(animationName)

func play_animation(animationName : String) :
	#"Bite_Front", "Dance", "Death", "HitRecieve", "Idle", "Jump", "No", "Walk", "Yes"
	true_agent.get_child(1).play(animationName)
	await true_agent.get_child(1).animation_finished

# L'agent mange une entite ou un autre agent
func eat(food):

	# Mise a jour des donnees de l'agent
	force_animation("Bite_Front")
	selfData.ateOnce=true
	selfData.feedingChildrensCooldown=20

	# Si l'agent mange un autre agent
	if food is Agent :
		if food.selfData.onFire :
			selfData.onFire=true
			selfData.speed*=2
		food.selfData.killed=true # Repercution sur l'autre agent
		selfData.hunger-=1000
	
	# Si l'agent mange de la nourriture
	if food is Entity : 
		if food.entityResource.isOnFire : 
			selfData.onFire=true
		selfData.hunger-=food.eat(world) # Repercution sur l'entite
		
# Retourne la position du centre de tile le plus proche		
func get_closest_center():
	if true_agent.global_position.distance_squared_to(selfData.currentPosition)<true_agent.global_position.distance_squared_to(selfData.currentPath[0]) :
		return selfData.currentPosition
	#else :
	return selfData.currentPath[0]

# Fonctions de rotation de l'agent ------

func rotate_towards_direction():
	var axis = true_agent.global_position.cross(selfData.currentPath[0])
	var angle = acos(global_position.dot(selfData.currentPath[0])/(global_position.length()*selfData.currentPath[0].length()))
	if axis != Vector3.ZERO and not is_nan(angle) : 
		global_position = rotate_around_axis(global_position,axis.normalized(), angle / (50*(10/selfData.speed) )  )
	
func rotate_around_axis(pos:Vector3, axis:Vector3, angle:float):
	var x = pos.x*(cos(angle)+axis.x*axis.x*(1-cos(angle)))+pos.y*(axis.x*axis.y*(1-cos(angle))-axis.z*sin(angle))+pos.z*(axis.x*axis.z*(1-cos(angle))+axis.y*sin(angle))
	var y = pos.x*(axis.y*axis.x*(1-cos(angle))+axis.z*sin(angle))+pos.y*(cos(angle)+axis.y*axis.y*(1-cos(angle)))+pos.z*(axis.y*axis.z*(1-cos(angle))-axis.x*sin(angle))
	var z = pos.x*(axis.z*axis.x*(1-cos(angle))-axis.y*sin(angle))+pos.y*(axis.z*axis.y*(1-cos(angle))+axis.x*sin(angle))+pos.z*(cos(angle)+axis.z*axis.z*(1-cos(angle)))
	look_at(global_position*2)
	return Vector3(x,y,z)

# ------ 


var hasToRun : bool = false
var closestAdult : Agent = null
var closestAdultHunger : int
var closestFoodPos : Vector3
var closestStranger : Agent = null
var orientCD : int = 30 # Cooldown pour l'orientation de l'agent

# Fonctions de deplacement de l'agent ------

func update_position():
	selfData.currentPosition=get_closest_center()

func take_random_direction():
	play_animation("Jump")	
	var neigs = world.centersNeighboursDictionary[selfData.currentPosition]
	neigs.shuffle()

	# Prend un voisin qui n'est pas de l'eau et qui n'a pas de danger (autres agents si l'agent a peur)
	for i in range(3): 
		var cur_case = world.tilesData[world.find_point_centersDict(neigs[i])]
		if not (cur_case.is_water()) and not (selfData.fear and closestStranger!=null and closestStranger.global_position.distance_squared_to(true_agent.global_position)>closestStranger.global_position.distance_squared_to(neigs[i])):
			selfData.currentPath=[neigs[i]]

# ------


func update():

	# Si l'agent a fini de tourner
	if orientCD<0:
		if true_agent.global_position != selfData.previousPos : 
			true_agent.look_at_from_position(true_agent.global_position,selfData.previousPos, true_agent.global_position )
		orientCD=20

	# Recherche de nourriture
	selfData.previousPos=true_agent.global_position
	if selfData.lookForEntityCooldown<0 and world.amountOfVegetation!=0  :
		closestFoodPos=get_nearest_entity_position()
		selfData.lookForEntityCooldown=100

	# Met a jour la reference vers l'agent de sa propre espece, et d'une espece etrangere le plus proche
	for otherAgent in selfData.world.agents : 
		if otherAgent!=self and selfData.carnivor:
			if not otherAgent.selfData.baby and distance_to_agent(otherAgent)<selfData.view_distance :
				if closestAdult==null or (selfData.world.speciesDictionary[otherAgent]==selfData.specie and distance_to_agent(otherAgent)<distance_to_agent(closestAdult)) : 
					closestAdult=otherAgent
				elif closestStranger==null or (distance_to_agent(otherAgent) < distance_to_agent(closestStranger)):
					closestStranger=otherAgent
	
	# Mise a jour des cooldowns, de l'age et de la faim
	orientCD-=1
	selfData.feedingChildrensCooldown-=1
	selfData.ticksSinceReproduced+=1*selfData.metabolismSpeed
	selfData.age+=1*selfData.metabolismSpeed

	selfData.hunger+=1*selfData.metabolismSpeed
	selfData.lookForEntityCooldown-=1*selfData.metabolismSpeed
	if selfData.baby and selfData.age > selfData.adultAge :
		true_agent.scale*=2
		selfData.baby=false
	
	
	auto_move()

# Arbre de decision de l'agent
func auto_move():

	play_animation("Walk")

	#Je retire de mon chemin les cases atteintes
	if selfData.currentPath[0] == selfData.currentPosition:
		selfData.currentPath.pop_front()
		#Si j'ai peur et que quelqu'un qui n'est pas de mon espèce est proche je fuis dans une direction aleatoire
		if selfData.fear and closestStranger!=null :
			take_random_direction()


		# Agent adulte
		if not selfData.baby:
			#si j'ai trop faim, je regarde si de la nouriture est proche de moi je la mange, sinon j'actualise mon chemin vers la nouriture la plus proche 
			if selfData.hunger>selfData.toleratedHunger :

				if not selfData.carnivor : # Regime vegetarien -> je regarde les entites non-steak

					# Je mange les entites proches
					var nearEntities=world.get_entities_on_tile(selfData.currentPosition)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if not pickedEntity.is_steak() :
								eat(pickedEntity)

					# S'il n'y a pas de nourriture aux alentours, je me dirige aleatoirement
					if closestFoodPos==selfData.currentPosition : 
						take_random_direction()
					else : 
						# Sinon, je me dirige vers la nouriture la plus proche
						selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestFoodPos))
						selfData.currentPath.pop_front()

				else: # Regime carnivore -> je regarde les entites steak ou autres agents

					var nearEntities=world.get_entities_on_tile(selfData.currentPosition)

					# Je mange les steaks a proximite
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if pickedEntity.is_steak() and pickedEntity.entityResource.steakOrigin!=selfData.specie :
								eat(pickedEntity)

					# Je mange les agents proches s'il n'y a pas de steaks aux alentours
					if closestFoodPos==selfData.currentPosition : 
						if closestStranger!=null:
							# Si l'agent est assez proche, je le mange
							if world.centersNeighboursDictionary[selfData.currentPosition].has(closestStranger.selfData.currentPosition) :
								eat(closestStranger)
							# Sinon, je me dirige vers lui
							else :  
								selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestStranger.selfData.currentPosition)) 
								selfData.currentPath.pop_front()
						
						# S'il n'y a pas d'agent proche, je me dirige aleatoirement
						else: 
							take_random_direction()

					# Sinon, je me dirige vers la nouriture la plus proche
					else : 
						selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestFoodPos))
						selfData.currentPath.pop_front()
			
			# Sinon reproduction si je le peux
			elif selfData.ticksSinceReproduced>70 and selfData.ateOnce :
				reproduce()
			# Sinon, je marche aleatoirement
			else : 
				take_random_direction()

		# Agent enfant
		else : 
			# S'il y a un adulte a proximite
			if closestAdult!=null :
				# Adulte qui nourrit l'enfant s'il le peut
				if closestAdult.selfData.feedingChildrensCooldown>0 : 
					selfData.hunger=0
				# Je me dirige vers l'adulte le plus proche
				selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestAdult.selfData.currentPosition)) 
				selfData.currentPath.pop_front()
			
			# S'il n'y a pas d'adulte a proximite, et que j'ai faim
			elif selfData.hunger>selfData.toleratedHunger :

				# Si je suis vegetarien
				if not selfData.carnivor :
					# Je mange les entites proches qui ne sont pas des steaks
					var nearEntities=world.get_entities_on_tile(selfData.currentPosition)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if not pickedEntity.is_steak():
								eat(pickedEntity)
					# S'il n'y a pas de nourriture aux alentours, je me dirige aleatoirement
					if closestFoodPos==selfData.currentPosition : 
						take_random_direction()
					# Sinon, je me dirige vers la nouriture la plus proche
					else : 
						selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestFoodPos))
						selfData.currentPath.pop_front()
				
				# Si je suis carnivore
				else:
					# Je mange les steaks a proximite
					var nearEntities=world.get_entities_on_tile(selfData.currentPosition)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if pickedEntity.is_steak() and pickedEntity.entityResource.steakOrigin!=selfData.specie :
								eat(pickedEntity)
					# S'il n'y a pas de nourriture aux alentours
					if closestFoodPos==selfData.currentPosition :
						# Je regarde l'agent d'une autre espece le plus proche
						if closestStranger!=null :
							# Si l'agent est assez proche, je le mange
							if world.centersNeighboursDictionary[selfData.currentPosition].has(closestStranger.selfData.currentPosition) :
								eat(closestStranger)
							# Sinon, je me dirige vers lui
							else :  
								selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestStranger.selfData.currentPosition)) 
								selfData.currentPath.pop_front()
						# S'il n'y a pas d'agent proche, je me dirige aleatoirement
						else: 
							take_random_direction()

					# Sinon, je me dirige vers la nouriture la plus proche
					else : 
						selfData.currentPath = world.myAstar.get_point_path(world.find_point_centersDict(selfData.currentPosition), world.find_point_centersDict(closestFoodPos))
						selfData.currentPath.pop_front()

			# Sinon, je me dirige aleatoirement
			else : 
				take_random_direction()

	# Pour eviter les bugs de pathfinding
	if selfData.currentPath.size()==0:
		selfData.currentPath=[selfData.currentPosition]
	
	# Je me deplace apres avoir decide de ce que je fais
	rotate_towards_direction()
	true_agent.get_child(true_agent.get_child_count()-1).global_position=selfData.currentPath[selfData.currentPath.size()-1]
	update_position()




# Pour le panel de stats
func toString():
	return(
	" Specie n°" + str(selfData.specie) + ("- Baby" if selfData.baby else "- Adult")+(" Carnivorous" if selfData.carnivor else " Herbivorous")
	
	+ "\n- Age : " + str(selfData.age)
	+ "\n- Max Age : " + str(selfData.maxAge)
	+ "\n- Adult Age : " + str(selfData.adultAge)
	+ "\n- Hunger : " + str(selfData.hunger)
	+ "\n- Looks for food at hunger : " + str(selfData.toleratedHunger)
	+ "\n- Max hunger : " + str(selfData.maxHunger)
	+ ("\n\n- Fear Others "+ ("& Fear Fire" if selfData.fearFire else "") if selfData.fear else ("\n- Fear Fire" if selfData.fearFire else "") )
	+ "\n- View distance : " + str(selfData.view_distance)
	+ "\n- Speed : " + str(selfData.speed)
	+ "\n- Genes variation rate : " + str(selfData.reproductionVariations)
	)
	
