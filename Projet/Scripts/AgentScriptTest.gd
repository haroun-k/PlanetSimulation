class_name Agent extends SpringArm3D

@export var selfData : AgentData
@onready var worldNode=get_parent().get_node("WorldMesh")
@onready var world=worldNode.worldResource

const TR_types = TileResource.TERRAIN_TYPE
const COOLDOWN = 50
const AGE_MIN = 200
const AGE_MAX = 30000





func play_animation(animationName : String) :
#"Bite_Front", "Dance", "Death", "HitRecieve", "Idle", "Jump", "No", "Walk", "Yes"
	get_child(0).get_child(1).play(animationName)
	await get_child(0).get_child(1).animation_finished

#func get_closest_centerz(pos:Vector3, points:Array):
#	var closest_point = points[0]
#	var closest_distance = pos.distance_to(points[0])
#	for point in points:
#		if pos.distance_to(point)<closest_distance:
#			closest_point = point
#			closest_distance = pos.distance_to(point)
#	return closest_point

func get_closest_center():
#	print("__________________________________________________________")
#	print("position actuellement considérée : ", selfData.current_position)
#	print("Les voisins : ",  world.centersNeighboursDictionary[selfData.current_position])
	var neigs = world.centersNeighboursDictionary[selfData.current_position]
	var closest_point = selfData.current_position
	var closest_distance = get_child(0).global_position.distance_to(selfData.current_position)
	for i in range(neigs.size()):
		if  get_child(0).global_position.distance_to(neigs[i])<closest_distance:
			closest_point= neigs[i]
			closest_distance =  get_child(0).global_position.distance_to(neigs[i])
#	print("le plus proche : ", closest_point)
	return closest_point 
	
func rotate_towards_point():
	var axis = get_child(0).global_position.cross(selfData.current_direction)
	var angle = acos(global_position.dot(selfData.current_direction)/(global_position.length()*selfData.current_direction.length()))
	if axis != Vector3.ZERO and not is_nan(angle) : 
		global_position = rotate_around_axis(global_position,axis.normalized(),angle/400)
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
		if not (cur_case.terrainType in [TR_types.FIRE, TR_types.WATER]):
			
			
#			var axis = selfData.current_position.normalized()
#			var angle = acos(global_position.dot(selfData.current_direction)/(global_position.length()*selfData.current_direction.length()))
#			get_child(0).get_child(0).rotate_object_local(selfData.current_position.normalized(), randf())
			get_child(0).rotate_object_local(position.normalized(),randf())
#			get_child(0).rotate(global_position.normalized(), PI)
			
			selfData.current_direction=neigs[i]
			return true
	return false
	
	selfData.agentScene.look_at_from_position(selfData.current_position, selfData.current_direction)

func auto_move():
	play_animation("Walk")
	if selfData.current_direction == selfData.current_position:
		take_random_direction()
	rotate_towards_point()
	update_position()
	
	
	get_child(0).get_child(get_child(0).get_child_count()-1).global_position=selfData.current_direction

func reproduire(other : Agent) -> Agent:
	play_animation("Dance")
	selfData.cooldown_reproduction=COOLDOWN
	other.selfData.cooldown_reproduction=COOLDOWN
	var new = Agent.new(worldNode, selfData.current_position)
	return new
		

func is_dead() -> bool:	
	return (selfData.age<0 or world.tilesData[world.get_point_index(selfData.current_position)].terrainType==TileResource.TERRAIN_TYPE.FIRE)

func update_stats():
	if selfData.cooldown_reproduction>0:
		selfData.cooldown_reproduction-=1
	selfData.age-=1
	
func update():
	auto_move()
	update_stats()
	

func _init(world : Node3D, initialCenterPosition : Vector3):
	selfData = AgentData.new()
	selfData.current_position=initialCenterPosition
	selfData.current_direction = selfData.current_position
	selfData.world = world
	position=initialCenterPosition*10
	
	
	randomize()
	selfData.cooldown_reproduction = COOLDOWN
	selfData.age = randi_range(AGE_MIN,AGE_MAX)


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
	
