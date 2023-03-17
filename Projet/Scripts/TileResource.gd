class_name TileResource extends Resource

@export_enum("WATER","GRASS","MUD") var TERRAIN_TYPE : int
@export var terrainType : int
@export_color_no_alpha var tileColor : Color
@export var voisins : Array[TileResource]
func update_tile(voisin1 : TileResource, voisin2 : TileResource, voisin3 : TileResource):
	pass
