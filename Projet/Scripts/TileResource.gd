class_name TileResource
extends Resource

@export var tile_position : Vector3

enum TERRAIN_TYPE {WATER, GRASS, MUD, UNDEFINED}
@export var terrainType : TERRAIN_TYPE
var original_terrainType : TERRAIN_TYPE

var extra_data : int
@export_color_no_alpha var tileColor : Color :
	get : return get_color()
@export var neighbours : Array[TileResource]
@export var distanceFromWater : int = 10


class WFC_Rule :
	
	var rules : Dictionary
	var forbidden : Array
	
	func _init(rules : Dictionary, forbidden : Array):
		self.rules = rules
		self.forbidden = forbidden
	
var wavefncollapse_Iundefined : Dictionary = {

	TERRAIN_TYPE.WATER : WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.2, TERRAIN_TYPE.MUD : 0.8 }, []),
	TERRAIN_TYPE.GRASS : WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.95, TERRAIN_TYPE.MUD : 0.05 }, []),
	TERRAIN_TYPE.MUD : WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.1, TERRAIN_TYPE.MUD : 0.9 }, []),
	
}

var wavefncollapse_Umud : Dictionary = {

	TERRAIN_TYPE.WATER : WFC_Rule.new({ TERRAIN_TYPE.GRASS : 1.0 }, [TERRAIN_TYPE.MUD]),
	TERRAIN_TYPE.GRASS : WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.9, TERRAIN_TYPE.MUD : 0.1 }, []),
	TERRAIN_TYPE.MUD : WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.3, TERRAIN_TYPE.MUD : 0.7 }, []),

}

var wavefncollapse_Uwater : Dictionary = {
	
	TERRAIN_TYPE.WATER : WFC_Rule.new({ TERRAIN_TYPE.WATER : 1.0 }, []),
	TERRAIN_TYPE.GRASS : WFC_Rule.new({ TERRAIN_TYPE.WATER : 1.0 }, []),
	TERRAIN_TYPE.MUD : WFC_Rule.new({ TERRAIN_TYPE.WATER : 1.0}, []),

}

var wfc_updates : Dictionary = {
	
	TERRAIN_TYPE.UNDEFINED : wavefncollapse_Iundefined,
	TERRAIN_TYPE.MUD : wavefncollapse_Umud,
	TERRAIN_TYPE.GRASS : wavefncollapse_Umud,
	TERRAIN_TYPE.WATER : wavefncollapse_Uwater,

}

#type de voisin -> proba de devenir ce type, intedits

func get_color():
	match terrainType :
		TERRAIN_TYPE.GRASS :
			return Color.PALE_GREEN#.lerp(Color.DARK_GREEN,clampf((distanceFromWater-1)/5.,0,1))
		TERRAIN_TYPE.WATER :
			return Color.LIGHT_SEA_GREEN
		TERRAIN_TYPE.MUD :
			return Color.DIM_GRAY
		TERRAIN_TYPE.UNDEFINED :
			return Color.BLACK

func isUndefined():
	return terrainType == TERRAIN_TYPE.UNDEFINED
	
func isWater():
	return terrainType == TERRAIN_TYPE.WATER

func isGrass():
	return terrainType == TERRAIN_TYPE.GRASS

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


func collapse_tile() -> bool:

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

func update_tile(waterHeight : float):

	if ((tile_position).length()<waterHeight) :
		self.terrainType = TERRAIN_TYPE.UNDEFINED 
		terrainType = TERRAIN_TYPE.WATER
		for n in neighbours:
			n.collapse_tile()
	
	else:
		if self.isWater():
			self.terrainType = self.original_terrainType
			self.collapse_tile()

	for i in neighbours :
		i.distanceFromWater=min(i.distanceFromWater,distanceFromWater+1)
