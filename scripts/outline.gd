class_name Outline
extends RefCounted
## Helper for the yellow interactable outline shader.

const SHADER := preload("res://assets/shaders/outline.gdshader")

static func apply(item: CanvasItem) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	item.material = m
	return m

static func set_enabled(item: CanvasItem, on: bool) -> void:
	if item.material == null:
		apply(item)
	(item.material as ShaderMaterial).set_shader_parameter("enabled", on)
