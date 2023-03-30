class_name EntityResource extends Resource
enum ENTITY_TYPE {TREE,ROCK,BUSH,EMPTY}

@export var position : Vector3

@export var entityType : ENTITY_TYPE
@export var quantity : int 

@export var mesh : Mesh

func init_entity_resource(position : Vector3):
	entityType=randi_range(0,ENTITY_TYPE.size())
	match entityType :
		ENTITY_TYPE.TREE :
			mesh = ResourceLoader.load("res://Objects/Entities/Tree3.obj")
		ENTITY_TYPE.ROCK :
			mesh = ResourceLoader.load("res://Objects/Entities/Rock1.obj")
		ENTITY_TYPE.BUSH :
			mesh = ResourceLoader.load("res://Objects/Entities/Bush3.obj")
		ENTITY_TYPE.EMPTY :
			mesh = Mesh.new()
			
	quantity=10
	self.position=position
