# Enemigo.gd — Enemigo genérico top-down para mazmorras de Ludic2026.
# Compatible con sprites de 4 direcciones (bandido) o animación única (fantasma).
 
extends CharacterBody2D
 
# ── Parámetros ajustables desde el Inspector ─────────────────────────────────
@export var speed_chase  : float = 90.0
@export var speed_patrol : float = 40.0
@export var chase_radius : float = 180.0
@export var stop_radius  : float = 30.0
@export var damage_radius: float = 20.0
 
## Si es true usa 4 animaciones (arriba/abajo/izquierda/derecha).
## Si es false usa una sola animación "default" — ideal para fantasma.
@export var four_directions: bool = true
 
## Nombre de la animación cuando four_directions = false
@export var anim_default: String = "default"
 
# ── Nodos hijos ───────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
# ── Estado interno ────────────────────────────────────────────────────────────
var _player       : Node2D  = null
var _patrol_dir   : Vector2 = Vector2.RIGHT
var _patrol_timer : float   = 0.0
const PATROL_CHANGE_TIME := 2.0
 
const ANIM_ABAJO     := "abajo"
const ANIM_ARRIBA    := "arriba"
const ANIM_IZQUIERDA := "izquierda"
const ANIM_DERECHA   := "derecha"
 
 
func _ready() -> void:
	add_to_group("enemigo")
	_player = get_tree().get_first_node_in_group("player")
	var angle := randf() * TAU
	_patrol_dir = Vector2(cos(angle), sin(angle))
	if sprite:
		sprite.play(ANIM_ABAJO if four_directions else anim_default)
 
 
func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
 
	var dist := global_position.distance_to(_player.global_position)
 
	if dist < damage_radius:
		get_tree().reload_current_scene()
		return
 
	var dir: Vector2
 
	if dist < chase_radius and dist > stop_radius:
		dir      = (_player.global_position - global_position).normalized()
		velocity = dir * speed_chase
	elif dist <= stop_radius:
		velocity = Vector2.ZERO
		dir      = (_player.global_position - global_position).normalized()
	else:
		_patrol_timer -= delta
		if _patrol_timer <= 0.0:
			_patrol_timer = PATROL_CHANGE_TIME + randf() * 1.5
			var angle := randf() * TAU
			_patrol_dir = Vector2(cos(angle), sin(angle))
		dir      = _patrol_dir
		velocity = dir * speed_patrol
 
	move_and_slide()
 
	if sprite and velocity.length() > 5.0:
		_update_animation(dir)
 
 
func _update_animation(dir: Vector2) -> void:
	if not four_directions:
		# Fantasma u otro enemigo con animación única — solo reproduce y ya
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
