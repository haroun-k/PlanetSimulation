class_name AgentData extends Resource

@export var appareancesArray : Array

@export var age : int
@export var adultAge : int
@export var maxAge : int
@export var hunger : int 
@export var toleratedHunger : int 
@export var maxHunger : int 
@export var size : float

@export var specie : int
@export var view_distance : float
@export var speed : int
@export var fear : bool
@export var heatResistance : int
@export var canReproduceAlone : bool
@export var canReproduce : bool
@export var reproductionVariations : float
@export var metabolismSpeed : float 
@export var carnivor : bool
@export var agressivity : float 
@export var amountOfFoodThatCanBeTransported : int
@export var transportedAmountOfFood : int

@export var current_path : Array
@export var current_direction : Vector3
@export var current_position : Vector3

@export var lookForEntityCooldown : int 
@export var ticksSinceReproduced : int

@export var agentMesh : MeshInstance3D
@export var world : Node3D
@export var directionMesh : MeshInstance3D
@export var agentScene : Node3D



func randomize_genes(): 
	age=0
	maxAge=randi_range(0,1000)
	adultAge=randi_range(0,maxAge)
	hunger=0
	maxHunger=randi_range(50,maxAge)
	toleratedHunger=randi_range(0,maxHunger)
	size=randf_range(0.01,0.1)
	
	specie
	
	view_distance=randf_range(0.1,2)
	speed=randi_range(1,10)
	fear=true if randi_range(0,1)==1 else false
	heatResistance=randi_range(-50,50)
	canReproduceAlone=true #if randi_range(0,1)==1 else false
	canReproduce=true
	reproductionVariations=randf()
	metabolismSpeed=randf_range(0.1,2)
	carnivor=true if randi_range(0,1)==1 else false
	agressivity=randf()
	amountOfFoodThatCanBeTransported=randi_range(0,10)
	transportedAmountOfFood=0
	
	lookForEntityCooldown=0
	ticksSinceReproduced=0
	
	agentScene=ResourceLoader.load(appareancesArray[specie%appareancesArray.size()]).instantiate()
	agentScene.scale=Vector3(size,size,size)
func meiose():
	pass
