@tool
extends MeshInstance3D


@export var baseMesh : Mesh
@export var resolution : int :
	set(v):
		resolution=v
		if Engine.is_editor_hint() : initial()
@export var refVertices : Array

@export var uvs = PackedVector2Array()
@export var normals = PackedVector3Array()
@export var colors = PackedColorArray()
@export var meshVertices = PackedVector3Array()

@export var centersDictionary = {}
@export var centersNeighboursDictionary = {}

@export var test_texture : ImageTexture
@export var pointsData : Array
	

func generate_centers_dictionary() :
	# Calcule les centres des triangles du mesh
	centersDictionary.clear()
	for i in range(0,meshVertices.size(),3):
		centersDictionary[(meshVertices[i]+meshVertices[i+1]+meshVertices[i+2])/3]=[meshVertices[i+0],meshVertices[i+1],meshVertices[i+2]]


func find_min_distance() -> float :
	# Calcule la distance minimale entre 2 centres
	var min_dist = 1000.0
	var current_dist
	
	# On trouve le centre le plus proche du centre 0
	for i in range(1,centersDictionary.size()):
		current_dist = centersDictionary.keys()[0].distance_to(centersDictionary.keys()[i])
		if current_dist < min_dist :
			min_dist = current_dist
	return min_dist


func generate_centers_neighbours_partial(keys : PackedVector3Array, start : int, end : int, dist : float):
	# Calcule les voisins du start-ieme centre au end-ieme centre en utilisant la distance constante entre 2 voisins.
	for k in range(start,end):

		var neighbours = [Vector3(9,9,9),Vector3(9,9,9),Vector3(9,9,9)]
		var found_neighbours = 0
		var distance = 1000.0
		var i = 0

		# Recherche de ses 3 voisins
		while found_neighbours < 3 :
			if i!=k : # On ne prend pas en compte le centre lui-meme
				distance = keys[i].distance_to(keys[k])
				if abs(distance - dist) < 0.02: # Approximation a cause des erreurs d'arrondi des floats
					neighbours[found_neighbours] = keys[i]
					found_neighbours += 1
			i+=1

		centersNeighboursDictionary[keys[k]] = neighbours

func generate_centers_neighbours():
	# Calcule la distance entre 2 voisins et calcule les voisins de tous les centres 

	centersNeighboursDictionary.clear()
	const DIVISIONS = 64 # Nombre de threads

	var taille = centersDictionary.size()
	var keys = centersDictionary.keys()
	var distance_min = find_min_distance()
	var slices = []

	# Repartition : chaque thread calcule les voisins de la ieme partie des centres
	for i in DIVISIONS:
		slices.append(int(float(taille*i)/DIVISIONS))
	slices.append(taille)
	
	# Creation et lancement des threads
	var threads = []
	for t in DIVISIONS :
		threads.append(Thread.new())
		threads[threads.size() - 1].start( func() : generate_centers_neighbours_partial(keys, slices[t], slices[t+1], distance_min))

	# Attente de la fin des threads
	for t in threads :
		t.wait_to_finish()
	

func initial():

	# Initialisation du mesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(baseMesh,0)

	# Redimensionnage des tableaux du mesh (vertices, uvs, normals, colors)
	meshVertices.resize(mdt.get_vertex_count())
	uvs.resize(mdt.get_vertex_count())
	normals.resize(mdt.get_vertex_count())

	# Remplissage des tableaux du mesh
	for i in range(mdt.get_vertex_count()):
		meshVertices[i] = mdt.get_vertex(i)
		uvs[i]=mdt.get_vertex_uv(i)
		normals[i]=mdt.get_vertex_normal(i)

	# Subdivision du mesh
	for i in range(resolution):
		var new_vertices = PackedVector3Array()
		var new_uvs = PackedVector2Array()
		for j in range(0,meshVertices.size(),3):

			var a = meshVertices[j]
			var b = meshVertices[j+2]
			var c = meshVertices[j+1]
			var ab= a+(b-a)*.5
			var bc= b+(c-b)*.5
			var ca= c+(a-c)*.5
		
			var uv_a = uvs[j]
			var uv_b = uvs[j+2]
			var uv_c = uvs[j+1]
			var uv_ab= uv_a+(uv_b-uv_a)*.5
			var uv_bc= uv_b+(uv_c-uv_b)*.5
			var uv_ca= uv_c+(uv_a-uv_c)*.5

			new_uvs.append_array([uv_a,uv_ca,uv_ab,uv_ab,uv_ca,uv_bc,uv_ca,uv_c,uv_bc,uv_ab,uv_bc,uv_b])
			new_vertices.append_array([a,ca,ab,ab,ca,bc,ca,c,bc,ab,bc,b])

		meshVertices=new_vertices
		uvs=new_uvs

	# Normalisation des vertices
	for j in range(meshVertices.size()) :
		meshVertices[j]=meshVertices[j].normalized()

	# Creation du mesh
	normals.resize(meshVertices.size())
	colors.resize(meshVertices.size())
	mdt.create_from_surface(mesh,0)

	# Generation des centres et des voisins
	generate_centers_dictionary()
	generate_centers_neighbours()
	
	# Calcul des normales
	for i in range(0,meshVertices.size(),3) :
		var n = -(meshVertices[i]-meshVertices[i+1]).cross(meshVertices[i]-meshVertices[i+2]).normalized()
		normals[i] = n
		normals[i+1] = n
		normals[i+2] = n

	# Creation du mesh avec les textures
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshVertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	# Creation du corps physique
	var collisionBody := StaticBody3D.new()
	var collisionShape := CollisionShape3D.new()
	add_child(collisionBody)
	collisionBody.add_child(collisionShape)
	collisionBody.owner = self
	collisionShape.owner = self
	collisionShape.shape=mesh.create_trimesh_shape()

func _ready():
	initial()

func _process(delta):
	pass
