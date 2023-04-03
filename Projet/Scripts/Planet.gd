extends Node3D
@onready var icosphere = get_node("WorldMesh")
@export var agents : Array[Agent]

func clear_simulation() : 
	for agent in agents :
		agent.queue_free()
	agents.clear()

func reproduire_agents():
	var agents_reproduisibles = agents.filter( func(a) : return a.selfData.cooldown_reproduction == 0)
	for agent in agents_reproduisibles :
		for agent2 in agents_reproduisibles :
			if agent!=agent2 and agent2.selfData.position == agent.selfData.position :
					agents_reproduisibles.erase(agent)
					agents_reproduisibles.erase(agent2)
					
					var newAg=Agent.new(icosphere, agent.selfData.position)
					agents.push_back(newAg)
					add_child(newAg)

func update_agents():
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
	
	
func init_agents():
	for _i in 50:
		var randPos = icosphere.worldResource.centersNeighboursDictionary.keys().pick_random()
		if icosphere.worldResource.tilesData[icosphere.worldResource.get_point_index_ordered(randPos)].terrainType!=TileResource.TERRAIN_TYPE.WATER :
			var newAg=Agent.new(icosphere, randPos)
			agents.push_back(newAg)
			add_child(newAg)

func init_world():
	icosphere.init_icosphere()
	icosphere.worldResource.maxAmountOfTrees=100
	
const tick_duration := 0
signal ticked
func run_ticks() :
	while true :
		if tick_duration<=1./120 :
			await get_tree().process_frame
		else :
			await get_tree().create_timer(tick_duration).timeout
		
		ticked.emit()


# Called when the node enters the scene tree for the first time.

func _ready() :
	ticked.connect(update_world)
	ticked.connect(update_agents)

func init_simulation():
	init_world()
	init_agents()
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
