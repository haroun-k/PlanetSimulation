extends Node3D

# référence vers l'instance de la node de la planète
@onready var icosphere = get_node("WorldMesh")

# tableau des références vers tout les agents existants.
@export var agents : Array[Agent]

# dictionnaire qui à un agent lui associe la valeure entière représentant son numéro d'espèce
@export var speciesDictionary : Dictionary

# dictionnaire qui a pour clé un numéro d'espèce et lui associe les références de chaque agent de cette espèce
@export var uniqueSpeciesNb : Dictionary

# Le nombre d'espèce maximales simultanéement vivantes naturellement.
# Plus il y a d'espèces moins il y a de chances d'apparition d'une nouvelle espèce 
@onready var avgNbSpecies : int = 5

# Nombre d'espèces générés au total.
@onready var nbSpecies : int = 0


# Variable pour le ray-casting qui va prendre la référence de l'agent touché par le ray-cast 
var target : Agent = null
# Potentiel raycasting qui ne se fait que si la touche shift est pressé lors d'un clique gauche
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).button_index==1 and event.is_pressed() and (event as InputEventWithModifiers).is_shift_pressed() : 
			
			# projete un rayon depuis le centre de la caméra 
			# vers la projection de la position du clic de la souris sur une très grande distance
			var camera = $"%Camera3D"
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 10000
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from,to)
			var result = space_state.intersect_ray(query)
			target = null
			if result:	
				#Considère le plus proche agent dont la distance au "rayon" simulé est inferieur à minDist
				var minDist = 0.2
				var dist
				for a in agents:
					dist = result.position.distance_to(a.selfData.currentPosition)
					if dist < minDist:
						minDist = dist
						target = a
				
				# si le raycast a touché un agent celui ci est mis comme cible de la caméra afin d'avoir une vue centrée sur celui-ci
				if target!=null : 
					camera.target=target.get_child(0)
					camera.offset=Vector3(0,0,1)
					
				# sinon la caméra est recentrée sur sa cible initiale qui est la planète
				else : 
					camera.target=camera.initialTarget
					camera.offset=camera.initialOffset


# Fonction qui efface toutes les données de la simulation afin de potentiellement en relancer une.
func clear_simulation() : 
	for agent in agents :
		agent.queue_free()
	speciesDictionary.clear()
	uniqueSpeciesNb.clear()
	agents.clear()
	for ent in icosphere.worldResource.entities :
		if ent!=null : ent.queue_free()
	icosphere.worldResource.entities.clear()

# Fonction qui s'occupe de réguler les agents, en faisant apparaitres des nouvelles espèces naturellement s'il n'y en a pas assez.
# elle recalcul en même temps le dictionaire qui à une espèce associe ses agents
func regulate_agents():
	uniqueSpeciesNb.clear()
	for i in speciesDictionary.values() :
		uniqueSpeciesNb[i]= 1 if not uniqueSpeciesNb.has(i) else uniqueSpeciesNb[i]+1
	
	if randf()<(1-(clamp(uniqueSpeciesNb.size()/(avgNbSpecies*1.),0,1)))/50 :
		spawn_new_specie()

# Fonction qui fait apparaitre une nouvelle espèce à une position aléatoire près de l'eau, l'ajoute dans l'arborescence incrémente le compteur d'espèces et modifie le dictionnaire des agents
func spawn_new_specie():
	var randArray = icosphere.worldResource.centersNeighboursDictionary.keys()
	randArray.shuffle()
	for cent in randArray :
		if icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.find_point_centersDict(cent)) :
			for centNeighbour in icosphere.worldResource.centersNeighboursDictionary[cent] :
				if not icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.find_point_centersDict(centNeighbour)) :
					var newAg=Agent.new(self, centNeighbour, nbSpecies)
					add_child(newAg)
					agents.push_back(newAg)
					nbSpecies+=1
					
					return


# Fonction qui met à jour les agents en appellant la fonction qui les régule et en éffacant et libérant de la mémoire les agents morts.
# Elle s'occupe aussi de faire un appel à une fonction pour faire apparaitre un "steak" à la position de mort de l'agent. 
func update_agents():
	regulate_agents()
	for agent in agents:
		agent.update()
		if agent.is_dead() or agents.size()>100 :
			icosphere.worldResource.spawn_steak(self, agent.selfData.currentPosition, agent.selfData.specie)
			speciesDictionary.erase(agent)
			agent.queue_free()
			agents.erase(agent)

# Fonction qui met à jour tout ce qui concerne le terrain: la planète et son apparence, Fait apparaitre des entités et met à jour l'atmosphère.
func update_world():
	icosphere.update()
	icosphere.worldResource.spawn_entities(self)
	$Atmosphere.update_atmosphere()
	

# Fonction appelée initialement pour initialiser la planète en initialisant l'atmosphère puis l'icosphère et elle défini le nombre d'entités naturelles maximal 
func init_world():
	$"%Atmosphere".init_atmosphere()
	icosphere.init_icosphere()
	icosphere.worldResource.maxAmountOfVegetation=12*(2**icosphere.worldResource.resolution)+ ( 200 if icosphere.worldResource.resolution>2 else 0 )




# Définition des valeures arbitraires de la fréquence de mise à jour des agents et du terrain à l'aide d'un système de tick séparé
const agent_tick_interval := 1./90 # max 1/120 pour 120fps, ou 1/60 pour 60 fps
const world_tick_interval := 1./50

# création des signaux qui, à leurs émission, vont provoquer l'appel de fonctions 
signal ticked_world
signal ticked_agents

# Fonction appelé automatiquement quand le noeud racine est instancié dans la scène pour la première fois.
func _ready() :
	# Une connection entre les signaux et les fonction à executer lors de l'emission de ces signaux est faite pour le système de ticks.
	ticked_world.connect(update_world)
	ticked_agents.connect(update_agents)

# La boucle infinie qui va faire des appels asynchrones pour les agents et le monde en attendant la duré d'un tick
# Elle est appelé une fois le bouton de lancement de la simulation est préssé
func run_ticks() :
	while true :
		await tickworld()
		await tickagents()

# Fonctions qui émettent un signal pour faire tick les fonction de mise à condition que le temps défini soit écoulé depuis la dernière émission.
func tickworld():
	await get_tree().create_timer(world_tick_interval).timeout
	ticked_world.emit()
	
func tickagents():
	await get_tree().create_timer(agent_tick_interval).timeout
	ticked_agents.emit()



# Fonction qui va être appelé au début de la simulation pour tout initialiser avant de commencer les mises à jour
func init_simulation():
	init_world()
	run_ticks()


# fonction qui met une variable à Vrai si l'un des paramètres de la simulation a été changé dans le menu 
# afin de savoir s'il faut relancer la simulation ou non si le boutton est préssé à nouveau
var needToUpdate=true
func _simulation_parameters_changed():
	needToUpdate=true

# Fonction qui recois l'appuie des boutons du menu afin de saovir s'il faut le faire apparaitre ou le cacher en jouant les bonnes animations. 
# Elle bloque également les appels tant que la précédente animation ne s'est pas terminée
# Et elle lance une simulation si les paramètres ont été changés ou s'il sagit du premier appel
var can := true
func _ui_button_pressed(toHide:bool):
	if not can : return
	can=false
	$Ui/Panel/MenuAnimationPlayer.play("Menu_come" if toHide else "Menu_go" )
	if needToUpdate :
		clear_simulation()
		init_simulation()
		needToUpdate=false
	await $Ui/Panel/MenuAnimationPlayer.animation_finished
	can=true


# Fonction appelée seulement si un bouton de l'interface est pressé, elle met dans une variable une valeur qui va impliquer que la simulation va se remplir aléatoirement d'entités.
func spree():
	icosphere.worldResource.spree=true

# Fonction appelée seulement si la couleur à choisir de l'interface est pressé
# Elle modifie la couleure du "WorldEnvironment" pour changer la couleur de l'espace dans la simulation.
func _on_color_picker_button_color_changed(color):
	var worldEnv : WorldEnvironment = get_node("WorldEnvironment")
	worldEnv.get_environment().background_color=color
	
