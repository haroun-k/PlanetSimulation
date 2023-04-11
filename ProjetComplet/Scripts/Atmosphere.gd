extends MeshInstance3D
var temperature = 0
var temp_min = -50
var temp_max = 100
var agents
var entities
var Mat

var water_bias = 0
var temp_bias = 0

# Called when the node enters the scene tree for the first time.
func init_atmosphere():
#	pass # Replace with function body.
	self.temperature = -50
	Mat = self.get_active_material(0)
	Mat.set_shader_parameter("temp_max",temp_min)
	Mat.set_shader_parameter("temp_min",temp_max)
	self.agents = get_parent().agents
	self.entities = get_parent().get_node("WorldMesh").worldResource.entities
	
func changer_temp():
	self.temperature = $"%WorldMesh".worldResource.amountOfVegetation/ (1000.0/(agents.size()+1)   ) + (agents.size()/15. - $"%WorldMesh".worldResource.amountOfVegetation/3.)
	self.temperature = clamp(temperature/10+ temp_bias + snapped( (sin(Time.get_ticks_msec() / 1000.0) * 0.5), 0.1),temp_min,temp_max)

	
func calculate_water():
	return 1.96 + (self.temperature/15000.0) + water_bias

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_atmosphere():
	self.changer_temp()
	Mat.set_shader_parameter("temperature",temperature)
	$"%WorldMesh".worldResource.waterHeight=calculate_water()

func _process(delta):
	self.water_bias = $"%waterSlider".value / 1000.0	
	self.temp_bias = $"%tempSlider".value 
