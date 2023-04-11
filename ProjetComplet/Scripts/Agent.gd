class_name Agent extends SpringArm3D

@export var selfData : AgentData
@onready var worldNode=get_parent().get_node("WorldMesh")
@onready var world: WorldResource = worldNode.worldResource
@onready var atmosphere = get_parent().get_node("Atmosphere")
const TR_types = TileResource.TERRAIN_TYPE

func is_dead() -> bool:
	return ( selfData.killed  or (selfData.age>selfData.maxAge or selfData.hunger>selfData.maxHunger or world.tilesData[world.get_point_index_ordered(selfData.current_position)].terrainType==TileResource.TERRAIN_TYPE.WATER) )
	
func reproduce() -> Agent:
	force_animation("Dance")
	selfData.ticksSinceReproduced=0
	var new = Agent.new(selfData.world, selfData.current_position, selfData.specie, self)
	selfData.world.add_child(new)
	selfData.world.agents.append(new)
	return new
	
func get_nearest_entity_position():
	var nearest : Vector3 =selfData.current_position*10
	for i in world.centersDictionary.keys():
		var ents = world.get_entities_on_tile(i)
		if ents.size()!=0 : 
			for j in ents :
#				if j!=null : 
				if ((j.entityResource.entityType!=EntityResource.ENTITY_TYPE.STEAK and selfData.carnivor==false) or (j.entityResource.entityType==EntityResource.ENTITY_TYPE.STEAK and selfData.carnivor==true)) and (nearest==selfData.current_position*10 or ( j.entityResource!=null and j.entityResource.position.distance_squared_to(get_child(0).global_position)<nearest.distance_squared_to(get_child(0).global_position) ) ) and j.entityResource.position.distance_squared_to(get_child(0).global_position)<selfData.view_distance :
					nearest=i
	var res = nearest if nearest !=selfData.current_position*10 else selfData.current_position
	return res

func force_animation(animationName : String) :
	get_child(0).get_child(1).play(animationName)
func play_animation(animationName : String) :
#"Bite_Front", "Dance", "Death", "HitRecieve", "Idle", "Jump", "No", "Walk", "Yes"
	get_child(0).get_child(1).play(animationName)
	await get_child(0).get_child(1).animation_finished

func eat(food):
	force_animation("Bite_Front")
	selfData.ateOnce=true
	selfData.feedingChildrensCooldown=20
	if food is Agent :
		if food.selfData.onFire :
			selfData.onFire=true
			selfData.speed*=2
		food.selfData.killed=true
		selfData.hunger-=1000
	if food is Entity : 
		if food.entityResource.isOnFire : 
			selfData.onFire=true
		selfData.hunger-=food.eat(world)
		
func get_closest_center():
	return selfData.current_position if get_child(0).global_position.distance_squared_to(selfData.current_position)<get_child(0).global_position.distance_squared_to(selfData.current_path[0]) else selfData.current_path[0]

func rotate_towards_direction():
	var axis = get_child(0).global_position.cross(selfData.current_path[0])
	var angle = acos(global_position.dot(selfData.current_path[0])/(global_position.length()*selfData.current_path[0].length()))
	if axis != Vector3.ZERO and not is_nan(angle) : 
		global_position = rotate_around_axis(global_position,axis.normalized(), angle / (50*(10/selfData.speed) )  )
	
	
	if get_child(0).global_position != selfData.previousPos : get_child(0).look_at_from_position(get_child(0).global_position,selfData.previousPos, get_child(0).global_position )


func rotate_around_axis(pos:Vector3, axis:Vector3, angle:float):
	var x = pos.x*(cos(angle)+axis.x*axis.x*(1-cos(angle)))+pos.y*(axis.x*axis.y*(1-cos(angle))-axis.z*sin(angle))+pos.z*(axis.x*axis.z*(1-cos(angle))+axis.y*sin(angle))
	var y = pos.x*(axis.y*axis.x*(1-cos(angle))+axis.z*sin(angle))+pos.y*(cos(angle)+axis.y*axis.y*(1-cos(angle)))+pos.z*(axis.y*axis.z*(1-cos(angle))-axis.x*sin(angle))
	var z = pos.x*(axis.z*axis.x*(1-cos(angle))-axis.y*sin(angle))+pos.y*(axis.z*axis.y*(1-cos(angle))+axis.x*sin(angle))+pos.z*(cos(angle)+axis.z*axis.z*(1-cos(angle)))
	look_at(global_position*2)
	return Vector3(x,y,z)


func update_position():
	selfData.current_position=get_closest_center()

func take_random_direction():
	play_animation("Jump")	
	var neigs = world.centersNeighboursDictionary[selfData.current_position]
	neigs.shuffle()
	for i in range(3):
		var cur_case = world.tilesData[world.get_point_index_ordered(neigs[i])]
		if not (cur_case.terrainType==TR_types.WATER) and not (selfData.fear and closestStranger!=null and closestStranger.global_position.distance_squared_to(get_child(0).global_position)>closestStranger.global_position.distance_squared_to(neigs[i])):
			selfData.current_path=[neigs[i]]



var hasToRun : bool = false
var closestAdult : Agent = null
var closestAdultHunger : int
var closestFoodPos : Vector3
var closestStranger : Agent =  null



func update():
	selfData.previousPos=get_child(0).global_position
	if selfData.lookForEntityCooldown<0 and world.amountOfVegetation!=0  :
		closestFoodPos=get_nearest_entity_position()
		selfData.lookForEntityCooldown=100

	for otherAgent in selfData.world.agents : 
		if otherAgent!=self and selfData.carnivor:
			if not otherAgent.selfData.baby and otherAgent.get_child(0).global_position.distance_squared_to(get_child(0).global_position)<selfData.view_distance :
				if closestAdult==null or (selfData.world.speciesDictionary[otherAgent]==selfData.specie and otherAgent.get_child(0).global_position.distance_squared_to(get_child(0).global_position)<closestAdult.global_position.distance_squared_to(get_child(0).global_position)) : 
					closestAdult=otherAgent
				elif closestStranger==null or(otherAgent.get_child(0).global_position.distance_squared_to(get_child(0).global_position)<closestStranger.global_position.distance_squared_to(get_child(0).global_position)):
					closestStranger=otherAgent
	
	selfData.feedingChildrensCooldown-=1
	selfData.ticksSinceReproduced+=1*selfData.metabolismSpeed
	selfData.age+=1*selfData.metabolismSpeed

	selfData.hunger+=1*selfData.metabolismSpeed
	selfData.lookForEntityCooldown-=1*selfData.metabolismSpeed
	if selfData.baby and selfData.age > selfData.adultAge :
		get_child(0).scale*=2
		selfData.baby=false
	
	
	auto_move_ea()


func auto_move_ea():
	play_animation("Walk")
	#je retire de mon chemin les cases atteintes
	if selfData.current_path[0] == selfData.current_position:
		selfData.current_path.pop_front()
		#si j'ai peur et que quelqu'un qui n'est pas de mon espèce est proche je fuis dans une direction aléatoire
		if selfData.fear and closestStranger!=null :
			take_random_direction()


		if not selfData.baby:
			#si j'ai trop faim, je regardes si de la nouriture est proche de moi je la mange, sinon j'actualise mon chemin vers la nouriture la plus proche 
			if selfData.hunger>selfData.toleratedHunger :
				if not selfData.carnivor :
					var nearEntities=world.get_entities_on_tile(selfData.current_position)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if pickedEntity.entityResource.entityType!=EntityResource.ENTITY_TYPE.STEAK and selfData.hunger>selfData.toleratedHunger:
								eat(pickedEntity)
					if closestFoodPos==selfData.current_position : take_random_direction()
					else : 
						selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestFoodPos))
						selfData.current_path.pop_front()
				else:
					var nearEntities=world.get_entities_on_tile(selfData.current_position)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if pickedEntity.entityResource.entityType==EntityResource.ENTITY_TYPE.STEAK and pickedEntity.entityResource.steakOrigin!=selfData.specie  and selfData.hunger>selfData.toleratedHunger:
								eat(pickedEntity)
					if closestFoodPos==selfData.current_position : 
						if closestStranger!=null and world.centersNeighboursDictionary[selfData.current_position].has(closestStranger.selfData.current_position) :
							eat(closestStranger)
						elif closestStranger!=null  :  
							selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestStranger.selfData.current_position)) 
							selfData.current_path.pop_front()
						else: take_random_direction()
					else : 
						selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestFoodPos))
						selfData.current_path.pop_front()
			elif selfData.ticksSinceReproduced>70 and selfData.ateOnce :
				reproduce()
			else : take_random_direction()
		else : 
			if closestAdult!=null : 
				if closestAdult.selfData.feedingChildrensCooldown>0 : selfData.hunger=0
				selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestAdult.selfData.current_position)) 
				selfData.current_path.pop_front()
				
			elif selfData.hunger>selfData.toleratedHunger :
				if not selfData.carnivor :
					var nearEntities=world.get_entities_on_tile(selfData.current_position)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if pickedEntity.entityResource.entityType!=EntityResource.ENTITY_TYPE.STEAK and selfData.hunger>selfData.toleratedHunger:
								eat(pickedEntity)
					if closestFoodPos==selfData.current_position : take_random_direction()
					else : 
						selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestFoodPos))
						selfData.current_path.pop_front()
				else:
					var nearEntities=world.get_entities_on_tile(selfData.current_position)
					if nearEntities.size()!=0: 
						for pickedEntity in nearEntities :
							if pickedEntity.entityResource.entityType==EntityResource.ENTITY_TYPE.STEAK and pickedEntity.entityResource.steakOrigin!=selfData.specie  and selfData.hunger>selfData.toleratedHunger:
								eat(pickedEntity)
					if closestFoodPos==selfData.current_position : 
						if closestStranger!=null and world.centersNeighboursDictionary[selfData.current_position].has(closestStranger.selfData.current_position) :
							eat(closestStranger)
						elif closestStranger!=null  :  
							selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestStranger.selfData.current_position)) 
							selfData.current_path.pop_front()
						else: take_random_direction()
					else : 
						selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(closestFoodPos))
						selfData.current_path.pop_front()
			else : take_random_direction()

	if selfData.current_path.size()==0:
#		print("je met un point sur moi meme pour eviter des bugs")
		selfData.current_path=[selfData.current_position]
	rotate_towards_direction()
	get_child(0).get_child(get_child(0).get_child_count()-1).global_position=selfData.current_path[selfData.current_path.size()-1]
	update_position()



func _init(wrld : Node3D, initialCenterPosition : Vector3, specieNumber : int, copy : Agent=null):
	
	selfData = AgentData.new()
	selfData.current_position=initialCenterPosition
	selfData.current_path.push_back(selfData.current_position)
	selfData.world = wrld
	position=initialCenterPosition*10
	wrld.speciesDictionary[self]=specieNumber
	selfData.appareancesArray = paths_to_objs_array("res://Objects/glTF/")
	selfData.specie = specieNumber
	if copy==null : selfData.randomize_genes()
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
		selfData.agentScene.scale=Vector3(selfData.size/2,selfData.size/2,selfData.size/2)
	add_child(selfData.agentScene)
	
	


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

func _ready():
	selfData.agentScene.rotate(Vector3(1,0,0),-90)
	
	selfData.directionMesh = MeshInstance3D.new()
	selfData.directionMesh.mesh=BoxMesh.new()
	selfData.directionMesh.set_scale(Vector3(0.5, 1, 0.5))
	margin=0.03
	spring_length=3000
	get_child(0).add_child(selfData.directionMesh)
	look_at(global_position*2)
	
	update_position()
	take_random_direction()




func toString():
	return(
	" Specie n°" + str(selfData.specie)	+ ("- Baby" if selfData.baby else "- Adult")+(" Carnivorous" if selfData.carnivor else " Herbivorous")
	+ "\n- Age : " + str(selfData.age)
	+ "\n- Max Age : " + str(selfData.maxAge)
	+ "\n- Adult Age : " + str(selfData.adultAge)
	+ "\n- Hunger : " + str(selfData.hunger)
	+ "\n- Looks for food at hunger : " + str(selfData.toleratedHunger)
	+ "\n- maxHunger : " + str(selfData.maxHunger)
	+ ("\n\n- Fear Others "+ ("& Fear Fire" if selfData.fearFire else "") if selfData.fear else ("\n- Fear Fire" if selfData.fearFire else "") )
	+ "\n- view_distance : " + str(selfData.view_distance)
	+ "\n- speed : " + str(selfData.speed)
	+ "\n- genes variation rate : " + str(selfData.reproductionVariations)
	)
	
