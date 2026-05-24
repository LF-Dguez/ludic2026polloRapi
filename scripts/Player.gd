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

var mode: int = 0  # Mode enum (definido en Main.gd) — 0=overworld, 1=paquime, 2=cave, 3=mine

# Set of tile positions con decoración transitable (cave/mine modes).
# Main.gd lo popula al pintar floor_scatter/decor para evitar que tiles
# decorativos pintados en src 0 (atlas walls) bloqueen al jugador.
var passable_decor: Dictionary = {}  # Vector2i → bool


func _ready() -> void:
	sprite = Sprite2D.new()
	var img := Image.load_from_file(ProjectSettings.globalize_path(sprite_path))
	if img != null:
		sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = true
	add_child(sprite)


func set_mode(new_mode: int) -> void:
	mode = new_mode


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
	# SUBSTEPPING: si step > HALF_HITBOX, dividir en chunks para evitar tunneling a low FPS
	var max_chunk: float = float(HALF_HITBOX)
	var step_len: float = step.length()
	var num_substeps: int = maxi(1, int(ceil(step_len / max_chunk)))
	var sub_step: Vector2 = step / float(num_substeps)
	for _i in range(num_substeps):
		var nx := position + Vector2(sub_step.x, 0)
		if _can_stand_at(nx):
			position.x = nx.x
		var ny := position + Vector2(0, sub_step.y)
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
			# Overworld
			if src_id == -1:
				return false
			# Chequeo explícito por (src_id, atlas.x, atlas.y) en vez de `in` para evitar
			# weirdness de Variant comparison.
			if _is_impassable_overworld_explicit(src_id, atlas):
				return false
		elif mode == 1:
			# Paquimé: src 0 = atlas paquime. WHITELIST de tiles passable;
			# todo lo demás src 0 (incluyendo T_WALL/T_WATER/T_VOID y cualquier
			# decoración tipo-pared) es impasable.
			if src_id == -1:
				return false
			if src_id == 0:
				var ax: int = atlas.x
				var ay: int = atlas.y
				var passable: bool = (
					(ax == 1 and ay == 0) or  # T_FLOOR
					(ax == 3 and ay == 0) or  # T_DOOR
					(ax == 0 and ay == 1) or  # T_PLAZA
					(ax == 1 and ay == 1) or  # T_MACAW
					(ax == 2 and ay == 1) or  # T_WORKSHOP
					(ax == 0 and ay == 2) or  # T_EFFIGY_CROSS
					(ax == 1 and ay == 2) or  # T_EFFIGY_BIRD
					(ax == 2 and ay == 2) or  # T_EFFIGY_SERPENT
					(ax == 3 and ay == 2) or  # T_BALL
					(ax == 0 and ay == 3) or  # T_ENTRANCE
					(ax == 1 and ay == 3) or  # T_EXIT
					(ax == 2 and ay == 3)     # T_POT
				)
				if not passable:
					return false
		else:
			# Cave/Mine: src 0 = wall salvo decor explícito en passable_decor
			if src_id == -1:
				return false
			if src_id == 0:
				if passable_decor.has(Vector2i(tx, ty)):
					continue  # decoración sobre piso, transitable
				return false
	return true


func _is_impassable_overworld_explicit(src_id: int, atlas: Vector2i) -> bool:
	# Source 0 (overworld atlas)
	if src_id == 0:
		# Barranca borde (0,2), abismo (1,2), río (6,2), pico (0,5)
		if atlas.x == 0 and atlas.y == 2: return true
		if atlas.x == 1 and atlas.y == 2: return true
		if atlas.x == 6 and atlas.y == 2: return true
		if atlas.x == 0 and atlas.y == 5: return true
		# Stamps: adobe wall (0,4), cave rock (3,4), wood frame (5,4), roca sierra (6,1)
		if atlas.x == 0 and atlas.y == 4: return true  # ADOBE_WALL
		if atlas.x == 3 and atlas.y == 4: return true  # CAVE_ROCK
		if atlas.x == 5 and atlas.y == 4: return true  # WOOD_FRAME
		if atlas.x == 6 and atlas.y == 1: return true  # SIERRA_ROCA
	# Source 1 (desert atlas) — todos pasables por default
	return false


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
