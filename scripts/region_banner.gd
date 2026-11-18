class_name RegionBanner
extends CanvasLayer
## "Entering Pine Forest" title that fades in and out when the player crosses into a new region.

var label: Label
var _t := -1.0

func _init() -> void:
	layer = 20
	label = Label.new()
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.8))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.03))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate.a = 0.0
	add_child(label)

func show_region(name: String) -> void:
	label.text = name
	_t = 0.0

func _process(delta: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	label.size = Vector2(vs.x, 40)
	label.position = Vector2(0, vs.y * 0.16)
	if _t >= 0.0:
		_t += delta
		label.modulate.a = ChunkGrid.banner_alpha(_t)
		if _t > 3.0:
			_t = -1.0
