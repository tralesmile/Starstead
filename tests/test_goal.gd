extends BaseTest

func test_goal_progression() -> void:
	check(GoalText.current(0, 0, 1, 500, false).contains("hoe"), "start: till")
	check(GoalText.current(3, 0, 1, 500, false).contains("plant"), "tilled: plant")
	check(GoalText.current(3, 2, 1, 500, false).contains("sleep"), "planted: water + sleep")
	check(GoalText.current(3, 2, 2, 300, false).contains("stall"), "day 2: earn")
	check(GoalText.current(3, 2, 5, 300, false).contains("Port Halden"), "day 4+: go to the city")
	check(GoalText.current(3, 2, 5, 300, true).contains("stall"), "after the city: earn")
	check_eq(GoalText.current(3, 2, 9, 5000, true, 100), "", "late game: no nag")

func test_crops_planted() -> void:
	var f := FarmModel.new({})
	f.till(Vector2i(1, 1)); f.till(Vector2i(2, 1))
	check_eq(f.crops_planted(), 0)
	f.soil[Vector2i(1, 1)]["crop"] = "turnip"
	check_eq(f.crops_planted(), 1)
