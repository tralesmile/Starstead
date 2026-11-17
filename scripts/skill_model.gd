class_name SkillModel
extends RefCounted
## Pure skill levels (farming, foraging, mining, fishing): xp thresholds, level, bonus yield chance.

const SKILLS := ["farming", "foraging", "mining", "fishing"]
const XP_FOR := {"farming": 8, "foraging": 6, "mining": 6, "fishing": 10}
const THRESHOLDS := [0, 100, 280, 570, 1000, 1600, 2400, 3500, 5000, 7000, 10000]  # level 0..10

static func level(xp: int) -> int:
	var l := 0
	for i in THRESHOLDS.size():
		if xp >= THRESHOLDS[i]:
			l = i
	return l

static func xp_to_next(xp: int) -> int:
	var l := level(xp)
	return 0 if l >= THRESHOLDS.size() - 1 else THRESHOLDS[l + 1] - xp

static func bonus_chance(lvl: int) -> float:
	## Chance (0..0.5) of one extra harvested item; +5% per level.
	return clampf(lvl * 0.05, 0.0, 0.5)

static func roll_bonus(lvl: int, roll: float) -> int:
	return 1 if roll < bonus_chance(lvl) else 0

static func gain(xp: Dictionary, skill: String, amount: int = -1) -> bool:
	## Adds xp; returns true when that raised the level.
	var before := level(int(xp.get(skill, 0)))
	xp[skill] = int(xp.get(skill, 0)) + (int(XP_FOR.get(skill, 5)) if amount < 0 else amount)
	return level(int(xp[skill])) > before
