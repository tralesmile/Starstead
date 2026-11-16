class_name Outline
extends RefCounted
## Helper for the yellow interactable outline shader.

const SHADER := preload("res://assets/shaders/prop.gdshader")

static func apply(item: CanvasItem) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	item.material = m
	return m

static func set_enabled(item: CanvasItem, on: bool) -> void:
	if item.material == null:
		apply(item)
	(item.material as ShaderMaterial).set_shader_parameter("enabled", on)

static func set_sway(item: CanvasItem, pixels: float, phase: float) -> void:
	if item.material == null:
		apply(item)
	(item.material as ShaderMaterial).set_shader_parameter("sway", pixels)
	(item.material as ShaderMaterial).set_shader_parameter("phase", phase)
