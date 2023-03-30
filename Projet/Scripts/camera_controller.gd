extends Node3D

@export var target : MeshInstance3D

func _ready():
	set_captured(true)


func _process(delta) :
	if ready :
		position = position.lerp(target.position, delta*40);
	if Input.is_action_pressed("up") :
		translate_object_local(Vector3(0,0,-0.01))
	if Input.is_action_pressed("down") :
		translate_object_local(Vector3(0,0,0.01))
	if Input.is_action_pressed("left") :
		translate_object_local(Vector3(-0.01,0,0))
	if Input.is_action_pressed("right") :
		translate_object_local(Vector3(0.01,0,0))
	if Input.is_action_just_pressed("esc") :
		set_captured(!get_captured())

var captured : bool
	
func get_captured():
	return captured
	
func set_captured(value:bool):
		captured = value;
		if (captured) :Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else : Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event):
	if (event is InputEventMouseMotion) :
		var mouse_event = event as InputEventMouseMotion
		rotate_y(-mouse_event.relative.x/1000.)
		rotate(transform.basis.x, -mouse_event.relative.y/1000.)
