class_name LevelFxMath
extends RefCounted
## Pure math for the level-up fanfare: sparkle ring around the player and the rising banner.

const DURATION := 1.6

static func sparkle_pos(i: int, n: int, k: float) -> Vector2:
	## Sparkle i of n at progress k 0..1: starts on a small ring, spirals outward and floats up.
	var kk := clampf(k, 0.0, 1.0)
	var a := TAU * float(i) / float(maxi(n, 1)) + kk * 1.6
	var r := 6.0 + 22.0 * (1.0 - pow(1.0 - kk, 2.0))
	return Vector2(cos(a) * r, sin(a) * r * 0.5 - 14.0 - 26.0 * kk)

static func sparkle_alpha(k: float) -> float:
	## Quick pop in, hold, fade out in the last 40%.
	var kk := clampf(k, 0.0, 1.0)
	return clampf(kk * 8.0, 0.0, 1.0) * clampf((1.0 - kk) / 0.4, 0.0, 1.0)

static func banner_offset(k: float) -> float:
	## Banner rises from -34 to -58 px above the feet, easing out.
	var kk := clampf(k, 0.0, 1.0)
	return -34.0 - 24.0 * (1.0 - pow(1.0 - kk, 3.0))

static func banner_scale(k: float) -> float:
	## Overshoot pop: 0 -> 1.25 -> 1.0 in the first 25%.
	var kk := clampf(k / 0.25, 0.0, 1.0)
	if kk >= 1.0:
		return 1.0
	return sin(kk * PI * 0.5) * 1.25 if kk < 0.7 else lerpf(1.25, 1.0, (kk - 0.7) / 0.3)

static func skill_color(skill: String) -> Color:
	match skill:
		"farming": return Color(0.55, 0.95, 0.35)
		"foraging": return Color(0.35, 0.8, 0.5)
		"mining": return Color(0.75, 0.8, 0.95)
		"fishing": return Color(0.4, 0.8, 1.0)
	return Color(1.0, 0.9, 0.4)

static func bar_fill(xp: int) -> float:
	## Progress 0..1 through the current level (1.0 at max level), for the bag skill bars.
	var l := SkillModel.level(xp)
	if l >= SkillModel.THRESHOLDS.size() - 1:
		return 1.0
	var lo: int = SkillModel.THRESHOLDS[l]
	var hi: int = SkillModel.THRESHOLDS[l + 1]
	return clampf(float(xp - lo) / float(hi - lo), 0.0, 1.0)
