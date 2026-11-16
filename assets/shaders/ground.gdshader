shader_type canvas_item;
// Procedural painted ground for one 64x64-tile chunk (2048x2048 px).
// data texture (64x64, linear): R = signed distance to shore in tiles (0.5 = shore, <0.5 water),
// G = path mask, B = dirt mask. Everything is snapped to the world pixel grid for a pixel-art look.

uniform sampler2D data : filter_linear;
uniform float chunk_px = 2048.0;
uniform float sdf_range = 8.0;

// palette
const vec3 DEEP = vec3(0.075, 0.25, 0.31);
const vec3 MID = vec3(0.13, 0.40, 0.42);
const vec3 SHALLOW = vec3(0.33, 0.62, 0.56);
const vec3 SUNK_ROCK = vec3(0.50, 0.72, 0.64);
const vec3 GRASS_D = vec3(0.24, 0.44, 0.16);
const vec3 GRASS_M = vec3(0.39, 0.58, 0.20);
const vec3 GRASS_L = vec3(0.58, 0.70, 0.28);
const vec3 DRY = vec3(0.74, 0.69, 0.36);
const vec3 DIRT_D = vec3(0.55, 0.32, 0.17);
const vec3 DIRT_M = vec3(0.72, 0.45, 0.24);
const vec3 DIRT_L = vec3(0.83, 0.58, 0.34);
const vec3 STONE_D = vec3(0.42, 0.44, 0.42);
const vec3 STONE_M = vec3(0.68, 0.69, 0.64);
const vec3 STONE_L = vec3(0.86, 0.86, 0.80);
const vec3 MOSS = vec3(0.45, 0.60, 0.25);

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 hash2(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * vnoise(p); p *= 2.03; a *= 0.5; }
	return v;
}
// voronoi: x = distance to nearest centre, y = edge distance (F2-F1), zw = cell id
vec4 voronoi(vec2 p) {
	vec2 n = floor(p); vec2 f = fract(p);
	float d1 = 8.0; float d2 = 8.0; vec2 id = vec2(0.0);
	for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
		vec2 g = vec2(float(i), float(j));
		vec2 o = hash2(n + g) * 0.8 + 0.1;
		float d = length(g + o - f);
		if (d < d1) { d2 = d1; d1 = d; id = n + g; } else if (d < d2) { d2 = d; }
	}
	return vec4(d1, d2 - d1, id);
}
float sdf_at(vec2 tile) {
	vec2 warp = vec2(fbm(tile * 0.9), fbm(tile * 0.9 + 17.3)) - 0.5;
	float r = texture(data, (tile + warp * 0.9) / 64.0).r;
	return (r - 0.5) * 2.0 * sdf_range + (fbm(tile * 2.5) - 0.5) * 0.5;
}
float band(float v, float steps) { return floor(v * steps + 0.5) / steps; }

void fragment() {
	vec2 px = floor(UV * chunk_px) + 0.5;      // world pixel centre
	vec2 tile = px / 32.0;                       // tile units
	vec4 d = texture(data, (tile + (vec2(fbm(tile * 0.9), fbm(tile * 0.9 + 17.3)) - 0.5) * 0.9) / 64.0);
	float sdf = sdf_at(tile);
	// 3/4 view bank: where land lies just NORTH of shore/water we see the bank's vertical stone face
	float sN = sdf_at(tile - vec2(0.0, 0.55));
	float sS = sdf_at(tile + vec2(0.0, 0.3));
	vec3 col;
	if (sdf < 0.42 && sN >= 0.42 && sdf > -0.6) {
		// ---- bank face: stacked mossy stones, darker toward the waterline
		float k = clamp((0.42 - sdf) / 1.0, 0.0, 1.0);
		vec4 v = voronoi(tile * vec2(2.6, 4.0) + 11.0);
		float sh = band(clamp(1.0 - v.x * 1.3 + (hash(v.zw) - 0.5) * 0.3 - k * 0.5, 0.0, 1.0), 3.0);
		col = mix(STONE_D * 0.85, STONE_M * 0.95, sh);
		col = mix(STONE_D * 0.55, col, smoothstep(0.03, 0.1, v.y));
		col = mix(col, MOSS * 0.8, step(0.6, fbm(tile * 6.0 + 3.0)) * (1.0 - k) * 0.7);
		col = mix(col, GRASS_D * 0.6, 1.0 - smoothstep(0.0, 0.08, sN - 0.42) );  // grass overhang shadow
		if (sdf < -0.35) col = mix(col, DEEP, 0.5);   // wet base
	} else if (sdf < 0.0) {
		// ---- water: see-through, darkening with depth, submerged stones, ripples
		float depth = -sdf;
		float t = clamp(depth / 5.0, 0.0, 1.0);
		col = mix(SHALLOW, MID, smoothstep(0.0, 0.45, t));
		col = mix(col, DEEP, smoothstep(0.4, 1.0, t));
		// sparse rounded submerged boulders: lit top-left, fading out with depth
		vec2 bp = tile * 1.3 + 3.0;
		vec4 v = voronoi(bp);
		float hv = hash(v.zw);
		float radius = 0.18 + 0.36 * hash(v.zw + 7.0) * hash(v.zw + 13.0);
		float present = step(0.62, hv) * (1.0 - smoothstep(0.05, 0.5, t));
		float body = 1.0 - smoothstep(radius - 0.04, radius, v.x + (vnoise(tile * 4.0) - 0.5) * 0.22);
		vec4 v2 = voronoi(bp + vec2(0.1, 0.1));
		float lit = band(clamp(0.45 + (v2.x - v.x) * 3.5 + (radius - v.x) * 0.8, 0.0, 1.0), 3.0);
		vec3 rockc = mix(SUNK_ROCK * 0.8, SUNK_ROCK * 1.05, lit);
		col = mix(col, rockc, body * present * 0.75);
		col += (fbm(tile * 3.0 + TIME * 0.05) - 0.5) * 0.06;          // caustic shimmer
		col *= 1.0 - 0.35 * (1.0 - smoothstep(0.0, 0.35, depth));     // shadow under the bank
		// short animated ripple dashes
		vec2 rp = floor(vec2(px.x / 6.0 + TIME * 0.6 * (hash(vec2(floor(px.y / 5.0))) - 0.3), px.y / 5.0));
		float r = step(0.985, hash(rp)) * step(mod(px.y, 5.0), 1.0);
		col = mix(col, vec3(0.55, 0.78, 0.80), r * 0.55 * smoothstep(0.2, 1.0, depth));
		col = floor(col * 24.0) / 24.0;
	} else if (sdf < 0.42) {
		// ---- shoreline: mossy rounded stones
		vec4 v = voronoi(tile * vec2(2.2, 2.8));
		float edge = smoothstep(0.03, 0.09, v.y);
		vec2 cellc = v.zw;
		float sh = band(clamp(1.0 - v.x * 1.4 + (hash(cellc) - 0.5) * 0.3, 0.0, 1.0), 3.0);
		col = mix(STONE_D, STONE_M, sh);
		col = mix(col, STONE_L, step(0.85, sh));
		float moss = step(0.55, fbm(tile * 5.0)) * step(0.15, sdf);
		col = mix(col, MOSS, moss * 0.85);
		col = mix(STONE_D * 0.7, col, edge);
		col = mix(col, GRASS_D, step(0.36, sdf) * 0.6);
	} else {
		// ---- land: layered grass with dry patches and blade clusters; dirt/path on top
		float n = fbm(tile * 0.55);
		float m = fbm(tile * 2.2 + 5.0);
		float shade = band(clamp(n * 0.7 + m * 0.5 - 0.1, 0.0, 1.0), 4.0);
		col = mix(GRASS_D, GRASS_M, smoothstep(0.0, 0.5, shade));
		col = mix(col, GRASS_L, smoothstep(0.5, 1.0, shade));
		float dry = smoothstep(0.58, 0.66, fbm(tile * 0.35 + 40.0));
		col = mix(col, DRY, dry * 0.55);
		// blade clusters: small tufts on a 4px grid, lit tip + dark root
		vec2 cell = floor(px / 6.0);
		float h = hash(cell);
		vec2 lp = mod(px, 6.0);
		if (h > 0.8) {
			// a little tuft: three blades, lit tips, shadowed base
			bool blade = (lp.x == 1.5 && lp.y >= 1.5) || (lp.x == 2.5 && lp.y >= 0.5) || (lp.x == 3.5 && lp.y >= 2.5);
			if (blade) col = mix(col, (lp.y < 2.0 ? GRASS_L * 1.1 : GRASS_M * 1.05), 0.75);
			if (lp.y > 4.5 && lp.x > 0.5 && lp.x < 4.5) col = mix(col, GRASS_D * 0.8, 0.5);
		}
		if (hash(cell + 91.0) > 0.994) {  // tiny flower: 4 petals around a yellow centre
			vec3 petal = mix(vec3(0.96, 0.94, 0.86), vec3(0.93, 0.58, 0.70), step(0.5, hash(cell + 3.0)));
			vec2 q = abs(lp - vec2(2.5, 2.5));
			if (q.x + q.y < 0.1) col = vec3(0.98, 0.82, 0.30);
			else if (q.x + q.y < 1.1) col = petal;
		}
		// path and dirt
		float pathm = max(d.g, d.b * 0.9);
		float pe = pathm + (fbm(tile * 3.0 + 9.0) - 0.5) * 0.35;
		if (pe > 0.5) {
			float ds = band(fbm(tile * 0.9 + 2.0), 3.0);
			vec3 dc = mix(mix(DIRT_D, DIRT_M, 0.7), DIRT_M, smoothstep(0.2, 0.55, ds));
			dc = mix(dc, DIRT_L, smoothstep(0.55, 0.9, ds));
			vec4 pv = voronoi(tile * 7.0);
			float peb = step(pv.x, 0.13) * step(0.88, hash(pv.zw));
			dc = mix(dc, mix(STONE_M, STONE_L, step(pv.x, 0.07)), peb);
			dc = mix(dc, DIRT_D, (1.0 - smoothstep(0.5, 0.54, pe)) * 0.45);  // soft darker rim
			col = dc;
		}
		col = mix(col, col * 0.8, (1.0 - smoothstep(0.42, 0.7, sdf)) * 0.5);  // damp grass near shore
		if (sS < 0.42 && sdf < 0.6) col = mix(col, GRASS_L * 1.05, 0.55);    // sunlit lip above a bank face
	}
	COLOR = vec4(col, 1.0);
}
