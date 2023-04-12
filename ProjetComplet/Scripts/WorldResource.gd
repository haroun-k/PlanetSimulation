class_name WorldResource extends Resource

class SetFile :

	var file : Array

	func _init() -> void :
		self.file = []

	func enfiler(e : TileResource) -> void :
		if e.is_undefined() && e not in self.file:
			self.file.push_back(e)
			
	func enfiler_unchecked(e : TileResource) -> void :
		self.file.push_back(e)

	func defiler() : # -> type contenu dans l'array (ici un Tile)
		if self.file.size() > 0 :
			return self.file.pop_front()
		else :
			return null

	func est_vide() -> bool :
		return self.file.size() == 0

#Variables de la planete
@export var resolution :int
@export var seed : int
@export var waterHeight : float
@export var maxAmountOfVegetation : int
@export var amountOfVegetation : int 

#Variable pour le systeme de coordonnees
@export var points : Array = [null]
@export var pointDictionnary : Dictionary
@export var centersDictionary : Dictionary
@export var centersNeighboursDictionary := {}

#La surface de la planete avec les tiles et les entites
@export var tilesData : Array[TileResource]
@export var updateTilesArray : Array[TileResource]
@export var entities : Array[Entity]

var atmosphere #Reference a l'atmosphere de la planete
	
func find_edge(pt : Vector3) -> int : 
	return points.find(pt)
	
func find_point_centersDict(center : Vector3) -> int: 
	return centersDictionary.keys().find(center)

func init_world(atmo : MeshInstance3D) -> void:
	
	self.atmosphere = atmo
	entities.resize(points.size())
	
	#Initialisation des tiles avec des tilesRessource, et l'array contenant toutes les tiles
	tilesData.clear()
	var ki = 0 #Equivalent a un enumerate(centersDicrionary.keys()) sauf que Godot n'a pas cette fonctionalite
	var clefs = centersDictionary.keys()
	for k in clefs :
		tilesData.push_back(TileResource.new())
		tilesData[ki].tilePosition=k
		tilesData[ki].init_tile(waterHeight)
		ki+=1
	ki = 0
	
	
	var tiles_a_traiter = SetFile.new()
	
	#Initialisation des voisins pour le tileRessource
	for i in range(centersNeighboursDictionary.size()) :
		var voisins = centersNeighboursDictionary[clefs[i]]
		tilesData[i].neighbours=[
						tilesData[find_point_centersDict(voisins[0])],
						tilesData[find_point_centersDict(voisins[1])],
						tilesData[find_point_centersDict(voisins[2])]
						]
	
	#On enfile tous les voisins de cases d'eau car eux pourront etre initialise (donc moins de renfilage)
	for tile in tilesData :
		if tile.is_water():
			for n in tile.neighbours :
				tiles_a_traiter.enfiler(n)
		
	#On enfile le reste des cases
	for tile in tilesData:
		if tile.is_undefined():
			tiles_a_traiter.enfiler(tile)
	
	#On collapse toutes les tiles une premiere fois
	while not tiles_a_traiter.est_vide() :
		var tile = tiles_a_traiter.defiler()
		if tile.collapse_tile(atmosphere.temperature):
			tiles_a_traiter.enfiler_unchecked(tile)
			
	#Pour etre sur que tout le monde fu traite		
	for tile in tilesData:
		if tile.is_undefined():
			tile.collapse_tile(atmosphere.temperature)
	
	#On initialise le dictionnaire des points pour les entites
	for cent in centersDictionary:
		for pt in centersDictionary[cent] :
			if not pointDictionnary.keys().has(pt) :
				pointDictionnary[pt]=[]
			else :
				pointDictionnary[pt] = pointDictionnary[pt] + [cent] 
	
	#Mise a jour asychrone avec ordre random			
	updateTilesArray=tilesData.duplicate(true)
	updateTilesArray.shuffle()
	
	generate_astar()
	
func get_entities_on_tile(position: Vector3) -> Array[Entity]:
	var arr : Array[Entity] = []
	for pts in centersDictionary[position]:
		if entities[find_edge(pts)] != null : 
			arr.push_back(entities[find_edge(pts)])
	return arr


func spawn_steak(world : Node3D, deathPos:Vector3, specieOrigin : int) -> void :
	for entityPos in centersDictionary[deathPos] : #On essaye de mettre l'entite sur un des bords de la case ou l'agent est mort
		if entities[find_edge(entityPos)] == null : #S'il n'y a pas d'entites deja presentes
			init_entity(entityPos, EntityResource.ENTITY_TYPE.STEAK,specieOrigin)
			world.add_child(entities[find_edge(entityPos)])
			return
			
var spree : bool = false #Utilise pour remplir la planete d'entites

func spawn_entities(world : Node3D) -> void:
	
	for td in updateTilesArray :

		var entityPos = centersDictionary[td.tilePosition].pick_random()

		if entities[find_edge(entityPos)] == null:
			#Spawn petit a petit aleatoirement ou [Fill entities]
			if (not spree and randf()<(1-(amountOfVegetation/maxAmountOfVegetation))/10000.0) or (spree and amountOfVegetation<maxAmountOfVegetation) : 
				var new_vegetation = 1

				if td.is_tall_grass() :
					init_entity(entityPos, EntityResource.ENTITY_TYPE.CARROT)
					world.add_child(entities[find_edge(entityPos)])

				elif td.is_grass() :
					if randf()<0.5 :
						init_entity(entityPos, EntityResource.ENTITY_TYPE.TREE)
					else :
						init_entity(entityPos, EntityResource.ENTITY_TYPE.BUSH)
					world.add_child(entities[find_edge(entityPos)])

				elif not td.is_water() :
					init_entity(entityPos,EntityResource.ENTITY_TYPE.GRASS)
					world.add_child(entities[find_edge(entityPos)])

				else:
					new_vegetation = 0

				amountOfVegetation+=new_vegetation
				
	spree=false #On remprend normalement apres un remplissage
		

func init_entity(pos : Vector3, typ : EntityResource.ENTITY_TYPE, specieOrigin : int=0) -> void:
	entities[find_edge(pos)]=Entity.new(pos,typ,specieOrigin)
	
	
#Pathfinding des agents	avec l'algorithme du A*
var myAstar : AStar3D = AStar3D.new() 
	
func generate_astar() -> void:

	#On ajoute tous les points disponnibles
	for i in centersNeighboursDictionary.keys(): 
		var idi = find_point_centersDict(i)
		myAstar.add_point(idi,i)
		
		#On connecte les voisins entre eux
		for j in centersNeighboursDictionary[i] :
			var idj = find_point_centersDict(j)
			myAstar.add_point(idj,j)
			myAstar.connect_points(idi,idj)
			
		#On invalide les cases avec de l'eau	
			if tilesData[idj].is_water() : 
				myAstar.set_point_disabled(idj, true)
		if tilesData[idi].is_water() : 
			myAstar.set_point_disabled(idi, true)


# Mise a jour du monde
var nbCasesUpdated = 0

func update_world_resource(purge : bool=false, startAFire:bool=false):

	#On collapse 15 tiles au hasard
	for i in range(15) :
		nbCasesUpdated+=1
		#On re-shuffle les cases a traiter quand on a fait le tour
		if nbCasesUpdated >= tilesData.size() :
			nbCasesUpdated = 0
			updateTilesArray.shuffle()
		updateTilesArray[nbCasesUpdated].collapse_tile(atmosphere.temperature)

	# On met a jour les infos des cases et on update le Astar si une case a ete submergee ou immergee
	for tile in updateTilesArray :
		var previousType=tile.terrainType
		tile.update_tile(waterHeight, atmosphere.temperature)
		if tile.is_water() and previousType!=TileResource.TERRAIN_TYPE.WATER :
			myAstar.set_point_disabled(find_point_centersDict(tile.tilePosition))
		elif not tile.is_water() and previousType==TileResource.TERRAIN_TYPE.WATER :
			myAstar.set_point_disabled(find_point_centersDict(tile.tilePosition),false)
	
	# Demarrage du feu avec une faible probabilite en fonction de la temperature ou [Start a fire]
	if startAFire or randf()<clamp(atmosphere.temperature-30,0,20)/100000. :
		startAFire=true
		# On cherche une entite qui n'est pas deja en feu
		while startAFire :
			var rndEntity=entities.pick_random()
			if rndEntity != null and not rndEntity.entityResource.isOnFire: 
				startAFire=false
				rndEntity.burn()

	# On met a jour les entites non null
	for entity in entities.filter( func(x) : return x!=null ) :

		# Gestion du feu
		if entity.entityResource.isOnFire :
			entity.entityResource.timeOnFire+=1
			if (not atmosphere.temperature<10) : 
				for surroundingCenters in pointDictionnary[entity.entityResource.position] :
					for edgesToFire in centersDictionary[surroundingCenters] :
						if entities[find_edge(edgesToFire)]!=null and entity.entityResource.timeOnFire>100 and not entities[find_edge(edgesToFire)].entityResource.isOnFire : 
							entities[find_edge(edgesToFire)].burn()

		# Gestion de la mort/vie
		var toDelete = true 
		for surroundingCenters in pointDictionnary[entity.entityResource.position] :
			
			if entity.is_grass() and not tilesData[find_point_centersDict(surroundingCenters)].is_water() :
				toDelete=false
			elif entity.is_carrot() and tilesData[find_point_centersDict(surroundingCenters)].is_tall_grass() :
				toDelete=false
			elif (entity.is_tree() or entity.is_bush()):
				var case_dessus = tilesData[find_point_centersDict(surroundingCenters)]
				if case_dessus.is_grass() or case_dessus.is_tall_grass() :
					toDelete=false
			elif entity.is_steak(): 
				entity.entityResource.steakCountdown-=1
				toDelete=entity.entityResource.steakCountdown<0

			if entity.entityResource.timeOnFire>300: #Brule trop longtemps
				toDelete=true

		if toDelete or purge : #On supprime l'entite
			if not entity.is_steak() :
				amountOfVegetation-=1
			if purge : 
				amountOfVegetation=0
			entity.queue_free()
		

# Pour la couleur de la mesh
func get_world():
	var res = []
	for tile in tilesData : 
		res.push_back(tile.get_color(atmosphere.temperature))
		res.push_back(tile.get_color(atmosphere.temperature))
		res.push_back(tile.get_color(atmosphere.temperature))
	return PackedColorArray(res)
