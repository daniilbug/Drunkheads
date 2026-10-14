shader_type canvas_item;

uniform int active_cutouts = 1;

uniform vec4 cutouts[10];
uniform vec2 outside_shadow_offset = vec2(0.0);

varying vec2 outside_shadow_offset_screen;

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
	
	COLOR.a = final_color.a;
	// The outer face samples shadows outside the room's occluder contour.
	SHADOW_VERTEX += outside_shadow_offset_screen;
}
uniform vec2 excluded_light_local_position = vec2(-10000.0, -10000.0);

varying vec2 excluded_light_screen_position;

void vertex() {
	excluded_light_screen_position = (CANVAS_MATRIX * MODEL_MATRIX * vec4(excluded_light_local_position, 0.0, 1.0)).xy;
	outside_shadow_offset_screen = (CANVAS_MATRIX * MODEL_MATRIX * vec4(outside_shadow_offset, 0.0, 0.0)).xy;
}

void light() {
	if (distance(LIGHT_POSITION.xy, excluded_light_screen_position) < 2.0) {
		LIGHT = vec4(0.0);
	} else {
		// Directional light strength is applied by its alpha during blending.
		float energy = LIGHT_IS_DIRECTIONAL ? 1.0 : LIGHT_ENERGY;
		LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * energy, LIGHT_COLOR.a);
	}
}
