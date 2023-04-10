class_name EntityResource extends Resource
enum ENTITY_TYPE {TREE,BUSH,STEAK,CARROT,GRASS,EMPTY}

@export var position : Vector3

@export var isOnFire : bool
@export var timeOnFire : int
@export var entityType : ENTITY_TYPE
@export var quantity : int 
@export var quality : int
@export var steakOrigin : int
@export var steakCountdown : int
@export var mesh : Mesh

func init_entity_resource(pos : Vector3,type : int, steakOr : int = 0):
#	entityType=randi_range(0,ENTITY_TYPE.size())
	entityType=type
	isOnFire=false
	timeOnFire=0
	match entityType :
		ENTITY_TYPE.TREE :
			mesh = ResourceLoader.load("res://Objects/Entities/Tree3.obj") if randf()<0.5 else ResourceLoader.load("res://Objects/Entities/Tree1.obj")
			quantity = 20
			quality = 200
		ENTITY_TYPE.STEAK :
			mesh = ResourceLoader.load("res://Objects/Entities/Steak.obj")
			quantity = 3
			steakCountdown=1000
			quality = 1000
			steakOrigin=steakOr
		ENTITY_TYPE.CARROT :
			mesh = ResourceLoader.load("res://Objects/Entities/Carrot.obj") 
			quantity = 2
			quality = 1000
		ENTITY_TYPE.BUSH :
			mesh = ResourceLoader.load("res://Objects/Entities/Bush3.obj")
			quantity = 10
			quality = 500
		ENTITY_TYPE.GRASS :
			mesh = ResourceLoader.load("res://Objects/Entities/Grass1.obj")  if randf()<0.5 else ResourceLoader.load("res://Objects/Entities/Grass2.obj")
			quantity = 4
			quality = 300
		ENTITY_TYPE.EMPTY :
			mesh = Mesh.new()
			quantity = 0
			quality = 0

	position=pos
