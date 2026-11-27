class_name BankJobView
extends CanvasLayer
## Overlay for the Halden Bank vault job (rules in BankJob): move keys walk, Ctrl sneaks, Shift runs (loud),
## hold E for the keycard, fuse box, vault door and cash bags; walk out of the door to bank. Esc drops it all.

signal finished(result: Dictionary)   # {caught: bool, cash: int, bags: int}

const CELL := BankJob.CELL
const END_TIME := 1.8

var job := BankJob.new()
var canvas: Control
var done := false
var end_t := 0.0
var quit_armed := 0.0       # Esc with bags in hand asks once more
var frozen := false         # screenshot helper: hold the scene still
var facing := PlayerMath.Facing.UP
var walk_t := 0.0
var sneaking := false
var _props: Texture2D
var _folk: Texture2D

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false
	set_process_input(false)

func open() -> void:
	_props = load("res://assets/sprites/bankjob.png")
	_folk = load(NpcLook.SHEET)
	job.reset()
	done = false
	end_t = 0.0
	quit_armed = 0.0
	frozen = false
	facing = PlayerMath.Facing.UP
	visible = true
	set_process_input(true)
	canvas.queue_redraw()

## Leave right now with nothing (the day ended under you).
func abort() -> void:
	job.abandon()
	_finish()

func _finish() -> void:
	if done:
		return
	done = true
	visible = false
	set_process_input(false)
	var out := job.result == "out"
	finished.emit({"caught": job.result == "caught", "cash": job.banked(), "bags": job.taken.size() if out else 0})

func _input(e: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE and job.result == "":
		if job.taken.is_empty() or quit_armed > 0.0:
			abort()
		else:
			quit_armed = 3.0

func _process(d: float) -> void:
	if not visible:
		return
	if job.result != "":
		end_t += d
		if job.result != "caught" or end_t > END_TIME:
			_finish()
		canvas.queue_redraw()
		return
	quit_armed = maxf(quit_armed - d, 0.0)
	if not frozen:
		var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		sneaking = Input.is_action_pressed("sneak")
		var running := Input.is_action_pressed("sprint") and not sneaking
		job.step(d, v, sneaking, running, Input.is_action_pressed("interact"))
		if job.moving:
			walk_t += d * (13.0 if running else (6.0 if sneaking else 9.0))
			facing = _face_of(v.angle())
		else:
			walk_t = 0.0
	canvas.queue_redraw()

static func _face_of(a: float) -> int:
	if absf(a) <= PI * 0.25:
		return PlayerMath.Facing.RIGHT
	if absf(a) >= PI * 0.75:
		return PlayerMath.Facing.LEFT
	return PlayerMath.Facing.DOWN if a > 0.0 else PlayerMath.Facing.UP

func _prop(at: Vector2, x: int, w: int = 32) -> void:
	canvas.draw_texture_rect_region(_props, Rect2(at, Vector2(w, 32)), Rect2(x, 0, w, 32))

func _person(feet: Vector2, outfit: int, face: int, col: int, tint: Color) -> void:
	var fs := Vector2(_folk.get_width() / 8.0, _folk.get_height() / float(4 * NpcLook.OUTFITS.size()))
	var fr := NpcLook.frame(outfit, face, col)
	var src := Rect2(Vector2(fr % 8, fr / 8) * fs, fs)
	canvas.draw_circle(feet + Vector2(0, 1), 7.0, Color(0, 0, 0, 0.25))
	canvas.draw_texture_rect_region(_folk, Rect2((feet - fs * 0.5 + Vector2(0, -22)).round(), fs), src, tint)

func _cone(from: Vector2, a: float, rng: float, fov: float, col: Color, rects: Array[Rect2]) -> void:
	var o := BankJob.ORIGIN
	var pts := PackedVector2Array([o + from])
	for k in 17:
		var aa := a - fov * 0.5 + fov * k / 16.0
		pts.append(o + from + Vector2.from_angle(aa) * job.ray_length(from, aa, rng, rects))
	for k in range(1, pts.size() - 1):   # a fan of triangles: clipped cones are not always simple polygons
		var tri := PackedVector2Array([pts[0], pts[k], pts[k + 1]])
		if absf((tri[1] - tri[0]).cross(tri[2] - tri[0])) > 1.0:
			canvas.draw_colored_polygon(tri, col)
	canvas.draw_line(pts[0], pts[1], Color(col, 0.6), 1.0)
	canvas.draw_line(pts[0], pts[pts.size() - 1], Color(col, 0.6), 1.0)

func _wall(r: Rect2) -> void:
	canvas.draw_rect(r, Color(0.32, 0.29, 0.30))
	canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), Color(0.55, 0.50, 0.47))
	canvas.draw_rect(r, WoodUI.OUTLINE, false, 1.0)

func _draw_all() -> void:
	if not visible:
		return
	var c := canvas
	var vs := get_viewport().get_visible_rect().size
	var o := BankJob.ORIGIN
	var room := Vector2(BankJob.W, BankJob.H) * CELL
	c.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.03, 0.05, 0.97))
	var title := "HALDEN BANK - VAULT WING      bags %d/%d  $%d" % [job.taken.size(), BankJob.BAGS.size(), BankJob.total_cash(job.taken)]
	WoodUI.panel(c, BankJob.PANEL, title, WoodUI.Trim.IRON)
	# floor: night-blue marble in the hall, brass-tinted in the vault
	for y in BankJob.H:
		for x in BankJob.W:
			var base := Color(0.34, 0.30, 0.22) if x > 12 else Color(0.26, 0.28, 0.34)
			c.draw_rect(Rect2(o + Vector2(x, y) * CELL, Vector2(CELL, CELL)), base.lightened(0.05) if (x + y) % 2 == 0 else base)
	c.draw_rect(Rect2(o + Vector2(0, 0), Vector2(5, 3) * CELL), Color(0.45, 0.30, 0.16, 0.35))   # guard room boards
	WoodUI.text(c, o + Vector2(6, 80), "GUARD ROOM", 9, Color(1, 0.94, 0.72, 0.55))
	WoodUI.text(c, o + Vector2(13.4 * CELL, 3.3 * CELL), "VAULT", 12, Color(1, 0.85, 0.4, 0.6))
	var ex := o + Vector2(BankJob.EXIT_X * CELL, room.y - 6)
	c.draw_rect(Rect2(ex, Vector2(CELL, 6)), WoodUI.GOLD)
	WoodUI.text(c, ex + Vector2(34, 4), "EXIT", 9, WoodUI.GOLD)
	for r in BankJob.WALLS:
		var wr := BankJob.px(r)
		_wall(Rect2(o + wr.position, wr.size))
	for r in BankJob.COVER:
		for cx in r.size.x:
			for cy in r.size.y:
				_prop(o + Vector2(r.position + Vector2i(cx, cy)) * CELL, 224)
	_prop(o + BankJob.px(BankJob.DESK).position, 64 if job.has_card else 0, 64)
	_prop(o + BankJob.px(BankJob.FUSE).position, 128 if job.cams_on else 160)
	var door := BankJob.px(BankJob.VAULT_DOOR)
	door.position += o
	if job.vault_open:
		c.draw_rect(Rect2(door.position, Vector2(door.size.x, 4)), Color(0.62, 0.67, 0.72))
	else:
		c.draw_rect(door, Color(0.46, 0.50, 0.56))
		c.draw_rect(door, WoodUI.OUTLINE, false, 1.0)
		c.draw_arc(door.get_center(), 9.0, 0.0, TAU, 20, Color(0.82, 0.86, 0.9), 2.0)
		c.draw_line(door.get_center() - Vector2(9, 0), door.get_center() + Vector2(9, 0), Color(0.82, 0.86, 0.9), 2.0)
		c.draw_rect(Rect2(door.position + Vector2(3, 3), Vector2(4, 4)), Color(0.95, 0.25, 0.2))
	for i in BankJob.BAGS.size():
		if not (i in job.taken):
			var bp := o + BankJob.bag_rect(i).position
			_prop(bp, 192)
	# vision cones
	var rects := job.blockers()
	if job.cams_on:
		for i in BankJob.CAMS.size():
			var cam: Dictionary = BankJob.CAMS[i]
			var eye := job.cam_sees(i, job.pos)
			_cone(cam["pos"], BankJob.cam_angle(i, job.t), float(cam["range"]), float(cam["fov"]), Color(1.0, 0.2, 0.15, 0.34 if eye else 0.17), rects)
	var calm := job.g_state == BankJob.Guard.PATROL or job.g_state == BankJob.Guard.PAUSE
	var gcol := Color(1.0, 0.9, 0.35, 0.22) if calm else Color(1.0, 0.55, 0.1, 0.28)
	if job.guard_sees(job.pos):
		gcol = Color(1.0, 0.2, 0.1, 0.38)
	_cone(job.g_pos, job.g_face, BankJob.GUARD_RANGE, BankJob.GUARD_FOV, gcol, rects)
	for i in BankJob.CAMS.size():
		var piv: Vector2 = o + Vector2(BankJob.CAMS[i]["pos"])
		c.draw_circle(piv, 5.0, WoodUI.OUTLINE)
		var look := Vector2.from_angle(BankJob.cam_angle(i, job.t) if job.cams_on else PI * 0.5)
		c.draw_line(piv, piv + look * 8.0, Color(0.7, 0.74, 0.8), 3.0)
		c.draw_circle(piv, 2.0, Color(1, 0.25, 0.2) if job.cams_on else Color(0.3, 0.3, 0.32))
	# guard and burglar, drawn back to front
	var g_walking := job.g_state == BankJob.Guard.PATROL or job.g_state == BankJob.Guard.INVESTIGATE
	var folk := [
		[o + job.g_pos, NpcLook.POLICE, _face_of(job.g_face), 1 + int(job.t * 7.0) % 6 if g_walking else 0, Color.WHITE],
		[o + job.pos, NpcLook.outfit_of("citizen_b"), facing, 1 + int(walk_t) % 6 if walk_t > 0.0 else 0, Color(0.45, 0.48, 0.6) if sneaking else Color(0.68, 0.7, 0.82)]]
	if job.g_pos.y > job.pos.y:
		folk.reverse()
	for f in folk:
		_person(f[0], f[1], f[2], f[3], f[4])
	if not calm:
		var mark := "?" if job.g_state != BankJob.Guard.INVESTIGATE else "!"
		var at := o + job.g_pos + Vector2(-4, -34)
		at.y = maxf(at.y, o.y + 12.0)
		c.draw_string_outline(ThemeDB.fallback_font, at, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, WoodUI.OUTLINE)
		WoodUI.text(c, at, mark, 18, Color(1.0, 0.75, 0.2) if mark == "?" else Color(1.0, 0.35, 0.25))
	# detection meter on the lower right of the panel
	var footer_y := o.y + room.y + 15.0
	var mb := Rect2(BankJob.PANEL.end.x - 106, footer_y - 8, 96, 9)
	WoodUI.text(c, Vector2(mb.position.x - 34, footer_y), "SEEN", 10, WoodUI.INK)
	c.draw_rect(mb, WoodUI.WOOD_D)
	c.draw_rect(Rect2(mb.position, Vector2(mb.size.x * job.meter, mb.size.y)), Color(1.0, 0.75 * (1.0 - job.meter) + 0.1, 0.1))
	c.draw_rect(mb, WoodUI.OUTLINE, false, 1.0)
	var goal := "Take the keycard (guard desk)" if not job.has_card else ("Open the vault door" if not job.vault_open else ("Bag the cash" if job.taken.size() < BankJob.BAGS.size() else "Get out through the EXIT"))
	var hint := "Ctrl sneak  Shift run (loud)  Hold E use  Walk out of EXIT to keep cash  Esc drop it"
	if quit_armed > 0.0:
		hint = "Press Esc again to drop the bags and leave with nothing."
	WoodUI.text(c, Vector2(o.x, footer_y), hint, 10, WoodUI.BAD if quit_armed > 0.0 else WoodUI.INK, mb.position.x - 40 - o.x)
	WoodUI.text(c, BankJob.PANEL.position + Vector2(0, 15), goal, 10, WoodUI.CREAM, BankJob.PANEL.size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
	# what E does here, tagged above your head and kept inside the room
	var u := job.use_target()
	if not u.is_empty() and job.result == "":
		var s := String(u["label"])
		var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 10.0
		var tag := Rect2(o + job.pos + Vector2(-w * 0.5, -52), Vector2(w, 15))
		if tag.position.y < o.y + 2:
			tag.position.y = o.y + job.pos.y + 14
		tag.position.x = clampf(tag.position.x, o.x + 2, o.x + room.x - w - 2)
		c.draw_rect(tag.grow(1), WoodUI.OUTLINE)
		c.draw_rect(tag, WoodUI.PAPER)
		WoodUI.text(c, tag.position + Vector2(5, 11), s, 10)
		if job.hold > 0.0:
			var bar := Rect2(tag.position + Vector2(0, 16), Vector2(w, 4))
			c.draw_rect(bar, WoodUI.OUTLINE)
			c.draw_rect(Rect2(bar.position, Vector2(w * clampf(job.hold / float(u["need"]), 0.0, 1.0), 4)), Color(0.4, 0.9, 0.4))
	if job.result == "caught":
		c.draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.1, 0.05, 0.16 + 0.1 * sin(end_t * 14.0)))
		var box := Rect2(vs * 0.5 - Vector2(130, 32), Vector2(260, 56))
		WoodUI.panel(c, box, "CAUGHT!", WoodUI.Trim.EMBER)
		WoodUI.text(c, box.position + Vector2(0, 43), "The guard has you. The bags stay here.", 10, WoodUI.BAD, box.size.x, HORIZONTAL_ALIGNMENT_CENTER)
