shader_type canvas_item;

// These five source colors are the paint ramp in both car-body textures.
// Glass, lamps, seams and wheels keep their original colors.
uniform vec4 paint_source : source_color = vec4(0.27451, 0.52941, 0.54902, 1.0);
uniform vec4 shadow_source : source_color = vec4(0.17255, 0.38431, 0.41569, 1.0);
uniform vec4 highlight_source : source_color = vec4(0.45882, 0.67843, 0.69020, 1.0);
uniform vec4 roof_source : source_color = vec4(0.35294, 0.58824, 0.60784, 1.0);
uniform vec4 sill_source : source_color = vec4(0.13333, 0.27843, 0.30588, 1.0);
uniform vec4 paint_color : source_color = vec4(0.27451, 0.52941, 0.54902, 1.0);

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	// Keep the approved teal sprite pixel-identical at its default color.
	if (distance(paint_color.rgb, paint_source.rgb) >= 0.001) {
		if (distance(pixel.rgb, paint_source.rgb) < 0.01) {
			pixel.rgb = paint_color.rgb;
		} else if (distance(pixel.rgb, shadow_source.rgb) < 0.01) {
			pixel.rgb = paint_color.rgb * 0.72;
		} else if (distance(pixel.rgb, highlight_source.rgb) < 0.01) {
			pixel.rgb = mix(paint_color.rgb, vec3(1.0), 0.28);
		} else if (distance(pixel.rgb, roof_source.rgb) < 0.01) {
			pixel.rgb = mix(paint_color.rgb, vec3(1.0), 0.10);
		} else if (distance(pixel.rgb, sill_source.rgb) < 0.01) {
			pixel.rgb = paint_color.rgb * 0.52;
		}
	}
	COLOR = pixel;
}
