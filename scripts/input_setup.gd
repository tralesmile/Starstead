extends Node
## Registers the game's input actions in code (keeps project.godot readable and testable).
## Keyboard + gamepad bindings per action.

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E, KEY_SPACE],
	"use_tool": [KEY_F],
	"inventory": [KEY_TAB, KEY_I],
	"pause": [KEY_ESCAPE],
	"sprint": [KEY_SHIFT],
	"sneak": [KEY_CTRL],
}
const PAD := {
	"interact": JOY_BUTTON_A,
	"use_tool": JOY_BUTTON_X,
	"inventory": JOY_BUTTON_Y,
	"pause": JOY_BUTTON_START,
	"sprint": JOY_BUTTON_B,
}

func _ready() -> void:
	register()

func register() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.keycode = k
			InputMap.action_add_event(action, ev)
		if PAD.has(action):
			var pev := InputEventJoypadButton.new()
			pev.button_index = PAD[action]
			InputMap.action_add_event(action, pev)
