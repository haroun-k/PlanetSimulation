class_name WorldResource extends Resource

@export var resolution :int
@export var seed :int
@export var waterHeight : float

@export var maxAmountOfTrees : int
@export var amountOfTrees : int 
@export var points : Array = [null]


@export var centersDictionary : Dictionary
@export var centersNeighboursDictionary := {}

@export var tilesData : Array[TileResource]
@export var entities : Array[Entity]

@export var colors : PackedColorArray : 
	get : 
		return get_world()
var myAstar : AStar3D

func get_point_index(center : Vector3) : 
	return centersNeighboursDictionary.keys().find(center)
func get_edge_index(pt : Vector3) : 
	return points.find(pt)
func get_point_index_ordered(center : Vector3) : 
	return centersDictionary.keys().find(center)

func init_world():
	entities.resize(points.size())
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
	init_asta()
func get_entities_on_tile(position: Vector3):
	var arr := []
	for pts in centersDictionary[position]:
		if entities[get_edge_index(pts)] != null : 
			arr.push_back(entities[get_edge_index(pts)])
	return arr

func get_random_world():
	var res = []
	for i in range(self.centersDictionary.size()*3):
		res.push_back(Color(randf(),randf(),randf()))
	return PackedColorArray(res)


func spawn_entities(world : Node3D):
	for td in tilesData :
		if td.terrainType == TileResource.TERRAIN_TYPE.GRASS :
			var entityPos = centersDictionary[td.tile_position].pick_random()
			if randf()<(1-(amountOfTrees/maxAmountOfTrees) )/10000. and entities[get_edge_index(entityPos)]== null:
				amountOfTrees+=1
				init_entity(entityPos)
				world.add_child(entities[get_edge_index(entityPos)])

func init_entity(pos : Vector3):
	entities[get_edge_index(pos)]=Entity.new(pos)
	
func init_asta():
	var myastar = AStar3D.new()
	for i in centersNeighboursDictionary.keys():
		var idi = get_point_index_ordered(i)
		myastar.add_point(idi,i)
		for j in centersNeighboursDictionary[i] :
			var idj = get_point_index_ordered(j)
			myastar.add_point(idj,j)
			myastar.connect_points(idi,idj)
			if tilesData[idj].terrainType==TileResource.TERRAIN_TYPE.WATER : myastar.set_point_disabled(idj)
		if tilesData[idi].terrainType==TileResource.TERRAIN_TYPE.WATER : myastar.set_point_disabled(idi)
	myAstar=myastar
				
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
