
extends SpringArm3D
@export var current_direction : Vector3
@export var current_position : Vector3

func spherical_to_cartesian(theta:float, phi:float, r:float):
	return Vector3(r*sin(theta)*cos(phi),r*sin(theta)*sin(phi),r*cos(theta))

@onready var world=get_parent().get_node("WorldMesh")


func get_closest_center(pos:Vector3, points:Array):
	var closest_point = points[0]
	var closest_distance = pos.distance_to(points[0])
	for point in points:
		if pos.distance_to(point)<closest_distance:
			closest_point = point
			closest_distance = pos.distance_to(point)
	return closest_point

func action():
	var tab = world.centersDictionary.keys()
	var pooo = get_closest_center($MeshInstance3D.global_position,tab)
	
#
#func from_spherical_to_cartesian(vec : Vector3):
#	var r=vec.x*sin(vec.z)
#	var x = sin(vec.y)*r
#	var y = vec.x*sin(vec.z)
#	var z = cos(vec.y)*r
#	return Vector3(z,y,x)
#
#func from_cartesian_to_spherical(pos:Vector3):
#	var rho = sqrt(pos.z**2+(sqrt(pos.z**2+pos.x**2)))
#	var theta = fposmod( atan2(pos.x,pos.z)+2*PI,2*PI)
#	var phi = fposmod( atan2(pos.y,pos.z)+2*PI,2*PI)
#	return Vector3(5,theta,phi)

func from_spherical_to_cartesian(vec:Vector3):
	var r=vec.x
	var theta=vec.y
	var phi=vec.z
	return Vector3(r*sin(theta)*cos(phi),r*sin(theta)*sin(phi),r*cos(theta))
func from_cartesian_to_spherical(pos:Vector3):
	var r = pos.length()
	var theta = acos(pos.z/r)
	var phi = atan2(pos.y,pos.x)
	return Vector3(r,theta,phi)

func rotate_around_x_axis(pos:Vector3, angle:float):
	var x = pos.x
	var y = pos.y*cos(angle)-pos.z*sin(angle)
	var z = pos.y*sin(angle)+pos.z*cos(angle)
	look_at(global_position*2)
	return Vector3(x,y,z)
func rotate_around_y_axis(pos:Vector3, angle:float):
	var x = pos.x*cos(angle)+pos.z*sin(angle)
	var y = pos.y
	var z = -pos.x*sin(angle)+pos.z*cos(angle)
	look_at(global_position*2)
	return Vector3(x,y,z)
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


func movement():
	var tran3D = Transform3D(Vector3.RIGHT,Vector3.UP,Vector3.BACK,Vector3.ZERO)
	var sphereCoo=from_cartesian_to_spherical(global_position)
	if Input.is_action_pressed("up") :
		rotate_towards_point(Vector3(0,2,0))
	if Input.is_action_pressed("right") :
		global_position=rotate_around_y_axis(global_position,0.05)
		
		
	if Input.is_action_pressed("down") :
		global_position=rotate_around_x_axis(global_position,-0.05)
	if Input.is_action_pressed("left") :
		global_position=rotate_around_y_axis(global_position,-0.05)

func update_position():
	current_position=get_closest_center($MeshInstance3D.global_position,world.centersDictionary.keys())
func take_random_direction():
	current_direction=world.centersNeighboursDictionary[current_position][randi_range(0,2)]
	
func auto_move():
	if current_direction == current_position:
		update_position()
		take_random_direction()
	rotate_towards_point(current_direction)
	$MeshInstance3D/directionMesh.global_position=current_direction
	update_position()
	
func _process(delta):
	movement()
	auto_move()
	
func _ready():
	update_position()
	take_random_direction()
#	rotate_towards_point(current_direction)
	
