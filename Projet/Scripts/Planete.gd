extends Node3D

@onready var world_mesh = get_node("WorldMesh")
const Agent = preload("res://Agent.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in 200:
		add_child(Agent.new(self.world_mesh))
	pass # Replace with function body.

func reproduire_agents():
	
	var new_agents : Array = []
	var agents_reproduisibles = get_children().filter( func(a) : return a is Agent && a.cooldown_reproduction == 0)
	
	var i=0
	var ar_size=agents_reproduisibles.size()
	var j=0 
	
	while i<ar_size:
		j = i+1
		while j<ar_size-1:	
			if agents_reproduisibles[i].global_position.distance_to(agents_reproduisibles[j].global_position) < 0.023 && agents_reproduisibles[i].cooldown_reproduction==0 && agents_reproduisibles[j].cooldown_reproduction==0:
				new_agents.append(agents_reproduisibles[i].reproduire(agents_reproduisibles[j]))
				agents_reproduisibles.remove_at(i)
				agents_reproduisibles.remove_at(j)
				ar_size-=2
			j+=1
		i+=1
		
	for agent in new_agents:
		add_child(agent)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	for agent in get_children():
		if agent is Agent :
			agent.update()
			if agent.mourir() :
				self.remove_child(agent)
				
	print(get_child_count())
	reproduire_agents()

