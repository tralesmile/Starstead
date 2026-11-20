class_name DialogueView
extends CanvasLayer
## Speech box at the bottom of the screen with typewriter reveal. E/Esc/Space closes (first press completes the line).

signal closed
var panel: ColorRect
var name_label: Label
var body: Label
var text := ""
var t := 0.0
var counter := 0

func _init() -> void:
	layer = 9
	panel = ColorRect.new()
	panel.color = Color(0.08, 0.06, 0.04, 0.9)
	panel.position = Vector2(100, 262)
	panel.size = Vector2(440, 80)
	add_child(panel)
	name_label = Label.new()
	name_label.position = Vector2(10, 4)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	panel.add_child(name_label)
	body = Label.new()
	body.position = Vector2(10, 24)
	panel.add_child(body)
	visible = false

var gossip_cb: Callable   # main: (counter) -> closed-road gossip line or ""

func open(npc: Dictionary, activity: String) -> void:
	counter += 1
	name_label.text = str(npc["name"])
	var line := Dialogue.pick(npc, activity, counter)
	if gossip_cb.is_valid():
		var g := str(gossip_cb.call(counter))
		if g != "":
			line = g
	text = "\n".join(Dialogue.wrap(line, 58))
	t = 0.0
	body.text = ""
	visible = true

func _process(delta: float) -> void:
	if visible:
		t += delta
		body.text = Dialogue.reveal(text, t)

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("interact") or e.is_action_pressed("ui_cancel") or e.is_action_pressed("ui_accept"):
		if body.text.length() < text.length():
			t = 999.0
		else:
			visible = false
			closed.emit()
	return true
