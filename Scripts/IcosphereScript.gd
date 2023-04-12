extends MeshInstance3D

# Instance de la classe personalisé WorldResource crée
# Elle centralise toutes les informations concernant la planète pour le reste de la simulation. 
@export var worldResource := WorldResource.new()

# Valeure permettant de définir la mesh à subdiviser afin de créer une sphère.
# (l'on a choisi de lui fournir un icosahèdre. 12 Sommets d'arretes de mêmes longeurs et 20 faces initialement )
@export var baseMesh : Mesh

# Références vers des tableaux nécéssaires à la recréation de la mesh de la planète. 
@export var normals := PackedVector3Array()
@export var colors := PackedColorArray()
@export var meshVertices := PackedVector3Array()


# Fonction qui génère le dictionaire qui à 3 points formant un triangle de la mesh lui associe le centre formé de ces 3 points
func generate_centers_dictionary():
	var points = {}
	worldResource.centersDictionary.clear()
	for i in range(meshVertices.size()/3):
		for j in range(3):
			for po in points.keys() :
				if meshVertices[i*3+j]!=po and (meshVertices[i*3+j]).distance_to(po)<0.0001 :
					meshVertices[i*3+j]=po
			points[(meshVertices[i*3+j])]=1
		worldResource.centersDictionary[(meshVertices[i*3+0]+meshVertices[i*3+1]+meshVertices[i*3+2])/3]=[meshVertices[i*3+0],meshVertices[i*3+1],meshVertices[i*3+2]]
	worldResource.points=points.keys()


# Fonction qui à un centre donné trouve les 3 centres voisins (un triangle a 3 cotés donc 3 voisins)
# Elle utilise le dictionnaire de la fonction précédente afin de savoir quels centres ont 2 points en commun avec celui donné en argument.
# Elle s'arrete prématurément si la recherche est finie. 
func get_center_nieghbours(centerCoordinates : Vector3 ):
	var amountOfPointsInCommon=0
	var neighboursArray = []
	for i in worldResource.centersDictionary.keys():
		if neighboursArray.size()==3: return neighboursArray
		if worldResource.centersDictionary[i]!=worldResource.centersDictionary[centerCoordinates] :
			if worldResource.centersDictionary[centerCoordinates].has(worldResource.centersDictionary[i][0]):
				amountOfPointsInCommon+=1
			if worldResource.centersDictionary[centerCoordinates].has(worldResource.centersDictionary[i][1]):
				amountOfPointsInCommon+=1
			if amountOfPointsInCommon==0 : continue
			if worldResource.centersDictionary[centerCoordinates].has(worldResource.centersDictionary[i][2]):
				amountOfPointsInCommon+=1
		if(amountOfPointsInCommon==2):
			neighboursArray.append(i)
		amountOfPointsInCommon=0
	return neighboursArray


# Fonction qui va faire calculer à un thread les voisins des centres allant de l'indice début à l'indice fin 
func call_from_to(startingIndex:int ,endIndex:int):
	for c in range(startingIndex,endIndex,1) :
		var center = worldResource.centersDictionary.keys()[c]
		worldResource.centersNeighboursDictionary[center]=get_center_nieghbours(center)


# Fonction qui prends un nombre de threads et va diviser le calcul de tout les triplets de voisins pour chaque voisin en un nombre égal d'indices et appeller "call_from_to" sur ces intervales.
func generate_neighbours_dictionary(nbThread : int):
	var threadArray = []
	var nbParts=worldResource.centersDictionary.size()/nbThread
	for i in range(nbThread) :
		threadArray.append(Thread.new())
		threadArray[threadArray.size()-1].start(func(): call_from_to(nbParts*i, nbParts*i+nbParts))
	#On wait les threads afin de les tuer.
	for t in threadArray :
		t.wait_to_finish()



# fonction qui va appliquer du bruit de perlin sur la mesh de la planète afin de créer du relièf
func apply_perlin_noise() :
	var newVerticesArray := PackedVector3Array()
	var noise = FastNoiseLite.new() 
	noise.noise_type=FastNoiseLite.TYPE_PERLIN
	noise.set_seed(worldResource.seed)

	newVerticesArray.resize(meshVertices.size())
	for j in range(meshVertices.size()) :
		newVerticesArray[j]=meshVertices[j].normalized()

	for i in newVerticesArray.size() :
		var heightValue = noise.get_noise_3d(newVerticesArray[i].x*200,newVerticesArray[i].y*200,newVerticesArray[i].z*200)/3+2
		newVerticesArray[i]=newVerticesArray[i]*heightValue
	meshVertices=newVerticesArray




# Fonction appelé depuis Planet afin d'intialiser l'icosphère
func init_icosphere():
	# Initialise l'instance vers la classe WordlResource et initialise certaines de ses valeures
	worldResource=WorldResource.new()
	worldResource.resolution=int($"%ResolutionLine".get_text())
	worldResource.seed=int($"%SeedLine".get_text())
	worldResource.waterHeight=1.96
	
	# Donne la valeur du niveau d'eau au shader qui s'occupe de mettre au bon niveau les points submergés
	material_override.set_shader_parameter("water_height",1.96)
	
	# Récupère les informations de la mesh donnée en tant que mesh de base dans baseMesh et les place dans des tableaux redimensionnés à la bonne taille
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(baseMesh,0)
	
	meshVertices.resize(mdt.get_vertex_count())
	normals.resize(mdt.get_vertex_count())

	for i in range(mdt.get_vertex_count()):
		meshVertices[i] = mdt.get_vertex(i)
		normals[i]=mdt.get_vertex_normal(i)

# Subdivise autant de fois que "resolution" la mesh de base, en transformant un triangle de la mesh en 4 triangles de tailles égals. 
	for i in range(worldResource.resolution):
		var new_vertices := PackedVector3Array()
		for j in range(meshVertices.size()/3):
			var a = meshVertices[j*3]
			var b = meshVertices[j*3+2]
			var c = meshVertices[j*3+1]
			var ab= a+(b-a)*.5
			var bc= b+(c-b)*.5
			var ca= c+(a-c)*.5
			new_vertices.append_array([a,ca,ab,ab,ca,bc,ca,c,bc,ab,bc,b])
		meshVertices=new_vertices
	for j in range(meshVertices.size()) :
		meshVertices[j]=meshVertices[j].normalized()

# Redimensionne les tableaux des normales et des couleures en fonction du nombre de points crées après les subdivisions
	normals.resize(meshVertices.size())
	colors.resize(meshVertices.size())

	# Applique le bruit de perlin sur la mesh, génère les 2 dicitionaires des centres puis initialise le "monde" dans l'instance de worldRessource
	apply_perlin_noise()
	generate_centers_dictionary()
	generate_neighbours_dictionary(4)
	worldResource.init_world($"%Atmosphere")


	# calcul les normales de la mesh comme étant un point normal à la surface d'un triangle ABC  par produit en croix entre le vecteur AB et AC
	for i in range(meshVertices.size()/3) :
		var n = -(meshVertices[i*3+0]-meshVertices[i*3+1]).cross(meshVertices[i*3+0]-meshVertices[i*3+2]).normalized()
		normals[i*3+0] =n
		normals[i*3+1] =n
		normals[i*3+2] =n

	# Crée la mesh correspondant aux valeures jusqu'alors obtenues.
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshVertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	# Génère le corps de collision de la planète nécessaires pour les agents et l'ajoute dans ses propriétés. 
	var collisionBody := StaticBody3D.new()
	var collisionShape := CollisionShape3D.new()
	add_child(collisionBody)
	collisionBody.add_child(collisionShape)
	collisionBody.owner = self
	collisionShape.owner = self
	collisionShape.shape=mesh.create_trimesh_shape()


# Fonction de mise à jour appelé depuis Planet qui va reconstruire la mesh de la planète.
# Et appeler sur l'instance de WorldResource la fonction qui va mettre à jour les informations dans celle-ci 
# Puis va actualiser la valeure du niveau d'eau donnée au shader 
func update():
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshVertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	worldResource.update_world_resource()
	arrays[Mesh.ARRAY_COLOR] = worldResource.get_world()
	
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	material_override.set_shader_parameter("water_height",worldResource.waterHeight)



# Fonction appelée seulement si un bouton de l'interface est pressé, elle appel la fonction de mise à jour avec une valeure lui indiquant qu'il faut supprimer toutes les entités
func _on_purge_pressed():
	worldResource.update_world_resource(true)

# Fonction appelée seulement si un bouton de l'interface est pressé, elle appel la fonction de mise à jour avec une valeure lui indiquant qu'il faut allumer un feu sur une entité quelconque.
func _on_fire_pressed():
	worldResource.update_world_resource(false,true)
