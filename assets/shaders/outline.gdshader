shader_type canvas_item;
// Yellow interactable outline. Set `enabled` true on the highlighted target.
uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.1, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (enabled && c.a < 0.1) {
		vec2 s = TEXTURE_PIXEL_SIZE;
		float a = texture(TEXTURE, UV + vec2(s.x, 0)).a + texture(TEXTURE, UV - vec2(s.x, 0)).a
			+ texture(TEXTURE, UV + vec2(0, s.y)).a + texture(TEXTURE, UV - vec2(0, s.y)).a;
		if (a > 0.1) { c = outline_color; }
	}
	COLOR = c;
}
