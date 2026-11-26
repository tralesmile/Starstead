extends BaseTest

const DT := 1.0 / 60.0

func _line(n: int) -> PackedVector2Array:
	var cells: Array = []
	for i in n:
		cells.append(Vector2i(i, 0))
	return CartMath.points(cells)

func _run(st: Dictionary, pump: float, braking: bool, frames: int, load: float) -> void:
	var pts := _line(200)
	for i in frames:
		CartMath.step(st, pts, pump, braking, DT, load)

func _stop_distance(load: float) -> float:
	var st := {"s": 100.0, "v": 200.0}
	_run(st, 0.0, true, 240, load)
	return float(st["s"]) - 100.0

func test_weight_slows_pumping_but_it_can_still_get_home() -> void:
	var a := {"s": 3000.0, "v": 0.0}
	var b := {"s": 3000.0, "v": 0.0}
	_run(a, -1.0, false, 120, 0.0)
	_run(b, -1.0, false, 120, 1.0)
	check(float(b["v"]) < -20.0, "a full cart still climbs %s" % str(b))
	check(float(b["v"]) > float(a["v"]) * 0.6, "but gains speed much slower %s %s" % [str(a), str(b)])

func test_weight_rolls_longer_and_pulls_harder_downhill() -> void:
	var a := {"s": 3000.0, "v": -200.0}
	var b := {"s": 3000.0, "v": -200.0}
	_run(a, 0.0, false, 90, 0.0)
	_run(b, 0.0, false, 90, 1.0)
	check(float(b["v"]) < float(a["v"]) - 10.0, "keeps more uphill speed")
	var c := {"s": 0.0, "v": 0.0}
	var d := {"s": 0.0, "v": 0.0}
	_run(c, 0.0, false, 180, 0.0)
	_run(d, 0.0, false, 180, 1.0)
	check(float(d["s"]) > float(c["s"]) * 1.2, "runs away downhill faster")

func test_weight_lengthens_braking() -> void:
	var empty := _stop_distance(0.0)
	var half := _stop_distance(0.5)
	var full := _stop_distance(1.0)
	check(empty < half and half < full, "%s %s %s" % [empty, half, full])
	check(full > empty * 1.5 and full < 170.0, "longer but bounded %s" % full)

func test_spill_only_when_loaded_and_fast() -> void:
	check_eq(CartMath.spill_count(240.0, 0.0, 0), 0, "empty")
	check_eq(CartMath.spill_count(170.0, 1.0, 40), 0, "slow enough")
	check_eq(CartMath.spill_count(240.0, 0.05, 3), 0, "heap below the rim")
	check(CartMath.spill_count(190.0, 0.4, 20) >= 1)
	check_eq(CartMath.spill_count(260.0, 1.0, 40), CartMath.SPILL_MAX)
	check_eq(CartMath.spill_count(260.0, 1.0, 2), 2, "never more than aboard")
	var pts := CartMath.points([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)])
	var res := CartMath.step({"s": 60.0, "v": 240.0}, pts, 0.0, false, 0.03, 1.0)
	check(res["jolt"] and float(res["jolt_v"]) > CartMath.SPILL_V, "reports the entry speed")
	check_eq(float(res["jolt_s"]), 64.0)

func test_cargo_loads_only_ore_up_to_capacity() -> void:
	var bag := Inventory.new(10)
	bag.add("coal", 50)
	bag.add("gold_ore", 30)
	bag.add("wood", 5)
	var c := CartCargo.new()
	check_eq(c.load_from(bag), CartCargo.CAPACITY)
	check_eq(c.items, {"gold_ore": 30, "coal": 30}, "best first")
	check_eq(bag.count("coal"), 20)
	check_eq(bag.count("wood"), 5)
	check_eq(c.add("coal", 5), 0, "full")
	check_eq(c.add("wood", 5), 0, "not ore")
	check_eq(c.weight(), 120.0)
	check_eq(c.load_fraction(), 1.0)

func test_full_bag_keeps_the_rest_in_the_cart() -> void:
	var bag := Inventory.new(1, {"iron_ore": 10})
	var c := CartCargo.new()
	c.add("iron_ore", 14)
	c.add("coal", 3)
	var res := c.unload_to(bag)
	check_eq(res, {"moved": 10, "left": 7})
	check_eq(bag.count("iron_ore") + c.count(), 17, "nothing lost")

func test_spilled_and_kept_pieces_add_up_and_save_keeps_cargo() -> void:
	var c := CartCargo.new()
	c.add("copper_ore", 5)
	c.add("silver_ore", 2)
	var out := c.spill(4)
	var n := 0
	for id in out:
		n += int(out[id])
	check_eq(n, 4)
	check_eq(c.count(), 3)
	var d := CartCargo.new()
	d.deserialize(JSON.parse_string(JSON.stringify(c.serialize())))
	check_eq(d.items, c.items, "through JSON")
	d.deserialize({"wood": 3, "coal": -1})
	check_eq(d.count(), 0)
	check_eq(c.spill(99).size() > 0 and c.count() == 0, true)

func test_heap_shows_every_ore() -> void:
	var c := CartCargo.new()
	check_eq(c.heap().size(), 0)
	c.add("coal", 55)
	c.add("gold_ore", 1)
	var h := c.heap()
	check_eq(h.size(), 14)
	check(h.has("gold_ore") and h.count("coal") >= 12)
