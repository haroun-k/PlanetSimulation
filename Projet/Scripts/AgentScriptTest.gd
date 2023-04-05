class_name Agent extends SpringArm3D

@export var selfData : AgentData
@onready var worldNode=get_parent().get_node("WorldMesh")
@onready var world: WorldResource = worldNode.worldResource
@onready var atmosphere = get_parent().get_node("Atmosphere")
const TR_types = TileResource.TERRAIN_TYPE


func reproduire(other : Agent) -> Agent:
	play_animation("Dance")
	selfData.ticksSinceReproduced=0
	other.selfData.ticksSinceReproduced=0
	var new = Agent.new(worldNode, selfData.current_position, selfData.specie)
	return new

func play_animation(animationName : String) :
#"Bite_Front", "Dance", "Death", "HitRecieve", "Idle", "Jump", "No", "Walk", "Yes"
	get_child(0).get_child(1).play(animationName)
	await get_child(0).get_child(1).animation_finished

		
func get_nearest_entity_position():
	var nearest : Vector3 =selfData.current_position*10
	for i in world.centersDictionary.keys():
		var ents = world.get_entities_on_tile(i)
		if ents.size()!=0 : 
			for j in ents :
#				if j!=null : 
				if (nearest==selfData.current_position*10 or ( j.entityResource!=null and j.entityResource.position.distance_squared_to(get_child(0).global_position)<nearest.distance_squared_to(get_child(0).global_position) )) and j.entityResource.position.distance_squared_to(get_child(0).global_position)<selfData.view_distance :
					nearest=i
	return nearest if nearest !=selfData.current_position*10 else selfData.current_position

func get_nearest_agent():
	var nearest = self
	for ag in  $"Planet".agents :
		if (nearest==self or (ag.position.distance_squared_to(get_child(0).global_position)<nearest.distance_squared_to(get_child(0).global_position) )) and ag.position.distance_squared_to(get_child(0).global_position)<selfData.view_distance :
			nearest=ag
	return nearest if nearest !=selfData.current_position*10 else selfData.current_position
	
	
func eat(food):
	if food is Agent : 
		pass
	if food is Entity : 
		if food.eat() :
			world.amountOfTrees-=1
		selfData.hunger-=225
		
func get_closest_center():
	return selfData.current_position if get_child(0).global_position.distance_squared_to(selfData.current_position)<get_child(0).global_position.distance_squared_to(selfData.current_path[0]) else selfData.current_path[0]

func rotate_towards_direction():
	
	var axis = get_child(0).global_position.cross(selfData.current_path[0])
	var angle = acos(global_position.dot(selfData.current_path[0])/(global_position.length()*selfData.current_path[0].length()))
	if axis != Vector3.ZERO and not is_nan(angle) : 
		global_position = rotate_around_axis(global_position,axis.normalized(),angle/70)
#	transform.rotated(axis.normalized(),angle/100)


func rotate_around_axis(pos:Vector3, axis:Vector3, angle:float):
	var x = pos.x*(cos(angle)+axis.x*axis.x*(1-cos(angle)))+pos.y*(axis.x*axis.y*(1-cos(angle))-axis.z*sin(angle))+pos.z*(axis.x*axis.z*(1-cos(angle))+axis.y*sin(angle))
	var y = pos.x*(axis.y*axis.x*(1-cos(angle))+axis.z*sin(angle))+pos.y*(cos(angle)+axis.y*axis.y*(1-cos(angle)))+pos.z*(axis.y*axis.z*(1-cos(angle))-axis.x*sin(angle))
	var z = pos.x*(axis.z*axis.x*(1-cos(angle))-axis.y*sin(angle))+pos.y*(axis.z*axis.y*(1-cos(angle))+axis.x*sin(angle))+pos.z*(cos(angle)+axis.z*axis.z*(1-cos(angle)))
	look_at(global_position*2)
	return Vector3(x,y,z)


func update_position():
	selfData.current_position=get_closest_center()

func take_random_direction():
	var neigs = world.centersNeighboursDictionary[selfData.current_position]
	neigs.shuffle()
	for i in range(3):
		var cur_case = world.tilesData[world.get_point_index_ordered(neigs[i])]
		if not (cur_case.terrainType==TR_types.WATER):
			selfData.current_path=[neigs[i]]


func auto_move_ea():
	play_animation("Walk")
	if selfData.current_path[0] == selfData.current_position:
		selfData.current_path.pop_front()
		if selfData.current_path.size()==0:
			if selfData.hunger>500 and selfData.lookForEntityCooldown>200 and world.amountOfTrees!=0 : 
				var nearEntities=world.get_entities_on_tile(selfData.current_position)
				if nearEntities.size()!=0: eat(nearEntities.pick_random())
				selfData.current_path = world.myAstar.get_point_path(world.get_point_index_ordered(selfData.current_position), world.get_point_index_ordered(get_nearest_entity_position()))
				selfData.lookForEntityCooldown=0
			if selfData.current_path.size()==0 : 
				take_random_direction()
		get_child(0).rotate_object_local(transform.basis.y.normalized(), randf() ) #acos(get_rotation().dot(selfData.current_path[0])/(get_rotation().length()*selfData.current_path[0].length()))
	if selfData.current_path.size()==0:
		selfData.current_path=[selfData.current_position]
	rotate_towards_direction()
	get_child(0).get_child(get_child(0).get_child_count()-1).global_position=selfData.current_path[selfData.current_path.size()-1]
	update_position()


func is_dead() -> bool:	
	return (selfData.age>2000000 or world.tilesData[world.get_point_index_ordered(selfData.current_position)].terrainType==TileResource.TERRAIN_TYPE.WATER)

func update_stats():
	selfData.ticksSinceReproduced+=1
	selfData.age+=1
	selfData.hunger+=1
	selfData.lookForEntityCooldown+=1
	
func update():
	auto_move_ea()
	update_stats()
	

func _init(world : Node3D, initialCenterPosition : Vector3, specieNumber : int):
	selfData = AgentData.new()
	selfData.current_position=initialCenterPosition
	selfData.current_path.push_back(selfData.current_position)
	selfData.world = world
	position=initialCenterPosition*10
	
	selfData.view_distance = 0.5
	selfData.specie = specieNumber
	randomize()
	selfData.ticksSinceReproduced = 0
	selfData.age = 0


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
	
	var appareancesPathArray = paths_to_objs_array("res://Objects/glTF/")
	selfData.agentScene=ResourceLoader.load(appareancesPathArray.pick_random()).instantiate()
	selfData.agentScene.scale=Vector3(0.05, 0.05, 0.05)
	selfData.agentScene.rotate(Vector3(1,0,0),-90)
	
	selfData.directionMesh = MeshInstance3D.new()
	selfData.directionMesh.mesh=BoxMesh.new()
	selfData.directionMesh.set_scale(Vector3(0.5, 1, 0.5))

	
	margin=0.03
	spring_length=3000
	add_child(selfData.agentScene)

	get_child(0).add_child(selfData.directionMesh)
	look_at(global_position*2)
	
	update_position()
	take_random_direction()
	
