class_name MapView
extends CanvasLayer
## World map (M): terrain, roads, regions, points of interest (fuel stations in orange), player marker and the nearest fuel hint.

signal closed

const SCALE := 2
const KIND_COL := {"home": Color(1, 0.9, 0.3), "town": Color(0.9, 0.9, 0.95), "fuel": Color(1, 0.55, 0.1), "sea": Color(0.4, 0.8, 1), "race": Color(1, 0.3, 0.3), "cave": Color(0.8, 0.6, 0.9), "place": Color(0.8, 0.95, 0.6)}
const REGION_COL := {"gull_isle": Color(0.34, 0.55, 0.3), "homestead": Color(0.36, 0.55, 0.28), "farmland": Color(0.5, 0.62, 0.3), "pine_forest": Color(0.2, 0.38, 0.24), "port_halden": Color(0.45, 0.47, 0.5), "harbour": Color(0.5, 0.52, 0.45), "highlands": Color(0.5, 0.45, 0.4), "vance": Color(0.45, 0.45, 0.5), "circuit": Color(0.42, 0.55, 0.3)}

var canvas: Control
var tex: ImageTexture
var gen: WorldGen
var stream: ChunkStream
var player: Node2D
var pois: Array = []
var locked: Dictionary = {}          # region id -> msg (story gates still shut), refreshed on open
var locked_cb: Callable              # main supplies MapModel.locked_regions(...) for the current story
var _open := false
var _t := 0.0

func _init() -> void:
	layer = 12
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)

func setup(p: Node2D, g: WorldGen, workshop: Vector2i) -> MapView:
	player = p
	gen = g
	stream = g.stream_ref
	var roads: RoadNet = stream.roads if stream != null else null
	pois = MapModel.pois(roads.cave_mouth if roads else Vector2i(RoadNet.NO_CELL, 0), roads.hubs if roads else {}, workshop)
	return self

func is_open() -> bool:
	return _open

func toggle() -> void:
	_open = not _open
	if _open and locked_cb.is_valid():
		locked = locked_cb.call()
	if _open and tex == null:
		tex = ImageTexture.create_from_image(_build_image())
	canvas.queue_redraw()
	if not _open:
		closed.emit()

func handle(e: InputEvent) -> bool:
	if e is InputEventKey and e.is_action_pressed("map"):
		toggle()
		return true
	if _open and (e.is_action_pressed("pause") or e.is_action_pressed("inventory")):
		toggle()
		return true
	return _open and (e is InputEventKey or e is InputEventMouseButton)

func _build_image() -> Image:
	var img := Image.create(MapModel.N, MapModel.N, false, Image.FORMAT_RGBA8)
	for y in MapModel.N:
		for x in MapModel.N:
			var c := Vector2i(MapModel.X0 + x * MapModel.STEP + 2, MapModel.Y0 + y * MapModel.STEP + 2)
			var wet := 0
			for o in [Vector2i(0, 0), Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2)]:   # majority vote: fewer salt-and-pepper pixels
				if _is_water(c + o):
					wet += 1
			var col := _terrain(c)
			if wet >= 3 and not _is_water(c):
				col = _water_col(c)
			elif wet <= 2 and _is_water(c):
				col = _land_col(c)
			img.set_pixel(x, y, col)
	if stream != null:   # roads on top
		for ch in stream.roads.cells:
			var o := ChunkGrid.origin_cell(ch)
			for lc in stream.roads.cells[ch]:
				var p := MapModel.to_map(Vector2(o + lc))
				var px := Vector2i(int(p.x), int(p.y))
				if px.x >= 0 and px.y >= 0 and px.x < MapModel.N and px.y < MapModel.N:
					img.set_pixel(px.x, px.y, Color(0.85, 0.72, 0.5))
	return img

func _terrain(c: Vector2i) -> Color:
	if CityModel.in_rect(c):
		return Color(0.5, 0.52, 0.56) if CityModel.is_asphalt(c) or CityModel.RECT.has_point(c) else Color(0.7, 0.7, 0.72)
	if CircuitModel.in_rect(c):
		return Color(0.3, 0.3, 0.33) if CircuitModel.on_circuit(c) else Color(0.42, 0.55, 0.3)
	if HarbourModel.is_quay(c) or IsleModel.is_jetty(c):
		return Color(0.62, 0.6, 0.55)
	if IsleModel.is_island(c):
		return Color(0.82, 0.74, 0.5) if IsleModel.is_beach(c) else Color(0.34, 0.55, 0.3)
	if _is_water(c):
		return _water_col(c)
	return _land_col(c)

func _is_water(c: Vector2i) -> bool:
	if CityModel.in_rect(c) or CircuitModel.in_rect(c) or HarbourModel.is_quay(c):
		return false
	return gen != null and gen._water_noise(c.x, c.y)

func _water_col(c: Vector2i) -> Color:
	return Color(0.16, 0.32, 0.52) if HarbourModel.is_deep(c) else Color(0.22, 0.45, 0.65)

func _land_col(c: Vector2i) -> Color:
	var ch := ChunkGrid.chunk_of_cell(c)
	var rid := String(stream.region_at(ch).get("id", "")) if stream != null else ""
	return REGION_COL.get(rid, Color(0.4, 0.5, 0.3))

func _process(d: float) -> void:
	if _open:
		_t += d
		canvas.queue_redraw()

func _draw_all() -> void:
	if not _open or tex == null:
		return
	var vs := get_viewport().get_visible_rect().size
	canvas.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.72))
	var sz := Vector2(MapModel.N, MapModel.N) * SCALE
	var o := Vector2(16, (vs.y - sz.y) * 0.5)
	canvas.draw_rect(Rect2(o - Vector2(3, 3), sz + Vector2(6, 6)), Color(0.82, 0.7, 0.45))
	canvas.draw_texture_rect(tex, Rect2(o, sz), false)
	var font := ThemeDB.fallback_font
	_draw_locked(o, font)
	for p in pois:
		var mp := o + MapModel.to_map(Vector2(p["cell"])) * SCALE
		var col: Color = KIND_COL.get(p["kind"], Color.WHITE)
		canvas.draw_rect(Rect2(mp - Vector2(2, 2), Vector2(5, 5)), Color(0, 0, 0))
		canvas.draw_rect(Rect2(mp - Vector2(1, 1), Vector2(3, 3)), col)
	var pc := Vector2(floori(player.position.x / 32.0), floori(player.position.y / 32.0))
	var pm := o + MapModel.clamp_px(MapModel.to_map(pc)) * SCALE
	var r := 4.0 + 1.5 * sin(_t * 6.0)
	canvas.draw_circle(pm, r + 1.0, Color(0, 0, 0))
	canvas.draw_circle(pm, r, Color(1, 0.2, 0.2))
	# legend
	var lx := o.x + sz.x + 16.0
	var ly := o.y + 4.0
	canvas.draw_string(font, Vector2(lx, ly + 10), "WORLD MAP   (M or Esc closes)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.7))
	ly += 24.0
	for p in pois:
		var col: Color = KIND_COL.get(p["kind"], Color.WHITE)
		canvas.draw_rect(Rect2(Vector2(lx, ly - 7), Vector2(6, 6)), col)
		var dist := int(Vector2(p["cell"] - Vector2i(pc)).length())
		var shut := _poi_locked(p)
		canvas.draw_string(font, Vector2(lx + 12, ly), "%s  (%d)%s" % [p["name"], dist, "  LOCKED" if shut else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.6, 0.6) if shut else Color(0.95, 0.95, 0.95))
		ly += 14.0
	canvas.draw_string(font, Vector2(lx, ly + 8), "Red dot = you. Orange = fuel.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.7, 0.3))
	var fp := MapModel.fuel_prompt(Vector2i(pc), pois)
	canvas.draw_string(font, Vector2(lx, ly + 22), fp, HORIZONTAL_ALIGNMENT_LEFT, int(vs.x - lx - 4), 9, Color(1, 0.8, 0.4))
	if not locked.is_empty():
		ly += 40.0
		canvas.draw_string(font, Vector2(lx, ly), "Hatched = closed for now:", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 0.55, 0.45))
		var ids: Array = locked.keys()
		ids.sort()
		for rid in ids:
			ly += 13.0
			canvas.draw_string(font, Vector2(lx + 6, ly), "- " + str(locked[rid]), HORIZONTAL_ALIGNMENT_LEFT, int(vs.x - lx - 10), 8, Color(0.9, 0.8, 0.75))

func _region_of_cell(c: Vector2i) -> String:
	return String(stream.region_at(ChunkGrid.chunk_of_cell(c)).get("id", "")) if stream != null else ""

func _poi_locked(p: Dictionary) -> bool:
	return locked.has(_region_of_cell(p["cell"]))

func _draw_locked(o: Vector2, _font: Font) -> void:
	## Story-gated regions: darkened with red diagonal hatching (like a closed road on a paper map).
	if locked.is_empty() or stream == null:
		return
	for cy in ChunkGrid.GRID:
		for cx in ChunkGrid.GRID:
			var ch := Vector2i(cx, cy)
			if not locked.has(String(stream.region_at(ch).get("id", ""))):
				continue
			var r := MapModel.chunk_rect(ch)
			var rr := Rect2(o + r.position * SCALE, r.size * SCALE)
			canvas.draw_rect(rr, Color(0.05, 0.03, 0.03, 0.45))
			var step := 6.0
			var k := 0.0
			while k < rr.size.x + rr.size.y:
				var a := rr.position + Vector2(minf(k, rr.size.x), maxf(0.0, k - rr.size.x))
				var b := rr.position + Vector2(maxf(0.0, k - rr.size.y), minf(k, rr.size.y))
				canvas.draw_line(a, b, Color(0.85, 0.25, 0.2, 0.55), 1.0)
				k += step
