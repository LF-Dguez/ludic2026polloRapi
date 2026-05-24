# LevelUpPopup — texto flotante "¡NIVEL UP!" + bonus al centro.

class_name LevelUpPopup
extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_level(new_level: int, bonus_text: String) -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	visible = true
	var vp: Vector2 = get_viewport_rect().size
	var title := Label.new()
	title.text = "¡NIVEL %d!" % new_level
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.55)
	title.size = Vector2(vp.x, 50)
	add_child(title)
	var bonus := Label.new()
	bonus.text = bonus_text
	bonus.add_theme_font_size_override("font_size", 20)
	bonus.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85))
	bonus.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	bonus.add_theme_constant_override("shadow_offset_x", 2)
	bonus.add_theme_constant_override("shadow_offset_y", 2)
	bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus.position = Vector2(0, vp.y * 0.55 + 50)
	bonus.size = Vector2(vp.x, 30)
	add_child(bonus)
	# Tween: pop in + fade out
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.0)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	await tw.finished
	visible = false
	modulate.a = 1.0
