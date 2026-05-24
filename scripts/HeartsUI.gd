# HeartsUI — 10 corazones HP en esquina inferior izquierda, animados (5 frames).

class_name HeartsUI
extends Control

const HEART_SIZE := 48  # doble del tamaño anterior
const SPACING := 8
const N_FRAMES := 5
const ANIM_FPS := 6.0  # corazón late ~1.2 veces por segundo (5 frames a 6fps)

var _frame_textures: Array = []  # AtlasTexture[5]
var _hearts: Array[TextureRect] = []
var _hp_states: Array[int] = []  # 0 = empty, 1 = full
var _max_hp: int = 10
var _frame_index: int = 0
var _frame_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := "res://art/tiles/hearts.png"
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		push_warning("HeartsUI: no pude cargar hearts.png")
		return
	var src_tex := ImageTexture.create_from_image(img)
	# Construye AtlasTexture por cada frame (64x64 cada uno)
	for i in range(N_FRAMES):
		var at := AtlasTexture.new()
		at.atlas = src_tex
		at.region = Rect2(i * 64, 0, 64, 64)
		_frame_textures.append(at)
	_build_hearts(_max_hp)
	set_process(true)


func _build_hearts(count: int) -> void:
	for h in _hearts:
		h.queue_free()
	_hearts.clear()
	_hp_states.clear()
	for i in range(count):
		var tr := TextureRect.new()
		tr.texture = _frame_textures[0]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.custom_minimum_size = Vector2(HEART_SIZE, HEART_SIZE)
		tr.size = Vector2(HEART_SIZE, HEART_SIZE)
		tr.position = Vector2(i * (HEART_SIZE + SPACING), 0)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(tr)
		_hearts.append(tr)
		_hp_states.append(1)


func _process(delta: float) -> void:
	_frame_timer += delta
	var dt := 1.0 / ANIM_FPS
	if _frame_timer >= dt:
		_frame_timer -= dt
		_frame_index = (_frame_index + 1) % N_FRAMES
		_update_textures()


func _update_textures() -> void:
	if _frame_textures.is_empty():
		return
	var current_tex: AtlasTexture = _frame_textures[_frame_index]
	# Para "empty" usamos el último frame del atlas como variante "vacía"
	var empty_tex: AtlasTexture = _frame_textures[N_FRAMES - 1]
	for i in range(_hearts.size()):
		if _hp_states[i] == 1:
			_hearts[i].texture = current_tex
			_hearts[i].modulate = Color.WHITE
		else:
			_hearts[i].texture = empty_tex
			_hearts[i].modulate = Color(0.3, 0.3, 0.3, 0.6)  # apagado


func set_hp(current: int, max_hp: int) -> void:
	if _hearts.size() != max_hp:
		_max_hp = max_hp
		_build_hearts(max_hp)
	for i in range(_hearts.size()):
		_hp_states[i] = 1 if i < current else 0
	_update_textures()
