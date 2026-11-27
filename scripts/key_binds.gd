class_name KeyBinds
extends RefCounted
## Pure rules for rebindable keys. Every action here is read only through the InputMap (or key_of/down), so a new key works
## everywhere. Each has one rebindable main key; InputSetup's extra keys (Space, I, arrows) stay as fixed second keys.
## Keys used by features that cannot be rebound are refused. Saved under "keys" in the settings file.

const SETUP := preload("res://scripts/input_setup.gd")
## [action, name on the Controls page] in page order.
const LIST := [["move_up", "Walk up"], ["move_down", "Walk down"], ["move_left", "Walk left"], ["move_right", "Walk right"],
	["sprint", "Sprint"], ["sneak", "Sneak"], ["interact", "Use / talk"], ["use_tool", "Tool / brake"], ["inventory", "Bag"],
	["craft", "Craft"], ["map", "Map"], ["journal", "Fish log / job"], ["quests", "Quests"]]
const MOVES := ["move_up", "move_down", "move_left", "move_right"]
const HOLDS := ["sprint", "sneak"]
const RESERVED := {
	KEY_ESCAPE: "pauses and goes back", KEY_F1: "hides the key list", KEY_ENTER: "confirms menus",
	KEY_UP: "always walks up", KEY_DOWN: "always walks down", KEY_LEFT: "always walks left", KEY_RIGHT: "always walks right",
	KEY_SPACE: "is the second Use key and the sports key", KEY_I: "always opens the bag",
	KEY_0: "picks the hotbar", KEY_1: "picks the hotbar", KEY_2: "picks the hotbar", KEY_3: "picks the hotbar", KEY_4: "picks the hotbar",
	KEY_5: "picks the hotbar", KEY_6: "picks the hotbar", KEY_7: "picks the hotbar", KEY_8: "picks the hotbar", KEY_9: "picks the hotbar",
	KEY_EQUAL: "zooms in", KEY_PLUS: "zooms in", KEY_MINUS: "zooms out",
	KEY_B: "is build mode", KEY_Q: "picks build pieces / bends a shot", KEY_R: "picks blueprints / restarts a race",
	KEY_H: "builds a blueprint", KEY_X: "demolishes, unloads and trashes", KEY_G: "is gear and cart loading",
	KEY_T: "swipes from a stall", KEY_P: "picks a perk", KEY_L: "starts race laps", KEY_N: "mutes the sound",
}
const SPECIAL := {KEY_TAB: "Tab", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_BACKSPACE: "Bksp", KEY_INSERT: "Ins",
	KEY_HOME: "Home", KEY_END: "End", KEY_PAGEUP: "PgUp", KEY_PAGEDOWN: "PgDn"}

static var current: Dictionary = {}   # action -> main keycode; empty = the defaults
static var persist := false           # only a real session may write the player's settings (Main sets it)

static func defaults() -> Dictionary:
	var out := {}
	for row in LIST:
		out[row[0]] = int(SETUP.ACTIONS[row[0]][0])
	return out

static func binds() -> Dictionary:
	if current.is_empty():
		current = defaults()
	return current

static func key_of(action: String) -> int:
	return int(binds()[action])

## Held state of the main key only (for places where the fixed second key means something else).
static func down(action: String) -> bool:
	return Input.is_key_pressed(key_of(action))

static func action_name(action: String) -> String:
	for row in LIST:
		if row[0] == action:
			return row[1]
	return action

static func key_label(code: int) -> String:
	if SPECIAL.has(code):
		return SPECIAL[code]
	if code == KEY_SPACE:
		return "Space"
	if code == KEY_ESCAPE:
		return "Esc"
	if code > 32 and code < 127:
		return String.chr(code)
	return OS.get_keycode_string(code)

static func label(action: String) -> String:
	return key_label(key_of(action))

## "WASD" by default; the four main walking keys in up, left, down, right order.
static func move_label() -> String:
	var parts: Array[String] = []
	var short := true
	for a in ["move_up", "move_left", "move_down", "move_right"]:
		parts.append(label(a))
		short = short and parts[-1].length() == 1
	if short:
		return "".join(parts)
	var joined := "/".join(parts)
	return joined if joined.length() <= 12 else "Custom"

## "" if `code` may be the main key of `action`, else why not.
static func refusal(action: String, code: int) -> String:
	if RESERVED.has(code):
		return "%s %s" % [key_label(code), RESERVED[code]]
	if code == KEY_S and not (action in MOVES):
		return "S sorts the bag"
	if not (SPECIAL.has(code) or (code > 32 and code < 127)):
		return "That key cannot be used"
	if (code == KEY_SHIFT or code == KEY_CTRL) and not (action in HOLDS):
		return "%s only works for Sprint or Sneak" % key_label(code)
	return ""

## Gives `action` the key `code`. A key another action holds is swapped. -> {ok, binds, msg}; `from` is not changed.
static func rebind(from: Dictionary, action: String, code: int) -> Dictionary:
	var why := refusal(action, code)
	if why != "":
		return {"ok": false, "binds": from, "msg": why}
	var out := from.duplicate()
	var old := int(out[action])
	var msg := "%s is now %s" % [action_name(action), key_label(code)]
	for other in out:
		if other != action and int(out[other]) == code:
			var bad := refusal(other, old)
			if bad != "":
				return {"ok": false, "binds": from, "msg": "Cannot swap with %s: %s" % [action_name(other), bad]}
			out[other] = old
			msg = "Swapped: %s %s, %s %s" % [action_name(action), key_label(code), action_name(other), key_label(old)]
	out[action] = code
	return {"ok": true, "binds": out, "msg": msg}

## Saved settings -> binds. A broken or clashing "keys" entry falls back to the defaults as a whole.
static func from_settings(d: Dictionary) -> Dictionary:
	var out := defaults()
	var saved = d.get("keys")
	if not (saved is Dictionary):
		return out
	for a in out:
		if saved.has(a) and (saved[a] is float or saved[a] is int):
			out[a] = int(saved[a])
	var used := {}
	for a in out:
		if used.has(out[a]) or refusal(a, out[a]) != "":
			return defaults()
		used[out[a]] = true
	return out

## Writes the key choices and keeps every other setting.
static func store(chosen: Dictionary, path: String = PauseModel.SETTINGS_PATH) -> void:
	var d := PauseModel.read_settings(path)
	if chosen == defaults():
		d.erase("keys")
	else:
		d["keys"] = chosen
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))

## Makes the InputMap match `chosen` (key events only; pad buttons stay).
static func apply(chosen: Dictionary) -> void:
	current = chosen.duplicate()
	for a in current:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		for ev in InputMap.action_get_events(a):
			if ev is InputEventKey:
				InputMap.action_erase_event(a, ev)
		var codes: Array = [current[a]]
		codes.append_array((SETUP.ACTIONS[a] as Array).slice(1))
		for code in codes:
			var k := InputEventKey.new()
			k.keycode = code
			InputMap.action_add_event(a, k)

## Rewrites the key names inside a prompt or footer ("E: Drive", "Hold F", "(Tab)") to the bound keys.
## One pass over the original text, so swapped keys cannot be rewritten twice. "Shift+" stays: it is a fixed modifier.
const HINTS := [
	["interact", "(?<![\\w])E(?=: | / Esc| to |\\))|(?<=Hold )E(?!\\w)|(?<=\\+)E(?!\\w)"],
	["use_tool", "(?<![\\w])F(?= / Click)|(?<=Hold )F(?!\\w)"],
	["inventory", "(?<=\\()Tab(?=\\))"],
	["craft", "(?<=\\()C(?=\\))|(?<=press )C(?!\\w)"],
	["journal", "(?<![\\w])J(?=: | or Esc)"],
	["sprint", "(?<=\\()Shift(?=\\))|(?<![\\w])Shift(?=: brake)"],
]
static var _regex: Array = []

static func hint(text: String) -> String:
	if text == "" or binds() == defaults():
		return text
	if _regex.is_empty():
		for h in HINTS:
			_regex.append([h[0], RegEx.create_from_string(h[1])])
	var found: Array = []
	for r in _regex:
		for m in (r[1] as RegEx).search_all(text):
			found.append([m.get_start(), m.get_end(), label(r[0])])
	found.sort_custom(func(a, b): return a[0] > b[0])
	for f in found:
		text = text.substr(0, f[0]) + f[2] + text.substr(f[1])
	return text
