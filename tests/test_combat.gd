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
