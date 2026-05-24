# Jugador top-down con WASD + colisión por tile + interacción.
# Soporta 4 modos (overworld, paquime, cave, mine) con sus layers/impassable distintos.

class_name Player
extends Node2D

const SPEED := 240.0
const EFFECTIVE_TILE := 32
# Hitbox player: 12x12 box (HALF=6) — más permisivo que antes (HALF=10 → 20x20)
# para mejor feel al caminar entre obstáculos y pegado a paredes.
const HALF_HITBOX := 6

@export var sprite_path: String = "res://art/tiles/principal.png"

const FRAME_W := 48
const FRAME_H := 64
const ANIM_FPS := 8.0
const ANIMS := ["walk_down", "walk_left", "walk_right", "walk_up"]

var sprite: AnimatedSprite2D
var current_anim: String = "walk_down"

var overworld_layer: TileMapLayer
var overworld_decor_layer: TileMapLayer
var dungeon_layer: TileMapLayer
var cave_layer: TileMapLayer
var mines_layer: TileMapLayer

var mode: int = 0  # Mode enum (definido en Main.gd) — 0=overworld, 1=paquime, 2=cave, 3=mine

# Set of tile positions con decoración transitable (cave/mine modes).
# Main.gd lo popula al pintar floor_scatter/decor para evitar que tiles
# decorativos pintados en src 0 (atlas walls) bloqueen al jugador.
var passable_decor: Dictionary = {}  # Vector2i → bool

# Set de tile positions OCUPADAS POR ÁRBOLES (Sprite2D nodes) — impasable en overworld.
var tree_blocked_tiles: Dictionary = {}  # Vector2i → bool


func _ready() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(sprite_path))
	if img == null:
		push_error("Player: no pude cargar %s" % sprite_path)
		return
	var tex := ImageTexture.create_from_image(img)

	# Construye SpriteFrames con 4 animaciones (una por dirección) × 4 frames cada una.
	# Layout asumido (RPG standard): row 0=down, row 1=left, row 2=right, row 3=up.
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for row in range(4):
		var anim_name: String = ANIMS[row]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, ANIM_FPS)
		sf.set_animation_loop(anim_name, true)
		for col in range(4):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			sf.add_frame(anim_name, at)

	# Outline sprite (silhouette) detrás
	var outline := AnimatedSprite2D.new()
	outline.sprite_frames = sf
	outline.centered = true
	outline.animation = current_anim
	outline.scale = Vector2(1.08, 1.08)
	outline.modulate = Color(0, 0, 0, 0.5)
	outline.z_index = -1
	outline.name = "Outline"
	add_child(outline)
	outline.play()

	# Sprite principal animado encima
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = sf
	sprite.centered = true
	sprite.animation = current_anim
	sprite.name = "MainSprite"
	add_child(sprite)
	sprite.play()


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
		# Idle: detener animación en frame 0 (mantiene última dirección)
		if sprite != null and sprite.is_playing():
			sprite.stop()
			sprite.frame = 0
			var outline := get_node_or_null("Outline") as AnimatedSprite2D
			if outline != null:
				outline.stop()
				outline.frame = 0
		return
	# Update dirección animada según eje dominante
	var new_anim: String = current_anim
	if absf(dir.x) > absf(dir.y):
		new_anim = "walk_right" if dir.x > 0 else "walk_left"
	else:
		new_anim = "walk_down" if dir.y > 0 else "walk_up"
	if sprite != null:
		if new_anim != current_anim:
			current_anim = new_anim
			sprite.animation = new_anim
			var outline2 := get_node_or_null("Outline") as AnimatedSprite2D
			if outline2 != null:
				outline2.animation = new_anim
		if not sprite.is_playing():
			sprite.play()
			var outline3 := get_node_or_null("Outline") as AnimatedSprite2D
			if outline3 != null:
				outline3.play()
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
			# Overworld: check base + decor overlay + trees (Sprite2D nodes)
			if src_id == -1:
				return false
			if _is_impassable_overworld_explicit(src_id, atlas):
				return false
			# Decor overlay (rocas grandes etc.)
			if overworld_decor_layer != null:
				var d_src: int = overworld_decor_layer.get_cell_source_id(Vector2i(tx, ty))
				if d_src != -1:
					var d_atlas: Vector2i = overworld_decor_layer.get_cell_atlas_coords(Vector2i(tx, ty))
					if _is_impassable_overworld_explicit(d_src, d_atlas):
						return false
			# Árboles grandes (Sprite2D, tile occupado registrado en tree_blocked_tiles)
			if tree_blocked_tiles.has(Vector2i(tx, ty)):
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
	# Source 0 (overworld hand-drawn)
	if src_id == 0:
		if atlas.x == 0 and atlas.y == 2: return true  # barranca borde
		if atlas.x == 1 and atlas.y == 2: return true  # barranca abismo
		if atlas.x == 6 and atlas.y == 2: return true  # río
		if atlas.x == 0 and atlas.y == 5: return true  # pico
		if atlas.x == 0 and atlas.y == 4: return true  # ADOBE_WALL
		if atlas.x == 3 and atlas.y == 4: return true  # CAVE_ROCK
		if atlas.x == 5 and atlas.y == 4: return true  # WOOD_FRAME
		if atlas.x == 6 and atlas.y == 1: return true  # SIERRA_ROCA
		return false
	# Source 1 (desert atlas) — todos pasables
	if src_id == 1:
		return false
	# Source 2 (afuera — vegetación). Impasables: bases de árboles + rocas grandes.
	if src_id == 2:
		# Bases de árboles row 5 cols 0-5 (no las uso pero por si acaso)
		if atlas.y == 5 and atlas.x <= 5: return true
		# Rocas grandes: row 8, cols 3-6
		if atlas.y == 8 and atlas.x >= 3 and atlas.x <= 6: return true
		return false
	# Source 3 (trees_topdown) — TODOS los árboles son impasables
	if src_id == 3:
		return true
	# Source 4 (biome_bases) — bases passable salvo RIO/BARRANCA/PICO
	if src_id == 4:
		# RIO (atlas 5), BARRANCA (atlas 3), PICO (atlas 7) impasables
		if atlas.x == 3: return true
		if atlas.x == 5: return true
		if atlas.x == 7: return true
		return false
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
