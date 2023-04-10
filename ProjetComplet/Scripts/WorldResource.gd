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

@export var maxAmountOfVegetation : int
@export var amountOfVegetation : int 
@export var points : Array = [null]
@export var pointDictionnary : Dictionary


@export var centersDictionary : Dictionary
@export var centersNeighboursDictionary := {}


@export var tilesData : Array[TileResource]
@export var updateTilesArray : Array[TileResource]
@export var entities : Array[Entity]

var myAstar : AStar3D

func get_point_index(center : Vector3) : 
	return centersNeighboursDictionary.keys().find(center)
func get_edge_index(pt : Vector3) : 
	return points.find(pt)
func get_point_index_ordered(center : Vector3) : 
	return centersDictionary.keys().find(center)


var atmosphere
func init_world(at):
	
	self.atmosphere = at
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
		if tile.collapse_tile(atmosphere.temperature):
			tiles_a_traiter.enfiler_unchecked(tile)
	for t in tilesData:
		if t.isUndefined():
			t.collapse_tile(atmosphere.temperature)
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

func spawn_steak(world : Node3D, deathPos:Vector3, specieOrigin :int):
	for entityPos in centersDictionary[deathPos] :
		if entities[get_edge_index(entityPos)]== null :
#			print("STEAK DROPPED GUYS")
			init_entity(entityPos, EntityResource.ENTITY_TYPE.STEAK,specieOrigin)
			world.add_child(entities[get_edge_index(entityPos)])
			return
var spree
func spawn_entities(world : Node3D):
	for td in tilesData :
		if td.terrainType == TileResource.TERRAIN_TYPE.TALL_GRASS :
			var entityPos = centersDictionary[td.tile_position].pick_random()
			if ( randf()<(1-(amountOfVegetation/maxAmountOfVegetation))/1000. if (not spree) else amountOfVegetation<maxAmountOfVegetation ) and entities[get_edge_index(entityPos)]== null:
				amountOfVegetation+=1
				init_entity(entityPos, EntityResource.ENTITY_TYPE.CARROT)
				world.add_child(entities[get_edge_index(entityPos)])
		elif td.terrainType == TileResource.TERRAIN_TYPE.GRASS :
			var entityPos = centersDictionary[td.tile_position].pick_random()
			if ( randf()<(1-(amountOfVegetation/maxAmountOfVegetation))/1000. if (not spree) else amountOfVegetation<maxAmountOfVegetation ) and entities[get_edge_index(entityPos)]== null:
				amountOfVegetation+=1
				init_entity(entityPos,EntityResource.ENTITY_TYPE.TREE if randf()<0.5 else EntityResource.ENTITY_TYPE.BUSH)
				world.add_child(entities[get_edge_index(entityPos)])
		elif td.terrainType != TileResource.TERRAIN_TYPE.WATER :
			var entityPos = centersDictionary[td.tile_position].pick_random()
			if ( randf()<(1-(amountOfVegetation/maxAmountOfVegetation))/1000. if (not spree) else amountOfVegetation<maxAmountOfVegetation ) and entities[get_edge_index(entityPos)]== null:
				amountOfVegetation+=1
				init_entity(entityPos,EntityResource.ENTITY_TYPE.GRASS)
				world.add_child(entities[get_edge_index(entityPos)])
				
	spree=false
		

func init_entity(pos : Vector3, typ : EntityResource.ENTITY_TYPE, specieOrigin : int=0):
	entities[get_edge_index(pos)]=Entity.new(pos,typ,specieOrigin)
	
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


var it = 0
func update_world_resource(purge : bool=false, startAFire:bool=false):

	for i in range(15) :
		it+=1
		it = it % tilesData.size() 
		updateTilesArray[it].collapse_tile(atmosphere.temperature)

	for i in updateTilesArray :
		var previousType=i.terrainType
		i.update_tile(waterHeight, atmosphere.temperature)
		if i.terrainType==TileResource.TERRAIN_TYPE.WATER and previousType!=TileResource.TERRAIN_TYPE.WATER :
			myAstar.set_point_disabled(get_point_index_ordered(i.tile_position))
		elif i.terrainType!=TileResource.TERRAIN_TYPE.WATER and previousType==TileResource.TERRAIN_TYPE.WATER :
			myAstar.set_point_disabled(get_point_index_ordered(i.tile_position),false)
			
	for entity in entities:
		
		if startAFire==true or randf()<clamp(atmosphere.temperature-50,0,50)/3000000. :
			startAFire=true
			while startAFire :
				var rndEntity =entities.pick_random()
				if rndEntity != null  and not rndEntity.entityResource.isOnFire: 
					startAFire=false
					rndEntity.burn()
		if entity !=null :
			if entity.entityResource.isOnFire :
				entity.entityResource.timeOnFire+=1
			for surroundingCenters in pointDictionnary[entity.entityResource.position] :
				for edgesToFire in centersDictionary[surroundingCenters] :
					if entities[get_edge_index(edgesToFire)]!=null and entity.entityResource.timeOnFire>100 and not entities[get_edge_index(edgesToFire)].entityResource.isOnFire : entities[get_edge_index(edgesToFire)].burn()
				
			var toDelete = true 
			for surroundingCenters in pointDictionnary[entity.entityResource.position] :
				if entity.entityResource.timeOnFire>300:
					toDelete=true
				elif entity.entityResource.entityType==EntityResource.ENTITY_TYPE.GRASS and tilesData[get_point_index_ordered(surroundingCenters)].terrainType!=TileResource.TERRAIN_TYPE.WATER :
					toDelete=false
				elif entity.entityResource.entityType==EntityResource.ENTITY_TYPE.CARROT and tilesData[get_point_index_ordered(surroundingCenters)].terrainType==TileResource.TERRAIN_TYPE.TALL_GRASS :
					toDelete=false
				elif (entity.entityResource.entityType==EntityResource.ENTITY_TYPE.TREE or entity.entityResource.entityType==EntityResource.ENTITY_TYPE.BUSH) and tilesData[get_point_index_ordered(surroundingCenters)].terrainType==TileResource.TERRAIN_TYPE.GRASS :
					toDelete=false
				elif (entity.entityResource.entityType==EntityResource.ENTITY_TYPE.STEAK ):#and tilesData[get_point_index_ordered(surroundingCenters)].terrainType!=TileResource.TERRAIN_TYPE.WATER) :
					entity.entityResource.steakCountdown-=1
#					print("steakCD : ", entity.entityResource.steakCountdown)
					toDelete=entity.entityResource.steakCountdown<0
			if toDelete or purge : 
				if purge : amountOfVegetation=0
				amountOfVegetation-=1 if entity.entityResource.entityType!=EntityResource.ENTITY_TYPE.STEAK else 0
				entity.queue_free()
		

func get_world():

	var res = []
	for i in tilesData : 
		res.push_back(i.get_color(atmosphere.temperature))
		res.push_back(i.get_color(atmosphere.temperature))
		res.push_back(i.get_color(atmosphere.temperature))
	return PackedColorArray(res)
