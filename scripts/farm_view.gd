class_name FarmView
extends Node2D
## Draws tilled soil (autotiled so furrows connect, darker when watered) and crop growth stages.

var dry: Texture2D = load("res://assets/sprites/soil_dry.png")
var wet: Texture2D = load("res://assets/sprites/soil_wet.png")
var turnip: Texture2D = load("res://assets/sprites/crop_turnip.png")
var weed_tex: Texture2D = load("res://assets/sprites/weed.png")
var sprinkler_tex: Texture2D = load("res://assets/sprites/sprinkler.png")
var generic: Texture2D = load("res://assets/sprites/crop_generic.png")

func _ready() -> void:
	z_index = -9

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var farm: FarmModel = GameState.farm
	var joins := {}
	for cell in farm.soil:
		joins[cell] = true
	var crops: Array = []
	for cell in farm.soil:
		var s = farm.soil[cell]
		var m := Autotile.mask(joins, cell, [true])
		var tex: Texture2D = wet if s.watered else dry
		draw_texture_rect_region(tex, Rect2(Vector2(cell) * 32.0, Vector2(32, 32)), Rect2(Autotile.atlas_index(m) * 32, 0, 32, 32))
		if s.crop != "":
			crops.append(cell)
	for cell in crops:  # crops drawn after all soil so tall plants overlap the next row
		var s = farm.soil[cell]
		var f := FarmModel.stage(int(s.age), int(farm.crops[s.crop].grow_days))
		var ct: Texture2D = turnip if s.crop == "turnip" else generic
		var mod := Color.WHITE
		if s.crop != "turnip" and f == 4 and farm.crops[s.crop].has("tint"):
			mod = Color(String(farm.crops[s.crop].tint)).lerp(Color.WHITE, 0.25)  # ripe fruit takes the crop's colour
		draw_texture_rect_region(ct, Rect2(Vector2(cell) * 32.0 + Vector2(0, 2), Vector2(32, 32)), Rect2(f * 32, 0, 32, 32), mod)
	for cell in farm.weeds:
		draw_texture_rect_region(weed_tex, Rect2(Vector2(cell) * 32.0, Vector2(32, 32)), Rect2(0, 0, 32, 32))
	for cell in farm.sprinklers:
		draw_texture_rect_region(sprinkler_tex, Rect2(Vector2(cell) * 32.0, Vector2(32, 32)), Rect2(0, 0, 32, 32))
