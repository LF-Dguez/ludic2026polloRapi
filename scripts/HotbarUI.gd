# HotbarUI — 4 slots al lado de los corazones (bottom-left).
# Muestra primeros 4 slots del inventory. Teclas 1-4 usan.

class_name HotbarUI
extends Control

const InventoryScript = preload("res://scripts/Inventory.gd")
const ItemDBScript = preload("res://scripts/ItemDB.gd")
const IconGenScript = preload("res://scripts/IconGenerator.gd")

const SLOT_COUNT := 4
const SLOT_SIZE := 56
const SLOT_SPACING := 8

var inventory = null  # Inventory instance
var _slots: Array[Control] = []
var _selected_slot: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(SLOT_COUNT * (SLOT_SIZE + SLOT_SPACING), SLOT_SIZE + 20)
	_build_slots()


func bind_inventory(inv) -> void:
	if inventory != null and inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	inventory = inv
	if inventory != null:
		inventory.changed.connect(_on_inventory_changed)
	_refresh()


func _build_slots() -> void:
	for c in _slots:
		c.queue_free()
	_slots.clear()
	for i in range(SLOT_COUNT):
		var slot := Panel.new()
		slot.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.position = Vector2(i * (SLOT_SIZE + SLOT_SPACING), 0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Background
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.06, 0.04, 0.85)
		sb.border_color = Color(0.85, 0.75, 0.45, 0.9)
		sb.set_border_width_all(2)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		slot.add_theme_stylebox_override("panel", sb)
		# TextureRect para icono procedural
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.size = Vector2(SLOT_SIZE - 14, SLOT_SIZE - 14)
		icon.position = Vector2(7, 7)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
		# Count
		var count_lbl := Label.new()
		count_lbl.name = "Count"
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		count_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		count_lbl.add_theme_constant_override("shadow_offset_x", 1)
		count_lbl.add_theme_constant_override("shadow_offset_y", 1)
		count_lbl.position = Vector2(SLOT_SIZE - 18, SLOT_SIZE - 18)
		count_lbl.size = Vector2(16, 14)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slot.add_child(count_lbl)
		# Key hint (1/2/3/4)
		var key_lbl := Label.new()
		key_lbl.name = "KeyHint"
		key_lbl.text = str(i + 1)
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
		key_lbl.position = Vector2(4, 2)
		key_lbl.size = Vector2(14, 12)
		slot.add_child(key_lbl)
		add_child(slot)
		_slots.append(slot)


func _on_inventory_changed() -> void:
	_refresh()


func _refresh() -> void:
	if inventory == null:
		return
	for i in range(SLOT_COUNT):
		var slot: Panel = _slots[i] as Panel
		var icon: TextureRect = slot.get_node("Icon") as TextureRect
		var count_lbl: Label = slot.get_node("Count") as Label
		var item = inventory.items[i] if i < inventory.items.size() else null
		if item == null:
			icon.texture = null
			count_lbl.text = ""
		else:
			icon.texture = IconGenScript.get_icon(item["id"])
			count_lbl.text = str(item["count"]) if item["count"] > 1 else ""
