shader_type spatial;
//gère les coordonées dans un référentiel global
render_mode world_vertex_coords;

//Permet de définir la couleur de l'eau et du reste
uniform vec4 water_color : source_color = vec4(1.0);
uniform vec4 grass_color : source_color = vec4(1.0);

//Permet de définir un niveau d'eau pour que tout les vertex en dessous de ce niveau se retrouvent remontées à ce nivea
uniform highp float water_height : hint_range(1, 3);

//Une texture qui va être utilisée comme height map pour donner l'apparence de vagues qui se déplacent (test)
uniform sampler2D water_heightmap;

//texture à appliquer qur la sphère en fonction des uv
uniform sampler2D test_texture;

// Creation d'une variable uv pour définir le mode d'interpolation au moment de la passer au fragment shader afin de ne pas avoir un flou pour les Textures de basses résolutions
varying flat vec2 uv;

//La position également l'on défini une méthode d'interpolation qui est différente de la moyenne pondérée des 3 points afin d'avoir un meilleur résultat (test)
varying highp vec3 pos;

//variable de vérification pour synchroniser le comportement du vertex shader et du fragment shader en ce qui concerne la définition de l'eau (pour regler un problème)
varying float toColor;

void vertex() {
	//par defaut le vertex n'est pas à considérer comme de l'eau
	toColor=0.;
	if(length(VERTEX)<water_height) { 
		//si la longeur du vecteyr est inférieure au niveau d'eau défini l'on normalise le vecteur et on le met au niveau de l'eau et on met la variable toColor à 1 (true)
		VERTEX=normalize(VERTEX)*water_height ;
		toColor=1.;
	}
//	NORMAL=VERTEX;
	
	//place les informations d'input dans les interpolateurs personalisés
	pos=VERTEX;
	uv=UV;
}

//
//void vertex() {
//	if(length(VERTEX)<water_height){
//		VERTEX=normalize(VERTEX)*water_height;
//	}
//	//NORMAL=VERTEX;
//	pos=VERTEX;
//}

void fragment() {
//	ALBEDO=(texture(test_texture,uv)).rgb;

// Met par défaut la couleur de l'herbe choisie
	ALBEDO =  grass_color.rgb;
	
	//Crée la normal map à appliquer sur l'eau à partir des textures choisies 
	vec3 water_normal = mix(texture(water_heightmap,UV +TIME/300.).rgb,texture(water_heightmap,UV/-500.).rgb, 0.5);
	if(toColor!=0.){
		
		// dans le cas ou le vertex est à considéré comme de l'eau, on applique la normal map et on change la couleure
		NORMAL_MAP=water_normal;
		ALBEDO=water_color.xyz;
		
	}

}