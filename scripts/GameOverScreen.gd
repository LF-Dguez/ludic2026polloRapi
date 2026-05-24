# GameOverScreen — pantalla de muerte roguelike con texto animado.
# 8 frames de gameover.png ciclando + stats de la run + opciones.

class_name GameOverScreen
extends Control

signal respawn_requested
signal new_game_requested

const N_FRAMES := 8
const FRAME_SIZE := 64
const ANIM_FPS := 8.0

var _frames: Array = []
var _frame_index: int = 0
var _frame_timer: float = 0.0
var _gameover_rect: TextureRect = null
var _stats_label: Label = null
var _instructions: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Fondo oscuro semi-transparente
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Carga el atlas y construye frames (8 frames de 64x64)
	var path := "res://art/tiles/gameover.png"
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img != null:
		var src_tex := ImageTexture.create_from_image(img)
		for i in range(N_FRAMES):
			var at := AtlasTexture.new()
			at.atlas = src_tex
			at.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			_frames.append(at)

	# TextureRect para mostrar el frame actual — GRANDE en el centro
	_gameover_rect = TextureRect.new()
	if _frames.size() > 0:
		_gameover_rect.texture = _frames[0]
	_gameover_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gameover_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_gameover_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_gameover_rect.custom_minimum_size = Vector2(512, 256)  # 8x el size original
	_gameover_rect.size = Vector2(512, 256)
	add_child(_gameover_rect)

	# Stats label (debajo)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 18)
	_stats_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_stats_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_stats_label.add_theme_constant_override("shadow_offset_x", 2)
	_stats_label.add_theme_constant_override("shadow_offset_y", 2)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_stats_label)

	# Instrucciones
	_instructions = Label.new()
	_instructions.add_theme_font_size_override("font_size", 16)
	_instructions.add_theme_color_override("font_color", Color(1, 1, 1))
	_instructions.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	_instructions.add_theme_constant_override("shadow_offset_x", 2)
	_instructions.add_theme_constant_override("shadow_offset_y", 2)
	_instructions.text = "[R] Respawn en Mata Ortiz (conserva progreso)\n[N] Nueva partida (borra save)\n[Esc] Salir del juego"
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_instructions)

	_layout_centered()
	visible = false
	set_process(false)


func _layout_centered() -> void:
	var vp: Vector2 = get_viewport_rect().size
	# GameOver text en el centro vertical alto
	_gameover_rect.position = Vector2(
		(vp.x - _gameover_rect.size.x) / 2,
		vp.y * 0.20
	)
	_stats_label.position = Vector2(0, vp.y * 0.55)
	_stats_label.size = Vector2(vp.x, 30)
	_instructions.position = Vector2(0, vp.y * 0.75)
	_instructions.size = Vector2(vp.x, 80)


func show_death(stats: Dictionary) -> void:
	# stats: {kills, runs, cleared, time_alive}
	var txt := "Caíste en Chihuahua\n"
	txt += "Enemigos derrotados: %d   Runs: %d   Mazmorras: %d" % [
		int(stats.get("kills", 0)),
		int(stats.get("runs", 0)),
		int(stats.get("cleared", 0)),
	]
	_stats_label.text = txt
	visible = true
	set_process(true)
	_layout_centered()  # recalcular por si viewport cambió


func hide_screen() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	if _frames.is_empty() or _gameover_rect == null:
		return
	_frame_timer += delta
	var dt := 1.0 / ANIM_FPS
	if _frame_timer >= dt:
		_frame_timer -= dt
		_frame_index = (_frame_index + 1) % N_FRAMES
		_gameover_rect.texture = _frames[_frame_index]


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				respawn_requested.emit()
				hide_screen()
			KEY_N:
				new_game_requested.emit()
				hide_screen()
			KEY_ESCAPE:
				get_tree().quit()
