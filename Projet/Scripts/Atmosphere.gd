extends MeshInstance3D
var temperature = 0
var temp_min = -50
var temp_max = 100
var Mat

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	self.temperature = -50
	Mat = self.get_active_material(0)
	Mat.set_shader_parameter("temp_max",temp_min)
	Mat.set_shader_parameter("temp_min",temp_max)
	
func update_temperature():
	print("nbT : ",$"%WorldMesh".worldResource.amountOfTrees)
	print("nbA : ",(get_parent().agents.size()))
	print("--temp-- ", temperature)
	self.temperature = $"%WorldMesh".worldResource.amountOfTrees/ (   10./(get_parent().agents.size()+1)   ) + (get_parent().agents.size() - $"%WorldMesh".worldResource.amountOfTrees/2)
	self.temperature = clamp(temperature,temp_min,temp_max)
	
func calculate_water():
	print("WATER EHIGHT ---------------- ",1.0 + temperature/50.0)
	return 1.0 + temperature/50.0

func update_atmosphere():
	self.update_temperature()
	Mat.set_shader_parameter("temperature",temperature)
	$"%WorldMesh".worldResource.waterHeight=calculate_water()
	pass
