shader_type canvas_item;
// Procedural painted ground for one 64x64-tile chunk (2048x2048 px).
// data texture (64x64, linear): R = signed distance to shore in tiles (0.5 = shore, <0.5 water),
// G = path mask, B = dirt mask. Everything is snapped to the world pixel grid for a pixel-art look.

uniform sampler2D data : filter_linear;
uniform float chunk_px = 2048.0;
uniform float sdf_range = 8.0;
uniform float data_size = 64.0;     // data texture side in texels (64 + 2 * pad)
uniform float data_pad = 0.0;
uniform vec2 origin_tiles = vec2(0.0);   // chunk origin in world tiles (0 for the homestead); data lookups stay chunk-local

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
uniform vec3 season_mul = vec3(1.0);
uniform float season_frost = 0.0;
uniform float wet = 0.0;             // rain on city asphalt: darker surface, sky-coloured puddles with sparkles
uniform sampler2D puddle_tex : filter_linear, repeat_enable;   // PuddleMath field: the same water the game splashes in

vec3 sg(vec3 c) {
	vec3 t = c * season_mul;
	return mix(t, vec3(0.90, 0.95, 1.0) * (0.75 + 0.25 * t.g), season_frost);
}


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
	float r = texture(data, (tile - origin_tiles + data_pad + warp * 0.9) / data_size).r;
	return (r - 0.5) * 2.0 * sdf_range + (fbm(tile * 2.5) - 0.5) * 0.5;
}
float puddle_at(vec2 wpx) { return smoothstep(0.58, 0.68, texture(puddle_tex, (floor(wpx) + 0.5) / 1024.0).r) * wet; }   // = PuddleMath.noise_at (4px texels, 256 side)
// a puddle over wet ground: damp halo, soft one-step edge, water, shaded north bank and a lit south lip (SEEN = 0.35)
vec3 puddle_paint(vec3 ground, vec2 wpx, float m, vec3 water, vec3 lip, float opacity) {
	vec3 c = ground * (1.0 - 0.13 * step(0.07, m) - 0.15 * step(0.2, m));             // darker wet rim in two crisp steps
	c = mix(c, water, opacity * (0.4 * step(0.29, m) + 0.6 * step(0.35, m)));
	c = mix(c, c * 0.86, smoothstep(0.75, 1.0, m));                                   // deeper middle
	if (m >= 0.35) {
		if (puddle_at(wpx - vec2(0.0, 2.0)) < 0.35) c *= 0.8;                          // the near bank shades the water's top edge
		else if (puddle_at(wpx + vec2(0.0, 1.0)) < 0.35) c = mix(c, lip, 0.55);        // sky catches the lower lip
		else if (puddle_at(wpx + vec2(0.0, 3.0)) < 0.35) c = mix(c, lip, 0.16);
	}
	return c;
}
float rain_ring(vec2 wpx) {
	// one expanding drop ring per 22px patch, each on its own beat
	vec2 c = floor(wpx / 22.0);
	float ph = fract(TIME * 1.1 + hash(c + 3.0));
	vec2 centre = (c + 0.35 + 0.3 * hash2(c + 11.0)) * 22.0;
	return step(abs(length((wpx - centre) * vec2(1.0, 1.9)) - ph * 8.0), 0.9) * (1.0 - ph);
}
float band(float v, float steps) { return floor(v * steps + 0.5) / steps; }

void fragment() {
	vec2 px = floor(UV * chunk_px) + 0.5 + origin_tiles * 32.0;      // world pixel centre
	vec2 tile = px / 32.0;                       // tile units
	vec4 d = texture(data, (tile - origin_tiles + data_pad + (vec2(fbm(tile * 0.9), fbm(tile * 0.9 + 17.3)) - 0.5) * 0.9) / data_size);
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
		col = mix(col, sg(GRASS_D) * 0.6, 1.0 - smoothstep(0.0, 0.08, sN - 0.42) );  // grass overhang shadow
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
		// causeway / roadside shadow: a road just north-west casts a soft, two-step shadow onto the water (sun top-left)
		vec2 cwarp = (vec2(fbm(tile * 1.7 + 5.0), fbm(tile * 1.7 + 29.0)) - 0.5) * 0.7;
		vec2 cw = (tile - origin_tiles + data_pad - vec2(0.22, 0.85) + cwarp) / data_size;
		float road_n = max(texture(data, cw).g, texture(data, cw + vec2(0.0, 0.25) / data_size).g * 0.8);
		float cshadow = band(smoothstep(0.15, 0.75, road_n), 2.0) * (1.0 - smoothstep(1.5, 4.0, depth));
		col *= 1.0 - 0.32 * cshadow;
		// short animated ripple dashes
		vec2 rp = floor(vec2(px.x / 6.0 + TIME * 0.6 * (hash(vec2(floor(px.y / 5.0))) - 0.3), px.y / 5.0));
		float r = step(0.985, hash(rp)) * step(mod(px.y, 5.0), 1.0);
		col = mix(col, vec3(0.55, 0.78, 0.80), r * 0.55 * smoothstep(0.2, 1.0, depth));
		// sun glints: sparse single bright pixels that twinkle on and off
		vec2 gp = floor(px / 3.0);
		float gph = hash(gp + 31.0);
		float twinkle = step(0.97, hash(gp + floor(TIME * 1.5 + gph * 8.0)));
		col = mix(col, vec3(0.92, 0.98, 0.95), twinkle * 0.6 * smoothstep(0.15, 0.6, depth) * step(0.5, gph));
		// light rays: slow diagonal shafts of sunlight drifting across the deeper water
		float rayc = (px.x + px.y * 0.6) / 22.0 + TIME * 0.05;
		float ray = smoothstep(0.62, 1.0, sin(rayc * 3.1 + sin(rayc * 1.3) * 1.5) * 0.5 + 0.5);
		col += vec3(0.07, 0.12, 0.10) * ray * smoothstep(0.2, 0.9, depth);
		// lapping shore foam: a ragged white pixel line that creeps in and out with the swell
		float lap = 0.22 + 0.16 * sin(TIME * 0.9 + fbm(tile * 1.7) * 6.0);
		float fz = smoothstep(0.1, 0.0, abs(depth - lap)) * step(0.45, fbm(tile * 4.0 + TIME * 0.1));
		col = mix(col, vec3(0.90, 0.97, 0.94), fz * 0.8 * (1.0 - smoothstep(0.2, 0.5, depth)));
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
		col = mix(col, sg(GRASS_D), step(0.36, sdf) * 0.6);
	} else {
		// ---- land: layered grass with dry patches and blade clusters; dirt/path on top
		float n = fbm(tile * 0.55);
		float m = fbm(tile * 2.2 + 5.0);
		float shade = band(clamp(n * 0.7 + m * 0.5 - 0.1, 0.0, 1.0), 4.0);
		col = mix(sg(GRASS_D), sg(GRASS_M), smoothstep(0.0, 0.5, shade));
		col = mix(col, sg(GRASS_L), smoothstep(0.5, 1.0, shade));
		float dry = smoothstep(0.58, 0.66, fbm(tile * 0.35 + 40.0));
		col = mix(col, sg(DRY), dry * 0.55);
		// blade clusters: small tufts on a 4px grid, lit tip + dark root
		vec2 cell = floor(px / 6.0);
		float h = hash(cell);
		vec2 lp = mod(px, 6.0);
		if (h > 0.8) {
			// a little tuft: three blades, lit tips, shadowed base
			bool blade = (lp.x == 1.5 && lp.y >= 1.5) || (lp.x == 2.5 && lp.y >= 0.5) || (lp.x == 3.5 && lp.y >= 2.5);
			if (blade) col = mix(col, (lp.y < 2.0 ? sg(GRASS_L) * 1.1 : sg(GRASS_M) * 1.05), 0.75);
			if (lp.y > 4.5 && lp.x > 0.5 && lp.x < 4.5) col = mix(col, sg(GRASS_D) * 0.8, 0.5);
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
		ivec2 tcell = ivec2(floor(tile - origin_tiles)) + ivec2(int(data_pad));
		vec4 cc = texelFetch(data, tcell, 0);                       // exact cell: city streets get crisp straight edges
		bool city_cell = cc.g > 0.5 && cc.a < 0.75;
		if (d.a < 0.98 && d.g > 0.02) pe = city_cell ? 1.0 : 0.0;
		if (pe > 0.5) {
			float ds = band(fbm(tile * 0.9 + 2.0), 3.0);
			vec3 dc = mix(mix(DIRT_D, DIRT_M, 0.7), DIRT_M, smoothstep(0.2, 0.55, ds));
			dc = mix(dc, DIRT_L, smoothstep(0.55, 0.9, ds));
			vec4 pv = voronoi(tile * 7.0);
			float peb = step(pv.x, 0.13) * step(0.88, hash(pv.zw));
			dc = mix(dc, mix(STONE_M, STONE_L, step(pv.x, 0.07)), peb);
			dc = mix(dc, DIRT_D, (1.0 - smoothstep(0.5, 0.54, pe)) * 0.45);  // soft darker rim
			col = dc;
			if (!city_cell && wet > 0.05) {
				// rain on dirt paths: darker mud and glossy sky-coloured puddles in the ruts, with a bright rim and a few ripple glints
				float pd = puddle_at(px) * step(0.5, pe);
				col = mix(col, col * 0.72, 0.5 * wet);
				col = puddle_paint(col, px, pd, vec3(0.42, 0.52, 0.64) * (0.88 + 0.25 * fbm(tile * 6.0 + TIME * 0.15)), vec3(0.80, 0.78, 0.74), 0.68);
				col += vec3(0.45) * step(0.985, hash(floor(px / 2.0) + floor(TIME * 3.0) + 17.0)) * step(0.35, pd) * pd;
				col = mix(col, vec3(0.78, 0.86, 0.94), rain_ring(px) * step(0.45, pd) * 0.8);
			}
			if (city_cell) {
				// ---- Port Halden: asphalt (a=0) and paved sidewalk (a=0.5)
				vec2 cp = floor(px / 2.0);
				float sp = hash(cp + 5.0);
				if (cc.a < 0.25) {
					col = mix(vec3(0.23, 0.24, 0.27), vec3(0.30, 0.31, 0.34), step(0.78, sp) * 0.8 + step(0.5, fbm(tile * 3.0)) * 0.12);
					float dash_h = step(0.5, fract(px.x / 64.0)) * step(abs(fract(tile.y) - 0.5), 0.045) * step(0.25, cc.b) * step(cc.b, 0.75);
					float dash_v = step(0.5, fract(px.y / 64.0)) * step(abs(fract(tile.x) - 0.5), 0.045) * step(0.75, cc.b);
					float zb1 = step(0.04, cc.a) * step(cc.a, 0.12);                 // zebra: bars run north-south
					float zb2 = step(0.12, cc.a);                                     // zebra: bars run east-west
					float lane = max(dash_h, dash_v) * (1.0 - max(zb1, zb2));
					col = mix(col, vec3(0.93, 0.80, 0.30), lane);
					float bars = max(zb1 * step(0.5, fract(px.x / 16.0)), zb2 * step(0.5, fract(px.y / 16.0)));
					col = mix(col, vec3(0.88, 0.88, 0.84) * (0.9 + 0.1 * sp), bars * 0.92);
					float pud = puddle_at(px);
					col *= 1.0 - 0.3 * wet;
					col = puddle_paint(col, px, pud, vec3(0.34, 0.45, 0.58) * (0.85 + 0.3 * fbm(tile * 5.0 + TIME * 0.2)), vec3(0.66, 0.76, 0.86), 0.66);
					col += vec3(0.5) * step(0.98, hash(floor(px / 2.0) + floor(TIME * 3.0))) * step(0.35, pud) * pud;
					col = mix(col, vec3(0.74, 0.82, 0.92), rain_ring(px) * step(0.45, pud) * 0.7);
					vec4 nn = texelFetch(data, tcell + ivec2(0, -1), 0);
					if (nn.g > 0.5 && nn.a > 0.25 && nn.a < 0.75) col *= mix(0.55, 1.0, smoothstep(0.0, 0.11, fract(tile.y)));  // curb shadow on the street
				} else {
					vec2 sl = fract(px / 16.0);
					float wsw = wet;
					col = mix(vec3(0.66, 0.64, 0.60), vec3(0.73, 0.71, 0.66), step(0.7, sp));
					col = mix(col, vec3(0.50, 0.48, 0.45), max(step(sl.x, 0.07), step(sl.y, 0.07)) * 0.8);
					float chk = mod(float(tcell.x + tcell.y), 2.0);                                   // paving variation: checkered slab tone + inlaid band every 4th tile
					col *= 0.96 + 0.05 * chk;
					if (mod(float(tcell.x), 4.0) == 0.0 && mod(float(tcell.y), 4.0) == 0.0 && sl.x > 0.3 && sl.x < 0.7 && sl.y > 0.3 && sl.y < 0.7) col = mix(col, vec3(0.62, 0.50, 0.40), 0.55);  // terracotta inlay
					col *= 1.0 - 0.15 * wsw;
					vec4 ns = texelFetch(data, tcell + ivec2(0, -1), 0);
					if (ns.g > 0.5 && ns.a < 0.25 && fract(tile.y) < 0.07) col = mix(col, vec3(0.84, 0.82, 0.77), 0.9);  // sunlit curb lip
				}
			}
		}
		// grass -> path transition: darker grass fringe hugging the edge, tufts leaning over it, and grass specks creeping into the dirt rim
		if (pe <= 0.5 && pe > 0.36) {
			float fr = smoothstep(0.36, 0.5, pe);
			col = mix(col, sg(GRASS_D) * 0.92, fr * 0.7);
			if (hash(floor(px / 2.0) + 13.0) > 0.72 && pe > 0.43) col = mix(col, sg(GRASS_L), 0.8);  // lit blade tips on the lip
		} else if (pe > 0.5 && pe < 0.6) {
			float sp = hash(floor(px / 2.0) + 71.0);
			if (sp > 0.8) col = mix(col, sg(GRASS_M), 0.7);                                          // grass creeping onto the dirt
			else if (pe < 0.53) col = mix(col, DIRT_D, 0.25);
		}
		col = mix(col, col * 0.8, (1.0 - smoothstep(0.42, 0.7, sdf)) * 0.5);  // damp grass near shore
		if (sS < 0.42 && sdf < 0.6) col = mix(col, sg(GRASS_L) * 1.05, 0.55);    // sunlit lip above a bank face
	}
	COLOR = vec4(col, 1.0);
}
