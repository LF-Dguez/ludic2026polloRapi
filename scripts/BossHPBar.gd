# BossHPBar — barra de HP grande arriba de la pantalla cuando hay boss activo.

class_name BossHPBar
extends Control

var _bg: ColorRect = null
var _fill: ColorRect = null
var _label: Label = null
var _current: int = 0
var _max: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var vp: Vector2 = get_viewport_rect().size
	var bar_w: float = 520.0
	var bar_h: float = 22.0
	var bar_x: float = (vp.x - bar_w) / 2.0
	var bar_y: float = 28.0
	# Background bar
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.02, 0.02, 0.85)
	_bg.position = Vector2(bar_x, bar_y)
	_bg.size = Vector2(bar_w, bar_h)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	# Borde
	var border := ColorRect.new()
	border.color = Color(0.85, 0.20, 0.20, 0.95)
	border.position = Vector2(bar_x - 2, bar_y - 2)
	border.size = Vector2(bar_w + 4, bar_h + 4)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)
	border.move_to_front()
	_bg.move_to_front()
	# Fill
	_fill = ColorRect.new()
	_fill.color = Color(0.85, 0.20, 0.20, 0.95)
	_fill.position = Vector2(bar_x + 2, bar_y + 2)
	_fill.size = Vector2(bar_w - 4, bar_h - 4)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)
	_fill.move_to_front()
	# Label
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(bar_x, bar_y - 24)
	_label.size = Vector2(bar_w, 20)
	add_child(_label)


func show_boss(name: String, current: int, max_hp: int) -> void:
	visible = true
	_current = current
	_max = max_hp
	_label.text = name
	_refresh()


func update_hp(current: int, max_hp: int, name: String) -> void:
	_current = current
	_max = max_hp
	_label.text = name
	_refresh()
	if current <= 0:
		hide_boss()


func hide_boss() -> void:
	visible = false


func _refresh() -> void:
	if _max <= 0:
		return
	var ratio: float = float(_current) / float(_max)
	var bar_w: float = 520.0 - 4.0
	_fill.size = Vector2(bar_w * ratio, _fill.size.y)
	# Color cambia con HP (rojo → amarillo → verde inverso para boss)
	if ratio < 0.25:
		_fill.color = Color(0.95, 0.30, 0.20)  # critical
	elif ratio < 0.55:
		_fill.color = Color(0.85, 0.55, 0.20)  # warning
	else:
		_fill.color = Color(0.85, 0.20, 0.20)  # normal
