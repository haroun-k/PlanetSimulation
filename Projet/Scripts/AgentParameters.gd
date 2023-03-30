class_name AgentData extends Resource

@export var world : Node3D
@export var current_direction : Vector3
@export var current_position : Vector3

@export var cooldown_reproduction : int
@export var age : int

@export var agentMesh : MeshInstance3D
@export var directionMesh : MeshInstance3D
@export var agentScene : Node3D

@export var speed : int
@export var experience : int 
@export var canReproduce : bool
@export var pressionResistance : float
@export var heatResistance : float
@export var canReproduceAlone : bool
@export var reproductionVariations : float
@export var mate : AgentData
@export var male : bool
@export var mateFriendliness : float
@export var carnivor : bool

@export var strenght : float  
@export var hunger : int 
@export var canTransportFood : bool
@export var transportedAmountOfFood : int
@export var metabolismSpeed : float 

@export var agressivity : float 
@export var friendliness : float 


func randomise(): 
	pass
func meiose():
	pass
