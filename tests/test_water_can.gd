extends BaseTest

func test_use_and_empty() -> void:
	var c := WaterCan.new()
	check_eq(c.level, 20)
	for i in 20:
		check(c.use())
	check(c.is_empty())
	check(not c.use())
	check_eq(c.level, 0)

func test_refill_and_fraction() -> void:
	var c := WaterCan.new()
	for i in 5:
		c.use()
	check_eq(c.refill(), 5)
	check_eq(c.refill(), 0)
	check_eq(c.fraction(), 1.0)
	c.level = 10
	check_eq(c.fraction(), 0.5)

func test_upgrade_and_save() -> void:
	var c := WaterCan.new()
	c.upgrade(10)
	check_eq(c.capacity, 30)
	check_eq(c.level, 30)
	c.level = 7
	var d := WaterCan.new()
	d.from_dict(c.to_dict())
	check_eq(d.level, 7)
	check_eq(d.capacity, 30)
	d.from_dict({"capacity": 5, "level": 99})
	check_eq(d.level, 5)
