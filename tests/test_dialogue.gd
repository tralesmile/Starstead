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

func test_gate_gossip() -> void:
	var g := {"a": {"needs": "s1", "msg": "x", "gossip": "road A shut"}, "b": {"needs": "s2", "msg": "y", "gossip": "road B shut"}}
	check_eq(Dialogue.gate_gossip(g, {}, 1), "", "odd talks use the NPC's own lines")
	check_eq(Dialogue.gate_gossip(g, {}, 0), "road A shut")
	check_eq(Dialogue.gate_gossip(g, {}, 2), "road B shut", "rotates")
	check_eq(Dialogue.gate_gossip(g, {"s1": true}, 0), "road B shut", "opened roads are not gossiped")
	check_eq(Dialogue.gate_gossip(g, {"s1": true, "s2": true}, 0), "")
	check_eq(Dialogue.gate_gossip({}, {}, 0), "", "gates off")

func test_real_gates_have_gossip() -> void:
	var g := StoryGate.load_gates()
	check(Dialogue.gate_gossip(g, {}, 0) != "")
	for rid in g:
		check((g[rid] as Dictionary).has("gossip"), rid)
