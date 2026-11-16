class_name Hotbar
extends CanvasLayer
## Tool/seed hotbar at the bottom of the screen; number keys 1-4 select.

var selected := 0
var label: Label

func _init() -> void:
	label = Label.new()
	label.position = Vector2(8, 336)
	add_child(label)

func current() -> String:
	return ToolUse.TOOLS[selected]

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode >= KEY_1 and e.keycode < KEY_1 + ToolUse.TOOLS.size():
		selected = e.keycode - KEY_1

func _process(_d: float) -> void:
	var parts := []
	for i in ToolUse.TOOLS.size():
		var t: String = ToolUse.TOOLS[i]
		var txt := "%d:%s" % [i + 1, t]
		if t.ends_with("_seed"):
			txt += "(%d)" % GameState.bag.count(t)
		parts.append(("[%s]" % txt) if i == selected else txt)
	label.text = "  ".join(parts)
