class_name BossBarLayout
extends RefCounted
## Pure rect math for the boss health bar: it sits low, above the context prompt and the hotbar,
## and turns see-through while the boss is standing under it.

const SIZE := Vector2(312, 30)
const RISE := 120.0          # panel top above the bottom of the view; the prompt line starts 84 above it
const COVERED_ALPHA := 0.25

static func panel(view: Vector2) -> Rect2:
	return Rect2(Vector2(roundf((view.x - SIZE.x) * 0.5), view.y - RISE), SIZE)

static func alpha_for(panel_rect: Rect2, boss_rect: Rect2) -> float:
	return COVERED_ALPHA if panel_rect.grow(3.0).intersects(boss_rect) else 1.0
