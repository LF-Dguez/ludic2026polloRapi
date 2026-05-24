# FogOverlay — capa atmosférica de niebla que cubre el viewport entero.
# Renderiza por encima del mundo (que es modulado por CanvasModulate)
# pero por debajo del HUD. Cada mode (overworld/dungeon) tiene su tinte y densidad.

class_name FogOverlay
extends CanvasLayer

const NOISE_SIZE := 256

var _rect: TextureRect = null
var _t: float = 0.0
var _base_color: Color = Color(0.55, 0.62, 0.78, 0.30)


func _ready() -> void:
	layer = 2  # arriba del world (0), debajo del HUD (10)
	# Genera textura perlin tileable
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.018
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.1
	var img := Image.create(NOISE_SIZE, NOISE_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(NOISE_SIZE):
		for x in range(NOISE_SIZE):
			var v: float = (noise.get_noise_2d(x, y) + 1.0) * 0.5
			v = clampf(v, 0.0, 1.0)
			# Curva para realzar wisps brillantes (gamma)
			v = pow(v, 0.6)
			img.set_pixel(x, y, Color(1, 1, 1, v))
	var tex := ImageTexture.create_from_image(img)
	# TextureRect que ocupa el viewport completo + tile
	_rect = TextureRect.new()
	_rect.texture = tex
	_rect.stretch_mode = TextureRect.STRETCH_TILE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate = _base_color
	add_child(_rect)
	set_intensity(0)


# mode_int: 0 = overworld, 1 = paquime, 2 = cave, 3 = mine
func set_intensity(mode_int: int) -> void:
	match mode_int:
		0:
			# Niebla nocturna fría azulada
			_base_color = Color(0.50, 0.58, 0.78, 0.28)
		1:
			# Paquimé: polvo desértico cálido
			_base_color = Color(0.55, 0.45, 0.30, 0.42)
		2:
			# Cueva Tarahumara: niebla fría con tinte morado
			_base_color = Color(0.35, 0.40, 0.55, 0.55)
		3:
			# Mina Naica: brumas violáceas de cristal
			_base_color = Color(0.42, 0.40, 0.65, 0.50)
		_:
			_base_color = Color(0.50, 0.55, 0.70, 0.30)
	if _rect != null:
		_rect.modulate = _base_color


func _process(delta: float) -> void:
	_t += delta
	if _rect == null:
		return
	# Pulse alpha + leve drift de posición (efecto respiración)
	var pulse: float = 1.0 + sin(_t * 0.35) * 0.06
	var color: Color = _base_color
	color.a = _base_color.a * pulse
	_rect.modulate = color
	# Drift: mueve el rect ligeramente fuera de bounds para que el tile parezca moverse
	var drift_x: float = sin(_t * 0.08) * 24.0 + _t * 4.0
	var drift_y: float = cos(_t * 0.06) * 16.0 + _t * 2.5
	# Wrap módulo size para tile seamless
	var wx: float = fmod(drift_x, float(NOISE_SIZE))
	var wy: float = fmod(drift_y, float(NOISE_SIZE))
	_rect.offset_left = -wx
	_rect.offset_top = -wy
	_rect.offset_right = get_viewport().get_visible_rect().size.x - wx + NOISE_SIZE
	_rect.offset_bottom = get_viewport().get_visible_rect().size.y - wy + NOISE_SIZE
