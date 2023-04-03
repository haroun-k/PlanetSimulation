extends MeshInstance3D
var temperature = 0
var temp_min = -50
var temp_max = 50
var Mat

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	self.temperature = -50
	Mat = self.get_active_material(0)
	Mat.set_shader_parameter("temp_max",temp_min)
	Mat.set_shader_parameter("temp_min",temp_max)
	
func rechauffer():
	self.temperature+=0.01
	self.temperature = max(self.temp_min,min(self.temperature, self.temp_max))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	Mat.set_shader_parameter("temperature",temperature)
	pass
