class_name WorldResource extends Resource

class SetFile :

	var file : Array

	func _init():
		self.file = []

	func enfiler(e : TileResource):
		if e.isUndefined() && e not in self.file:
			self.file.push_back(e)
			
	func enfiler_unchecked(e : TileResource):
		self.file.push_back(e)

	func defiler():
		if self.file.size() > 0 :
			return self.file.pop_front()
		else :
			return null

	func est_vide():
		return self.file.size() == 0

@export var resolution :int
@export var seed :int
@export var waterHeight : float

@export var maxAmountOfTrees : int
@export var amountOfTrees : int 
@export var points : Array = [null]
@export var pointDictionnary : Dictionary


@export var centersDictionary : Dictionary
@export var centersNeighboursDictionary := {}


@export var tilesData : Array[TileResource]
@export var updateTilesArray : Array[TileResource]
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
	var tiles_a_traiter = SetFile.new()
	tilesData.clear()
	entities.resize(points.size())
	var ki = 0
	var clefs = centersDictionary.keys()
	for k in clefs :
		tilesData.push_back(TileResource.new())
		tilesData[ki].tile_position=k
		tilesData[ki].init_tile(waterHeight)
		ki+=1
	ki = 0	
		
	for i in range(centersNeighboursDictionary.size()) :
		var voisins = centersNeighboursDictionary[clefs[i]]
		tilesData[i].neighbours=[
								tilesData[get_point_index_ordered(voisins[0])],
								tilesData[get_point_index_ordered(voisins[1])],
								tilesData[get_point_index_ordered(voisins[2])]
								]

		if tilesData[i].isWater() :
			for n in tilesData[i].neighbours :
				tiles_a_traiter.enfiler(n)
		else: #au cas ou pour que toutes les cases soient traitees
			tiles_a_traiter.enfiler(tilesData[i])

	while not tiles_a_traiter.est_vide() :
		var tile = tiles_a_traiter.defiler()
		if tile.collapse_tile():
			tiles_a_traiter.enfiler_unchecked(tile)
	for t in tilesData:
		if t.isUndefined():
			t.collapse_tile()
	for cent in centersDictionary:
		for pt in centersDictionary[cent] :
			pointDictionnary[pt]= [] if not pointDictionnary.keys().has(pt) else pointDictionnary[pt] + [cent] 
	updateTilesArray=tilesData.duplicate(true)
	updateTilesArray.shuffle()
	generate_astar()
	
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
			if randf()<(1-(amountOfTrees/maxAmountOfTrees))/10000. and entities[get_edge_index(entityPos)]== null:
				amountOfTrees+=1
				init_entity(entityPos)
				world.add_child(entities[get_edge_index(entityPos)])

func init_entity(pos : Vector3):
	entities[get_edge_index(pos)]=Entity.new(pos)
	
func generate_astar():
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

func update_world_resource():
	for i in updateTilesArray :
		var previousType=i.terrainType
		i.update_tile(waterHeight)
		if i.terrainType==TileResource.TERRAIN_TYPE.WATER and previousType!=TileResource.TERRAIN_TYPE.WATER :
			myAstar.set_point_disabled(get_point_index_ordered(i.tile_position))
		elif i.terrainType!=TileResource.TERRAIN_TYPE.WATER and previousType==TileResource.TERRAIN_TYPE.WATER :
			myAstar.set_point_disabled(get_point_index_ordered(i.tile_position),false)
	for entity in entities:
		if entity !=null :
			var toDelete = true
			for surroundingCenters in pointDictionnary[entity.entityResource.position] :	
				if tilesData[get_point_index_ordered(surroundingCenters)].terrainType!=TileResource.TERRAIN_TYPE.WATER :
					toDelete=false
			if toDelete : 
				entity.queue_free()
				amountOfTrees-=1
		

func get_world():

	var res = []
	for i in tilesData : 
		res.push_back(i.get_color())
		res.push_back(i.get_color())
		res.push_back(i.get_color())
	return PackedColorArray(res)
