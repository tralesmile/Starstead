extends BaseTest

func test_tiers_and_cash() -> void:
	var h := HomeUpgrades.new()
	check_eq(h.bag_slots(), 30)
	check_eq(h.can_buy("bag", 100), "cash")
	var r := h.buy("bag", 700)
	check(r.ok)
	check_eq(r.cash, 100)
	check_eq(h.bag_slots(), 40)
	check(h.buy("bag", 9999).ok)
	check_eq(h.bag_slots(), 50)
	check_eq(h.can_buy("bag", 9999), "maxed")
	check_eq(h.can_buy("nope", 5), "unknown")

func test_effects_grow_and_stay_modest() -> void:
	var h := HomeUpgrades.new()
	check_eq(h.eat_mult(), 1.0)
	check_eq(h.sell_mult(), 1.0)
	h.buy("kitchen", 9999)
	h.buy("cellar", 9999)
	check(h.eat_mult() > 1.2)
	check(h.sell_mult() > 1.0 and h.sell_mult() < 1.1)
	h.buy("cellar", 9999)
	check(h.sell_mult() <= 1.1, "cellar must not break the economy audit")

func test_total_sink_and_save() -> void:
	var h := HomeUpgrades.new()
	for id in h.ids():
		while h.can_buy(id, 99999) == "":
			h.buy(id, 99999)
	check(h.total_spent() >= 6000, "a real late-game sink")
	var g := HomeUpgrades.new()
	g.from_dict(h.to_dict())
	check_eq(g.total_spent(), h.total_spent())
	g.from_dict({"bag": 99, "ghost": 3})
	check_eq(g.level("bag"), 2)

func test_labels() -> void:
	var h := HomeUpgrades.new()
	check(h.label("bag").contains("30 slots"))
	check(h.label("cellar").contains("x1.00"))

func test_hooks() -> void:
	var inv := Inventory.new(30, {})
	inv.ensure_size(40)
	check_eq(inv.slots.size(), 40)
	inv.ensure_size(20)
	check_eq(inv.slots.size(), 40, "never shrinks")
	var e := Energy.new()
	e.value = 10.0
	var items := {"stew": {"energy": 20}}
	inv.add("stew", 2)
	check_eq(CookModel.eat(inv, items, e, "stew", 1.5), 30)
	check_eq(CookModel.eat(inv, items, e, "stew"), 20)
