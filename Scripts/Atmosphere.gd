extends MeshInstance3D

# Initialisation des variables de la température, celle minimale et celle maximale.
var temperature = 0
var temp_min = -10
var temp_max = 50

# Initialisation des variables de références vers le materiel, le tableau des agents et des entités
var agents
var entities
var Mat

# Valeurs des offset de la température et de l'eau.
var waterOffset = 0
var temperatureOffset = 0



# Fonction d'initialisation appelé par la fonction d'initialisation dans Planète.
func init_atmosphere():
	# Garde une référence vers le materiel, le tableau des agents et des entités initialement
	Mat = get_active_material(0)
	Mat.set_shader_parameter("temp_max",temp_min)
	Mat.set_shader_parameter("temp_min",temp_max)
	agents = get_parent().agents
	entities = get_parent().get_node("WorldMesh").worldResource.entities




# Fonction qui met à jour la température
# Elle calcul d'abord une température simple en fonction du nombre d'agents et de plantes
# Puis cette valeur est modifié par plusieurs valeures sinusoidales qui vont changer au cour du temps afin de simuler des températures plus naturelles. 
# Cette valeure est ensuite ramené dans l'intervalle [Temperature minimale; Temperature maxiamle] 
func update_temperature(): 
	temperature = $"%WorldMesh".worldResource.amountOfVegetation/ (1000.0/(agents.size()+1)   ) + (agents.size()/2-($"%WorldMesh".worldResource.amountOfVegetation/80))
	temperature = clamp(temperature/3 + (sin(Time.get_ticks_msec() / 4000.0) * 3)+ (sin(Time.get_ticks_msec() / 8000.0) * 6)+ (sin(Time.get_ticks_msec() / 30000.0) * 10) + 9 + temperatureOffset    ,temp_min,temp_max)



# Fonction qui calcul le niveau d'eau à partir d'une valeure précise fixé, sur la quelle influe une valeure sinusoidale qui va changer au cours du temps afin de simuler un changement du niveau d'eau plus naturel. 
# Ce niveau dépend aussi légèrement de la température. 
func update_water_height():
	$"%WorldMesh".worldResource.waterHeight = 1.96 + (temperature/15000.0) + waterOffset + (sin(Time.get_ticks_msec() / 40000.0) * 0.03) 



# Fonction de mise à jour appelé par la fonction de mise à jour du monde dans Planète.
# Elle appel les fonctions pour mettre à jour le niveau de l'eau et la température
# Ppuis donne l'information de la température au shader de la mesh de la sphère qui va calculer la couleur de l'atmosphère en fonction de celle-ci
func update_atmosphere():
	update_temperature()
	update_water_height()
	
	Mat.set_shader_parameter("temperature",temperature)



# Fonction appellé à chaque frame. 'delta' est le temps s'étant écoulé depuis la dernière frame.
# Elle récupère les valeurs des offset depuis les sliders de l'interface utilisateur.
func _process(delta):
	waterOffset = $"%waterSlider".value / 1000.0	
	temperatureOffset = $"%tempSlider".value 

