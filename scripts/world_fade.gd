class_name WorldFade
extends RefCounted
## Pure check: is the player hidden behind a prop sprite (above its base, inside its rect)?

static func is_behind(player: Vector2, base: Vector2, size: Vector2, offset: Vector2) -> bool:
	if player.y >= base.y:
		return false  # in front of the prop's base: drawn over it anyway
	var top_left := base + offset - size / 2.0
	var rect := Rect2(top_left, size).grow(-4.0)
	return rect.has_point(player + Vector2(0, -12))  # test the player's body centre
