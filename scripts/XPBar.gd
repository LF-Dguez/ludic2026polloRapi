# XPBar — barra XP delgada en la parte superior izquierda + nivel.
# Soporta nivel + XP curve cuadrática.

class_name XPBar
extends Control

signal level_up(new_level: int)

const BASE_XP: int = 50  # XP para subir del 1 al 2
const GROWTH: float = 1.4  # cada nivel cuesta 1.4x

var current_xp: int = 0
var level: int = 1
var _bar_bg: ColorRect = null
var _bar_fill: ColorRect = null
var _lvl_lbl: Label = null
var _xp_lbl: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_w: float = 220.0
	var bar_h: float = 12.0
	# Position: top-left, debajo del info label (offset Y 70)
	position = Vector2(8, 64)
	size = Vector2(bar_w + 60, bar_h + 20)
	# Level label
	_lvl_lbl = Label.new()
	_lvl_lbl.add_theme_font_size_override("font_size", 14)
	_lvl_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	_lvl_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_lvl_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_lvl_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_lvl_lbl.text = "Nv.1"
	_lvl_lbl.position = Vector2(0, 0)
	_lvl_lbl.size = Vector2(50, 14)
	add_child(_lvl_lbl)
	# BG bar
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.05, 0.05, 0.03, 0.85)
	_bar_bg.position = Vector2(50, 2)
	_bar_bg.size = Vector2(bar_w, bar_h)
	add_child(_bar_bg)
	# Fill
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.55, 0.85, 0.45, 0.95)
	_bar_fill.position = Vector2(50, 2)
	_bar_fill.size = Vector2(0, bar_h)
	add_child(_bar_fill)
	# XP label debajo
	_xp_lbl = Label.new()
	_xp_lbl.add_theme_font_size_override("font_size", 10)
	_xp_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.65))
	_xp_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_xp_lbl.add_theme_constant_override("shadow_offset_x", 1)
	_xp_lbl.add_theme_constant_override("shadow_offset_y", 1)
	_xp_lbl.text = "0/50"
	_xp_lbl.position = Vector2(50, 16)
	_xp_lbl.size = Vector2(bar_w, 12)
	_xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_xp_lbl)
	_refresh()


func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_for_next_level():
		current_xp -= xp_for_next_level()
		level += 1
		level_up.emit(level)
	_refresh()


func xp_for_next_level() -> int:
	return int(BASE_XP * pow(GROWTH, level - 1))


func _refresh() -> void:
	var need: int = xp_for_next_level()
	var ratio: float = float(current_xp) / float(need)
	_bar_fill.size = Vector2(220.0 * clampf(ratio, 0.0, 1.0), _bar_fill.size.y)
	_lvl_lbl.text = "Nv.%d" % level
	_xp_lbl.text = "%d/%d" % [current_xp, need]


func get_state() -> Dictionary:
	return {"level": level, "xp": current_xp}


func set_state(d: Dictionary) -> void:
	level = int(d.get("level", 1))
	current_xp = int(d.get("xp", 0))
	_refresh()
