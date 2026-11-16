extends RefCounted
class_name BaseTest

var runner
var current := ""

func check(cond: bool, msg: String = "") -> void:
	if not cond:
		runner.fail("%s %s" % [current, msg])

func check_eq(a, b, msg: String = "") -> void:
	if a != b:
		runner.fail("%s expected %s got %s %s" % [current, str(b), str(a), msg])
