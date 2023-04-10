extends Label

var nb_fps : int
var nb_agents : int
var planete
# Called when the node enters the scene tree for the first time.
func _ready():
	nb_fps = 0
	nb_agents = 0
	planete = get_node("../../../../../.")
	set_text("")
	self.add_theme_color_override("font_color", Color(1,1,255,1))

func _process(_delta):
	nb_fps = Performance.get_monitor(Performance.TIME_FPS)
	nb_agents = planete.agents.size()
	
	var texte_agent = "Aucun"
	if planete.target != null :
		texte_agent = planete.target.toString()
		set_text("Agent Focused : " + texte_agent)
	else :
		set_text("FPS: " + str(nb_fps)
		+ "\n\nAgents: " + str(nb_agents)
		+ "\nPlants: " + str(planete.icosphere.worldResource.amountOfVegetation)
		+ "\n\nTemperature : " + str(round($"%Atmosphere".temperature)) + "°"
		+ "\nWater Height : " + str(int($"%Atmosphere".calculate_water() * 100)) + "m"
		)
