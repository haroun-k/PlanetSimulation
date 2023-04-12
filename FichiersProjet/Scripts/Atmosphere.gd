extends MeshInstance3D
var temperature = 0
var temp_min = -50
var temp_max = 50
var agents
var entities
var Mat

var water_bias = 0
var temp_bias = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	self.temperature = -50
	Mat = self.get_active_material(0)
	Mat.set_shader_parameter("temp_max",temp_min)
	Mat.set_shader_parameter("temp_min",temp_max)
	self.agents = get_parent().agents
	self.entities = get_parent().get_node("WorldMesh").worldResource.entities
	
func changer_temp():
	self.temperature = $"%WorldMesh".worldResource.amountOfTrees/ (10.0/(agents.size()+1)   ) + (agents.size() - $"%WorldMesh".worldResource.amountOfTrees/2)
	self.temperature = clamp(temperature,temp_min,temp_max) + temp_bias + snapped( (sin(Time.get_ticks_msec() / 1000.0) * 0.5), 0.1)

	
func calculate_water():
	return 1.96 + (self.temperature/1500.0) + water_bias

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update_atmosphere():
	self.changer_temp()
	Mat.set_shader_parameter("temperature",temperature)
	$"%WorldMesh".worldResource.waterHeight=calculate_water()
	pass

func _process(delta):
	self.water_bias = $"%water_slider".value / 1000.0
	self.temp_bias = $"%temp_slider".value 
