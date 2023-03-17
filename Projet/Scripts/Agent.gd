class_name Agent extends SpringArm3D
@export var current_direction : Vector3
@export var current_position : Vector3

var world : Node3D
var agentMesh : MeshInstance3D
var directionMesh : MeshInstance3D

const COOLDOWN = 50
const AGE_MIN = 200
const AGE_MAX = 300

var cooldown_reproduction : int
var age : int

func spherical_to_cartesian(theta:float, phi:float, r:float):
	return Vector3(r*sin(theta)*cos(phi),r*sin(theta)*sin(phi),r*cos(theta))


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
	current_position=get_closest_center(agentMesh.global_position,world.centersDictionary.keys())
	
func take_random_direction():
	current_direction=world.centersNeighboursDictionary[current_position][randi_range(0,2)]

func go_to_random_position():
	rotate_towards_point(Vector3(randf(),randf(),randf()))
	
func auto_move():
	if current_direction == current_position:
		update_position()
		take_random_direction()
	rotate_towards_point(current_direction)
	directionMesh.global_position=global_position
	update_position()
	
func _init(world : Node3D):
	self.world = world
	
	randomize()
	self.cooldown_reproduction = COOLDOWN
	self.age = randi_range(AGE_MIN,AGE_MAX)
	
func update_stats():
	if self.cooldown_reproduction>0:
		self.cooldown_reproduction-=1
	if self.age>0:
		self.age-=1
		
func reproduire(other : Agent) -> Agent:
	self.cooldown_reproduction=COOLDOWN
	other.cooldown_reproduction=COOLDOWN
	var new = Agent.new(world)
	#new.set_pos(self.global_position)
	return new
		
func mourir() -> bool:
	return self.age==0
	
func set_pos(new_pos):
	self.global_position = new_pos
		
func update():
	auto_move()
	update_stats()
	
func _ready():
	
	agentMesh = MeshInstance3D.new()
	agentMesh.mesh = BoxMesh.new()
	agentMesh.set_scale(Vector3(0.1, 0.1, 0.1))
	
	directionMesh = MeshInstance3D.new()
	directionMesh.mesh=BoxMesh.new()
	directionMesh.set_scale(Vector3(0.05, 0.05, 0.05))

	
	margin=0.05
	spring_length=200
	#print("margin = ", margin, ", spring_length = ", spring_length)
	add_child(agentMesh)
	#print(get_child_count())
	agentMesh.add_child(directionMesh)
	global_position=Vector3(2,0,0)
#	go_to_random_position()
	
	update_position()
	take_random_direction()
	
