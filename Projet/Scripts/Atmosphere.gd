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
	
func changer_temp():
	self.temperature = $"%WorldMesh".worldResource.amountOfTrees + (get_parent().agents.size() - $"%WorldMesh".worldResource.amountOfTrees/2)
	self.temperature = clamp(temperature,temp_min,temp_max)
	
func calculate_water():
	return 1.0 + temperature/50.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.changer_temp()
	Mat.set_shader_parameter("temperature",temperature)
	$"%WorldMesh".worldResource.waterHeight=calculate_water()
	print(temperature)
	pass
