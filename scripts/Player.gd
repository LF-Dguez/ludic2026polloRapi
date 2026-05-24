# Player.gd — Jugador top-down con HP, ataques mouse, colisión por modo.

class_name Player
extends CharacterBody2D

const InventoryScript = preload("res://scripts/Inventory.gd")
const ItemDBScript = preload("res://scripts/ItemDB.gd")

# ── Constantes ───────────────────────────────────────────────────────────────
const SPEED       := 240.0
const TILE_PX     := 32
const HALF_HITBOX := 6

# HP system
const MAX_HP := 10
const INVULN_TIME := 0.6  # segundos de invulnerabilidad post-hit

const ANIM_ABAJO     := "abajo"
const ANIM_ARRIBA    := "arriba"
const ANIM_IZQUIERDA := "izquierda"
const ANIM_DERECHA   := "derecha"

var _sfx_hit: AudioStreamPlayer = null

signal hp_changed(new_hp: int, max_hp: int)
signal player_died
signal weapon_changed(weapon_id: String)
signal enemy_killed(enemy_type: String, xp_value: int)

# Armas — cada una con sus stats
const WEAPONS := {
	"machete": {
		"name": "Machete",
		"damage_melee": 3, "damage_throw": 2,
		"throw_speed": 400.0, "fire_rate": 0.35,
		"melee_radius": 60.0,
	},
	"cuchillo": {
		"name": "Cuchillo",
		"damage_melee": 2, "damage_throw": 1,
		"throw_speed": 550.0, "fire_rate": 0.15,
		"melee_radius": 45.0,
	},
	"pistola_villa": {
		"name": "Pistola de Villa",
		"damage_melee": 1, "damage_throw": 4,
		"throw_speed": 750.0, "fire_rate": 0.25,
		"melee_radius": 35.0,
	},
	"rifle_serrano": {
		"name": "Rifle serrano",
		"damage_melee": 2, "damage_throw": 7,
		"throw_speed": 900.0, "fire_rate": 0.9,
		"melee_radius": 50.0,
	},
}

var current_weapon: String = "machete"
var max_hp_bonus: int = 0  # +max_hp por corazones sagrados
var damage_bonus: int = 0   # +damage por filos
var speed_bonus: float = 0.0  # +speed por botines
var crit_chance: float = 0.10  # 10% base
var _attack_cooldown: float = 0.0
var _speed_boost_timer: float = 0.0
var _speed_boost_mult: float = 1.0
var _hotbar_keys_held: Array[bool] = [false, false, false, false]
var _q_held: bool = false
var _e_held: bool = false

# Dodge roll (Shift) — invuln + speed burst
const DODGE_DURATION := 0.35
const DODGE_SPEED_MULT := 2.6
const DODGE_COOLDOWN := 1.0
var _dodge_timer: float = 0.0
var _dodge_cd: float = 0.0
var _dodge_dir: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var machete_scene: PackedScene

var _current_anim : String  = ANIM_ABAJO
var _was_moving   : bool    = false
var _ultima_dir   : Vector2 = Vector2.DOWN

var current_hp: int = MAX_HP
var _invuln_timer: float = 0.0
# Inventario
var inventory = null  # InventoryScript instance

# Referencias a capas
var overworld_layer      : TileMapLayer
var overworld_decor_layer: TileMapLayer
var dungeon_layer        : TileMapLayer
var cave_layer           : TileMapLayer
var mines_layer          : TileMapLayer
var mode: int = 0

var passable_decor    : Dictionary = {}
var tree_blocked_tiles: Dictionary = {}


# ═════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("player")
	inventory = InventoryScript.new()
	# Items iniciales
	inventory.add("tortilla", 3)
	inventory.add("machete", 1)
	if sprite == null:
		push_error("Player: no se encontró AnimatedSprite2D hijo.")
		return
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(HALF_HITBOX * 2, HALF_HITBOX * 2)
		col.shape = shape
		col.name = "CollisionShape2D"
		add_child(col)
	sprite.animation = _current_anim
	sprite.frame = 0
	current_hp = MAX_HP
	hp_changed.emit(current_hp, MAX_HP)
	
	# SFX de golpe
	_sfx_hit = AudioStreamPlayer.new()
	_sfx_hit.stream = load("res://audio/music/hitsound.mp3")
	_sfx_hit.volume_db = 0.0
	add_child(_sfx_hit)


# ═════════════════════════════════════════════════════════════════════════
# HP SYSTEM
# ═════════════════════════════════════════════════════════════════════════

func take_damage(amount: int) -> void:
	if _invuln_timer > 0.0:
		return
	if _dodge_timer > 0.0:
		return  # dodge inmune
	current_hp -= amount
	# Screen shake on hit
	var main = get_tree().current_scene
	if main != null and main.has_method("camera_shake"):
		main.camera_shake(6.0, 0.25)
	if current_hp < 0:
		current_hp = 0
	hp_changed.emit(current_hp, get_max_hp())
	_invuln_timer = INVULN_TIME
	# Damage number rojo sobre el player
	_spawn_damage_number(amount, true)
	if sprite != null:
		sprite.modulate = Color(1.5, 0.4, 0.4, 1.0)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, INVULN_TIME)
	if current_hp == 0:
		player_died.emit()


func _spawn_damage_number(amount: int, is_player_hit: bool) -> void:
	var dn_script = load("res://scripts/DamageNumber.gd")
	var dn = dn_script.new()
	get_parent().add_child(dn)
	if is_player_hit:
		dn.setup(amount, global_position, true)  # crit color para player hit
	else:
		dn.setup(amount, global_position, false)


func get_max_hp() -> int:
	return MAX_HP + max_hp_bonus


func heal(amount: int) -> void:
	var before := current_hp
	current_hp = mini(current_hp + amount, get_max_hp())
	hp_changed.emit(current_hp, get_max_hp())
	# Damage number verde +N
	var actual := current_hp - before
	if actual > 0:
		var dn_script = load("res://scripts/DamageNumber.gd")
		var dn = dn_script.new()
		get_parent().add_child(dn)
		dn.heal(actual, global_position)


func reset_hp() -> void:
	current_hp = get_max_hp()
	_invuln_timer = 0.0
	if sprite != null:
		sprite.modulate = Color.WHITE
	hp_changed.emit(current_hp, get_max_hp())


# ─── ITEMS / INVENTARIO ──────────────────────────────────────────────
func use_inventory_slot(slot: int) -> void:
	if inventory == null:
		return
	# Solo "use" si el item es consumible o upgrade — armas se equipan distinto
	if slot < 0 or slot >= inventory.items.size():
		return
	var entry = inventory.items[slot]
	if entry == null:
		return
	var def: Dictionary = ItemDBScript.get_def(entry["id"])
	var cat: String = def.get("category", "")
	match cat:
		"consumable":
			_apply_consumable(entry["id"], def)
			inventory.use_slot(slot)
		"upgrade":
			_apply_upgrade(entry["id"], def)
			inventory.use_slot(slot)
		"weapon":
			_equip_weapon(def.get("weapon_id", "machete"))
		_:
			# key/currency/resource/relic — no usable directo
			pass


func _apply_consumable(id: String, def: Dictionary) -> void:
	var cure: int = int(def.get("cure", 0))
	if cure > 0:
		heal(cure)
	var invuln: float = float(def.get("invuln_seconds", 0.0))
	if invuln > 0.0:
		_invuln_timer = max(_invuln_timer, invuln)
	var speed_mult: float = float(def.get("speed_boost", 1.0))
	var speed_secs: float = float(def.get("speed_seconds", 0.0))
	if speed_secs > 0.0:
		_speed_boost_mult = speed_mult
		_speed_boost_timer = speed_secs


func _apply_upgrade(id: String, def: Dictionary) -> void:
	max_hp_bonus += int(def.get("upgrade_max_hp", 0))
	damage_bonus += int(def.get("upgrade_damage", 0))
	speed_bonus += float(def.get("upgrade_speed", 0.0))
	# Heal al máximo si subió max_hp
	if int(def.get("upgrade_max_hp", 0)) > 0:
		current_hp = get_max_hp()
	hp_changed.emit(current_hp, get_max_hp())


func _equip_weapon(weapon_id: String) -> void:
	if WEAPONS.has(weapon_id):
		current_weapon = weapon_id
		weapon_changed.emit(weapon_id)


func cycle_weapon(dir: int) -> void:
	var keys: Array = WEAPONS.keys()
	var idx: int = keys.find(current_weapon)
	if idx == -1:
		idx = 0
	idx = (idx + dir + keys.size()) % keys.size()
	_equip_weapon(keys[idx])


# ═════════════════════════════════════════════════════════════════════════
# API
# ═════════════════════════════════════════════════════════════════════════

func set_mode(new_mode: int) -> void:
	mode = new_mode


func get_current_tile() -> Vector2i:
	return Vector2i(
		int(floor(position.x / float(TILE_PX))),
		int(floor(position.y / float(TILE_PX)))
	)


func get_current_atlas() -> Vector2i:
	var layer := _active_layer()
	if layer == null:
		return Vector2i(-1, -1)
	return layer.get_cell_atlas_coords(get_current_tile())


func set_tile_position(tile: Vector2i) -> void:
	position = Vector2(
		tile.x * TILE_PX + TILE_PX * 0.5,
		tile.y * TILE_PX + TILE_PX * 0.5
	)


# ═════════════════════════════════════════════════════════════════════════
# FÍSICA Y MOVIMIENTO
# ═════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _speed_boost_timer > 0.0:
		_speed_boost_timer -= delta
		if _speed_boost_timer <= 0.0:
			_speed_boost_mult = 1.0
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0 and sprite != null:
			sprite.modulate = Color.WHITE
	if _dodge_cd > 0.0:
		_dodge_cd -= delta

	# Shift = dodge roll (con dir actual o última)
	if Input.is_action_just_pressed("esquivar") and _dodge_cd <= 0.0:
		var dodge_input := Vector2(
			Input.get_axis("mover_izquierda", "mover_derecha"),
			Input.get_axis("mover_arriba", "mover_abajo")
		)
		_dodge_dir = dodge_input.normalized() if dodge_input != Vector2.ZERO else _ultima_dir
		_dodge_timer = DODGE_DURATION
		_dodge_cd = DODGE_COOLDOWN
		if sprite != null:
			sprite.modulate = Color(1.5, 1.5, 2.0, 0.7)  # tint azul translucido

	var dir := Vector2(
		Input.get_axis("mover_izquierda", "mover_derecha"),
		Input.get_axis("mover_arriba",    "mover_abajo")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		_ultima_dir = dir

	# Si estamos dodging, override velocity y dir
	if _dodge_timer > 0.0:
		var dodge_speed: float = (SPEED + speed_bonus) * DODGE_SPEED_MULT
		var step := _dodge_dir * dodge_speed * delta
		var allowed_x := _can_stand_at(position + Vector2(step.x, 0))
		var allowed_y := _can_stand_at(position + Vector2(0, step.y))
		velocity.x = _dodge_dir.x * dodge_speed if allowed_x else 0.0
		velocity.y = _dodge_dir.y * dodge_speed if allowed_y else 0.0
		_update_animation(_dodge_dir)
		z_index = int(position.y / float(TILE_PX))
	elif dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		_set_idle()
	else:
		# COLISIÓN DE TILES en TODOS los modos (no solo cave/mine)
		var effective_speed: float = (SPEED + speed_bonus) * _speed_boost_mult
		var step := dir * effective_speed * delta
		var allowed_x := _can_stand_at(position + Vector2(step.x, 0))
		var allowed_y := _can_stand_at(position + Vector2(0, step.y))
		velocity.x = dir.x * effective_speed if allowed_x else 0.0
		velocity.y = dir.y * effective_speed if allowed_y else 0.0
		_update_animation(dir)
		z_index = int(position.y / float(TILE_PX))
	move_and_slide()

	# Ataques: mouse izquierdo = lanzar, mouse derecho = machetazo
	if Input.is_action_just_pressed("atacar_lanzar") and _attack_cooldown <= 0.0:
		_lanzar_machete_hacia_mouse()
		_attack_cooldown = _get_weapon_stat("fire_rate", 0.35)
	if Input.is_action_just_pressed("atacar_melee") and _attack_cooldown <= 0.0:
		_machetazo()
		_attack_cooldown = _get_weapon_stat("fire_rate", 0.35) * 0.5

	# Hotbar: teclas 1-4 usan slots (con edge detection manual)
	for key_idx in range(4):
		var k: int = KEY_1 + key_idx
		if Input.is_physical_key_pressed(k):
			if not _hotbar_keys_held[key_idx]:
				use_inventory_slot(key_idx)
				_hotbar_keys_held[key_idx] = true
		else:
			_hotbar_keys_held[key_idx] = false

	# Tab = cambiar arma (no más Q/E que choca con zoom)
	if Input.is_action_just_pressed("cambiar_arma"):
		cycle_weapon(1)


# ═════════════════════════════════════════════════════════════════════════
# ATAQUE
# ═════════════════════════════════════════════════════════════════════════

func _lanzar_machete() -> void:
	_lanzar_machete_dir(_ultima_dir)


func _lanzar_machete_hacia_mouse() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_world - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = _ultima_dir
	_ultima_dir = dir
	_lanzar_machete_dir(dir)


func _lanzar_machete_dir(dir: Vector2) -> void:
	if machete_scene == null:
		return
	var machete = machete_scene.instantiate()
	get_parent().add_child(machete)
	machete.global_position = global_position
	machete.call("inicializar", dir)
	# Inyectar stats del arma actual + crit roll
	var throw_dmg: int = _get_weapon_stat("damage_throw", 2) + damage_bonus
	var is_crit: bool = randf() < crit_chance
	if is_crit:
		throw_dmg = int(throw_dmg * 1.75)
	var throw_spd: float = _get_weapon_stat("throw_speed", 400.0)
	if "damage" in machete:
		machete.damage = throw_dmg
	if "speed" in machete:
		machete.speed = throw_spd


func _get_weapon_stat(key: String, default_val):
	var w: Dictionary = WEAPONS.get(current_weapon, {})
	return w.get(key, default_val)


# Machetazo melee — TAJADA animada (arco) en dirección al mouse.
# Daño y radio dependen del arma equipada.

func _machetazo() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var to_mouse: Vector2 = mouse_world - global_position
	var attack_dir: Vector2 = _ultima_dir
	if to_mouse.length_squared() > 4.0:
		attack_dir = to_mouse.normalized()
		_ultima_dir = attack_dir
	var melee_radius: float = _get_weapon_stat("melee_radius", 60.0)
	var base_dmg: int = _get_weapon_stat("damage_melee", 3) + damage_bonus
	var radius_sq: float = melee_radius * melee_radius
	for e in get_tree().get_nodes_in_group("enemigo"):
		if not is_instance_valid(e):
			continue
		var to_e: Vector2 = e.global_position - global_position
		if to_e.length_squared() > radius_sq:
			continue
		var dot: float = to_e.normalized().dot(attack_dir)
		if dot < 0.0:
			continue
		# Crit roll por enemigo
		var dmg: int = base_dmg
		if randf() < crit_chance:
			dmg = int(base_dmg * 1.75)
		if e.has_method("take_damage"):
			e.take_damage(dmg)
			if _sfx_hit != null:
				_sfx_hit.play()
		else:
			e.queue_free()
	_spawn_slash_vfx(attack_dir)
	# Pequeño shake en melee
	var main = get_tree().current_scene
	if main != null and main.has_method("camera_shake"):
		main.camera_shake(2.0, 0.1)


func _spawn_slash_vfx(attack_dir: Vector2) -> void:
	if machete_scene == null:
		return
	# Instancia un Sprite2D temporal con la textura del machete
	var slash := Sprite2D.new()
	# load() funciona en export — Image.load_from_file no funciona con res:// en .pck
	var tex_path := "res://sprites/Machete.png"
	var full_tex: Texture2D = load(tex_path) if ResourceLoader.exists(tex_path) else null
	if full_tex != null:
		var at := AtlasTexture.new()
		at.atlas = full_tex
		at.region = Rect2(0, 0, 64, 64)  # primer frame
		slash.texture = at
	slash.centered = true
	slash.scale = Vector2(1.2, 1.2)
	slash.z_index = 11
	get_parent().add_child(slash)
	# Posición a media distancia + rotación inicial -45° del attack_dir
	var base_angle: float = attack_dir.angle()
	var radius: float = 30.0
	slash.position = global_position + Vector2(radius, 0).rotated(base_angle - PI * 0.35)
	slash.rotation = base_angle - PI * 0.35
	# Tween: arco de -PI*0.35 a +PI*0.35 alrededor del player en 0.18s
	var tw := create_tween()
	tw.set_parallel(true)
	# Rotación
	tw.tween_method(
		func(a: float):
			slash.position = global_position + Vector2(radius, 0).rotated(base_angle + a)
			slash.rotation = base_angle + a,
		-PI * 0.35, PI * 0.35, 0.18
	)
	# Fade out al final
	tw.tween_property(slash, "modulate:a", 0.0, 0.18).set_delay(0.12)
	tw.chain().tween_callback(slash.queue_free)


# ═════════════════════════════════════════════════════════════════════════
# ANIMACIÓN
# ═════════════════════════════════════════════════════════════════════════

func _set_idle() -> void:
	if sprite == null or not _was_moving:
		return
	sprite.stop()
	sprite.frame = 0
	_was_moving = false


func _update_animation(dir: Vector2) -> void:
	if sprite == null:
		return
	var new_anim: String
	if absf(dir.x) > absf(dir.y):
		new_anim = ANIM_DERECHA if dir.x > 0 else ANIM_IZQUIERDA
	else:
		new_anim = ANIM_ABAJO if dir.y > 0 else ANIM_ARRIBA
	if new_anim != _current_anim:
		var keep_frame := sprite.frame if _was_moving else 1
		var keep_progress := sprite.frame_progress if _was_moving else 0.0
		_current_anim = new_anim
		sprite.animation = new_anim
		sprite.frame = keep_frame
		sprite.frame_progress = keep_progress
	if not _was_moving:
		if sprite.frame == 0:
			sprite.frame = 1
		sprite.play()
		_was_moving = true


# ═════════════════════════════════════════════════════════════════════════
# COLISIÓN DE TILES (mode-aware)
# ═════════════════════════════════════════════════════════════════════════

func _can_stand_at(pos: Vector2) -> bool:
	var layer := _active_layer()
	if layer == null:
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
		var src_id := layer.get_cell_source_id(cell)
		var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
		match mode:
			0:
				# Overworld
				if src_id == -1:
					return false
				if _is_impassable_overworld(src_id, atlas):
					return false
				# Decor overlay
				if overworld_decor_layer != null:
					var d_src := overworld_decor_layer.get_cell_source_id(cell)
					if d_src != -1:
						var d_atlas: Vector2i = overworld_decor_layer.get_cell_atlas_coords(cell)
						if _is_impassable_overworld(d_src, d_atlas):
							return false
				# Trees Sprite2D
				if tree_blocked_tiles.has(cell):
					return false
			1:
				# Paquimé: WHITELIST de tiles passable. Default impassable.
				if src_id == -1:
					return false
				if src_id == 0:
					if not _is_passable_paquime(atlas):
						return false
				# src 1 (floor) → passable
			_:
				# Cave/Mine: src 0 = wall (salvo passable_decor), src 1 = floor
				if src_id == -1:
					return false
				if src_id == 0 and not passable_decor.has(cell):
					return false
	return true


func _is_passable_paquime(atlas: Vector2i) -> bool:
	# Paquimé atlas (paquime_tiles.png 4x4):
	# T_VOID(0,0) T_FLOOR(1,0) T_WALL(2,0) T_DOOR(3,0)
	# T_PLAZA(0,1) T_MACAW(1,1) T_WORKSHOP(2,1) T_WATER(3,1)
	# T_EFFIGY_CROSS(0,2) T_EFFIGY_BIRD(1,2) T_EFFIGY_SERPENT(2,2) T_BALL(3,2)
	# T_ENTRANCE(0,3) T_EXIT(1,3) T_POT(2,3)
	# Impasables: T_WALL(2,0), T_WATER(3,1), T_VOID(0,0)
	var ax: int = atlas.x; var ay: int = atlas.y
	if ax == 2 and ay == 0: return false  # WALL
	if ax == 3 and ay == 1: return false  # WATER
	if ax == 0 and ay == 0: return false  # VOID
	return true  # todo lo demás passable


func _is_impassable_overworld(src_id: int, atlas: Vector2i) -> bool:
	# Source 0 (overworld hand-drawn)
	if src_id == 0:
		if atlas.x == 0 and atlas.y == 2: return true   # barranca borde
		if atlas.x == 1 and atlas.y == 2: return true   # barranca abismo
		if atlas.x == 6 and atlas.y == 2: return true   # río
		if atlas.x == 0 and atlas.y == 5: return true   # pico
		if atlas.x == 0 and atlas.y == 4: return true   # ADOBE_WALL stamp
		if atlas.x == 3 and atlas.y == 4: return true   # CAVE_ROCK
		if atlas.x == 5 and atlas.y == 4: return true   # WOOD_FRAME
		if atlas.x == 6 and atlas.y == 1: return true   # roca sierra
		return false
	# Source 1 (desert) — passable
	if src_id == 1:
		return false
	# Source 2 (afuera) — trees row 5 cols 0-5 + rocas grandes row 8 cols 3-6
	if src_id == 2:
		if atlas.y == 5 and atlas.x <= 5: return true
		if atlas.y == 8 and atlas.x >= 3 and atlas.x <= 6: return true
		return false
	# Source 3 (trees_topdown) — siempre impasable
	if src_id == 3:
		return true
	# Source 4 (biome_bases) — RIO(5), BARRANCA(3), PICO(7) impasable
	if src_id == 4:
		if atlas.x == 3: return true
		if atlas.x == 5: return true
		if atlas.x == 7: return true
		return false
	return false


func _active_layer() -> TileMapLayer:
	match mode:
		0: return overworld_layer
		1: return dungeon_layer
		2: return cave_layer
		3: return mines_layer
	return overworld_layer
