extends BaseTest


func test_animal_breath() -> void:
	check(AmbientMath.animal_breath_age(0.0, 0, 0.6) >= -1.0)
	var seen := 0
	for i in 40:
		if AmbientMath.animal_breath_age(float(i) * 0.1, 3, 1.0) >= 0.0:
			seen += 1
	check(seen > 5 and seen < 40)
	check(AmbientMath.animal_breath_size(1.5, 1.0) > AmbientMath.animal_breath_size(0.6, 1.0))
