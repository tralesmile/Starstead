extends BaseTest

func test_costs_scale_with_damage_and_fuel() -> void:
	check_eq(GarageModel.repair_cost(100.0, 100.0), 0)
	check_eq(GarageModel.repair_cost(50.0, 100.0), 50 * GarageModel.REPAIR_PRICE)
	check_eq(GarageModel.fuel_cost(40.0, 40.0), 0)
	check_eq(GarageModel.fuel_cost(0.0, 40.0), 60)

func test_pay_needs_money_and_something_to_buy() -> void:
	check_eq(GarageModel.pay(100, 40), 60)
	check_eq(GarageModel.pay(10, 40), -1)
	check_eq(GarageModel.pay(100, 0), -1)

func test_paint_cycle_wraps() -> void:
	check_eq(GarageModel.next_paint(GarageModel.PAINTS.size() - 1), 0)
