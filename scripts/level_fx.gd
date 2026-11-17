class_name LevelFx
extends Node2D
## Level-up fanfare: coloured sparkle ring plus a "SKILL 3!" banner above the player. Self-frees.

var skill := ""
var lvl := 1
var t := 0.0
const N := 10

static func spawn(parent: Node2D, pos: Vector2, skill_id: String, level: int) -> LevelFx:
	var f := LevelFx.new()
	f.skill = skill_id
	f.lvl = level
	f.position = pos
	f.z_index = 50
	parent.add_child(f)
	return f

func _process(delta: float) -> void:
	t += delta
	if t >= LevelFxMath.DURATION:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var k := t / LevelFxMath.DURATION
	var col := LevelFxMath.skill_color(skill)
	var a := LevelFxMath.sparkle_alpha(k)
	for i in N:
		var p := LevelFxMath.sparkle_pos(i, N, k).round()
		var c := Color(col.r, col.g, col.b, a)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), c)
		draw_rect(Rect2(p - Vector2(0, 2), Vector2(1, 5)), Color(1, 1, 1, a))
		draw_rect(Rect2(p - Vector2(2, 0), Vector2(5, 1)), Color(1, 1, 1, a))
	var font := ThemeDB.fallback_font
	var txt := "%s %d!" % [skill.to_upper(), lvl]
	var sc := LevelFxMath.banner_scale(k)
	var y := LevelFxMath.banner_offset(k)
	draw_set_transform(Vector2(0, y).round(), 0.0, Vector2(sc, sc))
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(-w / 2.0 + 1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, a))
	draw_string(font, Vector2(-w / 2.0, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col.r, col.g, col.b, clampf((1.0 - k) / 0.3, 0.0, 1.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
