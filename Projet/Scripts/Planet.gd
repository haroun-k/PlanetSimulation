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
	if randf()<(1-(clamp(nbSpecies/avgNbSpecies,0,1) - 0.0001))/100 :
		spawn_new_agent()

func update_agents():
	regulate_agents()
	for agent in agents:
		agent.update()
		if agent.is_dead() or agents.size()>1000 :
			agents.erase(agent)
			agent.queue_free()
#			self.remove_child(agent)
			
#	reproduire_agents()

func update_world():
	icosphere.update()
	icosphere.worldResource.spawn_entities(self)
	
#
#func spawn_new_agents():
#	for _i in 70:
#		var randPos = icosphere.worldResource.centersNeighboursDictionary.keys().pick_random()
#		if icosphere.worldResource.tilesData[icosphere.worldResource.get_point_index_ordered(randPos)].terrainType!=TileResource.TERRAIN_TYPE.WATER :
#			var newAg=Agent.new(icosphere, randPos)
#			agents.push_back(newAg)
#			add_child(newAg)
func spawn_new_agent():
	var randArray = icosphere.worldResource.centersNeighboursDictionary.keys()
	randArray.shuffle()
	for cent in randArray :
		if icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.get_point_index_ordered(cent)) :
			for centNeighbour in icosphere.worldResource.centersNeighboursDictionary[cent] :
				if not icosphere.worldResource.myAstar.is_point_disabled(icosphere.worldResource.get_point_index_ordered(centNeighbour)) :
					var newAg=Agent.new(icosphere, centNeighbour, nbSpecies)
					agents.push_back(newAg)
					add_child(newAg)
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
