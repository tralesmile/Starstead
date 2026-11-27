extends BaseTest
## Procedural music: the tunes follow their key and chords, the audio is clean, and the mood rules.

func test_mood_rules() -> void:
	check_eq(MusicSynth.mood_for(0, 12.0, false, false, false), "spring")
	check_eq(MusicSynth.mood_for(2, 12.0, false, false, false), "autumn")
	check_eq(MusicSynth.mood_for(3, 22.0, false, false, false), "night")
	check_eq(MusicSynth.mood_for(1, 25.0, false, false, false), "night", "past midnight")
	check_eq(MusicSynth.mood_for(1, 12.0, true, false, false), "mine")
	check_eq(MusicSynth.mood_for(1, 12.0, true, true, false), "boss")
	check_eq(MusicSynth.mood_for(1, 12.0, true, true, true), "title")

func test_degrees() -> void:
	var r := MusicSynth.recipe("spring")
	check_eq(MusicSynth.degree_pitch(r, 0), 60)
	check_eq(MusicSynth.degree_pitch(r, 7), 72)
	check_eq(MusicSynth.degree_pitch(r, -7), 48)
	check_eq(MusicSynth.degree_pitch(r, 4), 67)

func test_tunes_stay_in_key_and_on_the_chord() -> void:
	for mood in MusicSynth.MOODS:
		var r := MusicSynth.recipe(mood)
		for variant in 4:
			var lead: Array = MusicSynth.compose(mood, variant).filter(func(n): return n["voice"] == "lead")
			check(lead.size() >= MusicSynth.BARS * 2, "%s has a tune" % mood)
			for n in lead:
				check((n["pitch"] - int(r["root"]) + 120) % 12 in r["scale"], "%s in key" % mood)
				check(float(n["beat"]) + float(n["len"]) <= MusicSynth.BARS * MusicSynth.BEATS + 0.001, "inside the loop")
				if is_zero_approx(fposmod(n["beat"], 2.0)) and n != lead[-1]:
					var deg: int = r["prog"][int(n["beat"]) / MusicSynth.BEATS]
					check(posmod(n["step"] - deg, 7) in [0, 2, 4], "%s strong beats sit on the chord" % mood)
			check_eq(posmod(lead[-1]["step"], 7), 0, "%s comes home" % mood)

func test_deterministic_and_varied() -> void:
	check_eq(str(MusicSynth.compose("summer", 1)), str(MusicSynth.compose("summer", 1)))
	check(str(MusicSynth.compose("summer", 1)) != str(MusicSynth.compose("summer", 2)))
	check(MusicSynth.loop_seconds("boss") < MusicSynth.loop_seconds("night"), "the boss theme drives faster")

func test_audio_is_clean_and_loops_without_a_click() -> void:
	var buf := MusicSynth.mix("boss")
	check_eq(buf.size(), int(round(MusicSynth.loop_seconds("boss") * MusicSynth.RATE)))
	var top := 0.0
	var step := 0.0
	for i in buf.size():
		top = maxf(top, absf(buf[i]))
		if i > 0:
			step = maxf(step, absf(buf[i] - buf[i - 1]))
	check(top > 0.2 and top <= MusicSynth.PEAK + 0.001, "peak %f" % top)
	check(absf(buf[0] - buf[buf.size() - 1]) <= step, "the seam is no rougher than the music")

func test_rests_and_fades() -> void:
	var two := MusicSynth.loop_seconds("spring") * MusicSynth.PLAYS_BEFORE_REST
	check(not MusicPlayer.rest_due("spring", two - 1.0))
	check(MusicPlayer.rest_due("spring", two + 1.0))
	check(not MusicPlayer.rest_due("boss", 9999.0))
	check_eq(MusicPlayer.target_gain("spring", "spring", 0.0), 1.0)
	check_eq(MusicPlayer.target_gain("spring", "night", 0.0), 0.0, "fade out before the change")
	check_eq(MusicPlayer.target_gain("spring", "spring", 5.0), 0.0, "quiet while resting")
