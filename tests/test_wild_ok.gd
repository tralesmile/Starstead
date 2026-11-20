extends BaseTest

func test_wild_animals_keep_off_pavement() -> void:
	check(not AnimalModel.wild_ok(CityModel.SPAWN), "city")
	check(not AnimalModel.wild_ok(CircuitModel.START_CELL), "circuit")
	check(AnimalModel.wild_ok(Vector2i(20, 14)), "homestead meadow")
