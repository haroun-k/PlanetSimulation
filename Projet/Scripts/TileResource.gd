class_name TileResource
extends Resource

@export var tile_position : Vector3

enum TERRAIN_TYPE {WATER,GRASS,MUD,FIRE}
@export var terrainType : TERRAIN_TYPE
var extra_data : int
@export_color_no_alpha var tileColor : Color :
	get : return get_color()
@export var neighbours : Array[TileResource]


func get_color():
	match terrainType :
		TERRAIN_TYPE.GRASS :
			return Color.PALE_GREEN
		TERRAIN_TYPE.WATER :
			return Color.DODGER_BLUE
		TERRAIN_TYPE.MUD :
			return Color.DIM_GRAY
		TERRAIN_TYPE.FIRE :
			return Color.BROWN
		_ : return Color.DARK_SLATE_GRAY


func init_tile():
	terrainType = TERRAIN_TYPE.GRASS
	extra_data = 0
	if (randf()<0.1) : 
		terrainType = TERRAIN_TYPE.WATER 
	if (randf()<0.03) : 
		terrainType = TERRAIN_TYPE.FIRE 

func update_tile():

	match self.terrainType :

		TERRAIN_TYPE.GRASS : # ca fait rien
			self.extra_data = 0
		
		TERRAIN_TYPE.FIRE :
			for n in neighbours :
				if n.terrainType==TERRAIN_TYPE.GRASS :
					n.terrainType=TERRAIN_TYPE.FIRE

			self.terrainType = TERRAIN_TYPE.MUD

		TERRAIN_TYPE.MUD :
			if (randf()<0.01) :
				for n in neighbours :
					if n.terrainType==TERRAIN_TYPE.GRASS :
						self.terrainType=TERRAIN_TYPE.GRASS
						break
		
		TERRAIN_TYPE.WATER : # ca fait rien
			self.extra_data = 0
	
