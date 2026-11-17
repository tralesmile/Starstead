extends BaseTest

func test_pick_and_fallback() -> void:
	var n: Dictionary = {"lines": {"fish": ["a", "b"], "default": ["z"]}}
	check(Dialogue.pick(n, "fish", 0) == "a")
	check(Dialogue.pick(n, "fish", 3) == "b")
	check(Dialogue.pick(n, "sleep", 5) == "z")
	check(Dialogue.pick({}, "x", 0) == "...")

func test_wrap_reveal() -> void:
	var w := Dialogue.wrap("one two three four", 10)
	check(w.size() == 2 and w[0] == "one two")
	check(Dialogue.reveal("hello", 0.05) == "he")
	check(Dialogue.reveal("hello", 9.0) == "hello")

func test_every_npc_has_default_line() -> void:
	var d: Dictionary = DataDB.load_json("npcs")
	for n in d["npcs"]:
		check(n.get("lines", {}).has("default"), n["id"])
