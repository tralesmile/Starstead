class_name DealerModel
extends RefCounted
## Pure back-alley dealer: street tier unlocks the stall; sells a lockpick set and bribes cops to forget your stars.

const PICK_PRICE := 120

static func entries(street: int, stars: int, has_picks: bool) -> Array:
	## [{id, label, price, ok}] in menu order.
	var out := []
	out.append({"id": "lockpick_set", "label": "Lockpick set (+%d skill while carried)" % int(ReputationModel.cfg()["lockpick_bonus"]), "price": PICK_PRICE, "ok": not has_picks})
	out.append({"id": "bribe", "label": "Bribe the beat: forget %d star%s" % [stars, "" if stars == 1 else "s"], "price": ReputationModel.bribe_cost(stars, street), "ok": stars > 0})
	return out

static func buy(id: String, money: int, street: int, stars: int, has_picks: bool) -> Dictionary:
	## {money, ok, msg}; the caller applies the effect (item or heat) when ok.
	if not ReputationModel.dealer_open(street):
		return {"money": money, "ok": false, "msg": "Come back when you are Known on the street"}
	for e in entries(street, stars, has_picks):
		if e["id"] != id:
			continue
		if not e["ok"]:
			return {"money": money, "ok": false, "msg": "You do not need that"}
		if money < int(e["price"]):
			return {"money": money, "ok": false, "msg": "Cash first"}
		return {"money": money - int(e["price"]), "ok": true, "msg": "Done. You never saw me"}
	return {"money": money, "ok": false, "msg": "No such thing"}
