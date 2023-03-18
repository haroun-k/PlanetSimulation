class_name TileResource extends Resource

@export var tile_position : Vector3
enum TERRAIN_TYPE {WATER,GRASS,MUD,FIRE}
@export var terrainType : int
@export_color_no_alpha var tileColor : Color :
	get : return get_color()
@export var neighbours : Array[TileResource]


func get_color():
	match terrainType :
		TERRAIN_TYPE.GRASS :
			return Color.SPRING_GREEN
		TERRAIN_TYPE.WATER :
			return Color.DEEP_SKY_BLUE
		TERRAIN_TYPE.MUD :
			return Color.BURLYWOOD
		TERRAIN_TYPE.FIRE :
			return Color.DARK_RED
		_ : return Color.DARK_SLATE_GRAY


func init_tile():
	terrainType = TERRAIN_TYPE.GRASS
	if(randf()<0.2) : terrainType = TERRAIN_TYPE.WATER 
	if(randf()<0.1) : terrainType = TERRAIN_TYPE.FIRE 

func update_tile():
	if terrainType==TERRAIN_TYPE.GRASS and ( neighbours[0].terrainType == TERRAIN_TYPE.FIRE or neighbours[1].terrainType == TERRAIN_TYPE.FIRE or neighbours[2].terrainType == TERRAIN_TYPE.FIRE):
		terrainType=TERRAIN_TYPE.FIRE
	elif terrainType==TERRAIN_TYPE.GRASS and (randf()<0.0005) : terrainType = TERRAIN_TYPE.FIRE 
		
	elif terrainType==TERRAIN_TYPE.MUD and ( neighbours[0].terrainType == TERRAIN_TYPE.GRASS or neighbours[1].terrainType == TERRAIN_TYPE.GRASS or neighbours[2].terrainType == TERRAIN_TYPE.GRASS):
		terrainType=TERRAIN_TYPE.GRASS
	elif terrainType==TERRAIN_TYPE.MUD and (randf()<0.1) : terrainType = TERRAIN_TYPE.GRASS 
		
	elif terrainType==TERRAIN_TYPE.FIRE :
		for i in neighbours :
			if(i.terrainType==TERRAIN_TYPE.GRASS): i.terrainType=TERRAIN_TYPE.FIRE
			terrainType=TERRAIN_TYPE.MUD
	
