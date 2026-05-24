# Boss — enemigo único por mazmorra con HP grande, fases, ataques especiales,
# y drop garantizado de reliquia. Emite signals para HP bar y victoria.

class_name Boss
extends CharacterBody2D

const ItemDBScript = preload("res://scripts/ItemDB.gd")

signal hp_changed(current: int, max_hp: int, boss_name: String)
signal boss_died(boss_id: String, pos: Vector2, drops: Array)

# ─── Boss configs por mazmorra ──────────────────────────────────────────
const BOSSES := {
	"senor_paquime": {
		"name": "Señor de Casas Grandes",
		"max_hp": 80,
		"speed_chase": 50.0,
		"contact_damage": 2,
		"attack_cooldown": 1.4,
		"sprite_radius": 24,
		"sprite_color": Color(0.65, 0.45, 0.20),
		"accent_color": Color(0.85, 0.20, 0.20),
		"behavior": "priest",  # ranged orbs + summons
		"phase2_threshold": 0.55,
		"phase3_threshold": 0.25,
		"drops_guaranteed": [
			{"id": "corona_paquime", "count": 1},
			{"id": "codice_paquime", "count": 1},
			{"id": "pesos_plata", "count": 60},
			{"id": "ceramica_mata_ortiz", "count": 4},
		],
		"xp_reward": 80,
	},
	"bestia_cobre": {
		"name": "Bestia del Cobre",
		"max_hp": 120,
		"speed_chase": 110.0,
		"contact_damage": 3,
		"attack_cooldown": 1.0,
		"sprite_radius": 26,
		"sprite_color": Color(0.55, 0.25, 0.10),
		"accent_color": Color(0.95, 0.55, 0.10),
		"behavior": "charger",  # dashes + melee
		"phase2_threshold": 0.55,
		"phase3_threshold": 0.25,
		"drops_guaranteed": [
			{"id": "colmillo_bestia", "count": 1},
			{"id": "mapa_raramuri", "count": 1},
			{"id": "corazon_sagrado", "count": 2},
			{"id": "vetas_cobre", "count": 10},
			{"id": "pesos_plata", "count": 45},
		],
		"xp_reward": 100,
	},
	"espectro_cristal": {
		"name": "Espectro del Cristal",
		"max_hp": 70,
		"speed_chase": 80.0,
		"contact_damage": 2,
		"attack_cooldown": 0.9,
		"sprite_radius": 24,
		"sprite_color": Color(0.65, 0.45, 0.85),
		"accent_color": Color(0.55, 0.85, 1.00),
		"behavior": "phaser",  # teleports + crystal shards
		"phase2_threshold": 0.55,
		"phase3_threshold": 0.25,
		"drops_guaranteed": [
			{"id": "esquirla_espectro", "count": 1},
			{"id": "cristal_naica", "count": 1},
			{"id": "calavera_villa", "count": 1},
			{"id": "pesos_plata", "count": 70},
		],
		"xp_reward": 90,
	},
}

var boss_id: String = ""
var cfg: Dictionary = {}
var max_hp: int = 100
var hp: int = 100
var current_phase: int = 1
var _player: Node2D = null
var _attack_cd: float = 0.0
var _telegraph_t: float = 0.0
var _dash_t: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _dash_target: Vector2 = Vector2.ZERO
var _is_dashing: bool = false
var _last_teleport_t: float = 0.0
var _summon_cd: float = 8.0
var _hit_flash_t: float = 0.0
var tile_layer: TileMapLayer = null
var mode: int = 1
const HALF_HITBOX := 18
const TILE_PX := 32
@onready var _sprite: Node2D = null


func setup(id: String, layer: TileMapLayer, mode_int: int) -> void:
	boss_id = id
	cfg = BOSSES.get(id, BOSSES["senor_paquime"])
	max_hp = int(cfg["max_hp"])
	hp = max_hp
	tile_layer = layer
	mode = mode_int


func _ready() -> void:
	add_to_group("enemigo")
	add_to_group("boss")
	# Crear sprite procedural (círculo grande con accent)
	_build_sprite()
	_player = get_tree().get_first_node_in_group("player")
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = float(cfg.get("sprite_radius", 24))
	col.shape = shape
	col.name = "CollisionShape2D"
	add_child(col)
	# Notify spawn (UI engancha)
	hp_changed.emit(hp, max_hp, cfg.get("name", "Boss"))


func _build_sprite() -> void:
	# Boss sprite procedural: círculo + halo + ojos
	var radius: int = int(cfg.get("sprite_radius", 24))
	var size: int = radius * 2 + 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: int = size / 2
	var cy: int = size / 2
	var body: Color = cfg.get("sprite_color", Color(0.5, 0.3, 0.15))
	var accent: Color = cfg.get("accent_color", Color(0.95, 0.20, 0.20))
	# Cuerpo
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var d: int = dx * dx + dy * dy
			if d <= radius * radius:
				var px: int = cx + dx
				var py: int = cy + dy
				img.set_pixel(px, py, body)
	# Ring accent
	for a in range(0, 360, 4):
		var rr: float = deg_to_rad(a)
		var px: int = cx + int(cos(rr) * radius)
		var py: int = cy + int(sin(rr) * radius)
		if px >= 0 and px < size and py >= 0 and py < size:
			img.set_pixel(px, py, accent)
	# Ojos
	for s in [-radius / 3, radius / 3]:
		var ex: int = cx + s
		var ey: int = cy - radius / 4
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if dx * dx + dy * dy <= 4:
					var px: int = ex + dx
					var py: int = ey + dy
					if px >= 0 and px < size and py >= 0 and py < size:
						img.set_pixel(px, py, Color(0.95, 0.95, 0.30))
	var tex := ImageTexture.create_from_image(img)
	var spr := Sprite2D.new()
	spr.name = "Sprite"
	spr.texture = tex
	spr.centered = true
	spr.scale = Vector2(1.4, 1.4)
	add_child(spr)
	_sprite = spr


func take_damage(amount: int) -> void:
	hp -= amount
	if hp < 0:
		hp = 0
	hp_changed.emit(hp, max_hp, cfg.get("name", "Boss"))
	# Floating damage number
	var dn_script = load("res://scripts/DamageNumber.gd")
	var dn = dn_script.new()
	get_parent().add_child(dn)
	dn.setup(amount, global_position, amount >= 6)
	_hit_flash_t = 0.18
	if _sprite != null:
		_sprite.modulate = Color(2.5, 0.4, 0.4, 1.0)
	# Phase transitions
	var ratio: float = float(hp) / float(max_hp)
	var new_phase: int = 1
	if ratio <= float(cfg.get("phase3_threshold", 0.25)):
		new_phase = 3
	elif ratio <= float(cfg.get("phase2_threshold", 0.55)):
		new_phase = 2
	if new_phase != current_phase:
		current_phase = new_phase
		_on_phase_changed(new_phase)
	if hp <= 0:
		_die()


func _on_phase_changed(p: int) -> void:
	# Flash + telegraph en transición
	_telegraph_t = 0.4
	if _sprite != null:
		_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)


func _die() -> void:
	# Drop loot garantizado + XP reward + signal
	var drops: Array = cfg.get("drops_guaranteed", []).duplicate()
	boss_died.emit(boss_id, global_position, drops)
	# Spawn ItemDrops visibles
	var drop_script = load("res://scripts/ItemDrop.gd")
	for d in drops:
		var drop = drop_script.new()
		get_parent().add_child(drop)
		drop.setup(d["id"], d["count"])
		drop.global_position = global_position + Vector2(
			randf_range(-32, 32), randf_range(-32, 32)
		)
	queue_free()


func _physics_process(delta: float) -> void:
	if _attack_cd > 0.0:
		_attack_cd -= delta
	if _telegraph_t > 0.0:
		_telegraph_t -= delta
	if _summon_cd > 0.0:
		_summon_cd -= delta
	if _hit_flash_t > 0.0:
		_hit_flash_t -= delta
		if _hit_flash_t <= 0.0 and _sprite != null:
			_sprite.modulate = Color.WHITE

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return

	var behavior: String = cfg.get("behavior", "priest")
	match behavior:
		"priest": _ai_priest(delta)
		"charger": _ai_charger(delta)
		"phaser": _ai_phaser(delta)
	# Limita por colisión con tiles
	if velocity != Vector2.ZERO and tile_layer != null:
		var step := velocity * delta
		if not _can_move_to(global_position + Vector2(step.x, 0)):
			velocity.x = 0.0
		if not _can_move_to(global_position + Vector2(0, step.y)):
			velocity.y = 0.0
	move_and_slide()


# ─── BEHAVIOR: priest (Paquimé) ──────────────────────────────────────────
func _ai_priest(delta: float) -> void:
	var to_p: Vector2 = _player.global_position - global_position
	var dist: float = to_p.length()
	var speed: float = float(cfg["speed_chase"])
	# Movimiento: si lejos, acércate; si muy cerca, retrocede
	if dist > 220.0:
		velocity = to_p.normalized() * speed
	elif dist < 80.0:
		velocity = -to_p.normalized() * speed * 0.7
	else:
		velocity = Vector2.ZERO
	# Ataques
	if _attack_cd <= 0.0:
		var rate: float = float(cfg["attack_cooldown"])
		match current_phase:
			1:
				_shoot_fire_orb(to_p.normalized())
				_attack_cd = rate
			2:
				# Spread 3 orbs
				var base_angle: float = to_p.angle()
				for da in [-0.3, 0.0, 0.3]:
					_shoot_fire_orb(Vector2.RIGHT.rotated(base_angle + da))
				_attack_cd = rate * 1.2
			3:
				_shoot_fire_orb(to_p.normalized())
				_attack_cd = rate * 0.6
				if _summon_cd <= 0.0:
					_summon_minion("bandido")
					_summon_cd = 12.0


# ─── BEHAVIOR: charger (Bestia) ──────────────────────────────────────────
func _ai_charger(delta: float) -> void:
	var to_p: Vector2 = _player.global_position - global_position
	var dist: float = to_p.length()
	var speed: float = float(cfg["speed_chase"])
	if current_phase >= 2:
		speed *= 1.3
	# Dash mechanic
	if _is_dashing:
		_dash_t -= delta
		velocity = _dash_dir * speed * 2.8
		if _dash_t <= 0.0 or global_position.distance_to(_dash_target) < 24.0:
			_is_dashing = false
			velocity = Vector2.ZERO
		# Daño contacto durante dash
		if dist < 50.0 and _player.has_method("take_damage"):
			_player.take_damage(int(cfg["contact_damage"]))
			_attack_cd = float(cfg["attack_cooldown"])
		return
	# Persecución normal
	if dist > 50.0:
		velocity = to_p.normalized() * speed
	else:
		velocity = Vector2.ZERO
		if _attack_cd <= 0.0:
			if _player.has_method("take_damage"):
				_player.take_damage(int(cfg["contact_damage"]))
			_attack_cd = float(cfg["attack_cooldown"])
	# Dash si lejos
	if dist > 180.0 and _attack_cd <= 0.0 and not _is_dashing:
		_is_dashing = true
		_dash_dir = to_p.normalized()
		_dash_target = _player.global_position
		_dash_t = 1.0
		_attack_cd = float(cfg["attack_cooldown"]) * 1.5
		# Telegraph visual
		_telegraph_t = 0.3
		if _sprite != null:
			_sprite.modulate = Color(2.0, 1.5, 0.5, 1.0)
	# Summon fantasma en fase 3
	if current_phase == 3 and _summon_cd <= 0.0:
		_summon_minion("fantasma")
		_summon_cd = 15.0


# ─── BEHAVIOR: phaser (Espectro) ─────────────────────────────────────────
func _ai_phaser(delta: float) -> void:
	var to_p: Vector2 = _player.global_position - global_position
	var dist: float = to_p.length()
	var speed: float = float(cfg["speed_chase"])
	# Movimiento: orbital alrededor del player
	if dist > 180.0:
		velocity = to_p.normalized() * speed
	elif dist < 100.0:
		var perp := Vector2(-to_p.y, to_p.x).normalized()
		velocity = perp * speed
	else:
		velocity = Vector2.ZERO
	# Teleport: cada 4-5s en fase 2+
	_last_teleport_t += delta
	var teleport_interval: float = 5.5 if current_phase == 1 else 3.5
	if _last_teleport_t > teleport_interval:
		_teleport_near_player()
		_last_teleport_t = 0.0
	# Ataques
	if _attack_cd <= 0.0:
		var rate: float = float(cfg["attack_cooldown"])
		match current_phase:
			1:
				_shoot_crystal_shard(to_p.normalized())
				_attack_cd = rate
			2:
				# 5 shards en spread
				var base_angle: float = to_p.angle()
				for da in [-0.5, -0.25, 0.0, 0.25, 0.5]:
					_shoot_crystal_shard(Vector2.RIGHT.rotated(base_angle + da))
				_attack_cd = rate * 1.4
			3:
				# Ráfaga circular
				for i in range(8):
					var a: float = i * TAU / 8.0
					_shoot_crystal_shard(Vector2(cos(a), sin(a)))
				_attack_cd = rate * 2.0
				if _summon_cd <= 0.0:
					for _i in range(2):
						_summon_minion("fantasma")
					_summon_cd = 14.0


# ─── HELPERS ──────────────────────────────────────────────────────────

func _shoot_fire_orb(dir: Vector2) -> void:
	_spawn_projectile(dir, Color(1.0, 0.55, 0.10), 200.0, 3, 18)


func _shoot_crystal_shard(dir: Vector2) -> void:
	_spawn_projectile(dir, Color(0.65, 0.85, 1.0), 280.0, 2, 14)


func _spawn_projectile(dir: Vector2, color: Color, speed: float, dmg: int, radius: int) -> void:
	var proj_script = load("res://scripts/BossProjectile.gd")
	var p: Area2D = Area2D.new()
	p.set_script(proj_script)
	p.set("damage", dmg)
	p.set("speed", speed)
	p.set("travel_dir", dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT)
	p.set("color", color)
	p.set("radius", radius)
	get_parent().add_child(p)
	p.global_position = global_position


func _teleport_near_player() -> void:
	if _player == null:
		return
	var angle: float = randf() * TAU
	var dist: float = randf_range(120.0, 200.0)
	var new_pos: Vector2 = _player.global_position + Vector2(cos(angle), sin(angle)) * dist
	# VFX antes (flash + fade)
	if _sprite != null:
		_sprite.modulate = Color(2.0, 2.0, 3.0, 0.3)
	global_position = new_pos
	if _sprite != null:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate", Color.WHITE, 0.25)


func _summon_minion(kind: String) -> void:
	# Carga EnemySpawner y spawna 1 minion en posición del boss + offset
	var spawner_script = load("res://scripts/EnemySpawner.gd")
	# Necesitamos los SpriteFrames pre-cargados — buscamos en Main
	var main_node: Node = get_tree().current_scene
	if main_node == null:
		return
	if not "_bandido_frames" in main_node:
		return
	var off: Vector2 = Vector2(randf_range(-60, 60), randf_range(-60, 60))
	if kind == "bandido" and main_node._bandido_frames != null:
		spawner_script.spawn_bandido(get_parent(), global_position + off, main_node._bandido_frames, tile_layer, mode)
	elif kind == "fantasma" and main_node._fantasma_frames != null:
		spawner_script.spawn_fantasma(get_parent(), global_position + off, main_node._fantasma_frames, tile_layer, mode)


func rate_safe(v) -> float:
	return float(v) if v != null else 1.0


# ─── COLISIÓN ──────────────────────────────────────────────────────────
func _can_move_to(pos: Vector2) -> bool:
	if tile_layer == null:
		return true
	var hh := float(HALF_HITBOX)
	for c in [
		Vector2(pos.x - hh, pos.y - hh),
		Vector2(pos.x + hh, pos.y - hh),
		Vector2(pos.x - hh, pos.y + hh),
		Vector2(pos.x + hh, pos.y + hh),
	]:
		var tx := int(floor(c.x / float(TILE_PX)))
		var ty := int(floor(c.y / float(TILE_PX)))
		if tx < 0 or ty < 0:
			return false
		var cell := Vector2i(tx, ty)
		var src_id := tile_layer.get_cell_source_id(cell)
		var atlas: Vector2i = tile_layer.get_cell_atlas_coords(cell)
		if mode == 1:
			if src_id == -1:
				return false
			if src_id == 0:
				if atlas.x == 2 and atlas.y == 0: return false
				if atlas.x == 3 and atlas.y == 1: return false
				if atlas.x == 0 and atlas.y == 0: return false
		elif mode == 2 or mode == 3:
			if src_id == -1:
				return false
			if src_id == 0:
				return false
	return true
