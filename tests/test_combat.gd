extends BaseTest

func test_swing_cone() -> void:
	var a := Vector2(100, 100)
	check(CombatModel.in_swing(a, Vector2.RIGHT, Vector2(130, 100), 38.0))
	check(not CombatModel.in_swing(a, Vector2.RIGHT, Vector2(70, 100), 38.0))   # behind
	check(not CombatModel.in_swing(a, Vector2.RIGHT, Vector2(160, 100), 38.0))  # out of reach
	check(not CombatModel.in_swing(a, Vector2.RIGHT, Vector2(100, 130), 38.0))  # to the side
	check(CombatModel.in_swing(a, Vector2.RIGHT, a, 38.0))                       # on top of us

func test_facing_vectors_unit() -> void:
	for f in [PlayerMath.Facing.DOWN, PlayerMath.Facing.UP, PlayerMath.Facing.LEFT, PlayerMath.Facing.RIGHT]:
		check_eq(CombatModel.facing_vec(f).length(), 1.0)

func test_damage_and_knockout() -> void:
	var hp := CombatModel.MAX_HP
	hp = CombatModel.hit(hp, float(CombatModel.weapon("club")["dmg"]))
	check_eq(hp, 20.0)
	check(not CombatModel.is_down(hp))
	hp = CombatModel.hit(hp, 100.0)
	check_eq(hp, 0.0)
	check(CombatModel.is_down(hp))

func test_weapons_club_beats_fist() -> void:
	check(float(CombatModel.weapon("club")["dmg"]) > float(CombatModel.weapon("fist")["dmg"]))
	check_eq(CombatModel.weapon("nope"), CombatModel.WEAPONS["fist"])
	check(CombatModel.cooldown("club") > 0.0)

func test_recover() -> void:
	var t := CombatModel.DOWN_SECONDS
	t = CombatModel.recover(t, 2.0)
	check_eq(t, 4.0)
	check_eq(CombatModel.recover(t, 10.0), 0.0)
	check(CombatModel.stand_hp() > 0.0)

func test_knockback_pushes_away() -> void:
	var v := HitMath.knockback(Vector2(0, 0), Vector2(10, 0), float(CombatModel.weapon("club")["force"]))
	check(v.x > 0.0 and absf(v.y) < 0.001)

func test_car_hit_scales_with_speed() -> void:
	check_eq(CombatModel.car_hit(30.0)["dmg"], 0.0)
	var slow := CombatModel.car_hit(80.0)
	var fast := CombatModel.car_hit(240.0)
	check(float(fast["dmg"]) > float(slow["dmg"]))
	check(float(fast["force"]) > float(slow["force"]))
	check(float(fast["dmg"]) >= CombatModel.MAX_HP * 0.99 or float(fast["dmg"]) > 20.0)
	check(float(CombatModel.car_hit(9999.0)["force"]) <= 2.5)

func test_combo_chain() -> void:
	var w := CombatModel.weapon("club")
	var c := 0
	c = CombatModel.combo_next(c, 99.0, true)
	check_eq(c, 1)
	c = CombatModel.combo_next(c, 0.5, true)
	check_eq(c, 2)
	c = CombatModel.combo_next(c, 0.5, true)
	check_eq(c, 3, "finisher landed")
	check_eq(CombatModel.chain_len(c, 0.1), 0, "restarts after a finisher")
	check_eq(CombatModel.combo_next(c, 0.1, true), 1)
	check_eq(CombatModel.combo_next(2, 2.0, true), 1, "late swing starts over")
	check_eq(CombatModel.combo_next(2, 0.2, false), 0, "miss resets")
	check_eq(float(CombatModel.combo_weapon(w, 0)["dmg"]), float(w["dmg"]))
	check(float(CombatModel.combo_weapon(w, 1)["dmg"]) > float(w["dmg"]))
	var fin := CombatModel.combo_weapon(w, 2)
	check(float(fin["dmg"]) == float(w["dmg"]) * 1.5 and float(fin["force"]) > float(w["force"]), "heavy finisher")

func test_banded_clubs_scale_damage() -> void:
	var clubs: Dictionary = DataDB.load_json("clubs")
	var inv := Inventory.new()
	check_eq(CombatModel.club_mult(inv, clubs), 1.0)
	inv.add("club_copper", 1)
	check_eq(CombatModel.club_mult(inv, clubs), 1.4)
	inv.add("club_iron", 1)
	check_eq(CombatModel.club_mult(inv, clubs), 1.8, "best one counts")
	var w := CombatModel.with_mult(CombatModel.weapon("club"), 1.8)
	check_eq(float(w["dmg"]), 18.0)
	check_eq(float(w["range"]), float(CombatModel.weapon("club")["range"]), "other stats unchanged")
	var items: Dictionary = DataDB.load_json("items")
	var rec: Dictionary = DataDB.load_json("crafting")
	for id in clubs:
		check(items.has(id) and rec.has(id), "%s is an item and craftable" % id)
