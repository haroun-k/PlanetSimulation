class_name Entity extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func init_entity(res : EntityResource):
	mesh=res.mesh
	position=res.position
	
	var axis = position.cross(Vector3(0,1,0)).normalized()
	var angle = acos(Vector3(0,1,0).dot(position)/position.length())
	rotate_object_local(axis,-angle)


	match res.entityType :
		res.ENTITY_TYPE.TREE :
			scale=Vector3(randf_range(0.07,0.15),randf_range(0.07,0.15),randf_range(0.07,0.15))
		res.ENTITY_TYPE.ROCK :
			scale=Vector3(0.02,0.02,0.02)
		res.ENTITY_TYPE.BUSH :
			scale=Vector3(0.1,0.1,0.1)

