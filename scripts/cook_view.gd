class_name CookView
extends CanvasLayer
## Kitchen stove menu: click a recipe (or press its number) to cook it from the bag.

signal closed
signal cooked(name: String)
var canvas: Control
var recipes: Dictionary = DataDB.load_json("recipes")
var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var msg := ""
var title := "Kitchen - click a dish or press its number"
var footer := "Right-click a dish in your bag (Tab) to eat it.   E / Esc: leave"
var done_word := "Cooked"
var trim := WoodUI.Trim.GINGHAM
const ORIGIN := Vector2(150, 60)
const ROW := 34.0

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open() -> void:
	visible = true
	msg = ""

func close() -> void:
	visible = false
	closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _try(i: int) -> void:
	var ids := recipes.keys()
	if i < 0 or i >= ids.size():
		return
	var r: Dictionary = recipes[ids[i]]
	if CookModel.cook(GameState.bag, r):
		msg = "%s %s!" % [done_word, r["name"]]
		cooked.emit(String(r["name"]))
	elif CookModel.can_cook(GameState.bag, r):
		msg = "Your bag is full"
	else:
		msg = "Missing ingredients"

func _try_at(at: Vector2) -> void:
	_try(CraftGrid.list_index_at(at, recipes.size()))

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("pause") or e.is_action_pressed("inventory") or e.is_action_pressed("interact"):
		close()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_try_at(canvas.get_local_mouse_position())
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := TargetMath.key_slot(e.keycode)
		if k >= 0:
			_try(k)
	return true

func _draw_all() -> void:
	var ids := recipes.keys()
	var n := ids.size()
	var panel := CraftGrid.list_panel(n)
	WoodUI.panel(canvas, panel, title, trim)
	var hover := CraftGrid.list_index_at(canvas.get_local_mouse_position(), n)
	var narrow := n > CraftGrid.LIST_MAX
	for i in n:
		var r: Dictionary = recipes[ids[i]]
		var cr := CraftGrid.list_rect(i, n)
		var o := cr.position
		var ok := CookModel.can_cook(GameState.bag, r)
		var text_w := cr.size.x - 36.0
		WoodUI.row(canvas, cr, i == hover, ok)
		WoodUI.icon_well(canvas, Rect2(o + Vector2(3, 3), Vector2(23, 22)))
		canvas.draw_texture_rect_region(item_tex, Rect2(o + Vector2(4, 4), Vector2(20, 20)), Rect2(int(icons.get(r["makes"], 0)) * 16, 0, 16, 16), Color.WHITE if ok else Color(1, 1, 1, 0.45))
		var info: Dictionary = items.get(r["makes"], {})
		var label := ("%d. %s" % [(i + 1) % 10, r["name"]]) if i < 10 else String(r["name"])
		if int(info.get("energy", 0)) > 0:
			label += "   (+%d energy)" % int(info["energy"])
		elif not ("(" in String(r["name"])):
			label += "   (worth $%d)" % int(info.get("price", 0))
		WoodUI.text(canvas, o + Vector2(32, 12), label, 9 if narrow else 10, WoodUI.INK if ok else WoodUI.INK_SOFT, text_w)
		WoodUI.text(canvas, o + Vector2(32, 23 if narrow else 25), CookModel.ingredient_text(GameState.bag, r), 8 if narrow else 9, WoodUI.GOOD if ok else WoodUI.BAD, text_w)
	WoodUI.text(canvas, Vector2(panel.position.x + 10, panel.end.y - 8), msg if msg != "" else footer, 10, WoodUI.GOOD if msg != "" else WoodUI.INK, panel.size.x - 16)
