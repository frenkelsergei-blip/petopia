shader_type canvas_item;
render_mode unshaded;
uniform vec2 direction = vec2(0.002, 0.0);
void fragment() {
	vec4 blurred = texture(TEXTURE, UV) * 0.2270270270;
	blurred += texture(TEXTURE, UV + direction * 1.3846153846) * 0.3162162162;
	blurred += texture(TEXTURE, UV - direction * 1.3846153846) * 0.3162162162;
	blurred += texture(TEXTURE, UV + direction * 3.2307692308) * 0.0702702703;
	blurred += texture(TEXTURE, UV - direction * 3.2307692308) * 0.0702702703;
	COLOR = blurred;
}
