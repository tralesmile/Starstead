extends BaseTest

func test_mode_priority() -> void:
	check_eq(KeyLegend.mode_for(true, true, true), "car")
	check_eq(KeyLegend.mode_for(false, true, true), "mount")
	check_eq(KeyLegend.mode_for(false, false, true), "indoors")
	check_eq(KeyLegend.mode_for(false, false, false), "foot")

func test_every_mode_has_rows_with_help_key() -> void:
	for m in KeyLegend.MODES:
		var rows := KeyLegend.rows(m)
		check(rows.size() >= 4)
		check_eq(String(rows[0][0]), "WASD")
		check_eq(String(rows[rows.size() - 1][0]), "F1")
		for r in rows:
			check(String(r[0]) != "" and String(r[1]) != "")

func test_panel_fits_screen_corner() -> void:
	for m in KeyLegend.MODES:
		check(KeyLegend.panel_width(m) < 140.0)

func test_derby_bet_steps_within_budget() -> void:
	check_eq(DerbyModel.next_bet(0, 1, 500), 25)
	check_eq(DerbyModel.next_bet(100, 1, 500), 100)
	check_eq(DerbyModel.next_bet(25, -1, 500), 0)
	check_eq(DerbyModel.next_bet(0, 1, 40), 0)      # 25 + 20 fee > 40
	check_eq(DerbyModel.next_bet(0, 1, 45), 25)
	check_eq(DerbyModel.next_bet(0, 1, 500) , 25)
	check_eq(DerbyModel.next_bet(25, 1, 80), 50)    # 50 + 20 <= 80
	check_eq(DerbyModel.next_bet(50, 1, 80), 50)    # 100 + 20 > 80

func test_derby_payout() -> void:
	check_eq(DerbyModel.payout(50, 0), 150)
	check_eq(DerbyModel.payout(25, 1), 38)
	check_eq(DerbyModel.payout(100, 2), 0)
	check_eq(DerbyModel.payout(0, 0), 0)

func test_mount_rest_and_dust() -> void:
	check(MountMath.regen_rate(0.0) > MountMath.regen_rate(60.0))
	var s := MountMath.step(0.5, 0.0, 1.0)
	var w := MountMath.step(0.5, 60.0, 1.0)
	check(s > w)
	check_eq(MountMath.dust_rate(100.0), 0.0)
	check(MountMath.dust_rate(130.0) >= 4.0)
	check(MountMath.dust_rate(400.0) <= 9.0)
