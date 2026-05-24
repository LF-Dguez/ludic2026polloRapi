# InventoryPanel — panel completo 4x4 con los 16 slots del inventario.
# Se activa con tecla I. Pausa el juego mientras está abierto. Click en slot = usar.

class_name InventoryPanel
extends Control

const InventoryScript = preload("res://scripts/Inventory.gd")
const ItemDBScript = preload("res://scripts/ItemDB.gd")
const IconGenScript = preload("res://scripts/IconGenerator.gd")

const COLS := 4
const ROWS := 4
const SLOT_SIZE := 72
const SLOT_PADDING := 8

var inventory = null
var _player_ref: Node = null
var _slot_buttons: Array = []
var _info_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	# Fondo semi-transparente
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.80)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Título
	var title := Label.new()
	title.text = "INVENTARIO  —  [I] Cerrar  —  Click = Usar/Equipar"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp: Vector2 = get_viewport_rect().size
	title.position = Vector2(0, vp.y * 0.10)
	title.size = Vector2(vp.x, 40)
	add_child(title)
	# Grid de slots
	var grid_w: int = COLS * SLOT_SIZE + (COLS - 1) * SLOT_PADDING
	var grid_h: int = ROWS * SLOT_SIZE + (ROWS - 1) * SLOT_PADDING
	var grid_x: int = int((vp.x - grid_w) / 2)
	var grid_y: int = int(vp.y * 0.20)
	for r in range(ROWS):
		for c in range(COLS):
			var idx: int = r * COLS + c
			var btn := Button.new()
			btn.flat = false
			btn.text = ""
			btn.size = Vector2(SLOT_SIZE, SLOT_SIZE)
			btn.position = Vector2(grid_x + c * (SLOT_SIZE + SLOT_PADDING), grid_y + r * (SLOT_SIZE + SLOT_PADDING))
			btn.focus_mode = Control.FOCUS_NONE
			add_child(btn)
			# Icon overlay encima del botón
			var icon := TextureRect.new()
			icon.name = "Icon%d" % idx
			icon.size = Vector2(SLOT_SIZE - 14, SLOT_SIZE - 14)
			icon.position = Vector2(btn.position.x + 7, btn.position.y + 7)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(icon)
			# Count label encima del icon
			var cnt := Label.new()
			cnt.name = "Count%d" % idx
			cnt.add_theme_font_size_override("font_size", 13)
			cnt.add_theme_color_override("font_color", Color(1, 1, 1))
			cnt.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
			cnt.add_theme_constant_override("shadow_offset_x", 1)
			cnt.add_theme_constant_override("shadow_offset_y", 1)
			cnt.position = Vector2(btn.position.x + SLOT_SIZE - 24, btn.position.y + SLOT_SIZE - 18)
			cnt.size = Vector2(22, 16)
			cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cnt)
			btn.pressed.connect(_on_slot_pressed.bind(idx))
			btn.mouse_entered.connect(_on_slot_hover.bind(idx))
			_slot_buttons.append(btn)
	# Info label (debajo del grid) — muestra nombre + descripción al hover
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 16)
	_info_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_info_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_info_label.add_theme_constant_override("shadow_offset_x", 1)
	_info_label.add_theme_constant_override("shadow_offset_y", 1)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.position = Vector2(0, grid_y + grid_h + 24)
	_info_label.size = Vector2(vp.x, 60)
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_info_label)


func bind(inv, player) -> void:
	if inventory != null and inventory.changed.is_connected(_refresh):
		inventory.changed.disconnect(_refresh)
	inventory = inv
	_player_ref = player
	if inventory != null:
		inventory.changed.connect(_refresh)
	_refresh()


func toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()


func _close() -> void:
	visible = false
	get_tree().paused = false


func _refresh() -> void:
	if inventory == null:
		return
	for i in range(_slot_buttons.size()):
		var btn: Button = _slot_buttons[i] as Button
		var icon := get_node_or_null("Icon%d" % i) as TextureRect
		var cnt := get_node_or_null("Count%d" % i) as Label
		var item = inventory.items[i] if i < inventory.items.size() else null
		if item == null:
			if icon != null: icon.texture = null
			if cnt != null: cnt.text = ""
			btn.modulate = Color(1, 1, 1, 0.55)
		else:
			if icon != null: icon.texture = IconGenScript.get_icon(item["id"])
			if cnt != null: cnt.text = "x%d" % item["count"] if item["count"] > 1 else ""
			btn.modulate = Color(1, 1, 1, 1.0)


func _on_slot_pressed(idx: int) -> void:
	if inventory == null or _player_ref == null:
		return
	if idx >= inventory.items.size() or inventory.items[idx] == null:
		return
	if _player_ref.has_method("use_inventory_slot"):
		_player_ref.use_inventory_slot(idx)


func _unhandled_input(event: InputEvent) -> void:
	# I cierra el inventario MIENTRAS está abierto (Main.gd no recibe input
	# durante pausa porque su process_mode = INHERIT).
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_I, KEY_ESCAPE:
				_close()
				get_viewport().set_input_as_handled()


func _on_slot_hover(idx: int) -> void:
	if inventory == null:
		_info_label.text = ""
		return
	if idx >= inventory.items.size() or inventory.items[idx] == null:
		_info_label.text = ""
		return
	var item = inventory.items[idx]
	var def: Dictionary = ItemDBScript.get_def(item["id"])
	var cat: String = def.get("category", "")
	var info := "%s (%s)  ×%d" % [def.get("name", item["id"]), cat, item["count"]]
	if cat == "consumable":
		var c: int = int(def.get("cure", 0))
		if c > 0: info += "  ·  +%d HP" % c
		var iv: float = float(def.get("invuln_seconds", 0.0))
		if iv > 0: info += "  ·  %.1fs invuln" % iv
		var sm: float = float(def.get("speed_boost", 1.0))
		if sm != 1.0: info += "  ·  ×%.1f velocidad" % sm
	elif cat == "upgrade":
		var hp_b: int = int(def.get("upgrade_max_hp", 0))
		if hp_b > 0: info += "  ·  +%d max HP perm" % hp_b
		var dmg_b: int = int(def.get("upgrade_damage", 0))
		if dmg_b > 0: info += "  ·  +%d daño perm" % dmg_b
		var sp_b: float = float(def.get("upgrade_speed", 0.0))
		if sp_b > 0: info += "  ·  +%.0f speed perm" % sp_b
	elif cat == "weapon":
		info += "  ·  Click para equipar"
	_info_label.text = info
