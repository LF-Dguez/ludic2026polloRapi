# PauseMenu — overlay con opciones Resume/Save/Load/NewGame/Quit.
# Se activa con Esc o P. Pausa el juego via get_tree().paused = true.

class_name PauseMenu
extends Control

signal resume_pressed
signal save_pressed
signal load_pressed
signal new_game_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	# Fondo semi-transparente full screen
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Título
	var title := Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	# Layout centrado vertical
	var vp: Vector2 = get_viewport_rect().size
	title.position = Vector2(0, vp.y * 0.20)
	title.size = Vector2(vp.x, 80)
	# Botones
	var labels := [
		"[Esc/P] Reanudar",
		"[F5] Guardar partida",
		"[F9] Cargar último save",
		"[N] Nueva partida (borra save)",
		"[Q] Salir del juego",
	]
	var y_start := int(vp.y * 0.40)
	for i in range(labels.size()):
		var lbl := Label.new()
		lbl.text = labels[i]
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(0, y_start + i * 42)
		lbl.size = Vector2(vp.x, 38)
		add_child(lbl)


func show_pause() -> void:
	visible = true
	get_tree().paused = true


func hide_pause() -> void:
	visible = false
	get_tree().paused = false


func toggle() -> void:
	if visible:
		hide_pause()
	else:
		show_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var consumed: bool = false
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				hide_pause()
				resume_pressed.emit()
				consumed = true
			KEY_F5:
				save_pressed.emit()
				consumed = true
			KEY_F9:
				load_pressed.emit()
				hide_pause()
				consumed = true
			KEY_N:
				new_game_pressed.emit()
				hide_pause()
				consumed = true
			KEY_Q:
				get_tree().quit()
				consumed = true
		if consumed:
			# Evita que Main.gd reciba el mismo Esc y vuelva a abrir el menú
			get_viewport().set_input_as_handled()
