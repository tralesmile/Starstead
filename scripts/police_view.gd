class_name PoliceView
extends Node2D
## Wanted stars (top-right label), police sprites that chase the player, arrest = fine + reset.

signal message(msg: String)

var player: Node2D
var world: Node2D
var heat := 0.0
var cops: Array = []   # Node2D
var stars_label: Label
var hud: WantedHud
var home := Vector2.ZERO
var gen: WorldGen
var combat: CombatView

func setup(w: Node2D, p: Node2D, hud_parent: Node, g: WorldGen) -> void:
	world = w
	player = p
	gen = g
	home = p.position
	if "--wanted" in OS.get_cmdline_user_args():
		heat = 70.0
	var layer := CanvasLayer.new()
	layer.layer = 6
	hud = WantedHud.new()
	hud.position = Vector2(508, 8)
	layer.add_child(hud)
	hud_parent.add_child(layer)

func commit(kind: String, pos: Vector2) -> void:
	var cop_pos: Array = []
	for c in cops:
		cop_pos.append((c as Node2D).position)
	heat = WantedMath.add(heat, kind, PoliceModel.witnessed(cop_pos, pos) or cops.size() > 0 or randf() < 0.5)
	_sync_cops()

func add_heat(h: float) -> void:
	heat = clampf(heat + h, 0.0, WantedMath.MAX_HEAT)
	_sync_cops()

func stars() -> int:
	return WantedMath.stars(heat)

func _make_cop(p: Vector2) -> Node2D:
	var n := Node2D.new()
	var s := NpcLook.make_sprite(NpcLook.POLICE)   # navy uniform + peaked cap (tools/gen_npcs.py)
	s.name = "Sprite"
	n.add_child(s)
	n.set_meta("t", 0.0)
	n.set_meta("face", 0)
	n.add_child(World.make_shadow(20))
	n.position = p
	world.add_child(n)
	return n

func _sync_cops() -> void:
	var want := WantedMath.police_count(stars())
	while cops.size() < want:
		var pts := PoliceModel.spawn_positions(player.position, want)
		cops.append(_make_cop(pts[cops.size() % pts.size()]))
	while cops.size() > want:
		(cops.pop_back() as Node2D).queue_free()

func _process(delta: float) -> void:
	var cp: Array = []
	for c in cops:
		cp.append((c as Node2D).position)
	heat = WantedMath.decay(heat, delta, PoliceModel.any_sees(cp, player.position))
	var n := stars()
	hud.heat = heat
	hud.seen = PoliceModel.any_sees(cp, player.position)
	if n != WantedMath.stars(heat) or cops.size() != WantedMath.police_count(n):
		_sync_cops()
	for c in cops:
		var cn := c as Node2D
		if combat != null and combat.is_down(cn):
			continue  # knocked out
		var before := cn.position
		cn.position = PoliceModel.step(cn.position, player.position, n, delta)
		_animate(cn, cn.position - before, delta)
		if PoliceModel.arrests(cn.position, player.position):
			_arrest()
			return

func _animate(cn: Node2D, d: Vector2, delta: float) -> void:
	var moving := d.length() > 0.01
	var face := NpcSchedule.facing_of(d, int(cn.get_meta("face", 0)))
	var t: float = float(cn.get_meta("t", 0.0)) + delta if moving else 0.0
	cn.set_meta("face", face)
	cn.set_meta("t", t)
	var s := cn.get_node_or_null("Sprite") as Sprite2D
	if s != null:
		s.frame = NpcLook.frame(NpcLook.POLICE, face, PlayerMath.walk_frame_hd(t, moving))

func _arrest() -> void:
	var fine := mini(WantedMath.fine(stars()), GameState.money)
	GameState.money -= fine
	GameState.rep_honest = maxi(GameState.rep_honest - stars(), 0)
	heat = 0.0
	_sync_cops()
	player.position = home
	message.emit("Arrested! Fine $%d" % fine)
