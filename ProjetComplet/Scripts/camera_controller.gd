extends Node3D

@export var target : Node3D
@export var initialTarget : Node3D
@export var speed : float
var offset := Vector3.ZERO

@onready var initialOffset := global_position-target.global_position

var mouse_buttons := [false, false, false] # L R M

func _unhandled_input(event):
	if (event is InputEventMouseButton ) :
		var mouse_button = event as InputEventMouseButton
		if mouse_button.button_index-1 in range(3) :
			mouse_buttons[mouse_button.button_index-1] = mouse_button.is_pressed()
	update(event)

func _process(delta) :
	if target==null : 
		target = initialTarget
		offset=initialOffset
	get_parent().position=target.global_position
	position = position.move_toward(offset, delta*30);


func update(event) :
	if (event is InputEventMouseButton ) :
		var mouse_button = event as InputEventMouseButton
		offset.z -= ((0.2 if mouse_button.button_index==4 else 0.) + (-0.2 if mouse_button.button_index==5 else 0.))
		offset.z = max(offset.z, 0)
		
		if mouse_buttons[2] :
			position=Vector3(0.1,0.1,0.1)
		
	if (event is InputEventMouseMotion) :
		var mouse_motion = event as InputEventMouseMotion
		if abs(mouse_motion.relative.x)>200 or abs(mouse_motion.relative.y)>200 : return
	
		if mouse_buttons[1] :
			get_parent_node_3d().rotate(global_transform.basis.y,-3*event.relative.x/1000.)
			get_parent_node_3d().rotate(global_transform.basis.x, -3*event.relative.y/1000.)
			
		if mouse_buttons[0] :
			rotate(transform.basis.x.normalized(), -3*event.relative.y/1000.)
			rotate(transform.basis.y.normalized(),-3*event.relative.x/1000.)
			

func _ready():
	offset=initialOffset
	initialTarget=target


