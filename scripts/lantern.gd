class_name Lantern
extends Node2D
## Lantern post: warm PointLight2D that glows at dusk/night and flickers by whole-ish steps.

var light: PointLight2D
var phase := 0.0
var strength := 0.0  # 0..1, set by main from DayNight.lamp_strength (no autoload here: testable)

static var _tex: Texture2D = null

static func light_texture() -> Texture2D:
	if _tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_tex = t
	return _tex

func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/lantern.png")
	s.offset = Vector2(0, -20)
	add_child(s)
	add_child(World.make_shadow(14))
	light = PointLight2D.new()
	light.texture = light_texture()
	light.texture_scale = 1.6
	light.color = Color(1.0, 0.78, 0.45)
	light.position = Vector2(4, -28)
	light.energy = 0.0
	light.shadow_enabled = false
	add_child(light)

func _process(_d: float) -> void:
	var k := strength
	var t := Time.get_ticks_msec() / 1000.0
	var flick := 1.0 + 0.06 * sin(t * 9.0 + phase) + 0.04 * sin(t * 23.0 + phase * 2.0)
	light.energy = 1.1 * k * flick
	light.visible = k > 0.01
