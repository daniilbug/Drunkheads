shader_type canvas_item;

// Every cut shares one neutral ramp. Non-neutral eye pixels keep their color.
uniform vec4 hair_color : source_color = vec4(0.47059, 0.31373, 0.22353, 1.0);
varying vec4 item_color;

void vertex() {
	item_color = COLOR;
}

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (abs(pixel.r - pixel.g) < 0.005 && abs(pixel.g - pixel.b) < 0.005) {
		if (pixel.r < 0.35) {
			pixel.rgb = hair_color.rgb * 0.52;
		} else if (pixel.r < 0.55) {
			pixel.rgb = hair_color.rgb * 0.78;
		} else if (pixel.r < 0.80) {
			pixel.rgb = hair_color.rgb;
		} else {
			pixel.rgb = mix(hair_color.rgb, vec3(1.0), 0.18);
		}
	}
	COLOR = pixel * item_color;
}
