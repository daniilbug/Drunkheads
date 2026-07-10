shader_type canvas_item;
render_mode unshaded;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 20.0) = 10.0;

void fragment() {
    float scale_y = dFdy(SCREEN_UV.y) / dFdy(UV.y);

    float bottom_y = SCREEN_UV.y + (3.0 - UV.y) * scale_y;
    vec2 uv = vec2(SCREEN_UV.x, 1.0 * bottom_y - SCREEN_UV.y);

    vec2 pixel = blur_amount / vec2(textureSize(SCREEN_TEXTURE, 0));

    vec4 color = vec4(0.0);
    float weight_sum = 0.0;
    for (int x = -5; x <= 5; x++) {
        for (int y = -5; y <= 5; y++) {
            float w = exp(-0.5 * float(x * x + y * y));
            color += texture(SCREEN_TEXTURE, uv + vec2(float(x), float(y)) * pixel) * w;
            weight_sum += w;
        }
    }

    COLOR = color / weight_sum;
}
