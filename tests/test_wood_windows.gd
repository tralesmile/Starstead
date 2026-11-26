extends BaseTest
## Wooden bag, chest and bus windows: everything fits 640x360 and clicks land on what is drawn.

const SCREEN := Rect2(0, 0, 640, 360)
const FRAME := 6.0   # WoodUI.panel draws its planks this far outside the rect

func _inside(window: Rect2, r: Rect2, what: String) -> void:
	check(window.encloses(r), "%s %s leaves window %s" % [what, r, window])

func _grid(window: Rect2, origin: Vector2, n: int) -> void:
	for i in n:
		var r := WoodUI.grid_slot_rect(origin, i)
		_inside(window, r, "slot %d" % i)
		check_eq(Inventory.slot_at(r.get_center(), origin, WoodUI.GRID_CELL, WoodUI.GRID_COLS, n), i)
		check_eq(Inventory.slot_at(r.position + Vector2(0.5, 0.5), origin, WoodUI.GRID_CELL, WoodUI.GRID_COLS, n), i)

func test_bag_window_fits_every_bag_size() -> void:
	for n in [30, 40, 50]:
		for perk in [false, true]:
			var w := WoodUI.bag_window(n, perk)
			check(SCREEN.encloses(w.grow(FRAME)), "bag %d off screen %s" % [n, w])
			_grid(w, WoodUI.BAG_GRID, n)

func test_chest_window_fits_and_grids_do_not_overlap() -> void:
	for n in [30, 40, 50]:
		var w := WoodUI.chest_window(n)
		check(SCREEN.encloses(w.grow(FRAME)), "chest %d off screen %s" % [n, w])
		_grid(w, WoodUI.CHEST_GRID, 30)
		_grid(w, WoodUI.CHEST_BAG_GRID, n)
	# room for the "Bag" label between the two grids, and no point hits both
	var chest_end := WoodUI.grid_slot_rect(WoodUI.CHEST_GRID, 29).end.y
	check(WoodUI.CHEST_BAG_GRID.y - chest_end >= 16.0)
	for i in 50:
		var c := WoodUI.grid_slot_rect(WoodUI.CHEST_BAG_GRID, i).get_center()
		check_eq(Inventory.slot_at(c, WoodUI.CHEST_GRID, WoodUI.GRID_CELL, WoodUI.GRID_COLS, 30), -1)

func test_bus_rows_fit_and_hit() -> void:
	for n in range(1, 9):
		var w := WoodUI.bus_window(n)
		check(SCREEN.encloses(w.grow(FRAME)), "bus %d off screen %s" % [n, w])
		for i in n:
			var r := WoodUI.bus_row_rect(i)
			_inside(w, r, "row %d" % i)
			check_eq(WoodUI.bus_row_at(r.get_center(), n), i)
			check_eq(WoodUI.bus_row_at(r.position, n), i)
		check_eq(WoodUI.bus_row_at(WoodUI.bus_row_rect(n).get_center(), n), -1)
	check_eq(WoodUI.bus_row_at(WoodUI.BUS_ORIGIN - Vector2(1, -5), 7), -1)
	check_eq(WoodUI.bus_row_at(WoodUI.BUS_ORIGIN + Vector2(WoodUI.BUS_W, 5), 7), -1)
	check_eq(WoodUI.bus_row_at(WoodUI.BUS_ORIGIN + Vector2(5, -1), 7), -1)

func test_tooltip_stays_on_screen() -> void:
	for m in [Vector2(0, 0), Vector2(639, 359), Vector2(620, 100), Vector2(300, 355)]:
		var tip := WoodUI.tooltip_rect(m, 180.0, SCREEN.size)
		check(SCREEN.encloses(tip.grow(2)), "tooltip off screen at %s" % m)
