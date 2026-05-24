# BossChest — cofre especial que aparece al matar al boss.
# Player interactúa con Space para abrir. Spawnea recompensas únicas
# por boss (más raras que el loot base del boss).

class_name BossChest
extends Area2D

const ItemDBScript = preload("res://scripts/ItemDB.gd")

const INTERACT_RADIUS := 60.0

signal opened(boss_id: String, rewards: Array)

# Recompensas únicas por boss — diferentes a los drops garantizados
const REWARDS_BY_BOSS := {
	"senor_paquime": [
		{"id": "pesos_plata", "count": 120},
		{"id": "peyote", "count": 2},
		{"id": "corazon_sagrado", "count": 2},
		{"id": "mezcal", "count": 3},
		{"id": "ceramica_mata_ortiz", "count": 5},
		{"id": "filo_obsidiana", "count": 1},
		{"id": "sombrero_revolucion", "count": 1},
	],
	"bestia_cobre": [
		{"id": "pesos_plata", "count": 100},
		{"id": "herradura", "count": 2},
		{"id": "rifle_serrano", "count": 1},
		{"id": "agua_bendita", "count": 3},
		{"id": "vetas_cobre", "count": 15},
		{"id": "carne_seca", "count": 6},
		{"id": "filo_obsidiana", "count": 1},
	],
	"espectro_cristal": [
		{"id": "pesos_plata", "count": 150},
		{"id": "pistola_villa", "count": 1},
		{"id": "rosario", "count": 3},
		{"id": "agua_bendita", "count": 4},
		{"id": "piedra_mineral", "count": 12},
		{"id": "corazon_sagrado", "count": 2},
		{"id": "polvora", "count": 8},
	],
}

var boss_id: String = ""
var rewards: Array = []
var _is_opened: bool = false
var _sprite: Sprite2D = null
var _light: PointLight2D = null
var _player: Node2D = null
var _pulse_t: float = 0.0


func setup(b_id: String) -> void:
	boss_id = b_id
	rewards = REWARDS_BY_BOSS.get(b_id, REWARDS_BY_BOSS["senor_paquime"]).duplicate()


func _ready() -> void:
	add_to_group("boss_chest")
	z_index = 7
	# Intenta cargar art/tiles/cofre.png — fallback a sprite procedural
	_sprite = _try_load_cofre_sprite()
	if _sprite == null:
		_sprite = _build_chest_sprite()
	add_child(_sprite)
	# Luz dorada parpadeante (para hacerlo bien visible en la penumbra)
	_light = PointLight2D.new()
	var lt_img := Image.load_from_file(ProjectSettings.globalize_path("res://art/tiles/light_texture.png"))
	if lt_img != null:
		_light.texture = ImageTexture.create_from_image(lt_img)
	_light.color = Color(1.0, 0.85, 0.30)
	_light.energy = 1.4
	_light.texture_scale = 1.2
	add_child(_light)
	# Hit area para detección de player
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = INTERACT_RADIUS
	col.shape = shape
	add_child(col)
	_player = get_tree().get_first_node_in_group("player")


func _try_load_cofre_sprite() -> Sprite2D:
	var path := "res://art/tiles/cofre.png"
	var abs_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(abs_path)
	if img == null:
		return null
	var tex := ImageTexture.create_from_image(img)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	# Auto-scale: si el sprite es < 64px, scale 2 para display ~128px
	var w: int = tex.get_width()
	var target: float = 96.0
	var scale_factor: float = target / float(maxi(w, 1))
	spr.scale = Vector2(scale_factor, scale_factor)
	return spr


func _build_chest_sprite() -> Sprite2D:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Sombra debajo del cofre
	for dy in range(2, 6):
		for dx in range(-22, 23):
			var px: int = 24 + dx
			var py: int = 40 + dy
			if px >= 0 and px < size and py >= 0 and py < size:
				var falloff: float = 1.0 - (abs(dx) / 22.0)
				img.set_pixel(px, py, Color(0, 0, 0, 0.4 * falloff))
	# Cuerpo del cofre (caja madera)
	for y in range(20, 42):
		for x in range(8, 41):
			var c := Color(0.45, 0.30, 0.15)
			# Veteado madera horizontal sutil
			if y % 3 == 0:
				c = Color(0.55, 0.36, 0.20)
			img.set_pixel(x, y, c)
	# Tapa del cofre (curvada arriba)
	for y in range(8, 22):
		for x in range(8, 41):
			# Forma de domo - skip esquinas
			var dy_top: int = absi(y - 14)
			var dx_mid: int = absi(x - 24)
			if y < 14 and dx_mid > 16 - (14 - y) * 1.2:
				continue
			img.set_pixel(x, y, Color(0.55, 0.38, 0.20))
	# Bandas doradas horizontales
	for x in range(7, 42):
		img.set_pixel(x, 11, Color(0.95, 0.75, 0.25))
		img.set_pixel(x, 12, Color(0.75, 0.55, 0.15))
		img.set_pixel(x, 25, Color(0.95, 0.75, 0.25))
		img.set_pixel(x, 26, Color(0.75, 0.55, 0.15))
		img.set_pixel(x, 36, Color(0.95, 0.75, 0.25))
		img.set_pixel(x, 37, Color(0.75, 0.55, 0.15))
	# Bandas verticales (esquinas)
	for y in range(20, 41):
		img.set_pixel(8, y, Color(0.85, 0.65, 0.20))
		img.set_pixel(9, y, Color(0.65, 0.45, 0.10))
		img.set_pixel(40, y, Color(0.85, 0.65, 0.20))
		img.set_pixel(39, y, Color(0.65, 0.45, 0.10))
	# Candado dorado central
	for y in range(28, 35):
		for x in range(21, 28):
			img.set_pixel(x, y, Color(0.95, 0.78, 0.25))
	# Hoyo del candado
	img.set_pixel(24, 31, Color(0.10, 0.05, 0.02))
	img.set_pixel(24, 32, Color(0.10, 0.05, 0.02))
	img.set_pixel(23, 31, Color(0.10, 0.05, 0.02))
	img.set_pixel(25, 31, Color(0.10, 0.05, 0.02))
	# Outline negro
	for x in range(8, 41):
		img.set_pixel(x, 7, Color(0.10, 0.05, 0.02))
		img.set_pixel(x, 42, Color(0.10, 0.05, 0.02))
	for y in range(7, 43):
		img.set_pixel(7, y, Color(0.10, 0.05, 0.02))
		img.set_pixel(41, y, Color(0.10, 0.05, 0.02))
	var tex := ImageTexture.create_from_image(img)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2(2.0, 2.0)  # display 96x96
	return spr


func _process(delta: float) -> void:
	if _is_opened:
		return
	_pulse_t += delta
	# Pulse de luz + leve bob del sprite
	if _light != null:
		_light.energy = 1.2 + sin(_pulse_t * 2.5) * 0.5
	if _sprite != null:
		_sprite.position.y = sin(_pulse_t * 2.0) * 3.0
		var scale_pulse: float = 2.0 + sin(_pulse_t * 1.8) * 0.08
		_sprite.scale = Vector2(scale_pulse, scale_pulse)
	# Detectar player cercano + Space
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	if global_position.distance_to(_player.global_position) < INTERACT_RADIUS:
		if Input.is_action_just_pressed("atacar"):  # Space
			_open()


func is_player_in_range() -> bool:
	if _is_opened:
		return false
	if _player == null or not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) < INTERACT_RADIUS


func _open() -> void:
	if _is_opened:
		return
	_is_opened = true
	opened.emit(boss_id, rewards)
	# Spawn items en anillo alrededor del cofre
	var drop_script = load("res://scripts/ItemDrop.gd")
	var n: int = rewards.size()
	for i in range(n):
		var r = rewards[i]
		var angle: float = i * TAU / float(n)
		var radius: float = 60.0
		var drop = drop_script.new()
		get_parent().add_child(drop)
		drop.setup(r["id"], r["count"])
		drop.global_position = global_position + Vector2(cos(angle), sin(angle)) * radius
	# VFX: flash dorado + fade del cofre + apaga luz
	if _light != null:
		_light.energy = 4.0
		var tw_l := create_tween()
		tw_l.tween_property(_light, "energy", 0.0, 1.0)
	if _sprite != null:
		_sprite.modulate = Color(2.0, 1.7, 1.0, 1.0)
		var tw_s := create_tween()
		tw_s.tween_property(_sprite, "modulate", Color(1, 1, 1, 0), 1.5)
	# Screen shake al abrir
	var main = get_tree().current_scene
	if main != null and main.has_method("camera_shake"):
		main.camera_shake(4.0, 0.3)
	# Cleanup
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(self):
		queue_free()
