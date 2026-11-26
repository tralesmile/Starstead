class_name ArtisanView
extends Node2D
## Barn machines in play: loads/collects through ArtisanModel and paints what each machine is doing
## (steam puffs and day pips while working, a bobbing product bubble when ready).

signal message(msg: String)
signal collected(item: String)

var interior: InteriorView
var icons: Dictionary = DataDB.load_json("item_icons")
var items: Dictionary = DataDB.load_json("items")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var t := 0.0

func setup(world: Node2D, room: InteriorView) -> void:
	interior = room
	z_index = 20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(self)
	interior.artisan_requested.connect(use)
	interior.artisan_prompt_cb = func(slot: String) -> String: return GameState.artisan.prompt(slot, GameState.bag, items)

func use(slot: String) -> void:
	var m: ArtisanModel = GameState.artisan
	if m.ready(slot):
		var out := m.collect(slot, GameState.bag)
		if out == "":
			message.emit("Your bag is full")
			return
		GameState.bump("artisan_goods")
		collected.emit(out)
		message.emit("You collect %s" % items[out]["name"])
	elif m.busy(slot):
		message.emit(m.prompt(slot, GameState.bag, items))
	else:
		var r := m.load_machine(slot, GameState.bag)
		if r.is_empty():
			message.emit(m.prompt(slot, GameState.bag, items))
		else:
			message.emit("%s is working: back in %d night%s" % [m.label(slot), int(r["days"]), "" if int(r["days"]) == 1 else "s"])

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	if interior == null or not interior.active:
		return
	for f in interior.layout.get("furniture", []):
		if String(f.get("action", "")) != "artisan":
			continue
		var slot := String(f["id"])
		if not GameState.artisan.busy(slot):
			continue
		var tex: Texture2D = interior._t(String(f["sprite"]))
		var cell: Vector2i = f["cell"]
		var size: Vector2i = f["size"]
		var top := InteriorView.ORIGIN + Vector2(cell.x * 32.0 + size.x * 16.0, (cell.y + size.y) * 32.0 - tex.get_height())
		var phase := float(slot.hash() % 100) * 0.1
		if GameState.artisan.ready(slot):
			var at := top + Vector2(0, -10.0 + ArtisanMath.bubble_bob(t, phase))
			draw_circle(at, 11.0, Color(0.2, 0.12, 0.05, 0.9))
			draw_circle(at, 9.5, Color(0.98, 0.92, 0.72))
			draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 9), at + Vector2(4, 9), at + Vector2(0, 14)]), Color(0.2, 0.12, 0.05, 0.9))
			var out := String(GameState.artisan.slots[slot]["out"])
			draw_texture_rect_region(item_tex, Rect2(at - Vector2(8, 8), Vector2(16, 16)), Rect2(int(icons.get(out, 0)) * 16, 0, 16, 16))
		else:
			for i in 3:
				var p := ArtisanMath.puff(t, phase, i)
				draw_circle(top + Vector2(p.x, p.y + 4.0), p.z, Color(0.96, 0.96, 0.9, ArtisanMath.puff_alpha(t, phase, i)))
