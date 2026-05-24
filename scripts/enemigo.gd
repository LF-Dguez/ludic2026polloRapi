# Enemigo.gd — IA top-down con HP, wall collision, damage numbers, drops.

extends CharacterBody2D

const ItemDBScript = preload("res://scripts/ItemDB.gd")

@export var speed_chase  : float = 90.0
@export var speed_patrol : float = 40.0
@export var chase_radius : float = 220.0
@export var stop_radius  : float = 26.0
@export var damage_radius: float = 38.0
@export var damage_to_player: int = 1
@export var max_hp: int = 3
@export var four_directions: bool = true
@export var anim_default: String = "default"
@export var enemy_type: String = "bandido"  # "bandido" o "fantasma" — drop table

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var tile_layer: TileMapLayer = null
var mode: int = 1

var _player       : Node2D  = null
var _patrol_dir   : Vector2 = Vector2.RIGHT
var _patrol_timer : float   = 0.0
var hp: int = 0
var _attack_cooldown: float = 0.0
var _attack_anim_time: float = 0.0
const PATROL_CHANGE_TIME := 2.0
const ATTACK_COOLDOWN := 1.2
const ATTACK_WINDUP := 0.25
const HALF_HITBOX := 10
const TILE_PX := 32

const ANIM_ABAJO     := "abajo"
const ANIM_ARRIBA    := "arriba"
const ANIM_IZQUIERDA := "izquierda"
const ANIM_DERECHA   := "derecha"


func _ready() -> void:
	add_to_group("enemigo")
	hp = max_hp
	_player = get_tree().get_first_node_in_group("player")
	var angle := randf() * TAU
	_patrol_dir = Vector2(cos(angle), sin(angle))
	if sprite:
		sprite.play(ANIM_ABAJO if four_directions else anim_default)


func take_damage(amount: int) -> void:
	hp -= amount
	# Damage number flotante
	var dn_script = load("res://scripts/DamageNumber.gd")
	var dn = dn_script.new()
	get_parent().add_child(dn)
	dn.setup(amount, global_position, amount >= 5)
	# Flash rojo
	if sprite != null:
		sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	if hp <= 0:
		_drop_loot()
		# Notificar al player para XP
		if _player != null and _player.has_signal("enemy_killed"):
			var xp_val: int = 10 if enemy_type == "bandido" else 15
			_player.enemy_killed.emit(enemy_type, xp_val)
		queue_free()


func _drop_loot() -> void:
	var drops: Array = ItemDBScript.roll_drop(enemy_type)
	var drop_script = load("res://scripts/ItemDrop.gd")
	for d in drops:
		var drop_inst = drop_script.new()
		get_parent().add_child(drop_inst)
		drop_inst.setup(d["id"], d["count"])
		# Spread aleatorio alrededor del punto de muerte
		drop_inst.global_position = global_position + Vector2(
			randf_range(-16, 16), randf_range(-16, 16)
		)


func _physics_process(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _attack_anim_time > 0.0:
		_attack_anim_time -= delta
		if _attack_anim_time <= 0.0 and sprite != null:
			sprite.scale = Vector2.ONE

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return

	var dist := global_position.distance_to(_player.global_position)
	var dir: Vector2

	if dist < damage_radius and _attack_cooldown <= 0.0:
		_atacar_player()
		_attack_cooldown = ATTACK_COOLDOWN
		_attack_anim_time = ATTACK_WINDUP

	if dist < chase_radius and dist > stop_radius:
		dir = (_player.global_position - global_position).normalized()
		velocity = dir * speed_chase
	elif dist <= stop_radius:
		velocity = Vector2.ZERO
		dir = (_player.global_position - global_position).normalized()
	else:
		_patrol_timer -= delta
		if _patrol_timer <= 0.0:
			_patrol_timer = PATROL_CHANGE_TIME + randf() * 1.5
			var angle := randf() * TAU
			_patrol_dir = Vector2(cos(angle), sin(angle))
		dir = _patrol_dir
		velocity = dir * speed_patrol

	if velocity != Vector2.ZERO and tile_layer != null:
		var step := velocity * delta
		if not _can_move_to(global_position + Vector2(step.x, 0)):
			velocity.x = 0.0
		if not _can_move_to(global_position + Vector2(0, step.y)):
			velocity.y = 0.0

	move_and_slide()

	if sprite and velocity.length() > 5.0:
		_update_animation(dir)


func _atacar_player() -> void:
	if _player.has_method("take_damage"):
		_player.take_damage(damage_to_player)
	if sprite != null:
		sprite.modulate = Color(1.4, 1.4, 0.4, 1.0)
		sprite.scale = Vector2(1.3, 1.3)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, ATTACK_WINDUP)


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


func _update_animation(dir: Vector2) -> void:
	if not four_directions:
		if not sprite.is_playing():
			sprite.play(anim_default)
		return
	var anim: String
	if absf(dir.x) > absf(dir.y):
		anim = ANIM_DERECHA if dir.x > 0 else ANIM_IZQUIERDA
	else:
		anim = ANIM_ABAJO if dir.y > 0 else ANIM_ARRIBA
	if sprite.animation != anim:
		sprite.play(anim)
