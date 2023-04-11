extends Node3D
@onready var icosphere = get_node("WorldMesh")
@export var agents : Array[Agent]
@export var speciesDictionary : Dictionary
@export var uniqueSpeciesNb : Dictionary
@onready var avgNbSpecies : int = 5
@onready var nbSpecies : int = 0


var target : Agent = null
#Potentiel raycasting
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).button_index==1 and event.is_pressed() and (event as InputEventWithModifiers).is_shift_pressed() : 
			
			var camera = $"%Camera3D"
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 10000
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from,to)
			var result = space_state.intersect_ray(query)
			target = null
			if result:	
				#Find the closest agent
				var minDist = 0.4
				var dist
				for a in agents:
					dist = result.position.distance_to(a.selfData.current_position)
					if dist < minDist:
						minDist = dist
						target = a
				if target!=null : 
					camera.target=target.get_child(0)
					camera.offset=Vector3(0,0,1)
				else : 
					camera.target=camera.initialTarget
					camera.offset=camera.initialOffset

func clear_simulation() : 
	for agent in agents :
		agent.queue_free()
	speciesDictionary.clear()
	uniqueSpeciesNb.clear()
	agents.clear()
	for ent in icosphere.worldResource.entities :
		if ent!=null : ent.queue_free()
	icosphere.worldResource.entities.clear()

func regulate_agents():
	uniqueSpeciesNb.clear()
	for i in speciesDictionary.values() :
		uniqueSpeciesNb[i]= 1 if not uniqueSpeciesNb.has(i) else uniqueSpeciesNb[i]+1
	
	if randf()<(1-(clamp(uniqueSpeciesNb.size()/(avgNbSpecies*1.),0,1)))/50 :
		spawn_new_specie()

func update_agents():
	regulate_agents()
	for agent in agents:
		agent.update()
		if agent.is_dead() or agents.size()>100 :
			icosphere.worldResource.spawn_steak(self, agent.selfData.current_position, agent.selfData.specie)
			speciesDictionary.erase(agent)
			agent.queue_free()
			agents.erase(agent)
			

func spree():
	icosphere.worldResource.spree=true
func update_world():
	icosphere.update()
	icosphere.worldResource.spawn_entities(self)
	$Atmosphere.update_atmosphere()

func spawn_new_specie():
	var randArray = icosphere.worldResource.centersNeighboursDictionary.keys()
	randArray.shuffle()
	for cent in randArray :
		if icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.get_point_index_ordered(cent)) :
			for centNeighbour in icosphere.worldResource.centersNeighboursDictionary[cent] :
				if not icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.get_point_index_ordered(centNeighbour)) :
					var newAg=Agent.new(self, centNeighbour, nbSpecies)
					add_child(newAg)
					agents.push_back(newAg)
					nbSpecies+=1
					
					return

func init_world():
	$"%Atmosphere".init_atmosphere()
	icosphere.init_icosphere()
	icosphere.worldResource.maxAmountOfVegetation=12*(2**icosphere.worldResource.resolution)+ ( 200 if icosphere.worldResource.resolution>2 else 0 )



const agent_tick_interval := 1./90 # max 1/120 pour 120fps, ou 1/60 pour 60 fps
const world_tick_interval := 1./50
signal ticked_world
signal ticked_agents

func run_ticks() :
	while true :
		await tickworld()
		await tickagents()
		
func tickworld():
	await get_tree().create_timer(world_tick_interval).timeout
	ticked_world.emit()
func tickagents():
	await get_tree().create_timer(agent_tick_interval).timeout
	ticked_agents.emit()
# Called when the node enters the scene tree for the first time.

func _ready() :
	ticked_world.connect(update_world)
	ticked_agents.connect(update_agents)

func init_simulation():
	init_world()
	run_ticks()


var needToUpdate=true
func _simulation_parameters_changed():
	needToUpdate=true

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


func _on_color_picker_button_color_changed(color):
	var worldEnv : WorldEnvironment = get_node("WorldEnvironment")
	worldEnv.get_environment().background_color=color
	
