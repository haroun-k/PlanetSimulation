class_name WorldResource extends Resource

@export var resolution :int

#@export var pointNeighbours :={}
#@export var equivalentPoints :={}

@export var centersDictionary : Dictionary
@export var centersNeighboursDictionary := {}
@export var tilesData : Array[TileResource]
	
@export var colors : PackedColorArray : 
	get : 
		return get_world()

func get_point_index(center : Vector3) : 
	return centersDictionary.keys().find(center)

func init_world():
	tilesData.clear()
	for i in range(centersDictionary.size()) :
		tilesData.push_back(TileResource.new())
		tilesData[i].tile_position=centersDictionary.keys()[i]
		tilesData[i].init_tile()
	
	for i in range(centersDictionary.size()) :
		tilesData[i].neighbours=[
								tilesData[get_point_index(centersNeighboursDictionary[centersNeighboursDictionary.keys()[i]][0])],
								tilesData[get_point_index(centersNeighboursDictionary[centersNeighboursDictionary.keys()[i]][1])],
								tilesData[get_point_index(centersNeighboursDictionary[centersNeighboursDictionary.keys()[i]][2])]
								]

func get_random_world():
	var res = []
	for i in range(self.centersDictionary.size()*3):
		res.push_back(Color(randf(),randf(),randf()))
	return PackedColorArray(res)
	
func get_world():
#	pass
	for i in range(10) : tilesData.pick_random().update_tile()
	var res = []
	for i in tilesData : 

		res.push_back(i.get_color())
		res.push_back(i.get_color())
		res.push_back(i.get_color())
	return PackedColorArray(res)
