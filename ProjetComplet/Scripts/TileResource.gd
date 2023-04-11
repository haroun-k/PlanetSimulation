class_name TileResource extends Resource

# Position de la tuile (case/triangle) 
@export var tile_position : Vector3

# Enum des types de terrains 
enum TERRAIN_TYPE {WATER, GRASS, TALL_GRASS, MUD, UNDEFINED}

# Type du terrain de l'instance "self" de TileResource
@export var terrainType : TERRAIN_TYPE

# Référence vers les 3 voisins de cette case
@export var neighbours : Array[TileResource]

# Valeures utilisés pour la génération des types des cases : distance à une case eau et nombre de ticks passé depuis que la case est devenu de type 'grass' ou 'tall grass'
@export var amountOfTicksSinceTypeIsGrass : int
@export var distanceFromWater : int = 10


# Définition de la structure de classe pour la 'Wave Function Collapse'
class WFC_Rule :
	var rules : Dictionary
	var forbidden : Array
	
	# Constructeur prenant le tableau des valeures possibles associé à leurs pondération et les valeures interdites
	func _init(rules : Dictionary, forbidden : Array):
		self.rules = rules
		self.forbidden = forbidden


# Regles dans le cas d'une case de type UNDEFINED, qui indique pour chaque type de voisins qu'elle pourait avoir, une pondération qu'elle se transforme en un certain type 
var wfc_Iundefined : Dictionary = {
	
	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.3}, []),
	#Exemple : si la case est de type UNDEFINED, un voisin de type TALL_GRASS lui donnerai 
	# une probabilité de 0.7 de devenir de type GRASS 
	# une probabilité de 0.3 de devenir de type TALL_GRASS 
	# et une imposibilité de devenir de type MUD  
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.TALL_GRASS : 0.3}, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.MUD : 0.9, TERRAIN_TYPE.GRASS : 0.1}, []),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.5, TERRAIN_TYPE.MUD : 0.5}, [TERRAIN_TYPE.TALL_GRASS]),

}

# Regles dans le cas d'une case de type GRASS, qui indique pour chaque type de voisins qu'elle pourait avoir, une pondération qu'elle se transforme en un certain type 
var wfc_Ugrass : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 1.0}, []),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.99, TERRAIN_TYPE.TALL_GRASS : 0.01}, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.MUD : 0.2, TERRAIN_TYPE.GRASS : 0.8}, []),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.97, TERRAIN_TYPE.TALL_GRASS : 0.03}, []),

}
# Regles dans le cas d'une case de type TALL_GRASS, qui indique pour chaque type de voisins qu'elle pourait avoir, une pondération qu'elle se transforme en un certain type 
var wfc_Utall_grass : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.TALL_GRASS : 0.3, TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.05}, []),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.4, TERRAIN_TYPE.TALL_GRASS : 0.6}, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.95, TERRAIN_TYPE.MUD : 0.05}, []),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.TALL_GRASS : 0.5, TERRAIN_TYPE.GRASS : 0.5}, []),

}

# Regles dans le cas d'une case de type MUD, qui indique pour chaque type de voisins qu'elle pourait avoir, une pondération qu'elle se transforme en un certain type 
var wfc_Umud : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.3}, [TERRAIN_TYPE.TALL_GRASS]),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.8, TERRAIN_TYPE.TALL_GRASS : 0.2}, [TERRAIN_TYPE.TALL_GRASS]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.MUD : 0.7, TERRAIN_TYPE.GRASS : 0.3}, [TERRAIN_TYPE.TALL_GRASS]),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.GRASS : 1.0}, [TERRAIN_TYPE.TALL_GRASS, TERRAIN_TYPE.GRASS]),

}

# Dictionnaire qui à un type de terrain associe le dictionnaire des regles de mise à jour 
var wfc_updates : Dictionary = {
	
	TERRAIN_TYPE.UNDEFINED : wfc_Iundefined,
	TERRAIN_TYPE.GRASS : wfc_Ugrass,
	TERRAIN_TYPE.TALL_GRASS : wfc_Utall_grass,
	TERRAIN_TYPE.MUD : wfc_Umud,

}

# Fonction qui renvois la couleur d'une case en fonction de son type, cette couleure dépend de la température de la planète (ajoute du blanc si il fait entre 0 et -10°
func get_color(temp : int):
	match terrainType :
		TERRAIN_TYPE.GRASS :
			return Color.GREEN.lerp(Color.PALE_GREEN,clampf((distanceFromWater-1)/5.,0,1))+Color(clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.)
		TERRAIN_TYPE.TALL_GRASS :
			return Color.DARK_GREEN+Color(clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.)/1.5
		TERRAIN_TYPE.WATER :
			return Color.DODGER_BLUE+Color(clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.)/2.
		TERRAIN_TYPE.MUD :
			return Color.GOLDENROD+Color(clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.,clampi(temp,-10,0)/-10.)/3.
		TERRAIN_TYPE.UNDEFINED :
			return Color.BLACK

# Fonctions qui renvois si la case self est d'un certain type
func isUndefined(): return terrainType == TERRAIN_TYPE.UNDEFINED
func isWater(): return terrainType == TERRAIN_TYPE.WATER
func isGrass(): return terrainType == TERRAIN_TYPE.GRASS
func isTallGrass(): return terrainType == TERRAIN_TYPE.TALL_GRASS	
func isMud(): return terrainType == TERRAIN_TYPE.MUD


# Fonction qui va être appelé à l'initialisation d'une case 
# Si la case est en dessous du niveau d'eau elle, son type est défini comme tel et sa distance à l'eau est donc de 0
# Sinon son type est indéfini à ce stade.
func init_tile(waterHeight : float):
	terrainType = TERRAIN_TYPE.UNDEFINED
	if ((tile_position).length()<waterHeight) : 
		terrainType = TERRAIN_TYPE.WATER
		distanceFromWater=0

# Fonction qui influence les probabilité d'apparition d'herbe en fonction de la température, de l'eloignement à l'eau et du nombre de ticks passé sous le type GRASS ou TALL_GRASS
func shift_values(temperature : float, probas : Dictionary):

	# définition d'une température de référence.
	const TEMP_IDEAL_HERBE = 25.0

	# si la case est de type GRASS elle a 
	# plus de chance de le rester proportionellement au temps passé en tant qu'herbe 
	# et moins de chance de le rester proportionellement à la distance à l'eau
	if self.terrainType == TERRAIN_TYPE.GRASS :
		probas[TERRAIN_TYPE.GRASS] += self.amountOfTicksSinceTypeIsGrass / 10.0
		probas[TERRAIN_TYPE.GRASS] -= self.distanceFromWater

	# si la case est de type TALL_GRASS elle a 
	# plus de chance de le rester proportionellement au temps passé en tant qu'herbe 
	# et plus de chance de le rester proportionellement à la distance à l'eau
	# et plus de chances de devenir de type GRASS en fonction de l'éloignement à l'eau
	if self.terrainType == TERRAIN_TYPE.TALL_GRASS :
		probas[TERRAIN_TYPE.TALL_GRASS] += self.amountOfTicksSinceTypeIsGrass / 10.0
		probas[TERRAIN_TYPE.GRASS] -= 2.0 + self.distanceFromWater*2.0
		probas[TERRAIN_TYPE.TALL_GRASS] -= 2.0 + self.distanceFromWater

	# Et plus la case est proche de l'eau plus elle a de chances de devenir de type MUD
	probas[TERRAIN_TYPE.MUD] += (10.0 - distanceFromWater*2)



	# L'on calcul l'ecart à la température idéale
	var temp_diff = abs(temperature - TEMP_IDEAL_HERBE)
	
	# Si cet écart n'est pas trop grand l'on augmente d'un peu moins de 1 la probabilité qu'ils deviennent de type GRASS ou TALL_GRASS
	if (temp_diff < 10.0) :
		probas[TERRAIN_TYPE.GRASS] += 1.0 - temp_diff/50.0
		probas[TERRAIN_TYPE.TALL_GRASS] += 1.0 - temp_diff/50.0

	# Sinon l'on diminue conséquament la probabilité qu'ils deviennent de type GRASS ou TALL_GRASS en fonction de l'écart
	else :
		probas[TERRAIN_TYPE.GRASS] -= temp_diff / 400.0
		probas[TERRAIN_TYPE.TALL_GRASS] -= temp_diff / 400.0

	# Définition d'une température à la quelle la planète "s'achèsse"
	const TEMP_ASSECHEMENT = 35.0
	# Augmentation considérable que la case devienne de type MUD si la température dépasse la température d'assechement
	probas[TERRAIN_TYPE.MUD] += clampf((temperature - TEMP_ASSECHEMENT)/5.0, 0.0, 20.0)
	
	# Si les probabilités de devenir de type GRASS ou TALL_GRASS sont négatives elles sont ramené à 0.
	probas[TERRAIN_TYPE.GRASS] = max(probas[TERRAIN_TYPE.GRASS], 0.0)
	probas[TERRAIN_TYPE.TALL_GRASS] = max(probas[TERRAIN_TYPE.TALL_GRASS], 0.0)

	# Compte le nombre de voisins de type GRASS ou TALL_GRASS, rendant impossible d'être de type MUD et augmente la probabilité d'etre de type TALL_GRASS si tout les voisins le sont
	var neighboursOfTypeGrass = 0
	for n in neighbours:
		if n.isGrass() or n.isTallGrass():
			neighboursOfTypeGrass += 1
	if neighboursOfTypeGrass == 3:
		probas[TERRAIN_TYPE.MUD]=0.0
		probas[TERRAIN_TYPE.TALL_GRASS] += 1
	
	# Augmente les chance d'etre du type GRASS en fonction du nombre de voisins de type GRASS ou TALL_GRASS
	probas[TERRAIN_TYPE.GRASS] += neighboursOfTypeGrass * 2
	
	# Si la case initialement est de type MUD il lui est impossible de devenir de type TALL_GRASS
	if self.isMud():
		probas[TERRAIN_TYPE.TALL_GRASS] = 0.0
	
	#Si la case est d'un type différent de WATER ou UNDEFINED elle renforce ses probabilités de rester de son type initial 
	if not isUndefined() && not isWater():
		probas[self.terrainType] += 7.0
 



# Fonction qui va changer le type d'une case en fonction de ses voisins et de la température
func collapse_tile(temperature : float) -> bool:
	#Si la case est de type WATER elle n'est pas à changer.
	if terrainType == TERRAIN_TYPE.WATER :
		return false

	# Le Dictionnaire qui à des types associe des probabilités va servir à stocker la somme des chances de devenir de chaque type 
	# Un choix aléatoire sera fait ensuite pondéré par ces valeurs. 
	var probas = {}
	
	# initialisation des probabilités à 0 pour chaque type différent de UNDEFINED
	for t in range(TERRAIN_TYPE.keys().size()):
		if t != TERRAIN_TYPE.UNDEFINED :
			probas[t] = 0.0

	# Pour chaque voisins l'on va augmenter les probabilités de chaque type en fonction de celles définies dans les dictionnaires
	# Cela dépend du type actuel de la case et du type de chaque voisin
	for n in neighbours :
		if n.terrainType != TERRAIN_TYPE.UNDEFINED :
			for t in wfc_updates[self.terrainType][n.terrainType].rules.keys() :
				probas[t] += wfc_updates[self.terrainType][n.terrainType].rules[t]

	# L'on met à 0 la probilité des types dont l'un des voisins interdit la présence
	for n in neighbours :
		if n.terrainType != TERRAIN_TYPE.UNDEFINED :
			for t in wfc_updates[self.terrainType][n.terrainType].forbidden :
				probas[t] = 0.0

	# L'on vérifie qu'il existe une probabilité non nulle
	# Dans le cas contraire l'on s'arrete car l'on ne pourra pas définir le type de la case
	var has_probas = false
	for p in probas:
		if p!=0:
			has_probas = true
			break
	if not has_probas:
		return true

	# L'on applique les effets de la température de l'eau et du temps sur les probabilités selon la fonction 'shift_values()'
	shift_values(temperature, probas)
	
	
	# Si la case a passé énormément de temps sous la forme d'herbe, ses chances de devenir de type TALL_GRASS sont au moins plus grandes que celles de devenir de type GRASS. sinon c'est l'inverse
	if (isGrass() || isTallGrass()) :
		if self.amountOfTicksSinceTypeIsGrass > 300 :
			probas[TERRAIN_TYPE.TALL_GRASS] += probas[TERRAIN_TYPE.GRASS]
			probas[TERRAIN_TYPE.GRASS] = 0
		else:
			probas[TERRAIN_TYPE.GRASS] += probas[TERRAIN_TYPE.TALL_GRASS]
			probas[TERRAIN_TYPE.TALL_GRASS] = 0


	# Mises sous forme utilisable des probabilités pour chaque type afin de faire un tirage
	# Exemple : [ (herbe:2.4) , (haute_herbe:1.3), (terre:5.0) ] 
	# Devient : [ (herbe:2.4) , (haute_herbe:2.7), (terre:7.7) ] 
	# l'on somme la somme des probabilités précédentes dans le tableau 
	# ensuite l'on fait un tirage d'une valeure r entre 0 et la somme totale de toutes les probabilités, ici 7.7
	# si r<2.4 la case sera de type herbe sinon si r<2.7 elle sera de type haute_herbe et sinon de type terre
	var tile_probas = []
	for t in probas.keys():
		tile_probas.append([t,probas[t]])
	var weighted_tile_probas = [[tile_probas[0][0],tile_probas[0][1]]]
	var i=1
	while i<tile_probas.size() :
		weighted_tile_probas.append([tile_probas[i][0], tile_probas[i][1] + weighted_tile_probas[i-1][1]])
		i+=1


	# tirage et association du type. Réinitialisation du temps passé en herbe à 0 si le type précédent était different
	var r = randf()*weighted_tile_probas[-1][1]
	for t in weighted_tile_probas :
		if r<t[1] :
			self.terrainType = t[0]
			if not (isGrass() or isTallGrass()) :
				self.amountOfTicksSinceTypeIsGrass = 0
			break

	# Mise à 0 de la valeur de distance à l'eau dans le cas ou la case serait devenu de l'eau
	if self.isWater():
		self.distanceFromWater = 0
	# Sinon si l'un des voisins de la case est de type WATER, la distace à l'eau est mise à 1
	else:
		for n in neighbours:
			if n.isWater():
				n.distanceFromWater = 1
	# Et mise de la distance à l'eau des voisins commeétant le minimum entre la valeur qu'ils possèdent déjà et celle de cette case + 1
		for n in neighbours :
			n.distanceFromWater=min(n.distanceFromWater,distanceFromWater+1)

	return false



# Fonction appelé depuis la fonction 'update_world_resource()' qui met à jour une case en ce qui concerne le fait qu'elle soit de l'eau ou non et le temps passé en type herbe
func update_tile(waterHeight : float, temperature : float):

	# Si la case est en dessous du niveau d'eau et qu'elle était de type différent avant, elle change son type pour WATER et actualise le type de ses voisins
	if ((tile_position).length()<waterHeight) :
		if not isWater():
			terrainType = TERRAIN_TYPE.WATER
			for n in neighbours:
				n.collapse_tile(temperature)
	# Sinon si elle était de type eau, elle devient maintenant de type MUD car elle n'est plus submergée et l'on ne poursuis pas dans la fonction
	elif self.isWater():
			self.terrainType = TERRAIN_TYPE.MUD
			return
	
	# Les cases de type GRASS ou TALL_GRASS voient leurs vara=iable représentant le nombre de ticks passé sous ce type incrémenté
	elif self.isGrass() or self.isTallGrass():
		self.amountOfTicksSinceTypeIsGrass +=1

	# Pour chaque voisin l'on réactualise la distance à l'eau en fonction de celle de cette case 
	for i in neighbours :
		i.distanceFromWater=min(i.distanceFromWater,distanceFromWater+1)
