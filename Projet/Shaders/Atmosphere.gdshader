shader_type spatial;
render_mode cull_front;
uniform float temperature;
uniform float temp_max;
uniform float temp_min;

void fragment() {
	// Place fragment code here.
	ALPHA = 0.1;
	float diff_rouge = abs(temp_max - max(temp_max,temperature));
	float diff_bleu = abs(temp_min - min(temp_min,temperature));
	ALBEDO = (vec3(1.0,0.0,0.0) * diff_rouge + vec3(0.0,0.0,1.0) * diff_bleu) 
			/
			 (diff_rouge + diff_bleu);
}
