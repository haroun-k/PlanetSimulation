class_name TileResource
extends Resource

@export var tile_position : Vector3

enum TERRAIN_TYPE {WATER, GRASS, MUD, FIRE, UNDEFINED}
@export var terrainType : TERRAIN_TYPE
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
	
var wavefncollapse : Dictionary

#type de voisin -> proba de devenir ce type, intedits

func get_color():
	match terrainType :
		TERRAIN_TYPE.GRASS :
			return Color.PALE_GREEN.lerp(Color.DIM_GRAY,clampf((distanceFromWater-1)/5.,0,1))
		TERRAIN_TYPE.WATER :
			return Color.DODGER_BLUE
		TERRAIN_TYPE.MUD :
			return Color.DIM_GRAY
		TERRAIN_TYPE.FIRE :
			return Color.BROWN
		TERRAIN_TYPE.UNDEFINED :
			return Color.DARK_SLATE_GRAY


func init_tile(waterHeight : float):
	
	self.wavefncollapse = {}
	wavefncollapse[TERRAIN_TYPE.WATER] = WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.9, TERRAIN_TYPE.MUD : 0.1 }, [TERRAIN_TYPE.FIRE])
	wavefncollapse[TERRAIN_TYPE.GRASS] = WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.7, TERRAIN_TYPE.MUD : 0.3 }, [])
	wavefncollapse[TERRAIN_TYPE.MUD] = WFC_Rule.new({ TERRAIN_TYPE.GRASS : 0.1, TERRAIN_TYPE.MUD : 0.9 }, [])
	wavefncollapse[TERRAIN_TYPE.FIRE] = WFC_Rule.new({ TERRAIN_TYPE.FIRE : 1.0 }, [])
	
	terrainType = TERRAIN_TYPE.UNDEFINED
	extra_data = 1
	if ((tile_position).length()<waterHeight) : 
		terrainType = TERRAIN_TYPE.WATER
		distanceFromWater=0

func update_tile(waterHeight : float):
	if ((tile_position).length()<waterHeight) : 
		terrainType = TERRAIN_TYPE.WATER
	for i in neighbours :
		i.distanceFromWater=min(i.distanceFromWater,distanceFromWater+1)
	
	#Update avec la règle de WFC

	if self.terrainType != TERRAIN_TYPE.UNDEFINED :
		return

	var probas = {}
	for t in range(TERRAIN_TYPE.keys().size()):
		if t != TERRAIN_TYPE.UNDEFINED :
			probas[t] = 0.0
			
	print(probas)

	for n in neighbours :
		if n.terrainType != TERRAIN_TYPE.UNDEFINED :
			for t in wavefncollapse[n.terrainType].rules.keys() :
				probas[t] += wavefncollapse[n.terrainType].rules[t]
					
	for n in neighbours :
		if n.terrainType != TERRAIN_TYPE.UNDEFINED :
			for t in wavefncollapse[n.terrainType].forbidden :
				probas[t] = 0.0

	if probas.is_empty():
		self.terrainType = TERRAIN_TYPE.UNDEFINED
		return

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
			return
