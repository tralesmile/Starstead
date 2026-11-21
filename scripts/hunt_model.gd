class_name HuntModel
extends RefCounted
## Pure hunting rules (owner 2026-11-18: "I need the ability to hunt animals"): per-species hp and drops from
## data/animals.json "hunt". Wild animals only; hunting is not a crime. Tamed animals are never hunted.

static func hp_for(animals: Dictionary, id: String) -> float:
	return float(animals.get(id, {}).get("hunt", {}).get("hp", 0.0))

static func huntable(animals: Dictionary, id: String) -> bool:
	return hp_for(animals, id) > 0.0

static func tameable(animals: Dictionary, id: String) -> bool:
	return bool(animals.get(id, {}).get("tameable", true))

static func fights_back(animals: Dictionary, id: String) -> bool:
	return bool(animals.get(id, {}).get("hunt", {}).get("fights_back", false))

static func roll_drops(animals: Dictionary, id: String, rng: RandomNumberGenerator) -> Dictionary:
	## {item: count} for a kill; chance/min/max per drop from the data.
	var out := {}
	for d in animals.get(id, {}).get("hunt", {}).get("drops", []):
		if rng.randf() <= float(d.get("chance", 1.0)):
			var n := rng.randi_range(int(d.get("min", 1)), int(d.get("max", 1)))
			if n > 0:
				out[String(d["item"])] = int(out.get(String(d["item"]), 0)) + n
	return out

static func bite_damage(dist: float) -> float:
	## A cornered boar charges: 6 damage-as-energy within 18px, none farther.
	return 6.0 if dist < 18.0 else 0.0

static func scare_scale(sneaking: bool, sprinting: bool) -> float:
	## Multiplier on how far away wild animals spook: creeping 0.5x, walking 1x, sprinting 1.6x.
	if sneaking:
		return 0.5
	return 1.6 if sprinting else 1.0
