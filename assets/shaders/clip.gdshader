shader_type canvas_item;

uniform int active_cutouts = 1;

uniform vec4 cutouts[10];

void fragment() {
	vec4 orig_tex = texture(TEXTURE, UV);
	vec4 final_color = orig_tex * COLOR;
	
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 current_pixel = UV * texture_size;
	
	for (int i = 0; i < 10; i++) {
		if (i >= active_cutouts) {
			break;
		}
		
		vec4 cutout = cutouts[i];
		
		float left_edge = cutout.x;
		float top_edge = cutout.y;
		float right_edge = cutout.x + cutout.z;
		float bottom_edge = cutout.y + cutout.w;
		
		if (current_pixel.x >= left_edge && current_pixel.x <= right_edge && 
			current_pixel.y >= top_edge && current_pixel.y <= bottom_edge) {
			
			final_color.a = 0.0;
			break;
		}
	}
	
	COLOR = final_color;
}
