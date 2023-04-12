extends Node3D

var taille = 20
var faces = []
var texture = ImageTexture.new()
var image = Image.new()
var material = StandardMaterial3D.new()

const ROUGE = 0
const VERT = 1
const BLEU = 2
const JAUNE = 3
const VIOLET = 4
const CYAN = 5
const BLANC = 6
const NOIR = 7
const GRIS = 8
const GRIS_FONCE=9

func get_voisins(face : int, x : int, y : int):

	var voisins = PackedVector3Array()
	if 0<x && x<taille-1 && 0<y && y<taille-1: #MILIEU DE FACE
		for i in range(-1,2):
			for j in range(-1,2):
				if !(i==0 && j==0):
					voisins.append(Vector3(face,x+i,y+j))
		return voisins

	if y==0:
		match face:
			BLEU:
				for i in range(-1,2):
					voisins.append(Vector3(VIOLET,x+i,taille-1))
			VERT:
				for i in range(-1,2):
					voisins.append(Vector3(VIOLET,0,x+i))
			JAUNE:
				for i in range(-1,2):
					voisins.append(Vector3(VIOLET,taille-1,x+i))
			ROUGE:
				for i in range(-1,2):
					voisins.append(Vector3(VIOLET,x+i,0))
			VIOLET:
				for i in range(-1,2):
					voisins.append(Vector3(ROUGE,x+i,0))
			CYAN:
				for i in range(-1,2):
					voisins.append(Vector3(ROUGE,x+i,taille-1))

		for i in range(-1,2):
			for j in range(0,2):
				if !(i==0 && j==0):
					voisins.append(Vector3(face,x+i,y+j))

	elif y==taille-1:
		match face:
			BLEU:
				for i in range(-1,2):
					voisins.append(Vector3(CYAN,x+i,taille-1))

			VERT:
				for i in range(-1,2):
					voisins.append(Vector3(CYAN,taille-1,x+i))

			JAUNE:
				for i in range(-1,2):
					voisins.append(Vector3(CYAN,0,x+i))

			ROUGE:
				for i in range(-1,2):
					voisins.append(Vector3(CYAN,x+i,0))

			VIOLET:
				for i in range(-1,2):
					voisins.append(Vector3(VERT,0,x+i))

			CYAN:
				for i in range(-1,2):
					voisins.append(Vector3(JAUNE,x+i,taille-1))

		for i in range(-1,2):
			for j in range(-1,1):
				if !(i==0 && j==0):
					voisins.append(Vector3(face,x+i,y+j))

	#BORD INF X POUR EXCEPTIONS
	if x==0:
		match face:
			VIOLET:
				for i in range(-1,2):
					voisins.append(Vector3(BLEU,y+i,0))

			CYAN:
				for i in range(-1,2):
					voisins.append(Vector3(BLEU,y+i,taille-1))

			_ :
				for i in range(-1,2):
					voisins.append(Vector3(int(fposmod(face-1,4)),taille-1,y+i))

		for i in range(0,2):
			for j in range(-1,2):
				if !(i==0 && j==0):
					voisins.append(Vector3(face,x+i,y+j))

	#BORD SUP X POUR EXCEPTIONS
	elif x==taille-1:
		match face:
			VIOLET:
				for i in range(-1,2):
					voisins.append(Vector3(JAUNE,y+i,0))

			CYAN:
				for i in range(-1,2):
					voisins.append(Vector3(VERT,y+i,taille-1))

			_ :
				for j in range(-1,2):
					voisins.append(Vector3((face+1)%4,0,y+j))

		for i in range(-1,1):
			for j in range(-1,2):
				if !(i==0 && j==0):
					voisins.append(Vector3(face,x+i,y+j))

	var voisins_valides = PackedVector3Array()
	for v in voisins:
		if v not in voisins_valides && v[1]>=0 && v[1]<taille && v[2]>=0 && v[2]<taille:
			voisins_valides.append(v)

	return voisins_valides

func generer_planete():

	var cube = BoxMesh.new()
	cube.set_subdivide_width(taille)
	cube.set_subdivide_depth(taille)
	cube.set_subdivide_height(taille)

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,cube.get_mesh_arrays())
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)

	for i in range(mdt.get_vertex_count()):

		var vertex = mdt.get_vertex(i)

		#Meilleur distribution
		for _i in 5:
			var x = vertex.x
			var y = vertex.y
			var z = vertex.z
			vertex.x = x * sqrt(1 - y*y/2 - z*z/2 + y*y*z*z/3)
			vertex.y = y * sqrt(1 - z*z/2 - x*x/2 + z*z*x*x/3)
			vertex.z = z * sqrt(1 - x*x/2 - y*y/2 + x*x*y*y/3)

		vertex = vertex.normalized()
		mdt.set_vertex_normal(i, vertex)
		mdt.set_vertex(i, vertex)

	mdt.commit_to_surface(mesh)
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_material_override(material)
	add_child(mi)
	#trouver comment delete cube
	print(cube.is_queued_for_deletion())

func draw_face_to_image(fi : int, image_a_dessiner):
	var offset
	match fi:
		0:
			offset = Vector2(0,0)
		1:
			offset = Vector2(taille,0)
		2:
			offset = Vector2(2*taille,0)
		3:
			offset = Vector2(0,taille)
		4:
			offset = Vector2(taille,taille)
		5:
			offset = Vector2(2*taille,taille)

	for x in taille:
		for y in taille:
			match faces[fi][x][y]:
				ROUGE:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(255,0,0))
				VERT:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(0,255,0))
				BLEU:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(0,0,255))
				JAUNE:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(255,255,0))
				VIOLET:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(255,0,255))
				CYAN:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(0,255,255))
				BLANC:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(255,255,255))
				NOIR:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(0,0,0))
				GRIS:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(0.5,0.5,0.5))
				GRIS_FONCE:
					image_a_dessiner.set_pixel(x+offset.x,y+offset.y,Color(0.2,0.2,0.2))

func generer_plateau():
	for f in 6:
		var face = []
		for x in taille:
			var plateau = []
			for y in taille:
				if x<=1 && y<=1:
					plateau.append(9)
				elif x<=1:
					plateau.append(7)
				elif y<=1:
					plateau.append(8)
				else:
					plateau.append(f)
			face.append(plateau)
		faces.append(face)

func random_propagation():
	randomize()
	var face = randi_range(0,5)
	var x = randi_range(0,taille-1)
	var y = randi_range(0,taille-1)
	faces[face][x][y] = 6

func _ready():
	generer_plateau()
	generer_planete()
	#debug
	for face in faces:
		print(face)

	image = Image.create(3*taille,2*taille,true,Image.FORMAT_RGB8)
	update_plateau()
	random_propagation()

	print("VOISINS")
	print(get_voisins(0,taille-1,5))
	print(get_voisins(VERT,5,0))
	print(get_voisins(VIOLET,5,0))
	print(get_voisins(CYAN,5,0))
	print(get_voisins(VIOLET,5,taille-1))
	print(get_voisins(CYAN,5,taille-1))
	print(get_voisins(VIOLET,0,5))
	print(get_voisins(CYAN,0,5))
	print(get_voisins(VIOLET,taille-1,5))
	print(get_voisins(CYAN,taille-1,5))
	print(get_voisins(ROUGE,0,0))
	print(get_voisins(JAUNE,taille-1,taille-1))

func update_visual():

	for f in 6:
		draw_face_to_image(f, image)

	texture = ImageTexture.create_from_image(image)
	material.albedo_texture = texture

func propagation():
	for fi in 6:
		for x in taille:
			for y in taille:
				if faces[fi][x][y]==6:
					for voisin in get_voisins(fi,x,y):
						faces[voisin[0]][voisin[1]][voisin[2]]=faces[fi][x][y]

func update_plateau():
	for fi in 6:
		for x in taille:
			for y in taille:
				if get_voisins(fi,x,y).size()==8:
					faces[fi][x][y]+=1
					faces[fi][x][y]=faces[fi][x][y]%6

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	propagation()
	update_visual()
	pass
