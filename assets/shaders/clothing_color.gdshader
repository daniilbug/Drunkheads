shader_type canvas_item;

// Only the neutral fabric ramp is dyed. Skin, lining and hardware stay intact.
uniform vec4 clothing_color : source_color = vec4(0.27451, 0.42353, 0.60392, 1.0);
varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (abs(pixel.r - pixel.g) < 0.005 && abs(pixel.g - pixel.b) < 0.005) {
		if (pixel.r < 0.35) {
			pixel.rgb = clothing_color.rgb * 0.60;
		} else if (pixel.r < 0.55) {
			pixel.rgb = clothing_color.rgb * 0.80;
		} else if (pixel.r < 0.80) {
			pixel.rgb = clothing_color.rgb;
		} else {
			pixel.rgb = mix(clothing_color.rgb, vec3(1.0), 0.18);
		}
	}
	COLOR = pixel * item_color;
}
