extends BaseTest

static var _cache := {}

func _data(name: String) -> PackedByteArray:
	if not _cache.has(name):
		_cache[name] = SfxSynth.samples(name)
	return _cache[name]

func _all() -> Array:
	return SfxSynth.NAMES + SfxSynth.LOOPS

func _peak(b: PackedByteArray) -> int:
	var top := 0
	for i in b.size() / 2:
		top = maxi(top, absi(b.decode_s16(i * 2)))
	return top

func test_every_sound_has_audible_unclipped_data() -> void:
	for n in _all():
		var b := _data(n)
		check(b.size() > 1000 and b.size() % 2 == 0, n + " size")
		var p := _peak(b)
		check(p > 6000, n + " not silent")
		check(p <= 32000, n + " no clipping")

func test_variants_non_empty_and_different() -> void:
	for n in Sfx.VARIANTS:
		var a := SfxSynth.samples(n, 1)
		check(not a.is_empty() and _peak(a) > 6000, n)
		check(a != _data(n), n + " variant differs")

func test_one_shots_start_and_end_near_zero() -> void:
	for n in SfxSynth.NAMES:
		var b := _data(n)
		check(absi(b.decode_s16(0)) < 200, n + " start")
		check(absi(b.decode_s16(b.size() - 2)) < 200, n + " end")

func test_loops_have_small_seam_and_length() -> void:
	for n in SfxSynth.LOOPS:
		var b := _data(n)
		var count := b.size() / 2
		check(count >= SfxSynth.RATE * 2, n + " a few seconds")
		var biggest := 0
		for i in range(1, count):
			biggest = maxi(biggest, absi(b.decode_s16(i * 2) - b.decode_s16(i * 2 - 2)))
		var seam := absi(b.decode_s16(0) - b.decode_s16(b.size() - 2))
		check(seam <= biggest and seam < 6000, "%s seam %d (max step %d)" % [n, seam, biggest])

func test_determinism_and_unknown() -> void:
	for n in ["chop", "step_snow", "amb_birds"]:
		check_eq(SfxSynth.samples(n), _data(n), n)
	check(SfxSynth.samples("nope").is_empty())
	check(SfxSynth.stream("nope") == null)

func test_stream_loop_mode() -> void:
	var l := SfxSynth.stream("amb_wind")
	check_eq(l.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	check_eq(l.loop_end, l.data.size() / 2)
	check_eq(l.mix_rate, SfxSynth.RATE)
	check_eq(SfxSynth.stream("coin").loop_mode, AudioStreamWAV.LOOP_DISABLED)

func test_footstep_selection() -> void:
	check_eq(SfxSynth.footstep_name(WorldGen.GRASS + 2, 0, false, 0.0), "step_grass")
	check_eq(SfxSynth.footstep_name(WorldGen.DIRT, 0, false, 0.0), "step_path")
	check_eq(SfxSynth.footstep_name(WorldGen.PATH + 1, 1, false, 0.0), "step_path")
	check_eq(SfxSynth.footstep_name(WorldGen.ASPHALT, 3, false, 1.0), "step_path")
	check_eq(SfxSynth.footstep_name(WorldGen.GRASS, 3, false, 0.0), "step_snow")
	check_eq(SfxSynth.footstep_name(WorldGen.GRASS, 0, false, 0.5), "step_wet")
	check_eq(SfxSynth.footstep_name(WorldGen.DIRT, 2, false, 0.5), "step_wet")
	check_eq(SfxSynth.footstep_name(WorldGen.GRASS, 0, false, 0.2), "step_grass")
	check_eq(SfxSynth.footstep_name(WorldGen.WATER_SHALLOW, 0, false, 0.0), "step_wet")
	check_eq(SfxSynth.footstep_name(WorldGen.GRASS, 3, true, 1.0), "step_wood", "indoors")
	check_eq(SfxSynth.footstep_name(WorldGen.WATER_SHALLOW, 0, false, 0.0, true), "step_wood", "dock")

func test_ambience_rules() -> void:
	var day := SfxSynth.ambience_levels(0.0, 8.0, 0, false, 0.0)
	for k in SfxSynth.LOOPS:
		check(day.has(k), k)
	check(day["amb_birds"] > 0.5)
	check_eq(day["amb_rain"], 0.0)
	check_eq(day["amb_crickets"], 0.0)
	check_eq(day["amb_waves"], 0.0)
	var wet := SfxSynth.ambience_levels(0.5, 8.0, 0, false, 0.0)
	check_eq(wet["amb_birds"], 0.0, "no birds in rain")
	check(SfxSynth.ambience_levels(0.9, 8.0, 0, false, 0.0)["amb_rain"] > wet["amb_rain"])
	check(SfxSynth.ambience_levels(0.5, 8.0, 0, true, 0.0)["amb_rain"] < wet["amb_rain"], "muffled indoors")
	check(SfxSynth.ambience_levels(0.9, 8.0, 0, false, 0.0)["amb_wind"] > wet["amb_wind"], "storm wind")
	var winter := SfxSynth.ambience_levels(0.0, 8.0, 3, false, 0.0)
	check(winter["amb_wind"] > day["amb_wind"], "winter wind")
	check(winter["amb_birds"] < day["amb_birds"], "fewer winter birds")
	var night := SfxSynth.ambience_levels(0.0, 23.0, 1, false, 0.0)
	check(night["amb_crickets"] > 0.5)
	check_eq(night["amb_birds"], 0.0)
	check_eq(SfxSynth.ambience_levels(0.0, 25.0, 1, false, 0.0)["amb_crickets"], night["amb_crickets"], "wraps past midnight")
	check_eq(SfxSynth.ambience_levels(0.0, 23.0, 3, false, 0.0)["amb_crickets"], 0.0, "no winter crickets")
	check(SfxSynth.ambience_levels(0.0, 8.0, 0, false, 1.0)["amb_waves"] > SfxSynth.ambience_levels(0.0, 8.0, 0, false, 0.3)["amb_waves"])
	var cave := SfxSynth.ambience_levels(1.0, 23.0, 1, false, 1.0, true)
	for k in SfxSynth.LOOPS:
		check_eq(cave[k], 0.0, "underground " + k)
	for h in 24:
		for v in SfxSynth.ambience_levels(1.0, float(h), h % 4, false, 2.0).values():
			check(v >= 0.0 and v <= 1.0, "range")

func test_volume_db() -> void:
	check_eq(SfxSynth.volume_db(0.0), -60.0)
	check_eq(SfxSynth.volume_db(0.01), -60.0)
	check(SfxSynth.volume_db(1.0) > SfxSynth.volume_db(0.3))
	check(absf(SfxSynth.volume_db(1.0)) < 0.001)
	check(SfxSynth.volume_db(5.0) <= 0.001)

func test_player_counts_rate_limit_and_mute() -> void:
	var s := Sfx.new()
	check(s.play("chop"))
	check(not s.play("chop"), "rate limited")
	check(s.play("coin"), "other names are independent")
	check_eq(s.play_counts.get("chop", 0), 1)
	check(not s.play("nope"))
	check(s.toggle_mute())
	check(not s.play("hit"), "muted")
	check(not s.play_counts.has("hit"))
	check(not s.toggle_mute())
	check(s.play("hit"))
	s.free()

func test_player_ambience_eases() -> void:
	var s := Sfx.new()
	s.set_ambience({"amb_wind": 1.0}, 0.1)
	var first: float = s.ambience["amb_wind"]
	check(first > 0.0 and first < 1.0, "eases in")
	s.set_ambience({"amb_wind": 1.0}, 10.0)
	check_eq(s.ambience["amb_wind"], 1.0)
	s.set_ambience({}, 10.0)
	check_eq(s.ambience["amb_wind"], 0.0)
	s.free()
