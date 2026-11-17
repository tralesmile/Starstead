class_name WeatherView
extends Node2D
## Rain streaks around the player (whole-pixel lines) in world space; main darkens the tint.

var player: Player
var intensity := 0.0   # today's rain strength (0 = clear)
var now := 0.0         # current rain after fade window
var t := 0.0
const DROPS := 120

func _ready() -> void:
	z_index = 60

func _process(d: float) -> void:
	t += d
	now = WeatherMath.rain_now(intensity, GameState.clock.minutes)
	queue_redraw()

func _draw() -> void:
	if player == null or now <= 0.01:
		return
	var origin := player.position.round() - Vector2(180, 140)
	var n := int(DROPS * now)
	for i in n:
		var p := (origin + WeatherMath.drop_pos(i, t)).round()
		draw_line(p, p + Vector2(-2, 5), Color(0.75, 0.85, 1.0, 0.55), 1.0)
		if i % 6 == 0:  # splash
			var sp := (origin + WeatherMath.drop_pos(i + 500, t * 0.5)).round()
			draw_rect(Rect2(sp, Vector2(3, 1)), Color(0.85, 0.92, 1.0, 0.4))
