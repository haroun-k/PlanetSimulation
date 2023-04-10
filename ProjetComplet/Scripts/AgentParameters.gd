class_name AgentData extends Resource

@export var appareancesArray : Array
@export var previousPos : Vector3

@export var age : int
@export var adultAge : int
@export var baby : bool
@export var maxAge : int
@export var hunger : int 
@export var toleratedHunger : int 
@export var maxHunger : int 
@export var size : float

@export var specie : int
@export var view_distance : float
@export var speed : int
@export var fear : bool
@export var fearFire : bool
@export var reproductionVariations : float
@export var metabolismSpeed : float 
@export var carnivor : bool
@export var agressivity : float 
@export var ateOnce : bool
@export var killed : bool
@export var onFire : bool

@export var current_path : Array
@export var current_direction : Vector3
@export var current_position : Vector3

@export var lookForEntityCooldown : int 
@export var ticksSinceReproduced : int
@export var feedingChildrensCooldown : int 
@export var agentMesh : MeshInstance3D
@export var world : Node3D
@export var directionMesh : MeshInstance3D
@export var agentScene : Node3D



func randomize_genes(): 
	maxAge=randi_range(1000,5000)
	adultAge=randi_range(0,maxAge/1.5)
	age=adultAge/2
	hunger=0
	maxHunger=randi_range(400,adultAge/2)
	toleratedHunger=randi_range(0,maxHunger/1.6)
	size=randf_range(0.02,0.05)
	baby=true

	ateOnce=false
	speed=randi_range(3,10)
	fear=true if randi_range(0,1)==1 else false
	fearFire=true if randi_range(0,1)==1 else false
	reproductionVariations=randf_range(0,0.1)
	metabolismSpeed=randi_range(1,4)
	carnivor=true if randi_range(0,1)==1 else false
	agressivity=randf()
	view_distance=randf_range(0.3,2)
	killed=false
	onFire=false

	
	lookForEntityCooldown=0
	ticksSinceReproduced=0
	feedingChildrensCooldown=0
	
	agentScene=ResourceLoader.load(appareancesArray[specie%appareancesArray.size()]).instantiate()
	agentScene.scale=Vector3(size/2,size/2,size/2)

func meiose():
	pass
