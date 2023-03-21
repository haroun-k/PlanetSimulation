extends Node3D

@onready var icosphere = get_node("WorldMesh")

func reproduire_agents():
	var new_agents : Array = []
	var agents_reproduisibles = get_children().filter( func(a) : return a is Agent && a.selfData.cooldown_reproduction == 0)
	var i=0
	var ar_size=agents_reproduisibles.size()
	var j=0 
	
	while i<ar_size:
		j = i+1
		while j<ar_size-1:	
			if agents_reproduisibles[i].global_position.distance_to(agents_reproduisibles[j].global_position) < 0.023 && agents_reproduisibles[i].selfData.cooldown_reproduction==0 && agents_reproduisibles[j].selfData.cooldown_reproduction==0:
				new_agents.append(agents_reproduisibles[i].reproduire(agents_reproduisibles[j]))
				agents_reproduisibles.remove_at(i)
				agents_reproduisibles.remove_at(j)
				ar_size-=2
			j+=1
		i+=1
		
	for agent in new_agents:
		add_child(agent)

func update_agents():
	for agent in get_children():
		if agent is Agent :
			agent.update()
			if agent.is_dead() :
				self.remove_child(agent)
				
	reproduire_agents()

func update_world():
	icosphere.update()
	
func init_agents():
	for _i in 100:
		add_child(Agent.new(icosphere))

func init_world():
	icosphere.init_icosphere()



# Called when the node enters the scene tree for the first time.
func _ready():
	init_world()
	init_agents()

func _process(delta):
	update_world()
	update_agents()
