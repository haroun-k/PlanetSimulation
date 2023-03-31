extends Label

var nb_fps : int
var nb_agents : int
var planete
# Called when the node enters the scene tree for the first time.
func _ready():
	
	nb_fps = 0
	nb_agents = 0
	planete = get_parent()
	set_text("")
	self.add_theme_color_override("font_color", Color(1,1,255,1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	nb_fps = Performance.get_monitor(Performance.TIME_FPS)
	nb_agents = planete.agents.size()
	
	set_text("FPS: " + str(nb_fps) + " \nAgents: " + str(nb_agents))
