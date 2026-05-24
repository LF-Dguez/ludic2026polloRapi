
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
const EnemySpawnerScript := preload("res://scripts/EnemySpawner.gd")
const SaveManagerScript := preload("res://scripts/SaveManager.gd")
const BossScript := preload("res://scripts/Boss.gd")
 
var music_player: AudioStreamPlayer = null
 
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
const ATLAS_BASES_COLS := 8
const ATLAS_BASES_ROWS := 4
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
@onready var trees_container: Node2D = $TreesContainer
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
# Roguelike progression: POIs de mazmorra completados (Array[Vector2i])
var cleared_dungeons: Array = []
# Stats globales (persistidos)
var stats_kills: int = 0
var stats_runs: int = 0
# Inventory (Array[Dictionary {type, count}])
var inventory: Array = []
# Save data cargado al inicio (null si new game)
var _pending_load: Dictionary = {}
var _loaded_from_save: bool = false
var world  # Overworld.World
var dungeon  # BSPGenerator.Dungeon
var cave  # CaveGenerator.Cave
var mine  # MineGenerator.Mine
 
# Guard contra regeneraciones concurrentes (spam de R)
var regenerating: bool = false
 
# Textura del atlas de trees grandes (Sprite2D)
var _trees_big_tex: Texture2D = null
const TREE_SOURCE_SIZE := 32  # cada tile en trees_big.png es 32x32
const TREE_DISPLAY_SCALE := 4.0  # source 32 × scale 4 = 128px display = 2× player
 
# Enemy sprite frames (cached)
var _bandido_frames: SpriteFrames = null
var _fantasma_frames: SpriteFrames = null
# Container para enemigos (parent común para fácil cleanup)
var _enemies_container: Node2D = null
# Tracking de cementerios ya poblados (poi.pos → true)
var _cementerios_spawned: Dictionary = {}
 
var saved_overworld_tile: Vector2i = Vector2i.ZERO
var active_dungeon_poi: Variant = null
 
# Camera shake
var _shake_t: float = 0.0
var _shake_amp: float = 0.0
var _shake_seed: float = 0.0
# Active boss reference (uno por dungeon)
var _active_boss: Node = null
# UIs creadas en runtime
var _boss_bar = null
var _victory_screen = null
var _xp_bar = null
var _level_popup = null
var _achievements = null
var _weapon_label_ref: Label = null
var _fog: CanvasLayer = null
# Title screen state (instance vars porque lambdas no capturan locales por ref)
var _title_choice: String = "new"
var _title_done: bool = false
 
# Music of the world
var _music_dungeon: AudioStream = preload("res://audio/music/dungeonmusic.mp3")
var _music_overworld: AudioStream = preload("res://audio/music/exteriormusic.mp3")
 
# ─── Random overworld enemy spawning ─────────────────────────────────
const OVERWORLD_ENEMY_CAP := 14
const OVERWORLD_SPAWN_MIN_DIST := 220.0  # no spawn pegado al player
const OVERWORLD_SPAWN_MAX_DIST := 480.0  # no spawn fuera de pantalla lejos
const OVERWORLD_DESPAWN_DIST := 950.0
var _overworld_spawn_cd: float = 3.0
 
 
func _on_title_start() -> void:
	_title_choice = "new"
	_title_done = true
 
 
func _on_title_load() -> void:
	_title_choice = "load"
	_title_done = true
 
 
func _on_title_quit() -> void:
	get_tree().quit()
 
 
func _weapon_label_update(wid: String) -> void:
	if _weapon_label_ref == null:
		return
	var def: Dictionary = Player.WEAPONS.get(wid, {})
	_weapon_label_ref.text = "[Tab] Arma: %s" % def.get("name", wid)
 
 
func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	
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
	# Carga atlas de trees grandes para Sprite2D spawn
	_trees_big_tex = _load_texture("res://art/tiles/trees_big.png")
	# Pre-build SpriteFrames para enemigos (cached)
	var bandido_tex := _load_texture("res://sprites/npc's/BandidoMalo.png")
	var fantasma_tex := _load_texture("res://sprites/npc's/Fantasmiota.png")
	if bandido_tex != null:
		_bandido_frames = EnemySpawnerScript.build_bandido_frames(bandido_tex)
	if fantasma_tex != null:
		_fantasma_frames = EnemySpawnerScript.build_fantasma_frames(fantasma_tex)
	# Container para enemigos (oculto en overworld al spawnear, visible al entrar)
	_enemies_container = Node2D.new()
	_enemies_container.name = "EnemiesContainer"
	_enemies_container.z_index = 8
	add_child(_enemies_container)
	# HUD por encima de la niebla (layer 10), niebla en layer 2
	var hud := get_node("HUD") as CanvasLayer
	if hud != null:
		hud.layer = 10
	# FogOverlay — niebla atmosférica
	var fog_script = load("res://scripts/FogOverlay.gd")
	_fog = fog_script.new()
	_fog.name = "FogOverlay"
	add_child(_fog)
	# (continúa setup HUD)
	if hud != null:
		# HotbarUI — al lado de los corazones (bottom-left + offset right)
		var hb_script = load("res://scripts/HotbarUI.gd")
		var hotbar = hb_script.new()
		hotbar.name = "HotbarUI"
		var vp_hb: Vector2 = get_viewport_rect().size
		hotbar.set("offset_left", 8.0 + 10 * 56.0 + 24.0)
		hotbar.set("offset_top", vp_hb.y - 80.0)
		hotbar.set("offset_right", 8.0 + 10 * 56.0 + 24.0 + 4 * 64.0)
		hotbar.set("offset_bottom", vp_hb.y - 8.0)
		hud.add_child(hotbar)
		if "inventory" in player and player.inventory != null:
			hotbar.bind_inventory(player.inventory)
		# WeaponLabel — muestra arma actual encima del hotbar
		var weapon_lbl := Label.new()
		weapon_lbl.name = "WeaponLabel"
		weapon_lbl.add_theme_font_size_override("font_size", 14)
		weapon_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		weapon_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
		weapon_lbl.add_theme_constant_override("shadow_offset_x", 1)
		weapon_lbl.add_theme_constant_override("shadow_offset_y", 1)
		weapon_lbl.text = "[Q/E] Arma: Machete"
		weapon_lbl.set("offset_left", 8.0 + 10 * 56.0 + 24.0)
		weapon_lbl.set("offset_top", vp_hb.y - 100.0)
		weapon_lbl.set("offset_right", 8.0 + 10 * 56.0 + 24.0 + 240.0)
		weapon_lbl.set("offset_bottom", vp_hb.y - 80.0)
		hud.add_child(weapon_lbl)
		if player.has_signal("weapon_changed") and not player.weapon_changed.is_connected(_weapon_label_update):
			# Guarda label via closure
			_weapon_label_ref = weapon_lbl
			player.weapon_changed.connect(_weapon_label_update)
		weapon_lbl.text = "[Tab] Arma: Machete"
		# PauseMenu
		var pm_script = load("res://scripts/PauseMenu.gd")
		var pause_menu = pm_script.new()
		pause_menu.name = "PauseMenu"
		pause_menu.set("offset_left", 0.0)
		pause_menu.set("offset_top", 0.0)
		pause_menu.set("offset_right", get_viewport_rect().size.x)
		pause_menu.set("offset_bottom", get_viewport_rect().size.y)
		hud.add_child(pause_menu)
		pause_menu.save_pressed.connect(_save_game)
		pause_menu.load_pressed.connect(_load_game)
		pause_menu.new_game_pressed.connect(_on_new_game_requested)
		# InventoryPanel
		var ip_script = load("res://scripts/InventoryPanel.gd")
		var inv_panel = ip_script.new()
		inv_panel.name = "InventoryPanel"
		inv_panel.set("offset_left", 0.0)
		inv_panel.set("offset_top", 0.0)
		inv_panel.set("offset_right", get_viewport_rect().size.x)
		inv_panel.set("offset_bottom", get_viewport_rect().size.y)
		hud.add_child(inv_panel)
		if "inventory" in player and player.inventory != null:
			inv_panel.bind(player.inventory, player)
		var hearts_script = load("res://scripts/HeartsUI.gd")
		var hearts = hearts_script.new()
		hearts.name = "HeartsUI"
		# Esquina superior derecha — pequeños, encima del minimapa
		var vp: Vector2 = get_viewport_rect().size
		var heart_w: float = 24.0
		var heart_spacing: float = 4.0
		var total_w: float = 10 * (heart_w + heart_spacing)
		var bar_h: float = 24.0
		hearts.set("offset_left", vp.x - total_w - 12.0)
		hearts.set("offset_top", 12.0)
		hearts.set("offset_right", vp.x - 12.0)
		hearts.set("offset_bottom", 12.0 + bar_h)
		hud.add_child(hearts)
		# Conecta señal HP del player
		if player.has_signal("hp_changed"):
			player.hp_changed.connect(func(hp, max_hp): hearts.set_hp(hp, max_hp))
		# Death: muestra GameOverScreen
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		# GameOverScreen
		var go_script = load("res://scripts/GameOverScreen.gd")
		var go = go_script.new()
		go.name = "GameOverScreen"
		go.set("offset_left", 0.0)
		go.set("offset_top", 0.0)
		go.set("offset_right", get_viewport_rect().size.x)
		go.set("offset_bottom", get_viewport_rect().size.y)
		hud.add_child(go)
		go.respawn_requested.connect(_on_respawn_requested)
		go.new_game_requested.connect(_on_new_game_requested)
		# Boss HP bar
		var bb_script = load("res://scripts/BossHPBar.gd")
		_boss_bar = bb_script.new()
		_boss_bar.name = "BossHPBar"
		_boss_bar.set("offset_left", 0.0)
		_boss_bar.set("offset_top", 0.0)
		_boss_bar.set("offset_right", get_viewport_rect().size.x)
		_boss_bar.set("offset_bottom", 80.0)
		hud.add_child(_boss_bar)
		# Victory screen
		var vs_script = load("res://scripts/VictoryScreen.gd")
		_victory_screen = vs_script.new()
		_victory_screen.name = "VictoryScreen"
		_victory_screen.set("offset_left", 0.0)
		_victory_screen.set("offset_top", 0.0)
		_victory_screen.set("offset_right", get_viewport_rect().size.x)
		_victory_screen.set("offset_bottom", get_viewport_rect().size.y)
		hud.add_child(_victory_screen)
		# XP bar
		var xp_script = load("res://scripts/XPBar.gd")
		_xp_bar = xp_script.new()
		_xp_bar.name = "XPBar"
		hud.add_child(_xp_bar)
		_xp_bar.level_up.connect(_on_level_up)
		# Level-up popup
		var lp_script = load("res://scripts/LevelUpPopup.gd")
		_level_popup = lp_script.new()
		_level_popup.name = "LevelUpPopup"
		_level_popup.set("offset_left", 0.0)
		_level_popup.set("offset_top", 0.0)
		_level_popup.set("offset_right", get_viewport_rect().size.x)
		_level_popup.set("offset_bottom", get_viewport_rect().size.y)
		hud.add_child(_level_popup)
		# Achievements
		var ach_script = load("res://scripts/AchievementSystem.gd")
		_achievements = ach_script.new()
		_achievements.name = "AchievementSystem"
		_achievements.set("offset_left", 0.0)
		_achievements.set("offset_top", 0.0)
		_achievements.set("offset_right", get_viewport_rect().size.x)
		_achievements.set("offset_bottom", get_viewport_rect().size.y)
		hud.add_child(_achievements)
		# Enemy kill signal → XP + achievements
		if player.has_signal("enemy_killed"):
			player.enemy_killed.connect(_on_enemy_killed)
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
	# Pantalla de título primero — esperar input del jugador
	var ts_script = load("res://scripts/TitleScreen.gd")
	var title = ts_script.new()
	title.name = "TitleScreen"
	add_child(title)
	_title_choice = "new"
	_title_done = false
	title.start_pressed.connect(_on_title_start)
	title.load_pressed.connect(_on_title_load)
	title.quit_pressed.connect(_on_title_quit)
	while not _title_done:
		await get_tree().process_frame
	title.dismiss()
	# Si eligió cargar, intentar leer save
	if _title_choice == "load":
		var loaded = SaveManagerScript.load_from_disk()
		if loaded != null:
			_pending_load = loaded
			_loaded_from_save = true
			cleared_dungeons = loaded.get("cleared", [])
			stats_kills = loaded.get("kills", 0)
			stats_runs = loaded.get("runs", 0)
			inventory = loaded.get("inventory", [])
			print("[Save] Cargado save: seed=%d cleared=%d kills=%d runs=%d" % [
				loaded.get("seed", 0), cleared_dungeons.size(), stats_kills, stats_runs
			])
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
 
	# Source 4: biome_bases.png — bases SUAVES uniformes por bioma (no tile-able artifacts)
	var src4 := TileSetAtlasSource.new()
	src4.texture = _load_texture("res://art/tiles/biome_bases.png")
	src4.texture_region_size = Vector2i(TILE_SOURCE, TILE_SOURCE)
	for x in range(ATLAS_BASES_COLS):
		for y in range(ATLAS_BASES_ROWS):
			src4.create_tile(Vector2i(x, y))
	ts.add_source(src4, 4)
 
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
	var tex = load(res_path)
	if tex == null:
		push_error("No pude cargar %s" % res_path)
		return null
	if tex is Texture2D:
		return tex
	if tex is Image:
		return ImageTexture.create_from_image(tex)
	return null
 
 
# ============ OVERWORLD ============
 
func _regenerate_overworld() -> void:
	if regenerating:
		return  # guard contra spam de R durante async
	regenerating = true
	mode = Mode.OVERWORLD
	overworld_layer.visible = true
	overworld_decor_layer.visible = true
	trees_container.visible = true
	dungeon_layer.visible = false
	cave_layer.visible = false
	mines_layer.visible = false
	dark_bg.visible = false
	# NOCHE: penumbra azul profunda + luz cálida del jugador (linterna)
	canvas_modulate.color = Color(0.08, 0.10, 0.18, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.85, 0.55)
	player_light.energy = 1.0
	player_light.texture_scale = 2.5
	if _fog != null and _fog.has_method("set_intensity"):
		_fog.set_intensity(0)
	player.passable_decor = {}  # overworld no usa el dict
	player.set_mode(Mode.OVERWORLD)
 
	info.text = "Generando mundo de %dx%d tiles..." % [MAP_W, MAP_H]
	await get_tree().process_frame
 
	# Si veníamos de save, usa el seed guardado (mismo mundo). Sino random.
	if _loaded_from_save and _pending_load.has("seed"):
		current_seed = int(_pending_load["seed"])
		# Restaura upgrades permanentes ANTES de reset_hp para max correcto
		player.max_hp_bonus = int(_pending_load.get("max_hp_bonus", 0))
		player.damage_bonus = int(_pending_load.get("damage_bonus", 0))
		player.speed_bonus = float(_pending_load.get("speed_bonus", 0.0))
		player.crit_chance = float(_pending_load.get("crit_chance", 0.10))
		# Aplica HP al player
		if player.has_method("reset_hp"):
			player.reset_hp()
		var loaded_hp: int = int(_pending_load.get("hp", 10))
		# fuerza HP exacto cargado (reset_hp pone max; sustraemos diff)
		var diff: int = player.get_max_hp() - loaded_hp
		if diff > 0:
			player.current_hp = loaded_hp
			if player.has_signal("hp_changed"):
				player.hp_changed.emit(player.current_hp, player.get_max_hp())
		# Restaura inventory
		var inv_arr: Array = _pending_load.get("inventory", [])
		if player.inventory != null and inv_arr.size() > 0:
			player.inventory.from_array(inv_arr)
		# Restaura XP + achievements
		if _xp_bar != null:
			_xp_bar.set_state({
				"level": _pending_load.get("xp_level", 1),
				"xp": _pending_load.get("xp_current", 0),
			})
		if _achievements != null:
			_achievements.set_state({"unlocked": _pending_load.get("achievements", [])})
		_loaded_from_save = false  # solo aplicar 1 vez
	else:
		current_seed = randi()
	var ow := OverworldScript.new()
	var t0 := Time.get_ticks_msec()
	world = ow.generate(MAP_W, MAP_H, current_seed)
	var t_gen := Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	await _paint_overworld(world)
	var t_paint := Time.get_ticks_msec() - t0
 
	# Spawn: si hay save con tile_pos válido, usarlo; sino Mata Ortiz
	var spawn_tile: Vector2i
	if _pending_load.has("tile_pos") and (_pending_load["tile_pos"] as Vector2i) != Vector2i.ZERO:
		spawn_tile = _find_safe_spawn(_pending_load["tile_pos"])
	else:
		spawn_tile = _find_first_poi(OverworldScript.POIType.MATA_ORTIZ)
		if spawn_tile == Vector2i(-1, -1):
			spawn_tile = _find_safe_spawn(Vector2i(MAP_W / 2, MAP_H / 2))
	player.set_tile_position(spawn_tile)
	_pending_load.clear()
	# Renderiza minimap con el nuevo mundo
	minimap.render(world)
	minimap.visible = true
	minimap_hint.visible = true
	_update_hud(t_gen, t_paint)
	_play_music(_music_overworld)
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
	_clear_trees()
	_spawn_trees(w)
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
 
func _play_music(stream: AudioStream, volume_db: float = -6.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return  # ya está sonando, no reiniciar
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()
 
# ============ PAQUIMÉ ============
 
func _enter_paquime_dungeon(poi) -> void:
	mode = Mode.DUNGEON_PAQUIME
	overworld_layer.visible = false
	overworld_decor_layer.visible = false
	trees_container.visible = false
	dungeon_layer.visible = true
	cave_layer.visible = false
	mines_layer.visible = false
	dark_bg.visible = true  # fondo oscuro fuera de la dungeon (era gris Godot default)
	# PENUMBRA cálida + linterna íntima
	canvas_modulate.color = Color(0.07, 0.06, 0.05, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.78, 0.45)
	player_light.energy = 1.2
	player_light.texture_scale = 2.4
	if _fog != null and _fog.has_method("set_intensity"):
		_fog.set_intensity(1)
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
	_clear_enemies()
	_spawn_enemies_paquime(dungeon)
	# Boss en el cuarto exit — siempre respawna (roguelike)
	var exit_tile: Vector2i = _find_first_tile_in_dungeon(BSPScript.T_EXIT)
	if exit_tile != Vector2i(-1, -1):
		_spawn_boss("senor_paquime", exit_tile, dungeon_layer, 1)
	_update_hud(t_gen, t_paint)
	_play_music(_music_dungeon)
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
	trees_container.visible = false
	dungeon_layer.visible = false
	cave_layer.visible = true
	mines_layer.visible = false
	dark_bg.visible = true
	# PENUMBRA cueva — casi negro azulado
	canvas_modulate.color = Color(0.05, 0.06, 0.10, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.92, 0.75)
	player_light.energy = 1.1
	player_light.texture_scale = 2.2
	if _fog != null and _fog.has_method("set_intensity"):
		_fog.set_intensity(2)
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
	_clear_enemies()
	_spawn_enemies_cave(cave)
	_spawn_boss("bestia_cobre", cave.exit_pos, cave_layer, 2)
	_update_hud(t_gen, t_paint)
	_play_music(_music_dungeon)
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
	trees_container.visible = false
	dungeon_layer.visible = false
	cave_layer.visible = false
	mines_layer.visible = true
	dark_bg.visible = true
	# PENUMBRA mina — casi negro frío con tinte morado
	canvas_modulate.color = Color(0.04, 0.05, 0.10, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.78, 0.45)
	player_light.energy = 1.2
	player_light.texture_scale = 2.5
	if _fog != null and _fog.has_method("set_intensity"):
		_fog.set_intensity(3)
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
	_clear_enemies()
	_spawn_enemies_mine(mine)
	_spawn_boss("espectro_cristal", mine.exit_pos, mines_layer, 3)
	_update_hud(t_gen, t_paint)
	_play_music(_music_dungeon)
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
 
func _on_dungeon_exited_for_clear() -> void:
	# Llamado desde _exit_to_overworld para marcar el dungeon visitado como cleared.
	if active_dungeon_poi != null:
		_mark_dungeon_cleared(active_dungeon_poi.pos)
 
 
func _exit_to_overworld() -> void:
	_on_dungeon_exited_for_clear()
	mode = Mode.OVERWORLD
	overworld_layer.visible = true
	overworld_decor_layer.visible = true
	trees_container.visible = true
	dungeon_layer.visible = false
	cave_layer.visible = false
	mines_layer.visible = false
	# Limpia enemigos del dungeon (overworld reactiva fantasmas de cementerios via _process)
	_clear_enemies()
	dark_bg.visible = false
	# Restaura noche del overworld al salir de mazmorra
	canvas_modulate.color = Color(0.08, 0.10, 0.18, 1)
	player_light.enabled = true
	player_light.color = Color(1.0, 0.85, 0.55)
	player_light.energy = 1.0
	player_light.texture_scale = 2.5
	if _fog != null and _fog.has_method("set_intensity"):
		_fog.set_intensity(0)
	player.passable_decor = {}
	minimap.visible = true
	minimap_hint.visible = true
	player.set_mode(Mode.OVERWORLD)
	# Salir al sur de la entrada — pero si esa celda es impasable, spiral search.
	var target := saved_overworld_tile + Vector2i(0, 1)
	target = _find_safe_spawn(target)
	player.set_tile_position(target)
	_update_hud(0, 0)
	_play_music(_music_overworld)
 
 
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
			info.text = "Norte Profundo — OVERWORLD  |  %dx%d  |  Seed:%d  |  gen %dms paint %dms\n%s\n[WASD] mover  [Shift] esquivar  [Space] entrar  [I] inventario  [Esc/P] pausa  [R] regenerar" % [
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
 
 
func _process(delta: float) -> void:
	_update_prompt()
	_check_cementerio_spawns()
	_check_overworld_random_spawns(delta)
	_update_camera_shake(delta)
	_check_achievements()
 
 
# ─── Random overworld enemy spawn ────────────────────────────────────
func _check_overworld_random_spawns(delta: float) -> void:
	if mode != Mode.OVERWORLD or world == null or player == null:
		return
	_overworld_spawn_cd -= delta
	# Despawn enemigos lejanos (libera memoria + count)
	_despawn_far_overworld_enemies()
	if _overworld_spawn_cd > 0.0:
		return
	_overworld_spawn_cd = randf_range(4.5, 8.5)
	# Conteo de enemies non-boss
	var count: int = 0
	for c in _enemies_container.get_children():
		if c.is_in_group("enemigo") and not c.is_in_group("boss"):
			count += 1
	if count >= OVERWORLD_ENEMY_CAP:
		return
	# Random angle + dist alrededor del player
	var attempts: int = 0
	while attempts < 10:
		attempts += 1
		var angle: float = randf() * TAU
		var dist: float = randf_range(OVERWORLD_SPAWN_MIN_DIST, OVERWORLD_SPAWN_MAX_DIST)
		var spawn_world: Vector2 = player.position + Vector2(cos(angle), sin(angle)) * dist
		var tx: int = int(spawn_world.x / float(TILE_DISPLAY))
		var ty: int = int(spawn_world.y / float(TILE_DISPLAY))
		if not world.in_bounds(tx, ty):
			continue
		var b: int = world.get_biome(tx, ty)
		# Skip biomas impasables
		if b == OverworldScript.Biome.RIO: continue
		if b == OverworldScript.Biome.BARRANCA: continue
		if b == OverworldScript.Biome.PICO: continue
		# 65% bandido, 35% fantasma (bandidos más comunes de día/desierto)
		if randf() < 0.65 and _bandido_frames != null:
			EnemySpawnerScript.spawn_bandido(_enemies_container, spawn_world, _bandido_frames, overworld_layer, 0)
		elif _fantasma_frames != null:
			EnemySpawnerScript.spawn_fantasma(_enemies_container, spawn_world, _fantasma_frames, overworld_layer, 0)
		return  # spawn exitoso
 
 
func _despawn_far_overworld_enemies() -> void:
	if player == null:
		return
	var pp: Vector2 = player.position
	for c in _enemies_container.get_children():
		if not c.is_in_group("enemigo"):
			continue
		if c.is_in_group("boss"):
			continue
		if pp.distance_to(c.global_position) > OVERWORLD_DESPAWN_DIST:
			c.queue_free()
 
 
# ─── Camera shake ────────────────────────────────────────────────────
func camera_shake(amplitude: float, duration: float) -> void:
	_shake_amp = maxf(_shake_amp, amplitude)
	_shake_t = maxf(_shake_t, duration)
	if _shake_seed == 0.0:
		_shake_seed = randf() * 1000.0
 
 
func _update_camera_shake(delta: float) -> void:
	if camera == null:
		return
	if _shake_t > 0.0:
		_shake_t -= delta
		var t: float = Time.get_ticks_msec() * 0.05 + _shake_seed
		camera.offset = Vector2(
			sin(t * 0.9) * _shake_amp,
			cos(t * 1.3) * _shake_amp
		)
		if _shake_t <= 0.0:
			camera.offset = Vector2.ZERO
			_shake_amp = 0.0
 
 
# ─── XP / Level ───────────────────────────────────────────────────────
func _on_enemy_killed(enemy_type: String, xp_value: int) -> void:
	stats_kills += 1
	if _xp_bar != null:
		_xp_bar.add_xp(xp_value)
 
 
func _on_level_up(new_level: int) -> void:
	# Cada nivel: +1 max HP + dmg cada 3 niveles + crit chance escalable
	if player == null:
		return
	player.max_hp_bonus += 1
	player.current_hp += 1  # restaura 1 al subir
	if new_level % 3 == 0:
		player.damage_bonus += 1
	player.crit_chance = minf(0.40, player.crit_chance + 0.02)
	if player.has_signal("hp_changed"):
		player.hp_changed.emit(player.current_hp, player.get_max_hp())
	var bonus_txt := "+1 HP máx"
	if new_level % 3 == 0:
		bonus_txt += "   +1 daño"
	bonus_txt += "   +2%% crit"
	if _level_popup != null:
		_level_popup.show_level(new_level, bonus_txt)
	# Achievements de nivel
	if _achievements != null:
		if new_level >= 5: _achievements.unlock("level_5")
		if new_level >= 10: _achievements.unlock("level_10")
 
 
# ─── Achievements check (cada frame, cheap) ──────────────────────────
func _check_achievements() -> void:
	if _achievements == null:
		return
	if stats_kills >= 1:
		_achievements.unlock("first_blood")
	if stats_kills >= 10:
		_achievements.unlock("ten_kills")
	if stats_kills >= 50:
		_achievements.unlock("fifty_kills")
	if player != null and player.inventory != null:
		if player.inventory.count_of("pesos_plata") >= 200:
			_achievements.unlock("rich")
 
 
func _update_prompt() -> void:
	if mode == Mode.OVERWORLD:
		# Busca el POI más cercano dentro de radio 3 — no requiere estar
		# exactamente sobre la tile de entrada (el stamp tiene muros que la rodean).
		var nearest = _nearest_poi_within(player.get_current_tile(), 3)
		if nearest == null:
			prompt.text = ""
			return
		match nearest.type:
			OverworldScript.POIType.ENTRADA_PAQUIME:
				prompt.text = "[SPACE] Entrar a las ruinas de Paquimé"
			OverworldScript.POIType.ENTRADA_TARAHUMARA:
				prompt.text = "[SPACE] Entrar a la cueva Tarahumara"
			OverworldScript.POIType.ENTRADA_NAICA:
				prompt.text = "[SPACE] Entrar a la mina de Naica"
			OverworldScript.POIType.MATA_ORTIZ:
				prompt.text = "Mata Ortiz — pueblo de cerámica"
			OverworldScript.POIType.MISION:
				prompt.text = "Misión jesuita"
			OverworldScript.POIType.CEMENTERIO:
				prompt.text = "Cementerio"
			_:
				prompt.text = ""
	elif mode == Mode.DUNGEON_PAQUIME:
		if _nearby_chest_prompt():
			return
		var p_atlas: Vector2i = player.get_current_atlas()
		if p_atlas == BSPScript.T_EXIT:
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
		# Prioriza prompt de cofre si player está cerca
		if _nearby_chest_prompt():
			return
		var t: Vector2i = player.get_current_tile()
		var ex: Vector2i = cave.exit_pos if mode == Mode.CAVE_TARAHUMARA else mine.exit_pos
		var dx: int = t.x - ex.x
		var dy: int = t.y - ex.y
		if dx * dx + dy * dy <= 2:
			prompt.text = "[SPACE] Salir al overworld"
		else:
			prompt.text = ""
 
 
func _nearby_chest_prompt() -> bool:
	for chest in get_tree().get_nodes_in_group("boss_chest"):
		if is_instance_valid(chest) and chest.has_method("is_player_in_range") and chest.is_player_in_range():
			prompt.text = "[SPACE] Abrir cofre del boss"
			return true
	return false
 
 
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
			KEY_ESCAPE, KEY_P:
				var pm = $HUD.get_node_or_null("PauseMenu")
				if pm != null and pm.has_method("toggle"):
					pm.toggle()
			KEY_I:
				var ip = $HUD.get_node_or_null("InventoryPanel")
				if ip != null and ip.has_method("toggle"):
					ip.toggle()
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
			KEY_F5:
				_save_game()
			KEY_F9:
				_load_game()
			KEY_F12:
				if mode == Mode.OVERWORLD:
					_auto_tour()
			KEY_F10:
				# DEBUG: forzar muerte del player para verificar GameOverScreen
				if player != null and player.has_method("take_damage"):
					player.take_damage(999)
 
 
func _handle_interact() -> void:
	if mode == Mode.OVERWORLD:
		# Busca POI más cercano dentro de radio 3 (no exige tile exacta)
		var poi = _nearest_poi_within(player.get_current_tile(), 3)
		if poi == null:
			return
		match poi.type:
			OverworldScript.POIType.ENTRADA_PAQUIME:
				_enter_paquime_dungeon(poi)
				return
			OverworldScript.POIType.ENTRADA_TARAHUMARA:
				_enter_cave_dungeon(poi)
				return
			OverworldScript.POIType.ENTRADA_NAICA:
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
 
 
func _clear_trees() -> void:
	for child in trees_container.get_children():
		child.queue_free()
 
 
func _clear_enemies() -> void:
	if _enemies_container == null:
		return
	for child in _enemies_container.get_children():
		child.queue_free()
	_cementerios_spawned.clear()
	_active_boss = null
	if _boss_bar != null:
		_boss_bar.hide_boss()
 
 
# ─── Boss spawn / handlers ───────────────────────────────────────────
func _spawn_boss(boss_id: String, tile: Vector2i, layer: TileMapLayer, mode_int: int) -> void:
	var pwx: float = tile.x * TILE_DISPLAY + TILE_DISPLAY / 2.0
	var pwy: float = tile.y * TILE_DISPLAY + TILE_DISPLAY / 2.0
	var boss = CharacterBody2D.new()
	boss.set_script(BossScript)
	boss.position = Vector2(pwx, pwy)
	boss.setup(boss_id, layer, mode_int)
	_enemies_container.add_child(boss)
	_active_boss = boss
	boss.hp_changed.connect(_on_boss_hp_changed)
	boss.boss_died.connect(_on_boss_died)
	if _boss_bar != null:
		_boss_bar.show_boss(BossScript.BOSSES[boss_id]["name"], boss.hp, boss.max_hp)
 
 
func _on_boss_hp_changed(cur: int, max_hp: int, boss_name: String) -> void:
	if _boss_bar != null:
		_boss_bar.update_hp(cur, max_hp, boss_name)
 
 
func _spawn_boss_chest(boss_id: String, pos: Vector2) -> void:
	var chest_script = load("res://scripts/BossChest.gd")
	var chest = Area2D.new()
	chest.set_script(chest_script)
	chest.setup(boss_id)
	chest.position = pos
	_enemies_container.add_child(chest)
	chest.opened.connect(_on_chest_opened)
 
 
func _on_chest_opened(boss_id: String, rewards: Array) -> void:
	# Pequeño popup en prompt
	prompt.text = "[Cofre abierto: %d items]" % rewards.size()
 
 
func _on_boss_died(boss_id: String, pos: Vector2, drops: Array) -> void:
	if _boss_bar != null:
		_boss_bar.hide_boss()
	_active_boss = null
	# Spawn cofre especial donde murió el boss
	_spawn_boss_chest(boss_id, pos)
	# Marca dungeon como cleared inmediatamente
	if active_dungeon_poi != null:
		_mark_dungeon_cleared(active_dungeon_poi.pos)
	# Victory popup + XP
	var cfg: Dictionary = BossScript.BOSSES.get(boss_id, {})
	var xp_reward: int = int(cfg.get("xp_reward", 50))
	if _xp_bar != null:
		_xp_bar.add_xp(xp_reward)
	if _victory_screen != null:
		_victory_screen.show_victory(cfg.get("name", "Boss"), xp_reward, drops)
	# Achievements
	if _achievements != null:
		match boss_id:
			"senor_paquime": _achievements.unlock("clear_paquime")
			"bestia_cobre": _achievements.unlock("clear_cave")
			"espectro_cristal": _achievements.unlock("clear_mine")
		# Si los 3
		if _achievements.unlocked.has("clear_paquime") and _achievements.unlocked.has("clear_cave") and _achievements.unlocked.has("clear_mine"):
			_achievements.unlock("all_bosses")
	# Screen shake épico
	camera_shake(10.0, 0.5)
 
 
# Encuentra N tiles de FLOOR random en el dungeon Paquimé y spawnea bandidos
func _spawn_enemies_paquime(dun) -> void:
	if _bandido_frames == null:
		return
	var count: int = 8 + randi() % 5  # 8-12 bandidos
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 50:
		attempts += 1
		var x: int = randi_range(2, dun.width - 3)
		var y: int = randi_range(2, dun.height - 3)
		var t: Vector2i = dun.get_tile(x, y)
		# Solo en floor passable (T_FLOOR, T_PLAZA, T_BALL)
		if not (t == BSPScript.T_FLOOR or t == BSPScript.T_PLAZA or t == BSPScript.T_BALL):
			continue
		# No muy cerca del spawn del player
		var pwx: int = x * TILE_DISPLAY + TILE_DISPLAY / 2
		var pwy: int = y * TILE_DISPLAY + TILE_DISPLAY / 2
		var dx: int = pwx - int(player.position.x)
		var dy: int = pwy - int(player.position.y)
		if dx * dx + dy * dy < 120 * 120:
			continue
		EnemySpawnerScript.spawn_bandido(_enemies_container, Vector2(pwx, pwy), _bandido_frames, dungeon_layer, 1)
		placed += 1
 
 
# Cave Tarahumara: spawn fantasmas (cave atmosphere)
func _spawn_enemies_cave(c) -> void:
	if _fantasma_frames == null:
		return
	var count: int = 5 + randi() % 4
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 50:
		attempts += 1
		var x: int = randi_range(2, c.width - 3)
		var y: int = randi_range(2, c.height - 3)
		if c.walls[y * c.width + x] != 0:
			continue
		var pwx: int = x * TILE_DISPLAY + TILE_DISPLAY / 2
		var pwy: int = y * TILE_DISPLAY + TILE_DISPLAY / 2
		var dx: int = pwx - int(player.position.x)
		var dy: int = pwy - int(player.position.y)
		if dx * dx + dy * dy < 150 * 150:
			continue
		EnemySpawnerScript.spawn_fantasma(_enemies_container, Vector2(pwx, pwy), _fantasma_frames, cave_layer, 2)
		placed += 1
 
 
# Mina Naica: spawn bandidos
func _spawn_enemies_mine(m) -> void:
	if _bandido_frames == null:
		return
	var count: int = 6 + randi() % 5
	var placed: int = 0
	var attempts: int = 0
	while placed < count and attempts < count * 50:
		attempts += 1
		var x: int = randi_range(2, m.width - 3)
		var y: int = randi_range(2, m.height - 3)
		if m.walls[y * m.width + x] != 0:
			continue
		var pwx: int = x * TILE_DISPLAY + TILE_DISPLAY / 2
		var pwy: int = y * TILE_DISPLAY + TILE_DISPLAY / 2
		var dx: int = pwx - int(player.position.x)
		var dy: int = pwy - int(player.position.y)
		if dx * dx + dy * dy < 120 * 120:
			continue
		EnemySpawnerScript.spawn_bandido(_enemies_container, Vector2(pwx, pwy), _bandido_frames, mines_layer, 3)
		placed += 1
 
 
# Cementerios overworld: spawn 2-3 fantasmas al acercarse player (radio 200px)
func _check_cementerio_spawns() -> void:
	if mode != Mode.OVERWORLD or _fantasma_frames == null or world == null:
		return
	var ppos: Vector2 = player.position
	for poi in world.pois:
		if poi.type != OverworldScript.POIType.CEMENTERIO:
			continue
		var cem_world: Vector2 = Vector2(
			poi.pos.x * TILE_DISPLAY + TILE_DISPLAY / 2,
			poi.pos.y * TILE_DISPLAY + TILE_DISPLAY / 2
		)
		var d: float = ppos.distance_to(cem_world)
		if d < 350 and not _cementerios_spawned.has(poi.pos):
			# Spawn 2-3 fantasmas alrededor del cementerio
			var n: int = 2 + randi() % 2
			for _i in range(n):
				var off: Vector2 = Vector2(randf_range(-80, 80), randf_range(-80, 80))
				EnemySpawnerScript.spawn_fantasma(_enemies_container, cem_world + off, _fantasma_frames, overworld_layer, 0)
			_cementerios_spawned[poi.pos] = true
 
 
func _spawn_trees(w) -> void:
	# Sprite2D per tree, scale 4 → 128px display (2× player).
	# Offset visual: trunk (parte baja del sprite) cae sobre tile_pos; canopy
	# sube/se extiende hacia el norte. Collision: bloquea el tile del trunk
	# (tile_pos) — canopy es atravesable (player camina "debajo").
	if _trees_big_tex == null:
		return
	var blocked: Dictionary = {}
	for tree in w.trees:
		var tile_pos: Vector2i = tree["pos"]
		var t_type: int = tree["type"]
		var spr := Sprite2D.new()
		var atlas_tex := AtlasTexture.new()
		atlas_tex.atlas = _trees_big_tex
		atlas_tex.region = Rect2(t_type * TREE_SOURCE_SIZE, 0, TREE_SOURCE_SIZE, TREE_SOURCE_SIZE)
		spr.texture = atlas_tex
		spr.centered = true
		# Offset Y negativo en source coords (centered=true → shifts UP del position).
		# Source trunk en row y≈27, mitad en y=16 → shift -10 = trunk al position.
		spr.offset = Vector2(0, -10)
		spr.scale = Vector2(TREE_DISPLAY_SCALE, TREE_DISPLAY_SCALE)
		# Posición = centro del tile del TRUNK (donde está bloqueada la colisión)
		spr.position = Vector2(tile_pos.x * TILE_DISPLAY + TILE_DISPLAY / 2.0,
			tile_pos.y * TILE_DISPLAY + TILE_DISPLAY / 2.0)
		# Y-sort: trees del sur por encima de trees del norte
		spr.z_index = tile_pos.y
		trees_container.add_child(spr)
		blocked[tile_pos] = true
	player.tree_blocked_tiles = blocked
 
 
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
 
 
func _notification(what: int) -> void:
	# Auto-save al cerrar ventana
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
 
 
func _save_game() -> void:
	if world == null or player == null:
		return
	# Serializa inventory real del player
	var inv_data: Array = []
	if player.inventory != null:
		inv_data = player.inventory.to_array()
	# XP state
	var xp_lvl: int = 1
	var xp_cur: int = 0
	if _xp_bar != null:
		var st: Dictionary = _xp_bar.get_state()
		xp_lvl = st.get("level", 1)
		xp_cur = st.get("xp", 0)
	# Achievements
	var ach_arr: Array = []
	if _achievements != null:
		ach_arr = _achievements.unlocked.keys()
	var data := {
		"seed": current_seed,
		"hp": player.current_hp if "current_hp" in player else 10,
		"max_hp": player.get_max_hp() if player.has_method("get_max_hp") else 10,
		"tile_pos": player.get_current_tile() if mode == Mode.OVERWORLD else _find_first_poi(OverworldScript.POIType.MATA_ORTIZ),
		"cleared": cleared_dungeons,
		"kills": stats_kills,
		"runs": stats_runs,
		"inventory": inv_data,
		"xp_level": xp_lvl,
		"xp_current": xp_cur,
		"max_hp_bonus": player.max_hp_bonus,
		"damage_bonus": player.damage_bonus,
		"speed_bonus": player.speed_bonus,
		"crit_chance": player.crit_chance,
		"achievements": ach_arr,
	}
	var ok: bool = SaveManagerScript.save_to_disk(data)
	if ok:
		prompt.text = "[Save guardado]"
		print("[Save] Guardado OK — seed=%d cleared=%d lvl=%d" % [current_seed, cleared_dungeons.size(), xp_lvl])
	else:
		prompt.text = "[Error al guardar]"
 
 
func _load_game() -> void:
	var loaded = SaveManagerScript.load_from_disk()
	if loaded == null:
		prompt.text = "[No hay save]"
		return
	_pending_load = loaded
	_loaded_from_save = true
	cleared_dungeons = loaded.get("cleared", [])
	stats_kills = loaded.get("kills", 0)
	stats_runs = loaded.get("runs", 0)
	inventory = loaded.get("inventory", [])
	prompt.text = "[Save cargado, regenerando...]"
	_regenerate_overworld()
 
 
func _mark_dungeon_cleared(poi_pos: Vector2i) -> void:
	if not cleared_dungeons.has(poi_pos):
		cleared_dungeons.append(poi_pos)
		stats_runs += 1
 
 
func _on_player_died() -> void:
	# Pausa input del player (queda en su lugar)
	# Sale del dungeon (volver al overworld) y muestra GameOver
	if mode != Mode.OVERWORLD:
		_exit_to_overworld()
	var go = $HUD.get_node_or_null("GameOverScreen")
	if go != null and go.has_method("show_death"):
		go.show_death({
			"kills": stats_kills,
			"runs": stats_runs,
			"cleared": cleared_dungeons.size(),
		})
 
 
func _on_respawn_requested() -> void:
	# Respawn en Mata Ortiz, mantiene progreso (cleared, kills, inventory)
	var spawn := _find_first_poi(OverworldScript.POIType.MATA_ORTIZ)
	if spawn == Vector2i(-1, -1):
		spawn = _find_safe_spawn(Vector2i(MAP_W / 2, MAP_H / 2))
	player.set_tile_position(spawn)
	if player.has_method("reset_hp"):
		player.reset_hp()
	_save_game()  # auto-save al respawn (anti-cheat)
 
 
func _on_new_game_requested() -> void:
	# Borra save y regenera todo desde 0
	SaveManagerScript.delete_save()
	cleared_dungeons.clear()
	stats_kills = 0
	stats_runs = 0
	inventory.clear()
	_pending_load.clear()
	_loaded_from_save = false
	# Reset XP + achievements + upgrades
	if _xp_bar != null:
		_xp_bar.set_state({"level": 1, "xp": 0})
	if _achievements != null:
		_achievements.set_state({"unlocked": []})
	if player != null:
		player.max_hp_bonus = 0
		player.damage_bonus = 0
		player.speed_bonus = 0.0
		player.crit_chance = 0.10
		if player.inventory != null:
			player.inventory.from_array([])
			player.inventory.add("tortilla", 3)
			player.inventory.add("machete", 1)
		if player.has_method("reset_hp"):
			player.reset_hp()
	_regenerate_overworld()
 
 
func _nearest_poi_within(tile: Vector2i, radius: int):
	# Retorna el POI más cercano al tile (en distancia chebyshev) o null.
	if world == null:
		return null
	var best = null
	var best_d: int = radius + 1
	for poi in world.pois:
		var dx: int = poi.pos.x - tile.x
		var dy: int = poi.pos.y - tile.y
		var d: int = maxi(absi(dx), absi(dy))
		if d <= radius and d < best_d:
			best_d = d
			best = poi
	return best
 
 
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
