@tool
extends MeshInstance3D


# export de différentes variables pour définir le comportement du code

# seed pour la génération procédurale de l'altitude des points
@export_range(0,400,1) var NoiseSeed : int :
	set(v) :
		NoiseSeed=v
		compute_icosphere()
		

# Mesh de base sur la quelle les subdivisions vont se faire 
@export var baseMesh : Mesh

# Dictionnaire pour instancier de manière unique tout les points de la mesh 
@export var refVertices := {}

# nombre de subdivisions désiré
@export_range(0,7,1) var resolution : int :
	set(v) :
		resolution=v
		compute_icosphere()

# hauteur de l'eau ( synchronisée avec la hauteur définie dans le shader (à ne pas changer par là)
@export var water_height : float = material_override.get_shader_parameter("water_height")
 


# fonction qui rends le tableau de tableau des voisins 
func get_neighbours():
	
	
	refVertices.clear()
	var vertices = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var uniq_verts := []
	var association := []
	association.resize(vertices.size())
	
	var v_index = 0
	for v in vertices :
		var found_index = -1
		var unv_index = 0
		for unv in uniq_verts :
			unv_index+=1
			if (v-unv).length()<0.001 : found_index = unv_index
		if found_index>=0 : association[v_index] = found_index
		else :
			uniq_verts.append(v)
			association[v_index] = uniq_verts.size()-1
		v_index+=1


	var neighbours = {}
	print("______________TABLEAU REF______________")
#	print(refVertices)
	print("________________________________________")
#	print(" taille de voisins : ", neighbours.size())
	print(" taille de uniq_verts : ", uniq_verts.size())
	
	print("\n Liste des triangles :")
#	for ind in vertices.size()/3 :
#		print("[",refVertices.keys().find(vertices[ind*3]), "->", vertices[ind*3], ",",refVertices.keys().find(vertices[ind*3+1]), "->", vertices[ind*3+1] ,",",refVertices.keys().find(vertices[ind*3+2]), "->", vertices[ind*3+2],"]  | ")
#
	for i in range(association.size()) :
		var i0 = i - posmod(i,3)
		for j in range(3) :
			if i0+j==i : continue
			if not association[i0+j] in neighbours :
				neighbours[association[i0+j]] = [association[i]]
			else :
				if not association[i] in neighbours[association[i0+j]] :
					neighbours[association[i0+j]].push_back(association[i])
#		print("__pt",firstPointOfTriangleIndex," : vecteur correspondant : ",vertices[firstPointOfTriangleIndex])
#		print("Indice dans le tableau refVertices = ",refVertices.find(vertices[firstPointOfTriangleIndex]))
#		var keys = refVertices.keys()
#		if( not ((keys.find(vertices[firstPointOfTriangleIndex*3+1])) in neighbours[keys.find(vertices[firstPointOfTriangleIndex*3])])) :
#				neighbours[keys.find(vertices[firstPointOfTriangleIndex*3])].append((keys.find(vertices[firstPointOfTriangleIndex*3+1])))
#		if( not ((keys.find(vertices[firstPointOfTriangleIndex*3+2])) in neighbours[keys.find(vertices[firstPointOfTriangleIndex*3])])) :
#				neighbours[keys.find(vertices[firstPointOfTriangleIndex*3])].append((keys.find(vertices[firstPointOfTriangleIndex*3+2])))
#
#		if( not ((keys.find(vertices[firstPointOfTriangleIndex*3])) in neighbours[keys.find(vertices[firstPointOfTriangleIndex*3+1])])) :
#				neighbours[keys.find(vertices[firstPointOfTriangleIndex*3+1])].append((keys.find(vertices[firstPointOfTriangleIndex*3])))
#		if( not ((keys.find(vertices[firstPointOfTriangleIndex*3+2])) in neighbours[keys.find(vertices[firstPointOfTriangleIndex*3+1])])) :
#				neighbours[keys.find(vertices[firstPointOfTriangleIndex*3+1])].append((keys.find(vertices[firstPointOfTriangleIndex*3+2])))
#
#		if( not ((refVertices.keys().find(vertices[firstPointOfTriangleIndex*3])) in neighbours[refVertices.keys().find(vertices[firstPointOfTriangleIndex*3+2])])) :
#				neighbours[refVertices.keys().find(vertices[firstPointOfTriangleIndex*3+2])].append((refVertices.keys().find(vertices[firstPointOfTriangleIndex*3])))
#		if( not ((refVertices.keys().find(vertices[firstPointOfTriangleIndex*3+1])) in neighbours[refVertices.keys().find(vertices[firstPointOfTriangleIndex*3+2])])) :
#				neighbours[refVertices.keys().find(vertices[firstPointOfTriangleIndex*3+2])].append((refVertices.keys().find(vertices[firstPointOfTriangleIndex*3+1])))
	return neighbours




# fonction qui genere une icosphere avec la résolution indiquée dans les variables exporté 
func compute_icosphere():
	
	water_height= material_override.get_shader_parameter("water_height")
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(baseMesh,0)

	var vertices := PackedVector3Array()
	vertices.resize(mdt.get_vertex_count())
	var uvs := PackedVector2Array()
	uvs.resize(mdt.get_vertex_count())
	var normals := PackedVector3Array()
	normals.resize(mdt.get_vertex_count())
	for i in range(mdt.get_vertex_count()):
		vertices[i] = mdt.get_vertex(i)
		
		uvs[i]=mdt.get_vertex_uv(i)
		normals[i]=mdt.get_vertex_normal(i)

	for i in range(resolution):
		var new_vertices := PackedVector3Array()
		var new_uvs := PackedVector2Array()
		for j in range(vertices.size()/3):
			var a = vertices[j*3]
			var b = vertices[j*3+2]
			var c = vertices[j*3+1]
			var ab= a+(b-a)*.5
			var bc= b+(c-b)*.5
			var ca= c+(a-c)*.5
		
			var uv_a = uvs[j*3]
			var uv_b = uvs[j*3+2]
			var uv_c = uvs[j*3+1]
			var uv_ab= uv_a+(uv_b-uv_a)*.5
			var uv_bc= uv_b+(uv_c-uv_b)*.5
			var uv_ca= uv_c+(uv_a-uv_c)*.5

			new_uvs.append_array([
					uv_a,uv_ca,uv_ab,
					uv_ab,uv_ca,uv_bc,
					uv_ca,uv_c,uv_bc,
					uv_ab,uv_bc,uv_b
					])
			
			
			refVertices[ca] = 0
			
			new_vertices.append_array([
				a,ca,ab,
				ab,ca,bc,
				ca,c,bc,
				ab,bc,b
				])
		vertices=new_vertices
		uvs=new_uvs
		
		
		for j in range(vertices.size()) :
			vertices[j]=vertices[j].normalized()

	normals.resize(vertices.size())
	for i in range(vertices.size()/3) :
		var n = -(vertices[i*3+0]-vertices[i*3+1]).cross(vertices[i*3+0]-vertices[i*3+2]).normalized()
		normals[i*3+0] =n
		normals[i*3+1] =n
		normals[i*3+2] =n
	
	
#	print("Nombre de triangles : ",vertices.size()/3)

#	vertices = heighten(vertices)
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	

	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	material_override.set_shader_parameter("water_height",water_height)
#	generate_actual_texture(uvs)
#	generate_texture()
	print("voisins : ........... \n ",get_neighbours())





#fonnction qui modifie la longeur des vecteurs de chaque point en fonction de la seed et d'un bruit de perlin independament du niveau d'eau
func heighten(vertices: PackedVector3Array) :
	var vert := PackedVector3Array()
	var flyingVertices := PackedVector3Array()

	vert.resize(vertices.size())
	for j in range(vertices.size()) :
		vert[j]=vertices[j].normalized()

	var noise = FastNoiseLite.new() 
	noise.noise_type=FastNoiseLite.TYPE_PERLIN
	noise.set_seed(NoiseSeed)

	for i in vert.size() :
		var h1 = noise.get_noise_3d(vert[i].x*100,vert[i].y*100,vert[i].z*100)/3+2
		vert[i]=vert[i]*h1
	return vert


#fonnction qui modifie la longeur des vecteurs de chaque point en fonction de la seed et d'un bruit de perlin Mais gère aussi le niveau de l'eau par cpu 
func heighten_water(vertices: PackedVector3Array) :
	var vert := PackedVector3Array()
	var flyingVertices := PackedVector3Array()

	vert.resize(vertices.size())
	for j in range(vertices.size()) :
		vert[j]=vertices[j].normalized()

	var noise = FastNoiseLite.new() 
	noise.noise_type=FastNoiseLite.TYPE_PERLIN
	noise.set_seed(NoiseSeed)

	for i in vert.size()/3 :
		var h1 = noise.get_noise_3d(vert[i*3].x*100,vert[i*3].y*100,vert[i*3].z*100)/3+2
		var h2 = noise.get_noise_3d(vert[i*3+1].x*100,vert[i*3+1].y*100,vert[i*3+1].z*100)/3+2
		var h3 = noise.get_noise_3d(vert[i*3+2].x*100,vert[i*3+2].y*100,vert[i*3+2].z*100)/3+2
		if h1 > water_height  and h2 > water_height and h3 > water_height  :
			vert[i*3]=vert[i*3]*h1
			vert[i*3+1]=vert[i*3+1]*h2
			vert[i*3+2]=vert[i*3+2]*h3
		else :
			flyingVertices.append_array([vert[i*3],vert[i*3+1],vert[i*3+2]])
			vert[i*3]=vert[i*3]*water_height
			vert[i*3+1]=vert[i*3+1]*water_height
			vert[i*3+2]=vert[i*3+2]*water_height
	for i in range(flyingVertices.size()):
		var ind = vert.find(flyingVertices[i])
		if(not ind==-1):
			vert[ind]=vert[ind].normalized()*water_height
	return vert
