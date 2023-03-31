extends MeshInstance3D

@export var worldResource := WorldResource.new()

@export var baseMesh : Mesh
@export var resolution : int
@export var normals := PackedVector3Array()
@export var colors := PackedColorArray()
@export var meshVertices := PackedVector3Array()


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



func get_center_nieghbours(centerCoo : Vector3 ):
	var nbCoressp=0
	var neig = []
	for i in worldResource.centersDictionary.keys():
		if neig.size()==3: return neig
		if worldResource.centersDictionary[i]!=worldResource.centersDictionary[centerCoo] :
			if worldResource.centersDictionary[centerCoo].has(worldResource.centersDictionary[i][0]):
				nbCoressp+=1
			if worldResource.centersDictionary[centerCoo].has(worldResource.centersDictionary[i][1]):
				nbCoressp+=1
			if nbCoressp==0 : continue
			if worldResource.centersDictionary[centerCoo].has(worldResource.centersDictionary[i][2]):
				nbCoressp+=1
		if(nbCoressp==2):
			neig.append(i)
		nbCoressp=0
	return neig
	

func slice(debut:int ,fin:int):
	for c in range(debut,fin,1) :
		var center=worldResource.centersDictionary.keys()[c]
		worldResource.centersNeighboursDictionary[center]=get_center_nieghbours(center)
	
func generate_neighbours_dictionary(nbThread : int):
	var threads = []
	var nbParts=worldResource.centersDictionary.size()/nbThread
	for i in range(nbThread) :
		threads.append(Thread.new())
		threads[threads.size()-1].start(func(): slice(nbParts*i, nbParts*i+nbParts))
	for t in threads :
		t.wait_to_finish()
#	worldResource.centersDictionary=worldResource.centersNeighboursDictionary.keys()




func heighten() :
	var vert := PackedVector3Array()

	vert.resize(meshVertices.size())
	for j in range(meshVertices.size()) :
		vert[j]=meshVertices[j].normalized()

	var noise = FastNoiseLite.new() 
	noise.noise_type=FastNoiseLite.TYPE_PERLIN
	noise.set_seed(worldResource.seed)
	

	for i in vert.size() :
		var h1 = noise.get_noise_3d(vert[i].x*200,vert[i].y*200,vert[i].z*200)/3+2
		vert[i]=vert[i]*h1
	meshVertices=vert




func init_icosphere():

	worldResource=WorldResource.new()
	worldResource.resolution=int($"%ResolutionLine".get_text())
	worldResource.seed=int($"%SeedLine".get_text())
	worldResource.waterHeight=1.96
	material_override.set_shader_parameter("water_height",1.96)
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(baseMesh,0)
	meshVertices.resize(mdt.get_vertex_count())
	normals.resize(mdt.get_vertex_count())

	for i in range(mdt.get_vertex_count()):
		meshVertices[i] = mdt.get_vertex(i)
		normals[i]=mdt.get_vertex_normal(i)


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
	normals.resize(meshVertices.size())
	colors.resize(meshVertices.size())



	heighten()
	generate_centers_dictionary()
	generate_neighbours_dictionary(4)
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
	worldResource.waterHeight+=0.0001
	material_override.set_shader_parameter("water_height",worldResource.waterHeight)
