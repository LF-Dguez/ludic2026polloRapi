# Main — orquesta overworld + 3 tipos de mazmorra:
#   - DUNGEON_PAQUIME: BSP rectangular (puertas T)
#   - CAVE_TARAHUMARA: cellular automata (rocas orgánicas, atlas cueva del usuario)
#   - MINE_NAICA: drunkard's walk (túneles + rieles, atlas minas del usuario)

extends Node2D

const OverworldScript := preload("res://scripts/Overworld.gd")
const BSPScript := preload("res://scripts/BSPGenerator.gd")
const CaveScript := preload("res://scripts/CaveGenerator.gd")
const MineScript := preload("res://scripts/MineGenerator.gd")
const PlayerScript := preload("res://scripts/Player.gd")

const TILE_SOURCE := 16
const TILE_DISPLAY := 32
const MAP_W := 1024
const MAP_H := 768
const DUN_W := 120
const DUN_H := 80
const CAVE_W := 100
const CAVE_H := 70
const MINE_W := 100
const MINE_H := 70
const ATLAS_OVERWORLD_COLS := 8
const ATLAS_OVERWORLD_ROWS := 6
const ATLAS_DESERT_COLS := 8
const ATLAS_DESERT_ROWS := 8
const ATLAS_AFUERA_COLS := 11
const ATLAS_AFUERA_ROWS := 10
const ATLAS_TREES_COLS := 8
const ATLAS_TREES_ROWS := 1
const ATLAS_PAQUIME_COLS := 4
const ATLAS_PAQUIME_ROWS := 4
const ATLAS_CAVE_COLS := 8
const ATLAS_CAVE_ROWS := 8
const ATLAS_MINES_COLS := 8
const ATLAS_MINES_ROWS := 9

# Tiles impasables (overworld) — source << 16 | x << 8 | y para unificar
const IMPASSABLE_OVERWORLD := [
	# source 0 (overworld)
	(0 << 16) | (0 << 8) | 2,   # barranca borde
	(0 << 16) | (1 << 8) | 2,   # barranca abismo
	(0 << 16) | (6 << 8) | 2,   # río
	(0 << 16) | (0 << 8) | 5,   # pico (no escalable)
	# Stamps: paredes/rocas impasables
	(0 << 16) | (0 << 8) | 4,   # T_ADOBE_WALL — muros de casas/iglesias
	(0 << 16) | (3 << 8) | 4,   # T_CAVE_ROCK — boca de cueva Tarahumara
	(0 << 16) | (5 << 8) | 4,   # T_WOOD_FRAME — marco de mina Naica
	(0 << 16) | (6 << 8) | 1,   # roca sierra — perímetro cementerio
]

const IMPASSABLE_PAQUIME := [
	(0 << 16) | (2 << 8) | 0,   # muro
	(0 << 16) | (3 << 8) | 1,   # agua
	(0 << 16) | (0 << 8) | 0,   # void
]

enum Mode { OVERWORLD, DUNGEON_PAQUIME, CAVE_TARAHUMARA, MINE_NAICA }

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var dark_bg: ColorRect = $DarkBG
@onready var overworld_layer: TileMapLayer = $OverworldLayer
@onready var overworld_decor_layer: TileMapLayer = $OverworldDecorLayer
@onready var dungeon_layer: TileMapLayer = $DungeonLayer
@onready var cave_layer: TileMapLayer = $CaveLayer
@onready var mines_layer: TileMapLayer = $MinesLayer
@onready var player: Node2D = $Player
@onready var player_light: PointLight2D = $Player/PlayerLight
@onready var camera: Camera2D = $Player/Camera2D
@onready var info: Label = $HUD/Info
@onready var prompt: Label = $HUD/Prompt
@onready var minimap = $HUD/Minimap
@onready var minimap_hint: Label = $HUD/MinimapHint

# Límites del zoom (para que no se vea el grid haciendo zoom-out hasta el mapa entero)
const ZOOM_MIN := 0.6
const ZOOM_MAX := 3.0

# Estado del minimapa
const MINI_SMALL := Vector2(240, 180)
const MINI_LARGE := Vector2(900, 675)
var minimap_large: bool = false

var current_seed: int = 0
var mode: int = Mode.OVERWORLD
var world  # Overworld.World
var dungeon  # BSPGenerator.Dungeon
var cave  # CaveGenerator.Cave
var mine  # MineGenerator.Mine

# Guard contra regeneraciones concurrentes (spam de R)
var regenerating: bool = false

var saved_overworld_tile: Vector2i = Vector2i.ZERO
var active_dungeon_poi: Variant = null


func _ready() -> void:
	overworld_layer.tile_set = _build_overworld_tileset()
	# Decor layer comparte el mismo TileSet (3 sources)
	overworld_decor_layer.tile_set = overworld_layer.tile_set
	# Dungeons: source 0 = walls atlas, source 1 = floor tiles
	dungeon_layer.tile_set = _build_dual_tileset(
		"res://art/tiles/paquime_tiles.png", ATLAS_PAQUIME_COLS, ATLAS_PAQUIME_ROWS,
		"res://art/tiles/paquime_floor.png", 4, 1,
		TILE_SOURCE
	)
	cave_layer.tile_set = _build_dual_tileset(
		"res://art/tiles/cave_tiles_clean.png", ATLAS_CAVE_COLS, ATLAS_CAVE_ROWS,
		"res://art/tiles/cave_floor.png", 4, 1,
		TILE_DISPLAY
	)
	mines_layer.tile_set = _build_dual_tileset(
		"res://art/tiles/mines_tiles_clean.png", ATLAS_MINES_COLS, ATLAS_MINES_ROWS,
		"res://art/tiles/mine_floor.png", 4, 1,
		TILE_DISPLAY
	)
	# Carga la textura de luz radial para PointLight2D
	player_light.texture = _load_texture("res://art/tiles/light_texture.png")
	# Inicializa minimap con referencia al jugador
	minimap.player_ref = player
	_apply_minimap_size()
	# Pasa referencias al jugador
	player.overworld_layer = overworld_layer
	player.overworld_decor_layer = overworld_decor_layer
	player.dungeon_layer = dungeon_layer
	player.cave_layer = cave_layer
	player.mines_layer = mines_layer
	# (Player ya no usa estos arrays — collision via _is_impassable_overworld_explicit
	# y whitelist hardcoded por mode. Constants quedan acá como documentación.)
	randomize()
	await _regenerate_overworld()
	# Auto-tour solo se activa con F12 (QA screenshots), no automático al iniciar


func _auto_tour() -> void:
	var types_to_visit := [
		OverworldScript.POIType.ENTRADA_PAQUIME,
		OverworldScript.POIType.ENTRADA_TARAHUMARA,
		OverworldScript.POIType.ENTRADA_NAICA,
	]
	for t in types_to_visit:
		var found_poi = null
		for poi in world.pois:
			if poi.type == t:
				found_poi = poi
				break
		if found_poi == null:
			continue
		match t:
			OverworldScript.POIType.ENTRADA_PAQUIME:
				_enter_paquime_dungeon(found_poi)
			OverworldScript.POIType.ENTRADA_TARAHUMARA:
				_enter_cave_dungeon(found_poi)
			OverworldScript.POIType.ENTRADA_NAICA:
				_enter_mine_dungeon(found_poi)
		await get_tree().create_timer(1.2).timeout
		_exit_to_overworld()
		await get_tree().create_timer(0.4).timeout


func _build_overworld_tileset() -> TileSet:
	# Multi-source TileSet: overworld atlas (src 0) + desert atlas (src 1)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SOURCE, TILE_SOURCE)

	# Source 0: overworld_tiles.png
	var src0 := TileSetAtlasSource.new()
	src0.texture = _load_texture("res://art/tiles/overworld_tiles.png")
	src0.texture_region_size = Vector2i(TILE_SOURCE, TILE_SOURCE)
	for x in range(ATLAS_OVERWORLD_COLS):
		for y in range(ATLAS_OVERWORLD_ROWS):
			src0.create_tile(Vector2i(x, y))
	ts.add_source(src0, 0)

	# Source 1: desert_tiles_clean.png
	var src1 := TileSetAtlasSource.new()
	src1.texture = _load_texture("res://art/tiles/desert_tiles_clean.png")
	src1.texture_region_size = Vector2i(TILE_SOURCE, TILE_SOURCE)
	for x in range(ATLAS_DESERT_COLS):
		for y in range(ATLAS_DESERT_ROWS):
			src1.create_tile(Vector2i(x, y))
	ts.add_source(src1, 1)

	# Source 2: afuera_clean.png (vegetación: arbustos, flores, rocas, hongos, tocones)
	var src2 := TileSetAtlasSource.new()
	src2.texture = _load_texture("res://art/tiles/afuera_clean.png")
	src2.texture_region_size = Vector2i(TILE_SOURCE, TILE_SOURCE)
	for x in range(ATLAS_AFUERA_COLS):
		for y in range(ATLAS_AFUERA_ROWS):
			src2.create_tile(Vector2i(x, y))
	ts.add_source(src2, 2)

	# Source 3: trees_topdown.png — árboles top-down propios con canopy real
	var src3 := TileSetAtlasSource.new()
	src3.texture = _load_texture("res://art/tiles/trees_topdown.png")
	src3.texture_region_size = Vector2i(TILE_SOURCE, TILE_SOURCE)
	for x in range(ATLAS_TREES_COLS):
		for y in range(ATLAS_TREES_ROWS):
			src3.create_tile(Vector2i(x, y))
	ts.add_source(src3, 3)

	return ts


func _build_dual_tileset(wall_path: String, wall_cols: int, wall_rows: int,
		floor_path: String, floor_cols: int, floor_rows: int, tile_px: int) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_px, tile_px)
	# Source 0: walls
	var src0 := TileSetAtlasSource.new()
	src0.texture = _load_texture(wall_path)
	src0.texture_region_size = Vector2i(tile_px, tile_px)
	for x in range(wall_cols):
		for y in range(wall_rows):
			src0.create_tile(Vector2i(x, y))
	ts.add_source(src0, 0)
	# Source 1: floor
	var src1 := TileSetAtlasSource.new()
	src1.texture = _load_texture(floor_path)
	src1.texture_region_size = Vector2i(tile_px, tile_px)
	for x in range(floor_cols):
		for y in range(floor_rows):
			src1.create_tile(Vector2i(x, y))
	ts.add_source(src1, 1)
	return ts


func _load_texture(res_path: String) -> Texture2D:
	var img := Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img == null:
		push_error("No pude cargar %s" % res_path)
		return null
	return ImageTexture.create_from_image(img)


# ============ OVERWORLD ============

func _regenerate_overworld() -> void:
	if regenerating:
		return  # guard contra spam de R durante async
	regenerating = true
	mode = Mode.OVERWORLD
	overworld_layer.visible = true
	overworld_decor_layer.visible = true
	dungeon_layer.visible = false
	cave_layer.visible = false
	mines_layer.visible = false
	dark_bg.visible = false
	canvas_modulate.color = Color(1, 1, 1, 1)  # luz natural
	player_light.enabled = false
	player.passable_decor = {}  # overworld no usa el dict
	player.set_mode(Mode.OVERWORLD)

	info.text = "Generando mundo de %dx%d tiles..." % [MAP_W, MAP_H]
	await get_tree().process_frame

	current_seed = randi()
	var ow := OverworldScript.new()
	var t0 := Time.get_ticks_msec()
	world = ow.generate(MAP_W, MAP_H, current_seed)
	var t_gen := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	await _paint_overworld(world)
	var t_paint := Time.get_ticks_msec() - t0

	var spawn_tile: Vector2i = _find_first_poi(OverworldScript.POIType.MATA_ORTIZ)
	if spawn_tile == Vector2i(-1, -1):
		spawn_tile = _find_safe_spawn(Vector2i(MAP_W / 2, MAP_H / 2))
	player.set_tile_position(spawn_tile)
	# Renderiza minimap con el nuevo mundo
	minimap.render(world)
	minimap.visible = true
	minimap_hint.visible = true
	_update_hud(t_gen, t_paint)
	await _save_screenshot("overworld")
	regenerating = false


func _find_safe_spawn(origin: Vector2i) -> Vector2i:
	# Spiral outward desde origin buscando un tile transitable (no río/barranca/pico).
	var max_r: int = maxi(MAP_W, MAP_H)
	for r in range(0, max_r):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var x: int = origin.x + dx
				var y: int = origin.y + dy
				if x < 4 or x >= MAP_W - 4 or y < 4 or y >= MAP_H - 4:
					continue
				if not world.in_bounds(x, y):
					continue
				var b: int = world.get_biome(x, y)
				if b == OverworldScript.Biome.RIO:
					continue
				if b == OverworldScript.Biome.BARRANCA:
					continue
				if b == OverworldScript.Biome.PICO:
					continue
				return Vector2i(x, y)
	return origin


func _paint_overworld(w) -> void:
	overworld_layer.clear()
	overworld_decor_layer.clear()
	# Chunked: yield every ~60k cells. Pinta BASE en overworld_layer,
	# DECOR (con fondo transparente) en overworld_decor_layer encima.
	var painted: int = 0
	for y in range(w.height):
		var row_off: int = y * w.width
		for x in range(w.width):
			# Base
			var v: int = w.tiles[row_off + x]
			var src: int = (v >> 16) & 0xff
			var atlas: Vector2i = Vector2i((v >> 8) & 0xff, v & 0xff)
			overworld_layer.set_cell(Vector2i(x, y), src, atlas)
			# Decor (solo si no es sentinel 0xff)
			var dv: int = w.decor_tiles[row_off + x]
			var dsrc: int = (dv >> 16) & 0xff
			if dsrc != 0xff:
				var datlas: Vector2i = Vector2i((dv >> 8) & 0xff, dv & 0xff)
				overworld_decor_layer.set_cell(Vector2i(x, y), dsrc, datlas)
			painted += 1
			if painted >= 60000:
				painted = 0
				await get_tree().process_frame


func _find_first_poi(type: int) -> Vector2i:
	for poi in world.pois:
		if poi.type == type:
			return poi.pos
	return Vector2i(-1, -1)


# ============ PAQUIMÉ ============

func _enter_paquime_dungeon(poi) -> void:
	mode = Mode.DUNGEON_PAQUIME
	overworld_layer.visible = false
	overworld_decor_layer.visible = false
	dungeon_layer.visible = true
	cave_layer.visible = false
	mines_layer.visible = false
	dark_bg.visible = true  # fondo oscuro fuera de la dungeon (era gris Godot default)
	canvas_modulate.color = Color(0.65, 0.60, 0.55, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.85, 0.55)
	player_light.texture_scale = 4.0
	minimap.visible = false
	minimap_hint.visible = false
	player.set_mode(Mode.DUNGEON_PAQUIME)
	active_dungeon_poi = poi
	saved_overworld_tile = player.get_current_tile()

	var dungeon_seed: int = current_seed ^ (poi.pos.x * 73856093) ^ (poi.pos.y * 19349663)
	var gen := BSPScript.new()
	var t0 := Time.get_ticks_msec()
	dungeon = gen.generate(DUN_W, DUN_H, dungeon_seed)
	var t_gen := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	_paint_dungeon(dungeon)
	var t_paint := Time.get_ticks_msec() - t0

	var entrance_tile: Vector2i = _find_first_tile_in_dungeon(BSPScript.T_ENTRANCE)
	if entrance_tile == Vector2i(-1, -1):
		entrance_tile = Vector2i(DUN_W / 2, DUN_H / 2)
	player.set_tile_position(entrance_tile)
	_update_hud(t_gen, t_paint)
	await _save_screenshot("dungeon_paquime")


func _find_first_tile_in_dungeon(target: Vector2i) -> Vector2i:
	for y in range(dungeon.height):
		for x in range(dungeon.width):
			if dungeon.get_tile(x, y) == target:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _paint_dungeon(dun) -> void:
	dungeon_layer.clear()
	# Pase 1: Pinta TODOS los floor cells con paquime_floor (source 1)
	#   detectando floor por NO ser muro (atlas != T_WALL)
	var WALL := BSPScript.T_WALL
	for y in range(dun.height):
		for x in range(dun.width):
			var tile: Vector2i = dun.get_tile(x, y)
			if tile != WALL and tile != BSPScript.T_VOID:
				# es piso/decoración — sub-floor con hash anti-checkerboard
				var h: int = ((x * 73856093) ^ (y * 19349663) ^ (dun.seed_value * 83492791))
				h = (h ^ (h >> 13)) & 0x7fffffff
				var variant: int = h % 4
				dungeon_layer.set_cell(Vector2i(x, y), 1, Vector2i(variant, 0))
	# Pase 2: Pinta walls + decoraciones (source 0) — sobreescribe sobre el floor donde haya wall
	for y in range(dun.height):
		for x in range(dun.width):
			var tile: Vector2i = dun.get_tile(x, y)
			if tile == BSPScript.T_VOID:
				continue
			# Si es FLOOR base (T_FLOOR), ya pintamos en pase 1 — saltar
			if tile == BSPScript.T_FLOOR:
				continue
			# Resto: wall, doors, decoraciones — pintar
			dungeon_layer.set_cell(Vector2i(x, y), 0, tile)


# ============ TARAHUMARA CAVE ============

func _enter_cave_dungeon(poi) -> void:
	mode = Mode.CAVE_TARAHUMARA
	overworld_layer.visible = false
	overworld_decor_layer.visible = false
	dungeon_layer.visible = false
	cave_layer.visible = true
	mines_layer.visible = false
	dark_bg.visible = true
	canvas_modulate.color = Color(0.20, 0.22, 0.30, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.92, 0.75)
	player_light.texture_scale = 3.5
	minimap.visible = false
	minimap_hint.visible = false
	player.set_mode(Mode.CAVE_TARAHUMARA)
	active_dungeon_poi = poi
	saved_overworld_tile = player.get_current_tile()

	var cave_seed: int = current_seed ^ (poi.pos.x * 12586093) ^ (poi.pos.y * 89469663)
	var gen := CaveScript.new()
	var t0 := Time.get_ticks_msec()
	cave = gen.generate(CAVE_W, CAVE_H, cave_seed)
	var t_gen := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	_paint_cave(cave)
	var t_paint := Time.get_ticks_msec() - t0

	player.set_tile_position(cave.spawn)
	_update_hud(t_gen, t_paint)
	await _save_screenshot("dungeon_cave")


func _paint_cave(c) -> void:
	cave_layer.clear()
	# Pase 1: FLOOR tiles (source 1) en todas las celdas piso
	for y in range(c.height):
		for x in range(c.width):
			if c.walls[y * c.width + x] == 0:
				# Hash mejorado para distribución no-cuadriculada
				var h: int = ((x * 73856093) ^ (y * 19349663) ^ (c.seed_value * 83492791))
				h = (h ^ (h >> 13)) & 0x7fffffff
				var variant: int = h % 4
				cave_layer.set_cell(Vector2i(x, y), 1, Vector2i(variant, 0))
	# Pase 2: WALL tiles (source 0) con autotile
	for y in range(c.height):
		for x in range(c.width):
			if c.walls[y * c.width + x] == 1:
				var v: Vector2i = CaveScript.get_tile_for(c, x, y)
				cave_layer.set_cell(Vector2i(x, y), 0, v)
	# Pase 3: scatter sobre piso — marca passable_decor para que el jugador pueda caminar
	player.passable_decor = {}
	for k in c.floor_scatter.keys():
		var pos: Vector2i = k
		var atlas: Vector2i = c.floor_scatter[k]
		cave_layer.set_cell(pos, 0, atlas)
		player.passable_decor[pos] = true


# ============ NAICA MINE ============

func _enter_mine_dungeon(poi) -> void:
	mode = Mode.MINE_NAICA
	overworld_layer.visible = false
	overworld_decor_layer.visible = false
	dungeon_layer.visible = false
	cave_layer.visible = false
	mines_layer.visible = true
	dark_bg.visible = true
	canvas_modulate.color = Color(0.18, 0.18, 0.25, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.78, 0.45)
	player_light.texture_scale = 4.0
	minimap.visible = false
	minimap_hint.visible = false
	player.set_mode(Mode.MINE_NAICA)
	active_dungeon_poi = poi
	saved_overworld_tile = player.get_current_tile()

	var mine_seed: int = current_seed ^ (poi.pos.x * 35586093) ^ (poi.pos.y * 24569663)
	var gen := MineScript.new()
	var t0 := Time.get_ticks_msec()
	mine = gen.generate(MINE_W, MINE_H, mine_seed)
	var t_gen := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	_paint_mine(mine)
	var t_paint := Time.get_ticks_msec() - t0

	player.set_tile_position(mine.spawn)
	_update_hud(t_gen, t_paint)
	await _save_screenshot("dungeon_mine")


func _paint_mine(m) -> void:
	mines_layer.clear()
	# Pase 1: FLOOR (source 1) en celdas piso
	for y in range(m.height):
		for x in range(m.width):
			if m.walls[y * m.width + x] == 0:
				var h: int = ((x * 73856093) ^ (y * 19349663) ^ (m.seed_value * 83492791))
				h = (h ^ (h >> 13)) & 0x7fffffff
				var variant: int = h % 4
				mines_layer.set_cell(Vector2i(x, y), 1, Vector2i(variant, 0))
	# Pase 2: WALLS (source 0) autotile
	for y in range(m.height):
		for x in range(m.width):
			if m.walls[y * m.width + x] == 1:
				var v: Vector2i = MineScript.get_tile_for(m, x, y)
				mines_layer.set_cell(Vector2i(x, y), 0, v)
	# Pase 3: Decoraciones SOLO en celdas piso, marcadas como passable_decor
	player.passable_decor = {}
	for k in m.decor.keys():
		var pos: Vector2i = k
		# Skip si por algún bug cayó en wall
		if pos.x < 0 or pos.x >= m.width or pos.y < 0 or pos.y >= m.height:
			continue
		if m.walls[pos.y * m.width + pos.x] == 1:
			continue  # no pintar decor sobre walls
		var atlas: Vector2i = m.decor[k]
		mines_layer.set_cell(pos, 0, atlas)
		player.passable_decor[pos] = true


# ============ EXIT ============

func _exit_to_overworld() -> void:
	mode = Mode.OVERWORLD
	overworld_layer.visible = true
	overworld_decor_layer.visible = true
	dungeon_layer.visible = false
	cave_layer.visible = false
	mines_layer.visible = false
	dark_bg.visible = false
	canvas_modulate.color = Color(1, 1, 1, 1)
	player_light.enabled = false
	player.passable_decor = {}
	minimap.visible = true
	minimap_hint.visible = true
	player.set_mode(Mode.OVERWORLD)
	# Salir al sur de la entrada — pero si esa celda es impasable, spiral search.
	var target := saved_overworld_tile + Vector2i(0, 1)
	target = _find_safe_spawn(target)
	player.set_tile_position(target)
	_update_hud(0, 0)


# ============ HUD / INPUT ============

func _update_hud(t_gen: int, t_paint: int) -> void:
	match mode:
		Mode.OVERWORLD:
			var counts := {}
			for poi in world.pois:
				counts[poi.type] = counts.get(poi.type, 0) + 1
			var summary := "Mata Ortiz:%d  Misión:%d  Cementerio:%d  Paquimé:%d  Tarahumara:%d  Naica:%d" % [
				counts.get(OverworldScript.POIType.MATA_ORTIZ, 0),
				counts.get(OverworldScript.POIType.MISION, 0),
				counts.get(OverworldScript.POIType.CEMENTERIO, 0),
				counts.get(OverworldScript.POIType.ENTRADA_PAQUIME, 0),
				counts.get(OverworldScript.POIType.ENTRADA_TARAHUMARA, 0),
				counts.get(OverworldScript.POIType.ENTRADA_NAICA, 0),
			]
			info.text = "Norte Profundo — OVERWORLD  |  %dx%d  |  Seed:%d  |  gen %dms paint %dms\n%s\n[WASD] mover  [Space] entrar mazmorra  [R] regenerar mundo  [Esc] salir" % [
				MAP_W, MAP_H, current_seed, t_gen, t_paint, summary
			]
		Mode.DUNGEON_PAQUIME:
			info.text = "Norte Profundo — PAQUIMÉ  |  %dx%d  |  Cuartos:%d  |  gen %dms paint %dms\n[WASD] mover  [Backspace] salir al overworld" % [
				DUN_W, DUN_H, dungeon.rooms.size(), t_gen, t_paint
			]
		Mode.CAVE_TARAHUMARA:
			info.text = "Norte Profundo — CUEVA TARAHUMARA  |  %dx%d  |  gen %dms paint %dms\n[WASD] mover  [Backspace] salir  Spawn:(%d,%d)  Exit:(%d,%d)" % [
				CAVE_W, CAVE_H, t_gen, t_paint, cave.spawn.x, cave.spawn.y, cave.exit_pos.x, cave.exit_pos.y
			]
		Mode.MINE_NAICA:
			info.text = "Norte Profundo — MINA NAICA  |  %dx%d  |  gen %dms paint %dms\n[WASD] mover  [Backspace] salir  Spawn:(%d,%d)  Exit:(%d,%d)  Decor:%d" % [
				MINE_W, MINE_H, t_gen, t_paint, mine.spawn.x, mine.spawn.y, mine.exit_pos.x, mine.exit_pos.y, mine.decor.size()
			]


func _process(_delta: float) -> void:
	_update_prompt()


func _update_prompt() -> void:
	var atlas: Vector2i = player.get_current_atlas()
	if mode == Mode.OVERWORLD:
		match atlas:
			Vector2i(5, 3):
				prompt.text = "[SPACE] Entrar a las ruinas de Paquimé"
			Vector2i(6, 3):
				prompt.text = "[SPACE] Entrar a la cueva Tarahumara"
			Vector2i(7, 3):
				prompt.text = "[SPACE] Entrar a la mina de Naica"
			Vector2i(2, 3):
				prompt.text = "Mata Ortiz — pueblo de cerámica"
			Vector2i(3, 3):
				prompt.text = "Misión jesuita"
			Vector2i(4, 3):
				prompt.text = "Cementerio"
			_:
				prompt.text = ""
	elif mode == Mode.DUNGEON_PAQUIME:
		if atlas == BSPScript.T_EXIT:
			prompt.text = "[SPACE] Salir al overworld"
		else:
			prompt.text = ""
	elif mode == Mode.CAVE_TARAHUMARA or mode == Mode.MINE_NAICA:
		# null-safe (en transición puede no haber cave/mine todavía)
		if mode == Mode.CAVE_TARAHUMARA and cave == null:
			prompt.text = ""
			return
		if mode == Mode.MINE_NAICA and mine == null:
			prompt.text = ""
			return
		var t: Vector2i = player.get_current_tile()
		var ex: Vector2i = cave.exit_pos if mode == Mode.CAVE_TARAHUMARA else mine.exit_pos
		var dx: int = t.x - ex.x
		var dy: int = t.y - ex.y
		if dx * dx + dy * dy <= 2:
			prompt.text = "[SPACE] Salir al overworld"
		else:
			prompt.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_handle_interact()
			KEY_R:
				if mode == Mode.OVERWORLD and not regenerating:
					_regenerate_overworld()
			KEY_BACKSPACE:
				if mode != Mode.OVERWORLD:
					_exit_to_overworld()
			KEY_ESCAPE:
				get_tree().quit()
			KEY_Q:
				camera.zoom *= 0.85
				_clamp_zoom()
			KEY_E:
				camera.zoom *= 1.18
				_clamp_zoom()
			KEY_M:
				# Solo togglear minimap en overworld (oculto en dungeons)
				if mode == Mode.OVERWORLD:
					_toggle_minimap()
			KEY_F12:
				if mode == Mode.OVERWORLD:
					_auto_tour()


func _handle_interact() -> void:
	if mode == Mode.OVERWORLD:
		var atlas: Vector2i = player.get_current_atlas()
		var tile: Vector2i = player.get_current_tile()
		match atlas:
			Vector2i(5, 3):  # Paquimé
				for poi in world.pois:
					if poi.type == OverworldScript.POIType.ENTRADA_PAQUIME and poi.pos == tile:
						_enter_paquime_dungeon(poi)
						return
			Vector2i(6, 3):  # Tarahumara
				for poi in world.pois:
					if poi.type == OverworldScript.POIType.ENTRADA_TARAHUMARA and poi.pos == tile:
						_enter_cave_dungeon(poi)
						return
			Vector2i(7, 3):  # Naica
				for poi in world.pois:
					if poi.type == OverworldScript.POIType.ENTRADA_NAICA and poi.pos == tile:
						_enter_mine_dungeon(poi)
						return
	elif mode == Mode.DUNGEON_PAQUIME:
		var atlas2: Vector2i = player.get_current_atlas()
		if atlas2 == BSPScript.T_EXIT:
			_exit_to_overworld()
	elif mode == Mode.CAVE_TARAHUMARA or mode == Mode.MINE_NAICA:
		# Salir si cerca de exit (null-safe)
		if mode == Mode.CAVE_TARAHUMARA and cave == null:
			return
		if mode == Mode.MINE_NAICA and mine == null:
			return
		var t: Vector2i = player.get_current_tile()
		var ex: Vector2i = cave.exit_pos if mode == Mode.CAVE_TARAHUMARA else mine.exit_pos
		var dx: int = t.x - ex.x
		var dy: int = t.y - ex.y
		if dx * dx + dy * dy <= 2:
			_exit_to_overworld()


func _clamp_zoom() -> void:
	camera.zoom.x = clampf(camera.zoom.x, ZOOM_MIN, ZOOM_MAX)
	camera.zoom.y = clampf(camera.zoom.y, ZOOM_MIN, ZOOM_MAX)


func _toggle_minimap() -> void:
	minimap_large = not minimap_large
	_apply_minimap_size()


func _apply_minimap_size() -> void:
	# Usa viewport real (no hardcode 1280/720) por si la ventana cambia
	var vp: Vector2 = get_viewport_rect().size
	if minimap_large:
		minimap.size = MINI_LARGE
		minimap.position = Vector2((vp.x - MINI_LARGE.x) / 2, (vp.y - MINI_LARGE.y) / 2)
		minimap_hint.text = "[M] minimapa chico"
		minimap_hint.position = Vector2(minimap.position.x, minimap.position.y + MINI_LARGE.y + 4)
	else:
		minimap.size = MINI_SMALL
		minimap.position = Vector2(vp.x - MINI_SMALL.x - 10, 100)
		minimap_hint.text = "[M] agrandar minimapa"
		minimap_hint.position = Vector2(vp.x - MINI_SMALL.x - 10, 100 + MINI_SMALL.y + 4)
	minimap.queue_redraw()


func _save_screenshot(shot_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	# Preferir user:// para que funcione en exports (no solo editor); fallback a res://
	var dir_path := ProjectSettings.globalize_path("user://screenshots")
	var mk_err: int = DirAccess.make_dir_recursive_absolute(dir_path)
	if mk_err != OK:
		dir_path = ProjectSettings.globalize_path("res://screenshots")
		DirAccess.make_dir_recursive_absolute(dir_path)
	var save_err: int = img.save_png(dir_path + "/%s.png" % shot_name)
	if save_err != OK:
		push_warning("Screenshot save failed: %s/%s.png err=%d" % [dir_path, shot_name, save_err])
