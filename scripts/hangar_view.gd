class_name HangarView
extends CanvasLayer
## Overlay for the Vance hangar break-in (rules in HangarHeist). Move with the move keys, Ctrl sneaks, hold E at a case
## to crack it, walk out through the door (bottom) to bank the loot. Cameras sweep red cones; a full meter = alarm.

signal finished(result: Dictionary)   # {alarm, opened: Array, cash, items: Array}

var canvas: Control
var t := 0.0
var pos := Vector2.ZERO
var meter := 0.0
var opened: Array = []
var crack := 0.0
var crack_idx := -1
var alarm := false
var alarm_t := 0.0
var done := false
var sneaking := false
var demo_pos := Vector2(-1, -1)   # screenshot helper
const SCALE := 1.0

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false
	set_process_input(false)

func open() -> void:
	t = 0.0
	pos = HangarHeist.entrance()
	meter = 0.0
	opened = []
	crack = 0.0
	crack_idx = -1
	alarm = false
	alarm_t = 0.0
	done = false
	visible = true
	set_process_input(true)

func _finish() -> void:
	if done:
		return
	done = true
	visible = false
	set_process_input(false)
	var items: Array = []
	var cash := 0
	if not alarm:
		cash = HangarHeist.total_cash(opened)
		for i in opened:
			var c: Dictionary = HangarHeist.CASES[int(i)]
			if String(c["item"]) != "":
				items.append({"item": c["item"], "n": c["n"]})
	finished.emit({"alarm": alarm, "opened": opened.duplicate(), "cash": cash, "items": items})

func _input(e: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and not alarm:
		_finish()

func _process(d: float) -> void:
	if not visible:
		return
	t += d
	if alarm:
		alarm_t += d
		if alarm_t > 1.6:
			_finish()
		canvas.queue_redraw()
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	sneaking = Input.is_action_pressed("sneak")
	var sp := 60.0 if sneaking else 105.0
	var np := pos + v * sp * d
	var bounds := Rect2(10, 14, HangarHeist.W * 32.0 - 20.0, HangarHeist.H * 32.0 + 6.0 - 14.0)
	np.x = clampf(np.x, bounds.position.x, bounds.end.x)
	np.y = clampf(np.y, bounds.position.y, bounds.end.y + 4.0)
	if np.y > HangarHeist.H * 32.0 - 10.0 and absf(np.x - (HangarHeist.DOOR_X + 0.5) * 32.0) > 24.0:
		np.y = HangarHeist.H * 32.0 - 10.0
	var feet := Rect2(np - Vector2(6, 4), Vector2(12, 8))
	for r in HangarHeist.crate_rects():
		if r.intersects(feet):
			np = pos
			break
	pos = np
	if demo_pos.x >= 0.0:
		pos = demo_pos
	meter = HangarHeist.step_meter(meter, HangarHeist.seen(t, pos), sneaking, d)
	if meter >= 1.0:
		alarm = true
		canvas.queue_redraw()
		return
	var ci := HangarHeist.case_near(pos)
	if Input.is_key_pressed(KEY_E) and ci >= 0 and not (ci in opened):
		if crack_idx != ci:
			crack_idx = ci
			crack = 0.0
		crack += d
		if crack >= HangarHeist.CRACK_TIME:
			opened.append(ci)
			crack = 0.0
			crack_idx = -1
	else:
		crack = maxf(crack - d * 2.0, 0.0)
	if HangarHeist.at_door(pos) and v.y > 0.1:
		_finish()
	canvas.queue_redraw()

func _origin() -> Vector2:
	var vs := get_viewport().get_visible_rect().size
	return (vs - Vector2(HangarHeist.W * 32.0, HangarHeist.H * 32.0)) * 0.5 + Vector2(0, 8)

func _draw_all() -> void:
	var vs := get_viewport().get_visible_rect().size
	var c := canvas
	c.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.04, 0.06, 0.96))
	var o := _origin()
	var W := HangarHeist.W * 32.0
	var H := HangarHeist.H * 32.0
	# back wall and floor
	c.draw_rect(Rect2(o + Vector2(-8, -22), Vector2(W + 16, 24)), Color(0.20, 0.23, 0.28))
	c.draw_rect(Rect2(o + Vector2(-8, -22), Vector2(W + 16, 4)), Color(0.32, 0.36, 0.42))
	for y in HangarHeist.H:
		for x in HangarHeist.W:
			var shade := 0.0 if (x + y) % 2 == 0 else 0.025
			c.draw_rect(Rect2(o + Vector2(x, y) * 32.0, Vector2(32, 32)), Color(0.27 + shade, 0.29 + shade, 0.33 + shade))
	c.draw_rect(Rect2(o, Vector2(W, H)), Color(0.1, 0.1, 0.12), false, 2.0)
	# hazard stripes by the door
	var dx := (HangarHeist.DOOR_X) * 32.0
	for i in 8:
		c.draw_rect(Rect2(o + Vector2(dx + i * 8.0, H - 8.0), Vector2(4, 8)), Color(0.9, 0.75, 0.1))
	# crates and cases
	for r in HangarHeist.CRATES:
		var rr := Rect2(o + Vector2(r.position) * 32.0, Vector2(r.size) * 32.0)
		c.draw_rect(rr.grow(-1), Color(0.42, 0.32, 0.2))
		c.draw_rect(Rect2(rr.position + Vector2(1, 1), Vector2(rr.size.x - 2, 4)), Color(0.58, 0.45, 0.28))
		c.draw_rect(rr.grow(-1), Color(0.18, 0.12, 0.07), false, 1.0)
	for i in HangarHeist.CASES.size():
		var cell: Vector2i = HangarHeist.CASES[i]["cell"]
		var rc := Rect2(o + Vector2(cell) * 32.0, Vector2(32, 32))
		var done_c := i in opened
		c.draw_rect(rc.grow(-3), Color(0.25, 0.3, 0.38) if not done_c else Color(0.2, 0.2, 0.22))
		c.draw_rect(rc.grow(-3), Color(0.8, 0.85, 0.95) if not done_c else Color(0.35, 0.35, 0.38), false, 1.0)
		if not done_c:
			c.draw_rect(Rect2(rc.position + Vector2(13, 11), Vector2(6, 8)), Color(0.95, 0.8, 0.2))
	# camera cones
	for i in HangarHeist.CAMS.size():
		var cam: Dictionary = HangarHeist.CAMS[i]
		var a := HangarHeist.cam_angle(i, t)
		var half := float(cam["fov"]) * 0.5
		var pivot: Vector2 = o + Vector2(cam["pos"])
		var pts := PackedVector2Array([pivot])
		var rng := float(cam["range"])
		for k in 9:
			var aa := a - half + float(k) / 8.0 * half * 2.0
			var dir := Vector2.from_angle(aa)
			var len_px := rng
			# stop the cone at the first crate along each ray
			var s := 4.0
			while s < rng:
				var q: Vector2 = Vector2(cam["pos"]) + dir * s
				var blocked := false
				for r in HangarHeist.CRATES:
					if Rect2(Vector2(r.position) * 32.0, Vector2(r.size) * 32.0).has_point(q):
						blocked = true
						break
				if blocked or q.y > H or q.x < 0.0 or q.x > W:
					len_px = s
					break
				s += 4.0
			pts.append(pivot + dir * len_px)
		var tint := Color(1.0, 0.15, 0.1, 0.20 + (0.15 if alarm else 0.0))
		c.draw_colored_polygon(pts, tint)
		c.draw_circle(pivot, 5.0, Color(0.15, 0.15, 0.18))
		c.draw_circle(pivot + Vector2.from_angle(a) * 3.0, 2.5, Color(1.0, 0.25, 0.2) if int(t * 2.0) % 2 == 0 else Color(0.6, 0.1, 0.1))
	# player
	var pp := o + pos
	c.draw_rect(Rect2(pp + Vector2(-7, 4), Vector2(14, 4)), Color(0, 0, 0, 0.35))
	c.draw_rect(Rect2(pp + Vector2(-5, -10), Vector2(10, 12)), Color(0.2, 0.22, 0.3) if sneaking else Color(0.25, 0.3, 0.42))
	c.draw_rect(Rect2(pp + Vector2(-4, -16), Vector2(8, 7)), Color(0.9, 0.72, 0.55))
	c.draw_rect(Rect2(pp + Vector2(-4, -17), Vector2(8, 3)), Color(0.3, 0.2, 0.1))
	# HUD
	var font := ThemeDB.fallback_font
	c.draw_string(font, o + Vector2(0, -34), "VANCE HANGAR   cases %d/3   $%d" % [opened.size(), HangarHeist.total_cash(opened)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.5))
	c.draw_string(font, o + Vector2(0, H + 20), "Move: walk (Ctrl sneaks)   Hold E: crack a case   Door: leave and bank the loot   Esc: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.85))
	var mb := Rect2(o + Vector2(W - 110, -36), Vector2(110, 8))
	c.draw_rect(mb, Color(0.1, 0.1, 0.12))
	c.draw_rect(Rect2(mb.position, Vector2(mb.size.x * meter, 8)), Color(1.0, 0.3 + (1.0 - meter) * 0.5, 0.1))
	c.draw_rect(mb, Color(0.9, 0.9, 0.9), false, 1.0)
	if crack_idx >= 0:
		var bar := Rect2(pp + Vector2(-16, -26), Vector2(32, 5))
		c.draw_rect(bar, Color(0.1, 0.1, 0.1))
		c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(crack / HangarHeist.CRACK_TIME, 0.0, 1.0), 5)), Color(0.4, 0.9, 0.4))
	if alarm:
		c.draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.1, 0.05, 0.18 + 0.12 * sin(alarm_t * 14.0)))
		c.draw_string(font, o + Vector2(W * 0.5 - 90, H * 0.5), "ALARM! Guards are coming", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.9))
