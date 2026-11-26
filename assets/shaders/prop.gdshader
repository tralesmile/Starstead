shader_type canvas_item;
// Props: wind sway (top moves, base fixed) + yellow interactable outline.
// sway = max pixels of sway at the top; phase de-syncs neighbours.
uniform bool enabled = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.1, 1.0);
uniform float sway = 0.0;
uniform float phase = 0.0;
uniform float speed = 1.3;
uniform float push = 0.0;   // extra whole-pixel bend (walker parting reeds)
global uniform vec2 prop_wind;   // x = steady lean (in sways), y = storm 0..1 (WeatherMath.tree_wind)
varying vec4 tint;  // node modulate (used for see-through fade)

void vertex() {
	tint = COLOR;
	float h = 1.0 - UV.y;                       // 0 at the base, 1 at the top
	float gust = 0.6 + 0.4 * sin(TIME * 0.37 + phase * 0.5);
	float flutter = sin(TIME * speed + phase) * gust + sin(TIME * speed * 3.1 + phase * 1.7) * 0.7 * prop_wind.y;
	float w = (flutter + prop_wind.x * (0.75 + 0.25 * gust)) * sway * h * h;
	VERTEX.x += floor(w + push * h * h + 0.5);                 // whole pixels only: stays crisp
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (enabled && c.a < 0.1) {
		vec2 s = TEXTURE_PIXEL_SIZE;
		float a = texture(TEXTURE, UV + vec2(s.x, 0)).a + texture(TEXTURE, UV - vec2(s.x, 0)).a
			+ texture(TEXTURE, UV + vec2(0, s.y)).a + texture(TEXTURE, UV - vec2(0, s.y)).a;
		if (a > 0.1) { c = outline_color; }
	}
	COLOR = c * tint;
}
