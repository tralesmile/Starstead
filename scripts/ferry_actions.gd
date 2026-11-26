class_name FerryActions
extends RefCounted
## E on a ferry post or the star cairn. `m` is Main. Kept out of main.gd.

static func run(m, outbound: bool) -> void:
	var q := FerryModel.quote(GameState.clock.minutes, m.rain_today, GameState.money, outbound)
	if not q["ok"]:
		m._say(String(q["why"]))
		m.toast_t = 4.0
		m.sfx_director.play("error")
		return
	GameState.money -= int(q["fare"])
	GameState.clock.minutes = minf(float(q["arrive"]), float(GameClock.DAY_LENGTH_MIN) - 1.0)
	GameState.bump("ferry_rides")
	var cell: Vector2i = IsleModel.LANDING if outbound else FerryModel.HARBOUR_LANDING
	m.player.velocity = Vector2.ZERO
	m.player.move_v = Vector2.ZERO
	m.player.set_physics_process(false)
	m.player.position = (Vector2(cell) + Vector2(0.5, 0.6)) * 32.0
	m.player.facing = PlayerMath.Facing.RIGHT if outbound else PlayerMath.Facing.UP
	var where := "Gull Isle" if outbound else "Halden Harbour"
	var rough: String = " - rough crossing" if m.rain_today >= FerryModel.STORM else ""
	m.ferry_view.open(outbound, m.rain_today, "%s ferry to %s, arriving %s%s" % [FerryModel.time_text(int(q["depart"])), where, FerryModel.time_text(int(q["arrive"])), rough])
	m.sfx_director.play("ship_horn")

static func arrived(m) -> void:
	m.player.set_physics_process(true)
	if m.ferry_view.outbound:
		m._say("Beach finds wash up daily. Last boat home 22:00")
	else:
		m._say("Back at Halden Harbour")
	m.toast_t = 5.0
	m.region_banner.show_region("Gull Isle" if m.ferry_view.outbound else "Halden Harbour")
	GameState.save_game()

static func cairn(m) -> void:
	if GameState.isle.read_cairn():
		GameState.bag.add(IsleModel.CAIRN_REWARD, 1)
		m._say("A star is carved here, and 'E.' - grandmother? Under a loose stone: a pearl, and a note: 'The Moon was only the first door.'")
	else:
		m._say("Grandmother's star cairn. The carved star points straight up")
	m.toast_t = 6.0
