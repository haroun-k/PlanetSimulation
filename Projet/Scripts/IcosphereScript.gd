extends MeshInstance3D

@export var worldResource := WorldResource.new()

@export var baseMesh : Mesh
@export var resolution : int
@export var normals := PackedVector3Array()
@export var colors := PackedColorArray()
@export var meshVertices := PackedVector3Array()

'''
func generate_centers_dictionary() :
	# Calcule les centres des triangles du mesh
	worldResource.centersDictionary.clear()
	for i in range(0,meshVertices.size(),3):
		worldResource.centersDictionary[(meshVertices[i]+meshVertices[i+1]+meshVertices[i+2])/3]=[meshVertices[i+0],meshVertices[i+1],meshVertices[i+2]]

	worldResource.centersDictionary.clear()
	for i in range(meshVertices.size()/3):
		worldResource.centersDictionary[(meshVertices[i*3+0]+meshVertices[i*3+1]+meshVertices[i*3+2])/3]=[meshVertices[i*3+0],meshVertices[i*3+1],meshVertices[i*3+2]]
func generate_centers_neighbours_partial(keys : PackedVector3Array, start : int, end : int):
	# Calcule les voisins du start-ieme centre au end-ieme centre en utilisant la distance constante entre 2 voisins.
	for k in range(start,end):

		# Trouve les 3 centres les plus proches
		var neighbours = [keys[k],keys[k],keys[k]]
		var dists = [999,999,999]
		for i in range(0,keys.size()):
			if i!=k:
				var d = keys[i].distance_to(keys[k])
				if d < dists[0] :
					dists[0] = d
					neighbours[0] = keys[i]
				elif d < dists[1] :
					dists[1] = d
					neighbours[1] = keys[i]
				elif d < dists[2] :
					dists[2] = d
					neighbours[2] = keys[i]

		self.centersNeighboursDictionary[keys[k]] = neighbours

func generate_centers_neighbours():
	# Calcule la distance entre 2 voisins et calcule les voisins de tous les centres 

	worldResource.centersNeighboursDictionary = worldResource.centersDictionary.duplicate()
	const DIVISIONS = 64 # Nombre de threads

	var taille = worldResource.centersNeighboursDictionary.size()
	var keys = worldResource.centersNeighboursDictionary.keys()
	var slices = []

	# Repartition : chaque thread calcule les voisins de la ieme partie des centres
	for i in DIVISIONS:
		slices.append(int(float(taille*i)/DIVISIONS))
	slices.append(taille)
	
	# Creation et lancement des threads
	var threads = []
	for t in DIVISIONS :
		threads.append(Thread.new())
		threads[threads.size() - 1].start( func() : generate_centers_neighbours_partial(keys, slices[t], slices[t+1]))

	# Attente de la fin des threads
	for t in threads :
		t.wait_to_finish()'''

func generate_centers_dictionary():
	worldResource.centersDictionary.clear()
	for i in range(meshVertices.size()/3):
		worldResource.centersDictionary[(meshVertices[i*3+0]+meshVertices[i*3+1]+meshVertices[i*3+2])/3]=[meshVertices[i*3+0],meshVertices[i*3+1],meshVertices[i*3+2]]
		
		
func get_center_neighbours_d(center :Vector3):
	var neighbours=[]
	for i in worldResource.centersDictionary.keys():
		if i!=center:
			neighbours.push_back(i)
			for j in neighbours :
				var greatest = 0
				for n in range(neighbours.size()):
					if neighbours[n].distance_to(center) > neighbours[greatest].distance_to(center) :
						greatest=n
				if neighbours.size()>3 :
					neighbours.erase(neighbours[greatest])
	return neighbours
	
	
func generate_centers_neighbours():
	for center in worldResource.centersDictionary.keys() :
		worldResource.centersNeighboursDictionary[center]=get_center_neighbours_d(center)
	for c in worldResource.centersNeighboursDictionary.keys() :
		print("LE POINT : ",worldResource.centersDictionary.keys().find(c))
		print(" V : ")
		for cv in worldResource.centersNeighboursDictionary[c] :
			print(worldResource.centersDictionary.keys().find(cv))
		print(" _____________________________________ ")


func init_icosphere():
	worldResource=WorldResource.new()
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(baseMesh,0)
	meshVertices.resize(mdt.get_vertex_count())
	normals.resize(mdt.get_vertex_count())

	for i in range(mdt.get_vertex_count()):
		meshVertices[i] = mdt.get_vertex(i)
		normals[i]=mdt.get_vertex_normal(i)


	for i in range(resolution):
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
	normals.resize(meshVertices.size())
	colors.resize(meshVertices.size())

	generate_centers_dictionary()
	generate_centers_neighbours()
	worldResource.init_world()

	for i in range(meshVertices.size()/3) :
		var n = -(meshVertices[i*3+0]-meshVertices[i*3+1]).cross(meshVertices[i*3+0]-meshVertices[i*3+2]).normalized()
		normals[i*3+0] =n
		normals[i*3+1] =n
		normals[i*3+2] =n

	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshVertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	var collisionBody := StaticBody3D.new()
	var collisionShape := CollisionShape3D.new()
	add_child(collisionBody)
	collisionBody.add_child(collisionShape)
	collisionBody.owner = self
	collisionShape.owner = self
	collisionShape.shape=mesh.create_trimesh_shape()

func update():
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshVertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	arrays[Mesh.ARRAY_COLOR] = worldResource.colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
