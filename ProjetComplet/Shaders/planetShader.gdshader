shader_type spatial;  
//render_mode world_vertex_coords;

uniform vec4 water_color : source_color = vec4(1.0);
uniform vec4 grass_color : source_color = vec4(1.0);
uniform int seed;
uniform highp float water_height : hint_range(0, 3);
uniform sampler2D height_texture;
uniform sampler2D test_texture;

varying flat vec2 uv;
varying highp vec3 pos;
varying float toColor;

void vertex() {
	float coef = texture(height_texture, UV).x;
//	VERTEX*=coef;
	toColor=0.;
	if(length(VERTEX)<water_height+0.03) { 
		VERTEX=normalize(VERTEX)*water_height ;
		toColor=1.;
	}
	
	pos=VERTEX;
	uv=UV;
}

//		VERTEX=normalize(VERTEX)*water_height;
//}

void fragment() {

// Met par défaut la couleur de l'herbe choisie
//	ALBEDO =  grass_color.rgb;
//
//	if(toColor!=0.){
//		ALBEDO=water_color.xyz;
//	}
//	ALBEDO=texture(test_texture,UV).rgb;
	ALBEDO = COLOR.rgb/20.;

}
