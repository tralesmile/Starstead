extends SceneTree
## Simple headless test runner: godot --headless --path . -s tests/run_tests.gd
## Every tests/test_*.gd with methods named test_* is run; any failed assert fails the run.

var failures := 0
var passed := 0

func _init() -> void:
	var dir := DirAccess.open("res://tests")
	var files := []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f in files:
		var script = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			fail("cannot load " + f)
			continue
		var t = script.new()
		t.runner = self
		for m in t.get_method_list():
			if str(m.name).begins_with("test_"):
				t.current = "%s::%s" % [f, m.name]
				t.call(m.name)
				passed += 1
	print("TESTS: %d run, %d failed" % [passed, failures])
	quit(1 if failures > 0 else 0)

func fail(msg: String) -> void:
	failures += 1
	printerr("FAIL: " + msg)
