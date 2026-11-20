extends BaseTest

func test_named_outfits() -> void:
	check_eq(NpcLook.outfit_of("farmer"), 0)
	check_eq(NpcLook.outfit_of("mechanic"), 3)
	check_eq(NpcLook.outfit_of("police"), NpcLook.POLICE)

func test_citizens_stable_and_not_police() -> void:
	for i in 40:
		var id := "walker_%d" % i
		var o := NpcLook.outfit_of(id)
		check(o != NpcLook.POLICE, id)
		check(o >= 0 and o < NpcLook.OUTFITS.size(), id)
		check_eq(NpcLook.outfit_of(id), o, "stable")

func test_frame_layout() -> void:
	check_eq(NpcLook.frame(0, 0, 0), 0)
	check_eq(NpcLook.frame(0, 3, 7), 31)
	check_eq(NpcLook.frame(1, 0, 0), 32)
	check_eq(NpcLook.frame(7, 3, 7), 8 * 4 * 8 - 1)
	check_eq(NpcLook.frame(99, 9, 9), NpcLook.OUTFITS.size() * 4 * 8 - 1, "clamped")
	check_eq(NpcLook.outfit_of("vance"), 8)

func test_sheet_size_matches() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(NpcLook.SHEET))
	check_eq(img.get_width(), 8 * 32)
	check_eq(img.get_height(), NpcLook.OUTFITS.size() * 4 * 48)
