class_name TileResource
extends Resource

@export var tile_position : Vector3

enum TERRAIN_TYPE {WATER, GRASS, TALL_GRASS, MUD, UNDEFINED}
@export var terrainType : TERRAIN_TYPE

var extra_data : int
@export var neighbours : Array[TileResource]
@export var distanceFromWater : int = 10


class WFC_Rule :
	
	var rules : Dictionary
	var forbidden : Array
	
	func _init(rules : Dictionary, forbidden : Array):
		self.rules = rules
		self.forbidden = forbidden
	
var wfc_Iundefined : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.3}, []),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.TALL_GRASS : 0.3}, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.MUD : 0.9, TERRAIN_TYPE.GRASS : 0.1}, []),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.5, TERRAIN_TYPE.MUD : 0.5}, [TERRAIN_TYPE.TALL_GRASS]),

}


var wfc_Ugrass : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 1.0}, []),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.99, TERRAIN_TYPE.TALL_GRASS : 0.01}, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.MUD : 0.2, TERRAIN_TYPE.GRASS : 0.8}, []),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.97, TERRAIN_TYPE.TALL_GRASS : 0.03}, []),

}

var wfc_Utall_grass : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.TALL_GRASS : 0.3, TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.05}, []),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.4, TERRAIN_TYPE.TALL_GRASS : 0.6}, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.95, TERRAIN_TYPE.MUD : 0.05}, []),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.TALL_GRASS : 0.5, TERRAIN_TYPE.GRASS : 0.5}, []),

}

var wfc_Umud : Dictionary = {

	TERRAIN_TYPE.GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.3}, [TERRAIN_TYPE.TALL_GRASS]),
	TERRAIN_TYPE.TALL_GRASS : WFC_Rule.new({TERRAIN_TYPE.GRASS : 0.8, TERRAIN_TYPE.TALL_GRASS : 0.2}, [TERRAIN_TYPE.TALL_GRASS]),
	TERRAIN_TYPE.MUD : WFC_Rule.new({TERRAIN_TYPE.MUD : 0.7, TERRAIN_TYPE.GRASS : 0.3}, [TERRAIN_TYPE.TALL_GRASS]),
	TERRAIN_TYPE.WATER : WFC_Rule.new({TERRAIN_TYPE.GRASS : 1.0}, [TERRAIN_TYPE.TALL_GRASS, TERRAIN_TYPE.GRASS]),

}


var wfc_updates : Dictionary = {
	
	TERRAIN_TYPE.UNDEFINED : wfc_Iundefined,
	TERRAIN_TYPE.GRASS : wfc_Ugrass,
	TERRAIN_TYPE.TALL_GRASS : wfc_Utall_grass,
	TERRAIN_TYPE.MUD : wfc_Umud,

}

#type de voisin -> proba de devenir ce type, intedits

func get_color(temp : int):
	match terrainType :
		TERRAIN_TYPE.GRASS :
			return Color.GREEN.lerp(Color.PALE_GREEN,clampf((distanceFromWater-1)/5.,0,1))+Color(clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.)
		TERRAIN_TYPE.TALL_GRASS :
			return Color.DARK_GREEN+Color(clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.)/1.5
		TERRAIN_TYPE.WATER :
			return Color.DODGER_BLUE+Color(clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.)/2.
		TERRAIN_TYPE.MUD :
			return Color.GOLDENROD+Color(clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.,clampi(temp,-50,0)/-50.)/3.
		TERRAIN_TYPE.UNDEFINED :
			return Color.BLACK


func isUndefined():
	return terrainType == TERRAIN_TYPE.UNDEFINED
	
func isWater():
	return terrainType == TERRAIN_TYPE.WATER

func isGrass():
	return terrainType == TERRAIN_TYPE.GRASS
	
func isTallGrass():
	return terrainType == TERRAIN_TYPE.TALL_GRASS	

func isMud():
	return terrainType == TERRAIN_TYPE.MUD

func isElem(t : TERRAIN_TYPE):
	return terrainType == t
	

func init_tile(waterHeight : float):
	
	terrainType = TERRAIN_TYPE.UNDEFINED
	extra_data = 1
	if ((tile_position).length()<waterHeight) : 
		terrainType = TERRAIN_TYPE.WATER
		distanceFromWater=0

func atmosphere_effects(temperature : float, probas : Dictionary):

	const TEMP_IDEAL_HERBE = 25.0

	if self.terrainType == TERRAIN_TYPE.GRASS :
		probas[TERRAIN_TYPE.GRASS] += self.extra_data / 10.0
		probas[TERRAIN_TYPE.GRASS] -= self.distanceFromWater

	if self.terrainType == TERRAIN_TYPE.TALL_GRASS :
		probas[TERRAIN_TYPE.TALL_GRASS] += self.extra_data / 10.0
		probas[TERRAIN_TYPE.GRASS] -= 2.0 + self.distanceFromWater*2.0
		probas[TERRAIN_TYPE.TALL_GRASS] -= 2.0 + self.distanceFromWater
		
	
	probas[TERRAIN_TYPE.MUD] += (10.0 - distanceFromWater*2)
	var temp_diff = abs(temperature - TEMP_IDEAL_HERBE)
	if (temp_diff < 10.0) :
		probas[TERRAIN_TYPE.GRASS] += 1.0 - temp_diff/50.0
		probas[TERRAIN_TYPE.TALL_GRASS] += 1.0 - temp_diff/50.0
	
	else :
		probas[TERRAIN_TYPE.GRASS] -= temp_diff / 400.0
		probas[TERRAIN_TYPE.TALL_GRASS] -= temp_diff / 400.0

	const TEMP_ASSECHEMENT = 35.0
	probas[TERRAIN_TYPE.MUD] += clampf((temperature - TEMP_ASSECHEMENT)/5.0, 0.0, 20.0)
	probas[TERRAIN_TYPE.GRASS] = max(probas[TERRAIN_TYPE.GRASS], 0.0)
	probas[TERRAIN_TYPE.TALL_GRASS] = max(probas[TERRAIN_TYPE.TALL_GRASS], 0.0)
		
	var voisins_herbe = 0
	for n in neighbours:
		if n.isGrass() or n.isTallGrass():
			voisins_herbe += 1
	if voisins_herbe == 3:
		probas[TERRAIN_TYPE.MUD]=0.0
		probas[TERRAIN_TYPE.TALL_GRASS] += 1
		
	probas[TERRAIN_TYPE.GRASS] += voisins_herbe * 2
	
	if self.isMud():
		probas[TERRAIN_TYPE.TALL_GRASS] = 0.0
		
	if not isUndefined() && not isWater():
		probas[self.terrainType] += 7.0
 
func collapse_tile(temperature : float) -> bool:

	if terrainType == TERRAIN_TYPE.WATER :
		return false

	var probas = {}
	for t in range(TERRAIN_TYPE.keys().size()):
		if t != TERRAIN_TYPE.UNDEFINED :
			probas[t] = 0.0

	for n in neighbours :
		if n.terrainType != TERRAIN_TYPE.UNDEFINED :
			for t in wfc_updates[self.terrainType][n.terrainType].rules.keys() :
				probas[t] += wfc_updates[self.terrainType][n.terrainType].rules[t]

	
					
	for n in neighbours :
		if n.terrainType != TERRAIN_TYPE.UNDEFINED :
			for t in wfc_updates[self.terrainType][n.terrainType].forbidden :
				probas[t] = 0.0
			

	var has_probas = false
	for p in probas:
		if p!=0:
			has_probas = true
			break

	if not has_probas:
		return true

	atmosphere_effects(temperature, probas)
	
	

	if (isGrass() || isTallGrass()) :
		if self.extra_data > 300 :
			probas[TERRAIN_TYPE.TALL_GRASS] += probas[TERRAIN_TYPE.GRASS]
			probas[TERRAIN_TYPE.GRASS] = 0
		else:
			probas[TERRAIN_TYPE.GRASS] += probas[TERRAIN_TYPE.TALL_GRASS]
			probas[TERRAIN_TYPE.TALL_GRASS] = 0
		
	var tile_probas = []
	for t in probas.keys():
		tile_probas.append([t,probas[t]])

	var weighted_tile_probas = [[tile_probas[0][0],tile_probas[0][1]]]
	var i=1
	while i<tile_probas.size() :
		weighted_tile_probas.append([tile_probas[i][0], tile_probas[i][1] + weighted_tile_probas[i-1][1]])
		i+=1

	randomize()
	var r = randf()*weighted_tile_probas[-1][1]
	for t in weighted_tile_probas :
		if r<t[1] :
			self.terrainType = t[0]
			if not (isGrass() or isTallGrass()) :
				self.extra_data = 0
			break
	
	if self.isWater():
		self.distanceFromWater = 0
		
	else:
		for n in neighbours:
			if n.isWater():
				n.distanceFromWater = 1
			
		for n in neighbours :
			n.distanceFromWater=min(n.distanceFromWater,distanceFromWater+1)
		
	
	return false

func update_tile(waterHeight : float, temperature : float):

	if ((tile_position).length()<waterHeight) :
		if not isWater():
			terrainType = TERRAIN_TYPE.WATER
			for n in neighbours:
				n.collapse_tile(temperature)
	
	else:
		if self.isWater():
			self.terrainType = TERRAIN_TYPE.MUD
			return

	if self.isGrass() or self.isTallGrass():
		self.extra_data +=1

		
	for i in neighbours :
		i.distanceFromWater=min(i.distanceFromWater,distanceFromWater+1)
