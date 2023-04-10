class_name Entity extends MeshInstance3D

@export var entityResource : EntityResource

# Called when the node enters the scene tree for the first time.
func init_entity(res : EntityResource):

	mesh=res.mesh
	position=res.position
	var axis = position.cross(Vector3(0,1,0)).normalized()
	var angle = acos(Vector3(0,1,0).dot(position)/position.length())
	rotate_object_local(axis,-angle)

	rotate(position.normalized(),randf_range(0.1,6.))

	match res.entityType :
		res.ENTITY_TYPE.TREE :
			scale=Vector3(randf_range(0.07,0.15),randf_range(0.07,0.15),randf_range(0.07,0.15))
		res.ENTITY_TYPE.STEAK :
			scale=Vector3(0.05,0.05,0.05)
		res.ENTITY_TYPE.BUSH :
			scale=Vector3(0.1,0.1,0.1)
		res.ENTITY_TYPE.GRASS :
			scale=Vector3(0.4,0.4,0.4)
		res.ENTITY_TYPE.CARROT :
			scale=Vector3(0.1,0.1,0.1)

func eat(world:Resource):
	entityResource.quantity-=1
	if entityResource.quantity==0 : 
		world.amountOfVegetation-=1 if self.entityResource.entityType!=EntityResource.ENTITY_TYPE.STEAK else 0
		self.queue_free()
	return entityResource.quality
	
func burn():
	entityResource.isOnFire=true
	var fireInstance = preload("res://Scenes/fire_particle.tscn").instantiate()
	self.add_child(fireInstance)
	fireInstance.global_position=global_position

func _init(pos : Vector3,typ : EntityResource.ENTITY_TYPE,steakOrigin:int=0):
	entityResource = EntityResource.new()
	entityResource.init_entity_resource(pos,typ,steakOrigin)
	init_entity(entityResource)
