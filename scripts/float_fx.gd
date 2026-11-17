class_name FloatFx
extends Node2D
## Floating "+2 Wood" labels with the item icon over the player.

var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var tex: Texture2D = load("res://assets/sprites/items.png")
var active: Array = []  # {node, t, slot}
var recent := 0.0

func _ready() -> void:
	z_index = 90

func pickup(at: Vector2, id: String, n: int) -> void:
	var node := Node2D.new()
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = maxi(1, tex.get_width() / 16)
	spr.frame = int(icons.get(id, 0))
	spr.position = Vector2(-10, 0)
	spr.scale = Vector2(0.75, 0.75)
	node.add_child(spr)
	var l := Label.new()
	l.text = "+%d %s" % [n, String(items.get(id, {}).get("name", id))]
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(1, 1, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	l.add_theme_constant_override("outline_size", 3)
	l.position = Vector2(-2, -7)
	node.add_child(l)
	node.position = at
	add_child(node)
	var slot := mini(int(recent / 0.35), 3)
	recent += 0.35
	active.append({"node": node, "t": 0.0, "slot": slot, "base": at})

func _process(d: float) -> void:
	recent = maxf(0.0, recent - d)
	var keep: Array = []
	for a in active:
		a["t"] = float(a["t"]) + d
		var t: float = a["t"]
		var n: Node2D = a["node"]
		if t >= FloatMath.LIFE:
			n.queue_free()
			continue
		n.position = (a["base"] as Vector2) + Vector2(0, -FloatMath.rise(t) + FloatMath.stack_offset(int(a["slot"])) - 18.0)
		n.modulate.a = FloatMath.alpha(t)
		keep.append(a)
	active = keep
