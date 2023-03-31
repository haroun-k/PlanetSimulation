class_name WorldResource extends Resource

@export var resolution :int
@export var seed :int

#@export var pointNeighbours :={}
#@export var equivalentPoints :={}
@export var points : Array
@export var entities : Array[Entity]


@export var centersDictionary : Dictionary
@export var centersNeighboursDictionary := {}
@export var tilesData : Array[TileResource]
@export var waterHeight : float
@export var colors : PackedColorArray : 
	get : 
		return get_world()
		
@export var entitiesData : Array[EntityResource] 


func get_point_index(center : Vector3) : 
	return centersNeighboursDictionary.keys().find(center)
func get_point_index_ordered(center : Vector3) : 
	return centersDictionary.keys().find(center)

func init_world():
	
	tilesData.clear()
	for i in range(centersDictionary.size()) :
		tilesData.push_back(TileResource.new())
		tilesData[i].tile_position=centersDictionary.keys()[i]
		tilesData[i].init_tile(waterHeight)
	
	for i in range(centersNeighboursDictionary.size()) :
		tilesData[i].neighbours=[
								tilesData[get_point_index_ordered(centersNeighboursDictionary[centersDictionary.keys()[i]][0])],
								tilesData[get_point_index_ordered(centersNeighboursDictionary[centersDictionary.keys()[i]][1])],
								tilesData[get_point_index_ordered(centersNeighboursDictionary[centersDictionary.keys()[i]][2])]
								]

func get_random_world():
	var res = []
	for i in range(self.centersDictionary.size()*3):
		res.push_back(Color(randf(),randf(),randf()))
	return PackedColorArray(res)


func init_entities(world : Node3D):
	for entityPos in points :
		var tmp_res = EntityResource.new()
		tmp_res.init_entity_resource(entityPos)
		entities.push_back(Entity.new())
		world.add_child(entities[entities.size()-1])
		entities[entities.size()-1].init_entity(tmp_res)


func get_world():
#	pass
	for i in range(10) : tilesData.pick_random().update_tile(waterHeight)
	var res = []
#	res.resize(tilesData.size()*3)
	for i in tilesData : 
#		var colr=i.get_color()
#		var index = get_point_index_ordered(i.tile_position)
#		res[index]= colr
#		res[index+1]= colr
#		res[index+2]= colr
		res.push_back(i.get_color())
		res.push_back(i.get_color())
		res.push_back(i.get_color())
	return PackedColorArray(res)
