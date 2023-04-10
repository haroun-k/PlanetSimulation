shader_type spatial;
render_mode cull_front;
uniform float temperature;
uniform float temp_max;
uniform float temp_min;

void fragment() {
	// Place fragment code here.
	
	ALPHA = 0.2;
	float tempRatio = abs((temperature-temp_min)/(temp_max-temp_min));
	ALBEDO = mix(vec3(11./255., 14./255., 28./255.), vec3(10./255., 155./255., 251./255.), smoothstep(0.,1.,tempRatio));
//	ALBEDO = (vec3(1.0,0.0,0.0) *(1.-tempRatio) + vec3(10./255., 155./255., 251./255.) *(tempRatio));
}
