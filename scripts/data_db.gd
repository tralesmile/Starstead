class_name DataDB
extends RefCounted
## Loads balance data from res://data/*.json.

static func load_json(name: String) -> Variant:
	var p := "res://data/%s.json" % name
	return JSON.parse_string(FileAccess.get_file_as_string(p))
