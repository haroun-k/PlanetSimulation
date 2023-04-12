class_name EntityResource extends Resource
enum ENTITY_TYPE {TREE,BUSH,STEAK,CARROT,GRASS,EMPTY} #Toutes les entites possibles

@export var position : Vector3

@export var isOnFire : bool
@export var timeOnFire : int
@export var entityType : ENTITY_TYPE
@export var quantity : int #Influe combien de fois l'entite peut etre mangee
@export var quality : int #Influe a quel point l'agent qui la mange est rassasie
@export var steakOrigin : int
@export var steakCountdown : int #Pour supprimer les steaks après un certain temps
@export var mesh : Mesh

func init_entity_resource(pos : Vector3,type : int, steakOr : int = 0) -> void :

	randomize()
	
	#Affectation des variables
	entityType=type
	isOnFire=false
	timeOnFire=0
	position=pos
	
	#On load les modeles 3D et on initialise les variables
	match entityType :
		ENTITY_TYPE.TREE :
			if randf()<0.5 :
				mesh = ResourceLoader.load("res://Objects/Entities/Tree3.obj") 
			else:
				mesh = ResourceLoader.load("res://Objects/Entities/Tree1.obj")
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
			if randf()<0.5 :
				mesh = ResourceLoader.load("res://Objects/Entities/Grass1.obj") 
			else :
				ResourceLoader.load("res://Objects/Entities/Grass2.obj")
			quantity = 4
			quality = 300
		ENTITY_TYPE.EMPTY :
			mesh = Mesh.new()
			quantity = 0
			quality = 0

