class_name PerkModel
extends RefCounted
## Pure level-5 skill perks (data/perks.json): pick one of two per skill, permanent. `chosen` is {skill: perk id}.
## Effect keys ending in "_mult" multiply (neutral 1.0); all others add up (neutral 0.0).

const UNLOCK_LEVEL := 5
## Chooser layout on the 640x360 screen (used by PerkView and the layout test).
const PANEL := Rect2(100, 74, 440, 212)
const CARD_SIZE := Vector2(204, 140)
const CARD_GAP := 12.0
const CARD_TOP := 34.0      # from the panel top (below the title plank and trim)
const CARD_PAD := 10.0
const NAME_SIZE := 13
const NAME_Y := 22.0        # baseline from the card top
const DESC_SIZE := 11
const DESC_Y := 48.0
const DESC_LINES := 4
const PICK_Y := 128.0       # baseline of the "Press 1" line
const FOOTER_SIZE := 10
const FOOTER := "This choice is permanent.   Esc: decide later (P reopens)"

static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		_data = DataDB.load_json("perks")
	return _data

static func card_rect(i: int) -> Rect2:
	var x0 := PANEL.position.x + (PANEL.size.x - CARD_SIZE.x * 2.0 - CARD_GAP) * 0.5
	return Rect2(Vector2(x0 + i * (CARD_SIZE.x + CARD_GAP), PANEL.position.y + CARD_TOP), CARD_SIZE)

static func card_at(at: Vector2) -> int:
	for i in 2:
		if card_rect(i).has_point(at):
			return i
	return -1

static func options(skill: String) -> Array:
	return data().get(skill, [])

static func option(skill: String, id: String) -> Dictionary:
	for o in options(skill):
		if String(o["id"]) == id:
			return o
	return {}

static func pending(skill_xp: Dictionary, chosen: Dictionary) -> Array:
	## Skills at the unlock level or higher that have no perk yet.
	var out: Array = []
	for sk in SkillModel.SKILLS:
		if not chosen.has(sk) and not options(sk).is_empty() and SkillModel.level(int(skill_xp.get(sk, 0))) >= UNLOCK_LEVEL:
			out.append(sk)
	return out

static func choose(chosen: Dictionary, skill: String, id: String) -> bool:
	if chosen.has(skill) or option(skill, id).is_empty():
		return false
	chosen[skill] = id
	return true

static func clean(saved) -> Dictionary:
	## Keeps only valid skill -> id pairs from a save (old saves have none).
	var out := {}
	if saved is Dictionary:
		for sk in saved:
			choose(out, str(sk), str(saved[sk]))
	return out

static func value(chosen: Dictionary, effect_key: String) -> float:
	var mult := effect_key.ends_with("_mult")
	var v := 1.0 if mult else 0.0
	for sk in chosen:
		var effect: Dictionary = option(String(sk), String(chosen[sk])).get("effect", {})
		if effect.has(effect_key):
			v = v * float(effect[effect_key]) if mult else v + float(effect[effect_key])
	return v

static func sell_mult(chosen: Dictionary, item_id: String, crops: Dictionary, fish: Dictionary) -> float:
	if crops.has(QualityMath.base_id(item_id)):
		return value(chosen, "crop_sell_mult")
	if fish.has(item_id):
		return value(chosen, "fish_sell_mult")
	return 1.0

static func crop_bonus(chosen: Dictionary, farming_level: int, roll: float) -> int:
	## One extra crop: the skill's own chance plus the perk's.
	return 1 if roll < SkillModel.bonus_chance(farming_level) + value(chosen, "crop_bonus_chance") else 0

static func ore_extra(chosen: Dictionary, roll: float) -> int:
	return 1 if roll < value(chosen, "ore_bonus_chance") else 0

static func energy_discounts(chosen: Dictionary) -> Dictionary:
	## tool -> energy saved per use (Energy.discounts).
	return {"axe": int(value(chosen, "axe_energy_save")), "pickaxe": int(value(chosen, "pickaxe_energy_save"))}
