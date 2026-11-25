class_name FarmView
extends Node2D
## Draws tilled soil (autotiled so furrows connect, darker when watered) and crop growth stages.

var dry: Texture2D = load("res://assets/sprites/soil_dry.png")
var wet: Texture2D = load("res://assets/sprites/soil_wet.png")
var turnip: Texture2D = load("res://assets/sprites/crop_turnip.png")
var weed_tex: Texture2D = load("res://assets/sprites/weed.png")
var scarecrow_tex: Texture2D = load("res://assets/sprites/scarecrow.png")
var sprinkler_tex: Texture2D = load("res://assets/sprites/sprinkler.png")
var generic: Texture2D = load("res://assets/sprites/crop_generic.png")

var rain := 0.0        # 0..1, set by Main
var walker: Node2D     # the player: crops bend away when brushed past

func _ready() -> void:
	z_index = -9

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var farm: FarmModel = GameState.farm
	var t := Time.get_ticks_msec() * 0.001
	var joins := {}
	for cell in farm.soil:
		joins[cell] = true
	var crops: Array = []
	for cell in farm.soil:
		var s = farm.soil[cell]
		var m := Autotile.mask(joins, cell, [true])
		var tex: Texture2D = wet if s.watered else dry
		var dk := CropMath.rain_darken(rain, s.watered)
		draw_texture_rect_region(tex, Rect2(Vector2(cell) * 32.0, Vector2(32, 32)), Rect2(Autotile.atlas_index(m) * 32, 0, 32, 32), Color(dk, dk, dk * 1.02))
		if s.watered:   # wet soil catches the light: two tiny twinkles per tile
			for gi in 2:
				var g := CropMath.glint(cell, gi, t)
				if float(g["a"]) > 0.05:
					draw_rect(Rect2(Vector2(cell) * 32.0 + Vector2(float(g["x"]), float(g["y"])), Vector2(2, 1)), Color(0.78, 0.88, 0.95, 0.55 * float(g["a"])))
		if bool(s.get("fert", false)) and not bool(s.get("fert_spent", false)):   # fertiliser: pale-green flecks in the furrows
			var o := Vector2(cell) * 32.0
			for i in 7:
				var h: int = (cell.x * 92821 + cell.y * 68917 + i * 7919) & 0xffff
				draw_rect(Rect2(o + Vector2(4 + h % 24, 6 + (h / 24) % 22), Vector2(1, 1)), Color(0.72, 0.86, 0.45, 0.9))
				draw_rect(Rect2(o + Vector2(5 + h % 24, 6 + (h / 24) % 22), Vector2(1, 1)), Color(0.45, 0.6, 0.25, 0.9))
		if s.crop != "":
			crops.append(cell)
	for cell in crops:  # crops drawn after all soil so tall plants overlap the next row
		var s = farm.soil[cell]
		var f := FarmModel.stage(int(s.age), int(farm.crops[s.crop].grow_days))
		var ct: Texture2D = turnip if s.crop == "turnip" else generic
		var mod := Color.WHITE
		if s.crop != "turnip" and f == 4 and farm.crops[s.crop].has("tint"):
			mod = Color(String(farm.crops[s.crop].tint)).lerp(Color.WHITE, 0.25)  # ripe fruit takes the crop's colour
		var foot := Vector2(cell) * 32.0 + Vector2(16, 30)   # shear around the plant's foot so the roots stay put
		draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(CropMath.sway(cell, t, f) + (CropMath.brush(foot, walker.position + Vector2(0, 14), f) if walker != null else 0.0), 1), foot))
		draw_texture_rect_region(ct, Rect2(Vector2(-16, -28), Vector2(32, 32)), Rect2(f * 32, 0, 32, 32), mod)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	for cell in farm.weeds:
		draw_texture_rect_region(weed_tex, Rect2(Vector2(cell) * 32.0, Vector2(32, 32)), Rect2(0, 0, 32, 32))
	for cell in farm.scarecrows:
		var sway := sin(Time.get_ticks_msec() * 0.0015 + float(cell.x)) * 1.0
		draw_texture_rect(scarecrow_tex, Rect2(Vector2(cell) * 32.0 + Vector2(sway, -16), Vector2(32, 48)), false)
	for cell in farm.sprinklers:
		draw_texture_rect_region(sprinkler_tex, Rect2(Vector2(cell) * 32.0, Vector2(32, 32)), Rect2(0, 0, 32, 32))
