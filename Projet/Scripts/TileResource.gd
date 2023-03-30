class_name TileResource
extends Resource

@export var tile_position : Vector3

enum TERRAIN_TYPE {WATER,GRASS,MUD,FIRE}
@export var terrainType : TERRAIN_TYPE
var extra_data : int
@export_color_no_alpha var tileColor : Color :
	get : return get_color()
@export var neighbours : Array[TileResource]
@export var distanceFromWater : int = 10


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
		_ : return Color.DARK_SLATE_GRAY


func init_tile(waterHeight: float):
	terrainType = TERRAIN_TYPE.GRASS
	extra_data = 1
	if ((tile_position).length()<waterHeight) : 
		terrainType = TERRAIN_TYPE.WATER
		distanceFromWater=0
	if terrainType == TERRAIN_TYPE.GRASS and randf()<0.0 :
			terrainType = TERRAIN_TYPE.FIRE

func update_tile():
	for i in neighbours :
		i.distanceFromWater=min(i.distanceFromWater,distanceFromWater+1)
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
	
