class_name Entity extends MeshInstance3D

@export var entityResource : EntityResource

# Instanciateur de l'entité
func _init(pos : Vector3, typ : EntityResource.ENTITY_TYPE, steakOrigin : int=0):
	entityResource = EntityResource.new()
	entityResource.init_entity_resource(pos,typ,steakOrigin)
	init_entity(entityResource)

# Initialise l'entite
func init_entity(res : EntityResource) -> void:

	#Pour le positionnement et déformations de la mesh
	mesh = res.mesh
	position = res.position
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

# Méthodes de type d'entite
func is_tree() -> bool: return entityResource.entityType==EntityResource.ENTITY_TYPE.TREE
func is_bush() -> bool: return entityResource.entityType==EntityResource.ENTITY_TYPE.BUSH
func is_grass() -> bool: return entityResource.entityType==EntityResource.ENTITY_TYPE.GRASS
func is_carrot() -> bool: return entityResource.entityType==EntityResource.ENTITY_TYPE.CARROT
func is_steak() -> bool: return entityResource.entityType==EntityResource.ENTITY_TYPE.STEAK
func is_empty() -> bool: return entityResource.entityType==EntityResource.ENTITY_TYPE.EMPTY


# Quand l'entite est mangee
func eat(world:Resource) -> int:
	entityResource.quantity-=1
	if entityResource.quantity==0 : #Si l'entite est vide 
		if not self.is_steak():
			world.amountOfVegetation-=1
		self.queue_free()
	return entityResource.quality
	
# Brule l'entite
func burn() -> void:
	entityResource.isOnFire=true

	# Charge les particules de feu
	var fireInstance = preload("res://Scenes/fire_particle.tscn").instantiate()
	self.add_child(fireInstance)
	fireInstance.global_position=global_position
