extends BaseTest

const CROPS := {"turnip": {"grow_days": 4}, "tomato": {"grow_days": 6}}

func test_not_tilled() -> void:
	check(CropInfo.info({}, CROPS, Vector2i(1, 1)).is_empty())
	check_eq(CropInfo.text({}), "")

func test_empty_soil() -> void:
	var i := CropInfo.info({Vector2i(0, 0): {"watered": true, "crop": "", "age": 0}}, CROPS, Vector2i(0, 0))
	check_eq(i.crop, "")
	check(i.watered)
	check_eq(CropInfo.text(i), "Tilled soil (watered)")

func test_growing() -> void:
	var i := CropInfo.info({Vector2i(0, 0): {"watered": false, "crop": "turnip", "age": 1}}, CROPS, Vector2i(0, 0))
	check_eq(i.days_left, 3)
	check_eq(i.total, 4)
	check(absf(i.fraction - 0.25) < 0.001)
	check(not i.ripe)
	check_eq(CropInfo.text(i), "Turnip: 3 days left (dry)")

func test_last_day_singular() -> void:
	var i := CropInfo.info({Vector2i(0, 0): {"watered": true, "crop": "tomato", "age": 5}}, CROPS, Vector2i(0, 0))
	check_eq(CropInfo.text(i), "Tomato: 1 day left (watered)")

func test_ripe_and_overage() -> void:
	var i := CropInfo.info({Vector2i(0, 0): {"watered": true, "crop": "turnip", "age": 9}}, CROPS, Vector2i(0, 0))
	check(i.ripe)
	check_eq(i.days_left, 0)
	check(absf(i.fraction - 1.0) < 0.001)
	check_eq(CropInfo.text(i), "Turnip: ready to harvest")
