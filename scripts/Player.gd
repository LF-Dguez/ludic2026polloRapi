# Player.gd — Jugador top-down optimizado para Ludic2026.
# Usa el AnimatedSprite2D configurado en el editor con animaciones:
#   "arriba", "abajo", "izquierda", "derecha"
# Incluye lógica de ataque con machete (igual que la demo).
 
class_name Player
extends CharacterBody2D
 
# ── Constantes ───────────────────────────────────────────────────────────────
const SPEED        := 240.0
const TILE_PX      := 32
const HALF_HITBOX  := 6
 
const ANIM_ABAJO     := "abajo"
const ANIM_ARRIBA    := "arriba"
const ANIM_IZQUIERDA := "izquierda"
const ANIM_DERECHA   := "derecha"
 
# ── Nodos hijos — tomados de la escena ───────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
 
# ── Exports ───────────────────────────────────────────────────────────────────
## Escena del machete — asígnala desde el Inspector
@export var machete_scene: PackedScene
 
# ── Estado de animación ───────────────────────────────────────────────────────
var _current_anim : String  = ANIM_ABAJO
var _was_moving   : bool    = false
 
# ── Última dirección — para que el machete salga hacia donde miras ───────────
var _ultima_dir   : Vector2 = Vector2.DOWN
 
# ── Referencias a capas — Main.gd las asigna igual que antes ─────────────────
var overworld_layer      : TileMapLayer
var overworld_decor_layer: TileMapLayer
var dungeon_layer        : TileMapLayer
var cave_layer           : TileMapLayer
var mines_layer          : TileMapLayer
 
# ── Modo activo (0=overworld, 1=paquime, 2=cave, 3=mine) ─────────────────────
var mode: int = 0
 
# ── Diccionarios de colisión — Main.gd los popula igual que antes ────────────
var passable_decor    : Dictionary = {}
var tree_blocked_tiles: Dictionary = {}
 
 
# ════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════════════════
 
func _ready() -> void:
	if sprite == null:
		push_error("Player: no se encontró AnimatedSprite2D hijo.")
		return
 
	if not has_node("CollisionShape2D"):
		var col   := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(HALF_HITBOX * 2, HALF_HITBOX * 2)
		col.shape  = shape
		col.name   = "CollisionShape2D"
		add_child(col)
 
	sprite.animation = _current_anim
	sprite.frame     = 0
 
 
# ════════════════════════════════════════════════════════════════════════════
# API PÚBLICA — Main.gd no necesita cambios
# ════════════════════════════════════════════════════════════════════════════
 
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
 
 
# ════════════════════════════════════════════════════════════════════════════
# FÍSICA Y MOVIMIENTO
# ════════════════════════════════════════════════════════════════════════════
 
func _physics_process(delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("mover_izquierda", "mover_derecha"),
		Input.get_axis("mover_arriba",    "mover_abajo")
	)
 
	if dir != Vector2.ZERO:
		dir         = dir.normalized()
		_ultima_dir = dir  # guarda dirección para el machete
 
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		_set_idle()
		move_and_slide()
	else:
		velocity = dir * SPEED
		if mode == 2 or mode == 3:
			velocity = _apply_tile_collision(dir, delta)
		move_and_slide()
		_update_animation(dir)
		z_index = int(position.y / float(TILE_PX))
 
	# Ataque — funciona en cualquier modo y dirección
	if Input.is_action_just_pressed("atacar"):
		_lanzar_machete()
 
 
# ════════════════════════════════════════════════════════════════════════════
# ATAQUE — MACHETE
# ════════════════════════════════════════════════════════════════════════════
 
func _lanzar_machete() -> void:
	if machete_scene == null:
		return
	var machete = machete_scene.instantiate()
	get_parent().add_child(machete)
	machete.global_position = global_position
	machete.call("inicializar", _ultima_dir)
 
 
# ════════════════════════════════════════════════════════════════════════════
# ANIMACIÓN
# ════════════════════════════════════════════════════════════════════════════
 
func _set_idle() -> void:
	if sprite == null or not _was_moving:
		return
	sprite.stop()
	sprite.frame = 0
	_was_moving  = false
 
 
func _update_animation(dir: Vector2) -> void:
	if sprite == null:
		return
 
	var new_anim: String
	if absf(dir.x) > absf(dir.y):
		new_anim = ANIM_DERECHA if dir.x > 0 else ANIM_IZQUIERDA
	else:
		new_anim = ANIM_ABAJO if dir.y > 0 else ANIM_ARRIBA
 
	if new_anim != _current_anim:
		var keep_frame    := sprite.frame if _was_moving else 1
		var keep_progress := sprite.frame_progress if _was_moving else 0.0
		_current_anim         = new_anim
		sprite.animation      = new_anim
		sprite.frame          = keep_frame
		sprite.frame_progress = keep_progress
 
	if not _was_moving:
		if sprite.frame == 0:
			sprite.frame = 1
		sprite.play()
		_was_moving = true
 
 
# ════════════════════════════════════════════════════════════════════════════
# COLISIÓN DE TILES (cave / mine)
# ════════════════════════════════════════════════════════════════════════════
 
func _apply_tile_collision(dir: Vector2, delta: float) -> Vector2:
	var adjusted := velocity
	var step     := dir * SPEED * delta
 
	if not _can_stand_at(position + Vector2(step.x, 0)):
		adjusted.x = 0.0
	if not _can_stand_at(position + Vector2(0, step.y)):
		adjusted.y = 0.0
 
	return adjusted
 
 
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
		var cell   := Vector2i(tx, ty)
		var src_id := layer.get_cell_source_id(cell)
		if src_id == -1:
			return false
		if src_id == 0 and not passable_decor.has(cell):
			return false
	return true
 
 
func _active_layer() -> TileMapLayer:
	match mode:
		0: return overworld_layer
		1: return dungeon_layer
		2: return cave_layer
		3: return mines_layer
	return overworld_layer
