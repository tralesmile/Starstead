extends BaseTest
## A club blow steps the body forward on the strike frame.

func test_lunge_slides_the_planned_distance() -> void:
	for chain in 3:
		var v := CombatModel.lunge_velocity(Vector2.RIGHT, chain, HitMath.KNOCK_DECAY)
		var x := 0.0
		var dt := 1.0 / 600.0
		while v.length() > 0.0:
			v = HitMath.decay(v, dt)
			x += v.x * dt
		check(absf(x - CombatModel.lunge_px(chain)) < 1.0, "slides %.1f px" % CombatModel.lunge_px(chain))

func test_lunge_grows_with_the_chain_but_stays_small() -> void:
	check(CombatModel.lunge_px(2) > CombatModel.lunge_px(0), "finisher steps in further")
	check_eq(CombatModel.lunge_px(9), CombatModel.lunge_px(2))
	check(CombatModel.lunge_px(2) <= 10.0, "never more than a third of a tile")

func test_lunge_follows_the_facing() -> void:
	var v := CombatModel.lunge_velocity(Vector2(0, -3), 0, HitMath.KNOCK_DECAY)
	check(is_zero_approx(v.x) and v.y < 0.0, "pushes the way you face")

func test_club_and_fist_wait_for_the_strike() -> void:
	var club := PoseMath.strike_delay("club")
	check(club > 0.05 and club < 0.2, "club bites late but stays responsive")
	check(club < CombatModel.cooldown("club"), "lands before the next swing is allowed")
	check(PoseMath.FIST_DELAY > 0.0 and PoseMath.FIST_DELAY < PoseMath.SWING_TIME, "punch lands inside its swing")
