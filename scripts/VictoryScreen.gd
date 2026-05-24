# VictoryScreen — overlay temporal al matar boss. Lista drops + XP. Auto-fade.

class_name VictoryScreen
extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_victory(boss_name: String, xp_reward: int, drops: Array) -> void:
	# Limpia children previos
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	visible = true
	var vp: Vector2 = get_viewport_rect().size
	# Fondo translúcido top half
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.02, 0.65)
	bg.size = Vector2(vp.x, 240)
	bg.position = Vector2(0, vp.y * 0.18)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Título grande
	var title := Label.new()
	title.text = "¡VICTORIA!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.20)
	title.size = Vector2(vp.x, 80)
	add_child(title)
	# Nombre del boss vencido
	var sub := Label.new()
	sub.text = "Derrotaste a %s" % boss_name
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.95, 0.85, 0.65))
	sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	sub.add_theme_constant_override("shadow_offset_x", 2)
	sub.add_theme_constant_override("shadow_offset_y", 2)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, vp.y * 0.20 + 70)
	sub.size = Vector2(vp.x, 30)
	add_child(sub)
	# XP gain
	var xp_lbl := Label.new()
	xp_lbl.text = "+%d XP" % xp_reward
	xp_lbl.add_theme_font_size_override("font_size", 28)
	xp_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	xp_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	xp_lbl.add_theme_constant_override("shadow_offset_x", 2)
	xp_lbl.add_theme_constant_override("shadow_offset_y", 2)
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.position = Vector2(0, vp.y * 0.20 + 105)
	xp_lbl.size = Vector2(vp.x, 32)
	add_child(xp_lbl)
	# Drops list
	const ItemDB = preload("res://scripts/ItemDB.gd")
	var drops_text: String = "Botín: "
	var pieces: Array = []
	for d in drops:
		var def: Dictionary = ItemDB.get_def(d["id"])
		pieces.append("%s x%d" % [def.get("name", d["id"]), d["count"]])
	drops_text += ", ".join(pieces)
	var drop_lbl := Label.new()
	drop_lbl.text = drops_text
	drop_lbl.add_theme_font_size_override("font_size", 16)
	drop_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85))
	drop_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	drop_lbl.add_theme_constant_override("shadow_offset_x", 1)
	drop_lbl.add_theme_constant_override("shadow_offset_y", 1)
	drop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_lbl.position = Vector2(40, vp.y * 0.20 + 145)
	drop_lbl.size = Vector2(vp.x - 80, 60)
	drop_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(drop_lbl)
	# Auto-fade after 4 seconds
	await get_tree().create_timer(4.0).timeout
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	await tw.finished
	visible = false
	modulate.a = 1.0
