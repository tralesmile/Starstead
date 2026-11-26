class_name FerryView
extends CanvasLayer
## The crossing: a short painted scene of the ferry sailing over open water with its wake, then `arrived`.
## E / Esc skips. The player has already been moved behind it, so the world is streamed in when it lifts.

signal arrived

const DURATION := 4.0

var canvas: Control
var t := 0.0
var rain := 0.0
var outbound := true
var title := ""
var _tex: Texture2D = load("res://assets/sprites/ferry.png")

func _init() -> void:
	layer = 60
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open(is_outbound: bool, storm: float, text: String) -> void:
	outbound = is_outbound
	rain = storm
	title = text
	t = 0.0
	visible = true

func finish() -> void:
	if visible:
		visible = false
		arrived.emit()

func handle(e: InputEvent) -> void:
	if t > 0.4 and (e.is_action_pressed("interact") or e.is_action_pressed("pause")):
		finish()

func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	canvas.size = get_viewport().get_visible_rect().size
	canvas.queue_redraw()
	if t >= DURATION:
		finish()

func _draw_all() -> void:
	var sz := canvas.size
	var rough := clampf(rain, 0.0, 1.0)
	var sky_h := sz.y * 0.30
	var top := Color(0.5, 0.74, 0.9).lerp(Color(0.3, 0.35, 0.44), rough)
	var low := Color(0.86, 0.92, 0.9).lerp(Color(0.5, 0.54, 0.6), rough)
	for i in 12:
		canvas.draw_rect(Rect2(0, sky_h * i / 12.0, sz.x, sky_h / 12.0 + 1), top.lerp(low, i / 11.0))
	for i in 14:   # sea, darker toward the viewer
		var y0 := sky_h + (sz.y - sky_h) * i / 14.0
		canvas.draw_rect(Rect2(0, y0, sz.x, (sz.y - sky_h) / 14.0 + 1), Color(0.24, 0.62, 0.68).lerp(Color(0.05, 0.2, 0.34), i / 13.0).darkened(rough * 0.25))
	# far shores: the one we leave shrinks behind, the one ahead rises
	var f := FerryModel.sail_progress(t / DURATION)
	var dir := 1.0 if outbound else -1.0
	_shore(Vector2(sz.x * (0.5 - dir * (0.38 + 0.2 * f)), sky_h), 150.0 * (1.0 - 0.5 * f), outbound)
	_shore(Vector2(sz.x * (0.5 + dir * (0.52 - 0.2 * f)), sky_h), 60.0 + 100.0 * f, not outbound)
	for i in 60:   # drifting wave dashes, faster and bigger near the viewer
		var depth := fposmod(i * 0.618, 1.0)
		var y := sky_h + 4.0 + depth * (sz.y - sky_h - 8.0)
		var x := fposmod(i * 197.0 - dir * t * (20.0 + depth * 90.0), sz.x + 40.0) - 20.0
		canvas.draw_rect(Rect2(x, y + sin(t * 3.0 + i) * (1.0 + 2.0 * rough), 5.0 + depth * 14.0, 1.0 + roundf(depth)), Color(0.8, 0.96, 0.95, 0.2 + 0.25 * depth))
	var b := FerryModel.bob(t, rain)
	var at := Vector2(sz.x * (0.5 - dir * 0.18 + dir * 0.36 * f), sz.y * 0.62 + float(b["y"]) * 2.0)
	var speed := FerryModel.sail_speed(t / DURATION)
	for k in range(1, 22):   # wake: two spreading foam lines astern
		var back := at + Vector2(-dir * (70.0 + k * 9.0 * (0.5 + speed)), 34.0)
		var spread := k * 1.7
		var a := (1.0 - k / 22.0) * clampf(speed, 0.15, 1.0)
		var jit := sin(t * 9.0 + k) * 1.5
		for s in [-1.0, 1.0]:
			canvas.draw_rect(Rect2(back + Vector2(0, s * spread + jit), Vector2(8, 2)), Color(0.93, 0.99, 0.98, a))
	canvas.draw_set_transform(at, float(b["roll"]) * 1.5, Vector2(2.0 * dir, 2.0))
	canvas.draw_texture(_tex, Vector2(-48, -44))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for k in 7:   # funnel smoke drifting astern
		var age := fposmod(t * 1.2 + k / 7.0, 1.0)
		canvas.draw_circle(at + Vector2(-dir * (age * 90.0 + 6.0), -78.0 - age * 34.0), 3.0 + age * 9.0, Color(0.9, 0.92, 0.92, 0.5 * (1.0 - age)))
	for k in 5:   # gulls
		var g := Vector2(fposmod(k * 173.0 + t * (26.0 + k * 5.0), sz.x), 26.0 + k * 15.0 + sin(t * 2.0 + k) * 4.0)
		var flap := sin(t * 8.0 + k * 1.7) * 3.0
		canvas.draw_polyline(PackedVector2Array([g + Vector2(-6, -flap), g, g + Vector2(6, -flap)]), Color(0.97, 0.97, 0.95), 1.0)
	if rough > 0.5:
		for k in 90:
			var q := Vector2(fposmod(k * 97.0 - t * 220.0, sz.x), fposmod(k * 53.0 + t * 520.0, sz.y))
			canvas.draw_line(q, q + Vector2(-4, 11), Color(0.8, 0.87, 0.95, 0.35), 1.0)
	var font := ThemeDB.fallback_font
	canvas.draw_rect(Rect2(0, sz.y - 34, sz.x, 34), Color(0.03, 0.07, 0.12, 0.75))
	canvas.draw_string(font, Vector2(12, sz.y - 13), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.72))
	canvas.draw_string(font, Vector2(sz.x - 90, sz.y - 13), "E: skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.85, 0.9))

func _shore(at: Vector2, w: float, is_isle: bool) -> void:
	var pts := PackedVector2Array([at + Vector2(-w, 1)])
	for i in 11:
		var u := i / 10.0
		var h := sin(u * PI) * w * (0.16 if is_isle else 0.09) + absf(sin(u * 17.0)) * (4.0 if is_isle else 9.0)
		pts.append(at + Vector2(-w * 0.9 + u * w * 1.8, -h))
	pts.append(at + Vector2(w, 1))
	canvas.draw_colored_polygon(pts, Color(0.2, 0.4, 0.3) if is_isle else Color(0.34, 0.4, 0.46))
	if not is_isle:   # town lights/roofs on the mainland
		for i in 6:
			canvas.draw_rect(Rect2(at + Vector2(-w * 0.6 + i * w * 0.22, -12.0 - (i * 7) % 11), Vector2(8, 10)), Color(0.72, 0.52, 0.4))
