# Jugador top-down con WASD + colisión por tile + interacción.
# Soporta 4 modos (overworld, paquime, cave, mine) con sus layers/impassable distintos.

class_name Player
extends Node2D

const SPEED := 240.0
const EFFECTIVE_TILE := 32
const HALF_HITBOX := 10

@export var sprite_path: String = "res://art/tiles/player.png"

var sprite: Sprite2D

var overworld_layer: TileMapLayer
var dungeon_layer: TileMapLayer
var cave_layer: TileMapLayer
var mines_layer: TileMapLayer

var mode_overworld: bool = true  # legacy bool
var mode: int = 0  # Mode enum (definido en Main.gd) — 0=overworld, 1=paquime, 2=cave, 3=mine

var impassable_overworld: Array = []   # encoded ints
var impassable_dungeon: Array = []     # Vector2i atlas coords (single source)


func _ready() -> void:
	sprite = Sprite2D.new()
	var img := Image.load_from_file(ProjectSettings.globalize_path(sprite_path))
	if img != null:
		sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = true
	add_child(sprite)


func set_mode(new_mode: int) -> void:
	mode = new_mode
	mode_overworld = (new_mode == 0)


func _current_layer() -> TileMapLayer:
	match mode:
		0: return overworld_layer
		1: return dungeon_layer
		2: return cave_layer
		3: return mines_layer
	return overworld_layer


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_key_pressed(KEY_S): dir.y += 1
	if Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_D): dir.x += 1
	if dir == Vector2.ZERO:
		return
	dir = dir.normalized()
	var step := dir * SPEED * delta
	var nx := position + Vector2(step.x, 0)
	if _can_stand_at(nx):
		position.x = nx.x
	var ny := position + Vector2(0, step.y)
	if _can_stand_at(ny):
		position.y = ny.y


func _can_stand_at(pos: Vector2) -> bool:
	var layer: TileMapLayer = _current_layer()
	if layer == null:
		return true
	var corners := [
		Vector2(pos.x - HALF_HITBOX, pos.y - HALF_HITBOX),
		Vector2(pos.x + HALF_HITBOX, pos.y - HALF_HITBOX),
		Vector2(pos.x - HALF_HITBOX, pos.y + HALF_HITBOX),
		Vector2(pos.x + HALF_HITBOX, pos.y + HALF_HITBOX),
	]
	for c in corners:
		var tx: int = int(floor(c.x / float(EFFECTIVE_TILE)))
		var ty: int = int(floor(c.y / float(EFFECTIVE_TILE)))
		if tx < 0 or ty < 0:
			return false
		var src_id: int = layer.get_cell_source_id(Vector2i(tx, ty))
		var atlas: Vector2i = layer.get_cell_atlas_coords(Vector2i(tx, ty))
		if mode == 0:
			# Overworld: cualquier tile con tile válido es transitable salvo lista
			if src_id == -1:
				return false  # fuera del mapa pintado
			var encoded: int = (src_id << 16) | (atlas.x << 8) | atlas.y
			if encoded in impassable_overworld:
				return false
		elif mode == 1:
			# Paquimé: lista de Vector2i atlas
			if atlas == Vector2i(-1, -1):
				return false
			if atlas in impassable_dungeon:
				return false
		else:
			# Cave/Mine: tile pintado = wall (impasable); no tile = piso (transitable)
			if src_id != -1:
				return false  # hay tile → es roca/wall
			# else: piso (no tile), pasamos
	return true


func get_current_tile() -> Vector2i:
	var tx: int = int(floor(position.x / float(EFFECTIVE_TILE)))
	var ty: int = int(floor(position.y / float(EFFECTIVE_TILE)))
	return Vector2i(tx, ty)


func get_current_atlas() -> Vector2i:
	var layer: TileMapLayer = _current_layer()
	if layer == null:
		return Vector2i(-1, -1)
	return layer.get_cell_atlas_coords(get_current_tile())


func set_tile_position(tile: Vector2i) -> void:
	position = Vector2(
		tile.x * EFFECTIVE_TILE + EFFECTIVE_TILE / 2.0,
		tile.y * EFFECTIVE_TILE + EFFECTIVE_TILE / 2.0,
	)
