extends Label

var nb_fps : int
var nb_agents : int
var planete

# Fonction appelé automatiquement quand le noeud racine est instancié dans la scène pour la première fois.
func _ready():
	# stock la référence vers le noeud racine
	planete = get_node("../../../../../.")

# Fonction appellé à chaque frame. 'delta' est le temps s'étant écoulé depuis la dernière frame.
# Elle met à jour le texte affiché dans le panneau des stats dans la simulation en récupérant les valeurs dans chaque noeud.
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
		+ "\nWater Height : " + str(int($"%WorldMesh".worldResource.waterHeight * 100)) + "m"
		)
