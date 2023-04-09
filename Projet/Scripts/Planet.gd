extends Node3D
@onready var icosphere = get_node("WorldMesh")
@export var agents : Array[Agent]
@export var speciesDictionary : Dictionary
@onready var avgNbSpecies : int = 5
@onready var nbSpecies : int = 0

func clear_simulation() : 
	for agent in agents :
		agent.queue_free()
	agents.clear()

func regulate_agents():
	if randf()<(1-(clamp(speciesDictionary.values().size()/avgNbSpecies,0,1) - 0.0001))/100 :
		spawn_new_specie()

func update_agents():
	regulate_agents()
	for agent in agents:
		agent.update()
		if agent.is_dead() or agents.size()>1000 :
			speciesDictionary.erase(agent)
			agent.queue_free()
			agents.erase(agent)
#			self.remove_child(agent)
			
#	reproduire_agents()

func update_world():
	icosphere.update()
	icosphere.worldResource.spawn_entities(self)
	$Atmosphere.update_atmosphere()
#
#func spawn_new_agents():
#	for _i in 70:
#		var randPos = icosphere.worldResource.centersNeighboursDictionary.keys().pick_random()
#		if icosphere.worldResource.tilesData[icosphere.worldResource.get_point_index_ordered(randPos)].terrainType!=TileResource.TERRAIN_TYPE.WATER :
#			var newAg=Agent.new(icosphere, randPos)
#			agents.push_back(newAg)
#			add_child(newAg)
func spawn_new_specie():
	var randArray = icosphere.worldResource.centersNeighboursDictionary.keys()
	randArray.shuffle()
	for cent in randArray :
		if icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.get_point_index_ordered(cent)) :
			for centNeighbour in icosphere.worldResource.centersNeighboursDictionary[cent] :
				if not icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.get_point_index_ordered(centNeighbour)) :
					var newAg=Agent.new(self, centNeighbour, nbSpecies)
					if newAg.selfData.canReproduceAlone==false : 
						var mate = Agent.new(self,centNeighbour, nbSpecies, newAg)
						add_child(mate)
						agents.push_back(mate)
					add_child(newAg)
					agents.push_back(newAg)
					nbSpecies+=1
					
					return

func init_world():
	icosphere.init_icosphere()
	icosphere.worldResource.maxAmountOfTrees=100



const agent_tick_interval := 1./120 # max 1/120 pour 120fps, ou 1/60 pour 60 fps
const world_tick_interval := 1./110
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
func _ui_button_pressed(hide:bool):
	if not can : return
	can=false
	$Ui/Panel/MenuAnimationPlayer.play("Menu_come" if hide else "Menu_go" )
	if needToUpdate :
		clear_simulation()
		init_simulation()
		needToUpdate=false
	await $Ui/Panel/MenuAnimationPlayer.animation_finished
	can=true




var target : Agent = null
#Potentiel raycasting
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			
			var camera = get_node("SweetCamera").get_node("Camera3D")
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 10000
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from,to)
			var result = space_state.intersect_ray(query)
			
			target = null
			if result:	
				#Find the closest agent
				var minDist = 0.3
				var dist
				for a in agents:
					dist = result.position.distance_to(a.selfData.current_position)
					if dist < minDist:
						minDist = dist
						target = a
	
