# TitleScreen — pantalla de título inicial. Muestra "SIRUAMI" + opciones.
# Bloquea el flujo de Main._ready hasta que el jugador presione una tecla.

class_name TitleScreen
extends CanvasLayer

signal start_pressed
signal load_pressed
signal quit_pressed

var _title_lbl: Label = null
var _subtitle_lbl: Label = null
var _t: float = 0.0
var _input_consumed: bool = false


func _ready() -> void:
	layer = 100  # arriba de TODO (HUD incluido)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var vp: Vector2 = get_viewport().get_visible_rect().size
	# Fondo oscuro casi negro con tinte
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	# Vignette gradient sutil (sprite con noise)
	var vignette := ColorRect.new()
	vignette.color = Color(0.15, 0.10, 0.05, 0.4)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	# Niebla de fondo (reutiliza patrón de FogOverlay)
	_build_noise_layer(vp)
	# Título grande
	_title_lbl = Label.new()
	_title_lbl.text = "SIRUAMI"
	_title_lbl.add_theme_font_size_override("font_size", 140)
	_title_lbl.add_theme_color_override("font_color", Color(0.92, 0.78, 0.40))
	_title_lbl.add_theme_color_override("font_shadow_color", Color(0.20, 0.05, 0.02))
	_title_lbl.add_theme_constant_override("shadow_offset_x", 6)
	_title_lbl.add_theme_constant_override("shadow_offset_y", 6)
	_title_lbl.add_theme_constant_override("shadow_outline_size", 8)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.position = Vector2(0, vp.y * 0.22)
	_title_lbl.size = Vector2(vp.x, 160)
	add_child(_title_lbl)
	# Subtítulo
	_subtitle_lbl = Label.new()
	_subtitle_lbl.text = "— UN VIAJE POR LAS TIERRAS DEL NORTE —"
	_subtitle_lbl.add_theme_font_size_override("font_size", 20)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	_subtitle_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_subtitle_lbl.add_theme_constant_override("shadow_offset_x", 2)
	_subtitle_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.position = Vector2(0, vp.y * 0.22 + 165)
	_subtitle_lbl.size = Vector2(vp.x, 30)
	add_child(_subtitle_lbl)
	# Opciones
	var has_save: bool = FileAccess.file_exists("user://save.cfg")
	var options := [
		"[ESPACIO]  COMENZAR",
	]
	if has_save:
		options.append("[C]  CONTINUAR PARTIDA GUARDADA")
	options.append("[ESC]  SALIR")
	var y_start: float = vp.y * 0.58
	for i in range(options.size()):
		var lbl := Label.new()
		lbl.text = options[i]
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		lbl.add_theme_constant_override("shadow_offset_x", 2)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(0, y_start + i * 44)
		lbl.size = Vector2(vp.x, 32)
		add_child(lbl)
	# Footer
	var footer := Label.new()
	footer.text = "inspirado en Chihuahua  ·  Paquimé · Sierra Tarahumara · Naica"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.position = Vector2(0, vp.y - 28)
	footer.size = Vector2(vp.x, 20)
	add_child(footer)


func _build_noise_layer(vp: Vector2) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in range(size):
		for x in range(size):
			var v: float = (noise.get_noise_2d(x, y) + 1.0) * 0.5
			v = pow(v, 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, v))
	var tex := ImageTexture.create_from_image(img)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = Color(0.45, 0.38, 0.28, 0.22)
	add_child(rect)


func _process(delta: float) -> void:
	_t += delta
	# Pulse sutil del título
	if _title_lbl != null:
		var pulse: float = 1.0 + sin(_t * 1.5) * 0.04
		_title_lbl.scale = Vector2(pulse, pulse)
		_title_lbl.pivot_offset = _title_lbl.size * 0.5
	# Input polling — funciona aunque otro nodo consuma el evento.
	# Input.is_*_pressed lee del estado global, independiente del routing.
	if _input_consumed:
		return
	if Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_ENTER) or Input.is_physical_key_pressed(KEY_KP_ENTER):
		_input_consumed = true
		print("[TitleScreen] start_pressed via polling")
		start_pressed.emit()
		return
	if Input.is_physical_key_pressed(KEY_C):
		if FileAccess.file_exists("user://save.cfg"):
			_input_consumed = true
			print("[TitleScreen] load_pressed via polling")
			load_pressed.emit()
			return
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		_input_consumed = true
		print("[TitleScreen] quit_pressed via polling")
		quit_pressed.emit()
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_input_consumed = true
		print("[TitleScreen] start via mouse click")
		start_pressed.emit()
		return


func dismiss() -> void:
	queue_free()
