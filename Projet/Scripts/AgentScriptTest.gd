class_name Agent extends SpringArm3D

@export var selfData : AgentData
@onready var worldNode=get_parent().get_node("WorldMesh")
@onready var world=worldNode.worldResource

const TR_types = TileResource.TERRAIN_TYPE
const COOLDOWN = 50
const AGE_MIN = 200
const AGE_MAX = 300




func get_closest_center(pos:Vector3, points:Array):
	var closest_point = points[0]
	var closest_distance = pos.distance_to(points[0])
	for point in points:
		if pos.distance_to(point)<closest_distance:
			closest_point = point
			closest_distance = pos.distance_to(point)
	return closest_point

func rotate_towards_point(destination:Vector3):
	var axis = global_position.cross(destination)
	var angle = acos(global_position.dot(destination)/(global_position.length()*destination.length()))
	global_position = rotate_around_axis(global_position,axis.normalized(),angle/10)
	look_at(global_position*2)
	
func rotate_around_axis(pos:Vector3, axis:Vector3, angle:float):
	var x = pos.x*(cos(angle)+axis.x*axis.x*(1-cos(angle)))+pos.y*(axis.x*axis.y*(1-cos(angle))-axis.z*sin(angle))+pos.z*(axis.x*axis.z*(1-cos(angle))+axis.y*sin(angle))
	var y = pos.x*(axis.y*axis.x*(1-cos(angle))+axis.z*sin(angle))+pos.y*(cos(angle)+axis.y*axis.y*(1-cos(angle)))+pos.z*(axis.y*axis.z*(1-cos(angle))-axis.x*sin(angle))
	var z = pos.x*(axis.z*axis.x*(1-cos(angle))-axis.y*sin(angle))+pos.y*(axis.z*axis.y*(1-cos(angle))+axis.x*sin(angle))+pos.z*(cos(angle)+axis.z*axis.z*(1-cos(angle)))
	look_at(global_position*2)
	return Vector3(x,y,z)

func update_position():
	selfData.current_position=get_closest_center(get_child(0).global_position,world.centersDictionary.keys())
	
func take_random_direction():
	var neigs = world.centersNeighboursDictionary[selfData.current_position]

	neigs.shuffle()
	for i in range(3):
		var cur_case = world.tilesData[world.get_point_index(neigs[i])]
		if not (cur_case.terrainType in [TR_types.FIRE, TR_types.WATER]):
			selfData.current_direction=neigs[i]
			return true
	return false

func go_to_random_position():
	rotate_towards_point(Vector3(randf(),randf(),randf()))
	
func auto_move():
	if selfData.current_direction == selfData.current_position:
		update_position()
		if not take_random_direction() :
			return
	rotate_towards_point(selfData.current_direction)
	get_child(0).get_child(0).global_position=selfData.current_direction
	update_position()

func reproduire(other : Agent) -> Agent:
	selfData.cooldown_reproduction=COOLDOWN
	other.selfData.cooldown_reproduction=COOLDOWN
	var new = Agent.new(worldNode)
	#new.set_pos(self.global_position)
	return new
		

func is_dead() -> bool:
	return (selfData.age<0 or world.tilesData[world.get_point_index(selfData.current_position)].terrainType==TileResource.TERRAIN_TYPE.FIRE)
	
func set_pos(new_pos):
	selfData.global_position = new_pos
		
func update_stats():
	if selfData.cooldown_reproduction>0:
		selfData.cooldown_reproduction-=1
	if selfData.age>0:
		selfData.age-=5

func update():
	auto_move()
	update_stats()
	


func _init(world : Node3D):
	selfData = AgentData.new()
	selfData.world = world
	
	randomize()
	selfData.cooldown_reproduction = COOLDOWN
	selfData.age = randi_range(AGE_MIN,AGE_MAX)

func _ready():
	selfData.agentMesh = MeshInstance3D.new()
	selfData.agentMesh.mesh = BoxMesh.new()
	selfData.agentMesh.set_scale(Vector3(0.1, 0.1, 0.1))
	
	selfData.directionMesh = MeshInstance3D.new()
	selfData.directionMesh.mesh=BoxMesh.new()
	selfData.directionMesh.set_scale(Vector3(0.05, 0.05, 0.05))

	
	margin=0.05
	spring_length=200
	add_child(selfData.agentMesh)

	get_child(0).add_child(selfData.directionMesh)
	global_position=Vector3(0,0,2)
#	go_to_random_position()
	
	update_position()
	take_random_direction()
	
