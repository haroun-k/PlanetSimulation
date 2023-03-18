class_name Agent extends SpringArm3D

@export var selfData : AgentData

func spherical_to_cartesian(theta:float, phi:float, r:float):
	return Vector3(r*sin(theta)*cos(phi),r*sin(theta)*sin(phi),r*cos(theta))

@onready var worldNode=get_parent().get_node("WorldMesh")
@onready var world=worldNode.worldResource

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
	selfData.current_direction=world.centersNeighboursDictionary[selfData.current_position][randi_range(0,2)]

func go_to_random_position():
	rotate_towards_point(Vector3(randf(),randf(),randf()))
func auto_move():
	if selfData.current_direction == selfData.current_position:
		update_position()
		take_random_direction()
	rotate_towards_point(selfData.current_direction)
	get_child(0).get_child(0).global_position=selfData.current_direction
	update_position()
	
	
	
	
	
	
	
func _process(delta):
	auto_move()
	
func _ready():
	selfData = AgentData.new()
	var arr_mesh = ArrayMesh.new()
	
	var cube = BoxMesh.new()
	
	var agentMesh = MeshInstance3D.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cube.surface_get_arrays(0) )
	agentMesh.mesh=arr_mesh
	agentMesh.set_scale(Vector3(0.1, 0.1, 0.1))
	
	
	var directionMesh = MeshInstance3D.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cube.surface_get_arrays(0) )
	directionMesh.mesh=arr_mesh
	directionMesh.set_scale(Vector3(0.05, 0.05, 0.05))
	
	margin=0.05
	spring_length=200
	add_child(agentMesh)

	get_child(0).add_child(directionMesh)
	global_position=Vector3(0,0,2)
#	go_to_random_position()
	
	update_position()
	take_random_direction()
	
