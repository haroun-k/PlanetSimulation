@tool
extends MeshInstance3D


@export var baseMesh : Mesh
@export var resolution :int:
	set(v):
		resolution=v
		if Engine.is_editor_hint() : initial()
@export var refVertices : Array

@export var uvs := PackedVector2Array()
@export var normals := PackedVector3Array()
@export var colors := PackedColorArray()
@export var meshVertices := PackedVector3Array()

@export var pointNeighbours :={}
@export var equivalentPoints :={}
@export var centersDictionary := {}
@export var centersNeighboursDictionary := {}

@export var test_texture : ImageTexture
@export var pointsData : Array

func get_vector_index(vect:Vector3) -> int:
	for i in range(refVertices.size()):
		if vect==refVertices[i]:
			return i
	return -1


func cartesian_to_spherical(vector:Vector3):
	var r = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
	var theta = atan2(vector.y, vector.x)
	var phi = atan2(sqrt(vector.x * vector.x + vector.y * vector.y), vector.z)
	return Vector3(r, theta, phi)

func generate_centers_dictionary():
	centersDictionary.clear()
	for i in range(meshVertices.size()/3):
		centersDictionary[(meshVertices[i*3+0]+meshVertices[i*3+1]+meshVertices[i*3+2])/3]=[meshVertices[i*3+0],meshVertices[i*3+1],meshVertices[i*3+2]]

func generate_random_data():
	pointsData.clear()
	for i in centersDictionary.size():
		pointsData.append(1)
		if(randf()<0.2):
			pointsData[i]=0

func get_center_neighbours(centerCoo : Vector3 ):
	var nbCoressp=0
	var neig = []
	for i in centersDictionary.keys():
		if centersDictionary[i]!=centersDictionary[centerCoo] :
			if centersDictionary[centerCoo].has(centersDictionary[i][0]):
				nbCoressp+=1
			if centersDictionary[centerCoo].has(centersDictionary[i][1]):
				nbCoressp+=1
			if centersDictionary[centerCoo].has(centersDictionary[i][2]):
				nbCoressp+=1
		if(nbCoressp==2):
			neig.append(i)
		nbCoressp=0
	
	
	return neig
func generate_centers_neighbours():
	for center in centersDictionary.keys() :
		centersNeighboursDictionary[center]=get_center_neighbours_d(center)
		

func get_uniq_array():
	var uniq={}
	var toAdd=true
	for i in range(meshVertices.size()):
		toAdd=true
		for j in uniq.size():
			if meshVertices[i].distance_to(uniq.keys()[j])<0.02:
				toAdd=false
		if(toAdd):
			uniq[meshVertices[i]]=0
			
	return uniq.keys()
	
func get_equivalents():
	var equivalents={}
	for i in range(meshVertices.size()):
		equivalents[i]=[]
		for j in meshVertices.size():
			if meshVertices[i].distance_to(meshVertices[j])<0.002:
				var eQ=Array(equivalents[i])
				eQ.append(j)
				equivalents[i]=( eQ )
	return equivalents
	
func get_all_point_neighbours(vertices:PackedVector3Array):
	var neighbours={}
	for i in range(refVertices.size()):
		neighbours[i]=get_point_neighbours_d(i)
	return neighbours

	
func get_distance(vertices:Array):
	var minimalDistance=2
	for i in range(vertices.size()):
		for j in range(vertices.size()):
			if(vertices[i].distance_to(vertices[j])<minimalDistance and vertices[i].distance_to(vertices[j])>0.02):
				minimalDistance=vertices[i].distance_to(vertices[j])
	return minimalDistance+0.0002

	
func get_center_neighbours_d(center :Vector3):
	var neighbours=[]
	for i in centersDictionary.keys():
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
	
func get_point_neighbours_d(vertex:int):
	var neighbours={}
	var toAdd=true
	for i in range(meshVertices.size()):
		toAdd=true
		if meshVertices[i]!=meshVertices[vertex] and meshVertices[i].distance_to(meshVertices[vertex])>0.02 and meshVertices[i].distance_to(meshVertices[vertex])<=1.4/(2**resolution) :
			for j in neighbours.keys():
				if meshVertices[i].distance_to(meshVertices[j])<0.02:
					toAdd=false
			if(toAdd):
				neighbours[i]=0
#			neighbours[i]=0
#			notToAdd=false
			
	return neighbours.keys()
	
func initial():
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(baseMesh,0)


	meshVertices.resize(mdt.get_vertex_count())
	uvs.resize(mdt.get_vertex_count())
	normals.resize(mdt.get_vertex_count())
	

	for i in range(mdt.get_vertex_count()):
		meshVertices[i] = mdt.get_vertex(i)
		uvs[i]=mdt.get_vertex_uv(i)
		normals[i]=mdt.get_vertex_normal(i)


	for i in range(resolution):
		var new_vertices := PackedVector3Array()
		var new_uvs := PackedVector2Array()
		for j in range(meshVertices.size()/3):
			var a = meshVertices[j*3]
			var b = meshVertices[j*3+2]
			var c = meshVertices[j*3+1]
			var ab= a+(b-a)*.5
			var bc= b+(c-b)*.5
			var ca= c+(a-c)*.5
		
			var uv_a = uvs[j*3]
			var uv_b = uvs[j*3+2]
			var uv_c = uvs[j*3+1]
			var uv_ab= uv_a+(uv_b-uv_a)*.5
			var uv_bc= uv_b+(uv_c-uv_b)*.5
			var uv_ca= uv_c+(uv_a-uv_c)*.5

			new_uvs.append_array([uv_a,uv_ca,uv_ab,uv_ab,uv_ca,uv_bc,uv_ca,uv_c,uv_bc,uv_ab,uv_bc,uv_b])
			new_vertices.append_array([a,ca,ab,ab,ca,bc,ca,c,bc,ab,bc,b])
		meshVertices=new_vertices
		uvs=new_uvs
	
	
	

	for j in range(meshVertices.size()) :
		meshVertices[j]=meshVertices[j].normalized()

	normals.resize(meshVertices.size())
	colors.resize(meshVertices.size())
	
	
	
	mdt.create_from_surface(mesh,0)
	refVertices=get_uniq_array()
	pointNeighbours=get_all_point_neighbours(meshVertices)
	equivalentPoints=get_equivalents()
	generate_centers_dictionary()
	generate_centers_neighbours()
	generate_random_data()
	
	
	
	
	
	for i in range(meshVertices.size()/3) :
		var n = -(meshVertices[i*3+0]-meshVertices[i*3+1]).cross(meshVertices[i*3+0]-meshVertices[i*3+2]).normalized()
		normals[i*3+0] =n
		normals[i*3+1] =n
		normals[i*3+2] =n
		if pointsData[i]==0 :
			colors[i*3+0] = Color.MEDIUM_TURQUOISE
			colors[i*3+1] = Color.MEDIUM_TURQUOISE
			colors[i*3+2] = Color.MEDIUM_TURQUOISE
		else :
			colors[i*3+0] = Color.LIGHT_GREEN
			colors[i*3+1] = Color.LIGHT_GREEN
			colors[i*3+2] = Color.LIGHT_GREEN

	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = meshVertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	var collisionBody := StaticBody3D.new()
	var collisionShape := CollisionShape3D.new()
	add_child(collisionBody)
	collisionBody.add_child(collisionShape)
	collisionBody.owner = self
	collisionShape.owner = self
	collisionShape.shape=mesh.create_trimesh_shape()
	
#	var img=Image.create(100,100,false,Image.FORMAT_RGB8)
#	img.fill(Color(0.31, 0.23, 0.16))
#
#
#	for pointUV in range(refVertices.size()):
#		var teX = img.get_width()*uvs[pointUV].x if img.get_width()*uvs[pointUV].x !=img.get_width() else img.get_width()-1
#		var teY = img.get_height()*uvs[pointUV].y if img.get_height()*uvs[pointUV].y !=img.get_height() else img.get_height()-1
#		var colorPoint=Color(randf(),randf(),randf())
#		img.set_pixel(teX,teY,Color(randf(),randf(),randf()))
#
#
#		for i in equivalentPoints[pointUV]:


#			teX = img.get_width()*uvs[i].x if img.get_width()*uvs[i].x !=img.get_width() else img.get_width()-1
#			teY = img.get_height()*uvs[i].y if img.get_height()*uvs[i].y !=img.get_height() else img.get_height()-1
#			img.set_pixel(teX,teY,colorPoint)
#	test_texture= ImageTexture.create_from_image(img)
#
#	material_override.set_shader_parameter("test_texture",test_texture)
	


func _ready():
	initial()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
