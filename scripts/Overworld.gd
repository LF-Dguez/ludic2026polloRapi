# Generación basada en geografía REAL de Chihuahua.
# Multi-source tile encoding: (source_id << 16) | (atlas_x << 8) | atlas_y

class_name Overworld
extends RefCounted

# Source IDs (orden de adds al TileSet)
const SRC_OVERWORLD := 0
const SRC_DESERT := 1
const SRC_AFUERA := 2  # Atlas vegetación (afuera_clean.png 11x10)
const SRC_TREES := 3   # Árboles top-down generados (trees_topdown.png 8x1)
# trees_topdown index: 0=pino oscuro, 1=encina, 2=sabino, 3=cardón,
# 4=mezquite, 5=palo verde, 6=árbol seco, 7=pino claro
const SRC_BASES := 4   # Bases de bioma SUAVES (biome_bases.png 8x1)
# bases index: 0=LLANOS, 1=SIERRA, 2=DESIERTO, 3=BARRANCA, 4=MINERO, 5=RIO, 6=MESA, 7=PICO

enum Biome {
	DESIERTO, LLANOS, SIERRA, BARRANCA, MINERO, RIO, MESA, PICO,
}

enum POIType {
	MATA_ORTIZ, MISION, CEMENTERIO,
	ENTRADA_PAQUIME, ENTRADA_TARAHUMARA, ENTRADA_NAICA,
}

# Columna del bioma en biome_bases.png (8 biomas × 4 variantes filas)
const BIOME_BASE_COL := {
	Biome.LLANOS: 0,
	Biome.SIERRA: 1,
	Biome.DESIERTO: 2,
	Biome.BARRANCA: 3,
	Biome.MINERO: 4,
	Biome.RIO: 5,
	Biome.MESA: 6,
	Biome.PICO: 7,
}
# Tile primario (col fija por bioma, variant row 0-3 elegida por hash en generate())
const BIOME_PRIMARY := {
	Biome.LLANOS:   {"src": SRC_BASES, "atlas": Vector2i(0, 0)},
	Biome.SIERRA:   {"src": SRC_BASES, "atlas": Vector2i(1, 0)},
	Biome.DESIERTO: {"src": SRC_BASES, "atlas": Vector2i(2, 0)},
	Biome.BARRANCA: {"src": SRC_BASES, "atlas": Vector2i(3, 0)},
	Biome.MINERO:   {"src": SRC_BASES, "atlas": Vector2i(4, 0)},
	Biome.RIO:      {"src": SRC_BASES, "atlas": Vector2i(5, 0)},
	Biome.MESA:     {"src": SRC_BASES, "atlas": Vector2i(6, 0)},
	Biome.PICO:     {"src": SRC_BASES, "atlas": Vector2i(7, 0)},
}

# Decoraciones por bioma — ahora con vegetación del atlas "afuera" (SRC_AFUERA)
# afuera_clean.png layout (11 cols x 10 rows):
#   row 5 cols 0-5: BASES DE ÁRBOL grandes (IMPASABLES — ver Player.gd)
#   row 5 cols 6-10: troncos caídos / ramas
#   row 6 cols 0-7: arbustos verdes
#   row 6 cols 7-10: arbustos secos
#   row 7 cols 0-2: hongos rojos
#   row 7 cols 4-10: flores (rojas, azules, moradas, blancas, amarillas)
#   row 8 cols 0-2: matorrales secos
#   row 8 cols 3-6: rocas grandes (IMPASABLES)
#   row 8 cols 7-9: tocones
#   row 9 cols 0-10: hojas, ramas pequeñas
const BIOME_DECORS := {
	Biome.DESIERTO: [
		# Cardón top-down (estrella verde) y palo verde — árboles del desierto chihuahuense
		{"src": SRC_TREES, "atlas": Vector2i(3, 0)},  # cardón (impasable)
		{"src": SRC_TREES, "atlas": Vector2i(4, 0)},  # mezquite (impasable)
		{"src": SRC_TREES, "atlas": Vector2i(5, 0)},  # palo verde (impasable)
		# Variantes del atlas dorado
		{"src": SRC_DESERT, "atlas": Vector2i(1, 0)},
		{"src": SRC_DESERT, "atlas": Vector2i(2, 0)},
		{"src": SRC_DESERT, "atlas": Vector2i(3, 0)},
		{"src": SRC_DESERT, "atlas": Vector2i(0, 1)},
		{"src": SRC_DESERT, "atlas": Vector2i(1, 1)},
		{"src": SRC_DESERT, "atlas": Vector2i(2, 1)},
		# Decor atmosféricos del atlas viejo
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 0)},  # sotol
		{"src": SRC_OVERWORLD, "atlas": Vector2i(3, 0)},  # lechuguilla
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 0)},  # calavera vaca
		{"src": SRC_OVERWORLD, "atlas": Vector2i(6, 0)},  # cactus muerto
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 0)},  # huesos
		{"src": SRC_OVERWORLD, "atlas": Vector2i(1, 5)},  # cardón
		# Vegetación seca/dura del atlas afuera (matorrales y ramas secas)
		{"src": SRC_AFUERA, "atlas": Vector2i(0, 8)},  # matorral seco
		{"src": SRC_AFUERA, "atlas": Vector2i(1, 8)},  # matorral seco 2
		{"src": SRC_AFUERA, "atlas": Vector2i(2, 8)},  # matorral seco 3
		{"src": SRC_AFUERA, "atlas": Vector2i(7, 6)},  # arbusto seco
		{"src": SRC_AFUERA, "atlas": Vector2i(8, 6)},  # arbusto seco 2
		{"src": SRC_AFUERA, "atlas": Vector2i(3, 8)},  # roca pequeña
		{"src": SRC_AFUERA, "atlas": Vector2i(4, 8)},  # roca pequeña 2
	],
	Biome.LLANOS: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(1, 1)},  # mezquite
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 1)},  # pasto alto
		{"src": SRC_OVERWORLD, "atlas": Vector2i(3, 5)},  # alambrada
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 5)},  # fogata
		{"src": SRC_OVERWORLD, "atlas": Vector2i(6, 5)},  # huellas
		# Vegetación llanos del atlas afuera
		{"src": SRC_AFUERA, "atlas": Vector2i(0, 6)},  # arbusto verde
		{"src": SRC_AFUERA, "atlas": Vector2i(1, 6)},  # arbusto verde 2
		{"src": SRC_AFUERA, "atlas": Vector2i(2, 6)},  # arbusto verde 3
		{"src": SRC_AFUERA, "atlas": Vector2i(3, 6)},  # arbusto verde 4
		{"src": SRC_AFUERA, "atlas": Vector2i(4, 6)},  # arbusto verde 5
		{"src": SRC_AFUERA, "atlas": Vector2i(5, 6)},  # arbusto verde 6
		# Flores variadas
		{"src": SRC_AFUERA, "atlas": Vector2i(4, 7)},  # flores azules
		{"src": SRC_AFUERA, "atlas": Vector2i(5, 7)},  # flores moradas
		{"src": SRC_AFUERA, "atlas": Vector2i(6, 7)},  # flores rosas
		{"src": SRC_AFUERA, "atlas": Vector2i(7, 7)},  # flores blancas
		{"src": SRC_AFUERA, "atlas": Vector2i(8, 7)},  # flores azules 2
		{"src": SRC_AFUERA, "atlas": Vector2i(9, 7)},  # flores amarillas
		{"src": SRC_AFUERA, "atlas": Vector2i(10, 7)}, # flores amarillas 2
		{"src": SRC_AFUERA, "atlas": Vector2i(3, 8)},  # roca pequeña
	],
	Biome.SIERRA: [
		# ÁRBOLES TOP-DOWN REALES con canopy visible (impasables)
		{"src": SRC_TREES, "atlas": Vector2i(0, 0)},  # pino oscuro
		{"src": SRC_TREES, "atlas": Vector2i(0, 0)},  # repeat para weight
		{"src": SRC_TREES, "atlas": Vector2i(1, 0)},  # encina
		{"src": SRC_TREES, "atlas": Vector2i(2, 0)},  # sabino
		{"src": SRC_TREES, "atlas": Vector2i(6, 0)},  # árbol seco
		{"src": SRC_TREES, "atlas": Vector2i(7, 0)},  # pino claro
		{"src": SRC_TREES, "atlas": Vector2i(7, 0)},  # repeat
		# Rocas grandes sierra (impasables)
		{"src": SRC_AFUERA, "atlas": Vector2i(3, 8)},
		{"src": SRC_AFUERA, "atlas": Vector2i(5, 8)},
		# Sotobosque: arbustos del afuera (passable)
		{"src": SRC_AFUERA, "atlas": Vector2i(0, 6)},
		{"src": SRC_AFUERA, "atlas": Vector2i(1, 6)},
		{"src": SRC_AFUERA, "atlas": Vector2i(4, 6)},
		# Hongos rojos
		{"src": SRC_AFUERA, "atlas": Vector2i(0, 7)},
		{"src": SRC_AFUERA, "atlas": Vector2i(1, 7)},
		{"src": SRC_AFUERA, "atlas": Vector2i(2, 7)},
		# Tocones (passable)
		{"src": SRC_AFUERA, "atlas": Vector2i(7, 8)},
		{"src": SRC_AFUERA, "atlas": Vector2i(8, 8)},
	],
	Biome.BARRANCA: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(1, 2)},
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 2)},
		# Rocas grandes del atlas afuera (impasables — perfecto para barrancas)
		{"src": SRC_AFUERA, "atlas": Vector2i(3, 8)},
		{"src": SRC_AFUERA, "atlas": Vector2i(4, 8)},
		{"src": SRC_AFUERA, "atlas": Vector2i(5, 8)},
		{"src": SRC_AFUERA, "atlas": Vector2i(6, 8)},
	],
	Biome.MINERO: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 2)},
		{"src": SRC_OVERWORLD, "atlas": Vector2i(5, 2)},
		# Rocas mineras
		{"src": SRC_AFUERA, "atlas": Vector2i(3, 8)},
		{"src": SRC_AFUERA, "atlas": Vector2i(5, 8)},
	],
	Biome.RIO: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 2)},
	],
	Biome.MESA: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(5, 0)},
		{"src": SRC_AFUERA, "atlas": Vector2i(5, 8)},  # roca grande
	],
	Biome.PICO: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(0, 5)},
	],
}

const DECOR_PROBS := {
	Biome.DESIERTO: 0.40,
	Biome.LLANOS:   0.35,  # subido — más flores y arbustos
	Biome.SIERRA:   0.45,  # subido — bosque denso con árboles
	Biome.BARRANCA: 0.25,
	Biome.MINERO:   0.30,
	Biome.RIO:      0.08,
	Biome.MESA:     0.18,
	Biome.PICO:     0.05,
}

const POI_TILE := {
	POIType.MATA_ORTIZ:         Vector2i(2, 3),
	POIType.MISION:             Vector2i(3, 3),
	POIType.CEMENTERIO:         Vector2i(4, 3),
	POIType.ENTRADA_PAQUIME:    Vector2i(5, 3),
	POIType.ENTRADA_TARAHUMARA: Vector2i(6, 3),
	POIType.ENTRADA_NAICA:      Vector2i(7, 3),
}

# Atajos de tiles del overworld (componentes de stamps)
const T_ADOBE_WALL   := Vector2i(0, 4)
const T_CREAM_FLOOR  := Vector2i(1, 4)
const T_DIRT_PATH    := Vector2i(2, 4)
const T_CAVE_ROCK    := Vector2i(3, 4)
const T_CAVE_SHADOW  := Vector2i(4, 4)
const T_WOOD_FRAME   := Vector2i(5, 4)
const T_RAILS        := Vector2i(6, 4)


class POI:
	var pos: Vector2i
	var type: int


class World:
	var width: int
	var height: int
	var biomes: PackedInt32Array
	var tiles: PackedInt32Array        # BASE layer: bioma primary o POI structure
	var decor_tiles: PackedInt32Array  # OVERLAY: decoraciones con bg transparente
	var pois: Array = []
	var bridges: Array = []  # Array[Vector2i] — posiciones exactas de tiles puente
	var trees: Array = []    # Array of {pos: Vector2i (tile), type: int (0-7)}
	var seed_value: int

	func get_biome(x: int, y: int) -> int:
		return biomes[y * width + x]

	func set_biome(x: int, y: int, b: int) -> void:
		biomes[y * width + x] = b

	func set_tile_pair(x: int, y: int, src: int, atlas: Vector2i) -> void:
		tiles[y * width + x] = ((src & 0xff) << 16) | ((atlas.x & 0xff) << 8) | (atlas.y & 0xff)

	func set_tile(x: int, y: int, atlas: Vector2i) -> void:
		# Default source 0 (overworld atlas)
		tiles[y * width + x] = ((atlas.x & 0xff) << 8) | (atlas.y & 0xff)

	func set_decor(x: int, y: int, src: int, atlas: Vector2i) -> void:
		# Layer overlay: decoración con fondo transparente sobre base
		decor_tiles[y * width + x] = ((src & 0xff) << 16) | ((atlas.x & 0xff) << 8) | (atlas.y & 0xff)

	func clear_decor(x: int, y: int) -> void:
		# Sentinel: src 0xff = no decoración
		decor_tiles[y * width + x] = 0xff << 16

	func has_decor(x: int, y: int) -> bool:
		var raw: int = decor_tiles[y * width + x]
		return ((raw >> 16) & 0xff) != 0xff

	func get_tile_raw(x: int, y: int) -> int:
		return tiles[y * width + x]

	func in_bounds(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < width and y < height


func generate(w: int, h: int, seed_value: int) -> World:
	var world := World.new()
	world.width = w
	world.height = h
	world.seed_value = seed_value
	world.biomes = PackedInt32Array()
	world.biomes.resize(w * h)
	world.tiles = PackedInt32Array()
	world.tiles.resize(w * h)
	world.decor_tiles = PackedInt32Array()
	world.decor_tiles.resize(w * h)
	# Init decor layer con sentinel (0xff << 16 = no decor)
	for i in range(w * h):
		world.decor_tiles[i] = 0xff << 16
	world.pois = []
	world.bridges = []
	world.trees = []

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	# FRECUENCIAS BAJAS para blobs grandes coherentes (no chile-con-queso).
	var n_elev := FastNoiseLite.new()
	n_elev.seed = seed_value
	n_elev.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_elev.frequency = 0.0045
	n_elev.fractal_octaves = 3
	n_elev.fractal_lacunarity = 2.0
	n_elev.fractal_gain = 0.50

	var n_humid := FastNoiseLite.new()
	n_humid.seed = seed_value + 1031
	n_humid.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_humid.frequency = 0.006
	n_humid.fractal_octaves = 2

	var n_minero := FastNoiseLite.new()
	n_minero.seed = seed_value + 3023
	n_minero.noise_type = FastNoiseLite.TYPE_CELLULAR
	n_minero.frequency = 0.018
	n_minero.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	# CellularReturnType.CELL_VALUE → ~uniforme [-1,1] (antes DISTANCE → casi siempre negativo)
	n_minero.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

	var n_mesa := FastNoiseLite.new()
	n_mesa.seed = seed_value + 5077
	n_mesa.noise_type = FastNoiseLite.TYPE_CELLULAR
	n_mesa.frequency = 0.012
	n_mesa.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

	# Picos (Cerro Mohinora etc.)
	var peaks := [
		{"pos": Vector2(w * 0.10, h * 0.78), "h": 0.35, "r": w * 0.04},
		{"pos": Vector2(w * 0.38, h * 0.28), "h": 0.30, "r": w * 0.03},
		{"pos": Vector2(w * 0.20, h * 0.50), "h": 0.30, "r": w * 0.04},
	]

	# === Pase 1: biomas (thresholds AJUSTADOS para más diversidad) ===
	# W-bias reducido a 0.7 (era 1.0) → menos sierra dominante
	for y in range(h):
		for x in range(w):
			var pos_elev: float = (1.0 - float(x) / float(w)) * 0.65
			var noise: float = n_elev.get_noise_2d(x, y) * 0.25
			var elev: float = pos_elev + noise

			for peak in peaks:
				var dist: float = Vector2(x, y).distance_to(peak["pos"])
				if dist < peak["r"]:
					var falloff: float = 1.0 - dist / peak["r"]
					elev += peak["h"] * falloff * falloff

			var humid: float = n_humid.get_noise_2d(x, y) * 0.5 + 0.5
			var m: float = n_minero.get_noise_2d(x, y)
			var ms: float = n_mesa.get_noise_2d(x, y)

			var biome: int
			# Thresholds ajustados: PICO 0.88 (era 0.95, casi inalcanzable),
			# MESA sin humid gate (era doble-raro), MINERO con cell-value uniforme.
			if elev > 0.88:
				biome = Biome.PICO
			elif elev > 0.74:
				if absf(noise) > 0.13:
					biome = Biome.BARRANCA
				else:
					biome = Biome.SIERRA
			elif elev > 0.58:
				biome = Biome.SIERRA
			elif elev > 0.45:
				if humid > 0.55:
					biome = Biome.SIERRA
				else:
					biome = Biome.LLANOS
			elif elev > 0.28:
				if m > 0.30:
					biome = Biome.MINERO
				elif ms > 0.35:
					biome = Biome.MESA
				else:
					biome = Biome.LLANOS
			elif elev > 0.12:
				if m > 0.30:
					biome = Biome.MINERO
				elif ms > 0.40:
					biome = Biome.MESA
				elif humid > 0.65:
					biome = Biome.LLANOS
				else:
					biome = Biome.DESIERTO
			else:
				biome = Biome.DESIERTO

			world.set_biome(x, y, biome)

	# === Pase 2: Ríos con perlin perturbation (curvas naturales) + riberas + puentes ===
	_carve_river_natural(world, [
		Vector2i(int(w * 0.12), int(h * 0.85)),
		Vector2i(int(w * 0.22), int(h * 0.72)),
		Vector2i(int(w * 0.32), int(h * 0.65)),
		Vector2i(int(w * 0.42), int(h * 0.58)),
		Vector2i(int(w * 0.52), int(h * 0.50)),
		Vector2i(int(w * 0.62), int(h * 0.45)),
		Vector2i(int(w * 0.72), int(h * 0.38)),
		Vector2i(int(w * 0.82), int(h * 0.30)),
		Vector2i(int(w * 0.95), int(h * 0.18)),
	], 2, rng)  # Conchos principal (ancho varía 1-3)
	_carve_river_natural(world, [
		Vector2i(int(w * 0.58), int(h * 0.92)),
		Vector2i(int(w * 0.58), int(h * 0.80)),
		Vector2i(int(w * 0.60), int(h * 0.68)),
		Vector2i(int(w * 0.60), int(h * 0.55)),
	], 1, rng)
	_carve_river_natural(world, [
		Vector2i(int(w * 0.18), int(h * 0.08)),
		Vector2i(int(w * 0.25), int(h * 0.12)),
		Vector2i(int(w * 0.32), int(h * 0.18)),
		Vector2i(int(w * 0.32), int(h * 0.25)),
	], 1, rng)
	_carve_river_natural(world, [
		Vector2i(int(w * 0.45), int(h * 0.10)),
		Vector2i(int(w * 0.52), int(h * 0.30)),
		Vector2i(int(w * 0.55), int(h * 0.48)),
	], 1, rng)

	# === Pase 2.5: Puentes PROCEDURALES — recolecta tiles de río, elige K random con min-dist ===
	_place_random_bridges(world, rng, 7, 22)

	# === Pase 3: variantes (decoraciones) ===
	var n_decor := FastNoiseLite.new()
	n_decor.seed = seed_value + 4099
	n_decor.noise_type = FastNoiseLite.TYPE_VALUE
	n_decor.frequency = 0.25  # antes 0.7 — daba ruido casi puro; baja agrupa decor

	for y in range(h):
		for x in range(w):
			var biome: int = world.get_biome(x, y)
			# BASE: una de 4 variantes del biome_bases (hash anti-checkerboard)
			var col: int = BIOME_BASE_COL.get(biome, 0)
			var bh: int = ((x * 73856093) ^ (y * 19349663) ^ (seed_value * 83492791))
			bh = (bh ^ (bh >> 13)) & 0x7fffffff
			var variant: int = bh % 4
			world.set_tile_pair(x, y, SRC_BASES, Vector2i(col, variant))
			# DECOR opcional como OVERLAY
			var roll: float = (n_decor.get_noise_2d(x, y) + 1.0) * 0.5
			var prob: float = DECOR_PROBS.get(biome, 0.0)
			if roll < prob and BIOME_DECORS.has(biome) and not BIOME_DECORS[biome].is_empty():
				var decors: Array = BIOME_DECORS[biome]
				var idx: int = int(roll * 10000.0) % decors.size()
				var d: Dictionary = decors[idx]
				# Trees (SRC_TREES) → Sprite2D nodes via world.trees (NO al decor layer)
				if d["src"] == SRC_TREES:
					world.trees.append({"pos": Vector2i(x, y), "type": d["atlas"].x})
				else:
					world.set_decor(x, y, d["src"], d["atlas"])

	# === Pase 4: POIs + stamps ===
	_place_pois_chihuahua(world, rng)
	for poi in world.pois:
		_stamp_poi(world, poi)

	# === Pase 5: pinta tiles bridge desde world.bridges (tracking explícito) ===
	for bp in world.bridges:
		var bxy: Vector2i = bp
		if world.in_bounds(bxy.x, bxy.y):
			world.set_tile(bxy.x, bxy.y, Vector2i(2, 2))  # T_BRIDGE

	# === Pase 6: garantiza al menos un dungeon entrance alcanzable desde spawn ===
	_ensure_dungeon_reachable(world)

	return world


# Flood-fill desde Mata Ortiz; si NO hay dungeon alcanzable, carve path al más cercano.
func _ensure_dungeon_reachable(world: World) -> void:
	var spawn: Vector2i = Vector2i(world.width / 2, world.height / 2)
	for poi in world.pois:
		if poi.type == POIType.MATA_ORTIZ:
			spawn = poi.pos
			break
	# Recolectar dungeons
	var dungeons: Array = []
	for poi in world.pois:
		if poi.type == POIType.ENTRADA_PAQUIME or poi.type == POIType.ENTRADA_TARAHUMARA or poi.type == POIType.ENTRADA_NAICA:
			dungeons.append(poi)
	if dungeons.is_empty():
		return
	# BFS over passable
	var visited: Dictionary = {}
	var queue: Array = [spawn]
	visited[spawn] = true
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + off
			if not world.in_bounds(nxt.x, nxt.y):
				continue
			if visited.has(nxt):
				continue
			if not _is_overworld_passable(world, nxt.x, nxt.y):
				continue
			visited[nxt] = true
			queue.append(nxt)
	# ¿Algún dungeon entrance alcanzable?
	var nearest_unreachable = null
	var best_d: int = 999999999
	for d_poi in dungeons:
		if visited.has(d_poi.pos):
			return  # ya hay uno alcanzable, listo
		var dx: int = d_poi.pos.x - spawn.x
		var dy: int = d_poi.pos.y - spawn.y
		var dsq: int = dx * dx + dy * dy
		if dsq < best_d:
			best_d = dsq
			nearest_unreachable = d_poi
	# Ninguno alcanzable — force carve path al más cercano
	if nearest_unreachable != null:
		_carve_overworld_emergency_path(world, spawn, nearest_unreachable.pos)


func _is_overworld_passable(world: World, x: int, y: int) -> bool:
	var b: int = world.get_biome(x, y)
	if b == Biome.RIO or b == Biome.BARRANCA or b == Biome.PICO:
		return false
	var raw: int = world.get_tile_raw(x, y)
	var src: int = (raw >> 16) & 0xff
	if src != 0:
		return true  # desert atlas, passable
	var atlas := Vector2i((raw >> 8) & 0xff, raw & 0xff)
	# Impasables específicos
	if atlas == T_ADOBE_WALL: return false
	if atlas == T_CAVE_ROCK: return false
	if atlas == T_WOOD_FRAME: return false
	if atlas.x == 6 and atlas.y == 1: return false  # roca sierra
	if atlas.x == 0 and atlas.y == 2: return false  # barranca borde
	if atlas.x == 1 and atlas.y == 2: return false  # barranca abismo
	if atlas.x == 6 and atlas.y == 2: return false  # río
	if atlas.x == 0 and atlas.y == 5: return false  # pico
	return true


# Carve un camino de emergencia (3 tiles wide) por Bresenham, convirtiendo
# todo a LLANOS + DIRT_PATH para garantizar accesibilidad.
func _carve_overworld_emergency_path(world: World, a: Vector2i, b: Vector2i) -> void:
	var x0: int = a.x; var y0: int = a.y
	var x1: int = b.x; var y1: int = b.y
	var dx: int = absi(x1 - x0); var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	var max_steps: int = (dx + dy) * 3
	var steps: int = 0
	while (x0 != x1 or y0 != y1) and steps < max_steps:
		steps += 1
		for ddy in [-1, 0, 1]:
			for ddx in [-1, 0, 1]:
				var px: int = x0 + ddx
				var py: int = y0 + ddy
				if world.in_bounds(px, py):
					var bb: int = world.get_biome(px, py)
					if bb == Biome.RIO or bb == Biome.BARRANCA or bb == Biome.PICO:
						world.set_biome(px, py, Biome.LLANOS)
						world.set_tile(px, py, T_DIRT_PATH)
		var e2: int = 2 * err
		if e2 > -dy: err -= dy; x0 += sx
		if e2 < dx: err += dx; y0 += sy


func _carve_river_natural(world: World, waypoints: Array, base_width: int, rng: RandomNumberGenerator) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = world.seed_value + 7919 + waypoints[0].x + waypoints[0].y
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.06
	for i in range(waypoints.size() - 1):
		_draw_river_perlin(world, waypoints[i], waypoints[i + 1], base_width, noise)


func _draw_river_perlin(world: World, a: Vector2i, b: Vector2i, base_width: int, noise: FastNoiseLite) -> void:
	# Interpola de a→b en pasos pequeños, perturbando lateralmente con perlin.
	var distance: float = Vector2(a).distance_to(Vector2(b))
	var steps: int = int(distance * 1.3)
	if steps < 2:
		steps = 2
	var dir: Vector2 = (Vector2(b) - Vector2(a)).normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	for s in range(steps + 1):
		var t: float = float(s) / float(steps)
		var base_x: float = lerp(float(a.x), float(b.x), t)
		var base_y: float = lerp(float(a.y), float(b.y), t)
		# Perturbación perpendicular (sin falloff en los extremos para conectar bien)
		var falloff: float = sin(t * PI)
		var lateral: float = noise.get_noise_2d(base_x * 0.5, base_y * 0.5) * 6.0 * falloff
		var cx: int = int(base_x + perp.x * lateral)
		var cy: int = int(base_y + perp.y * lateral)
		# Ancho variable según otro noise
		var w_variation: float = noise.get_noise_2d(base_x * 0.3 + 99.0, base_y * 0.3 + 99.0) * 0.5 + 0.5
		var effective_w: int = base_width + (1 if w_variation > 0.65 else 0)
		_paint_river_at(world, cx, cy, effective_w)


func _paint_river_at(world: World, cx: int, cy: int, width: int) -> void:
	for dy in range(-width, width + 1):
		for dx in range(-width, width + 1):
			if dx * dx + dy * dy > width * width:
				continue
			var x: int = cx + dx
			var y: int = cy + dy
			if x < 0 or y < 0 or x >= world.width or y >= world.height:
				continue
			world.set_biome(x, y, Biome.RIO)


# Placement procedural de puentes: recolecta tiles de río, shuffle con rng,
# coloca hasta `target_count` con min-distance entre ellos. Trackea posiciones
# en world.bridges para que pase 5 las pinte como T_BRIDGE sin falsos positivos.
func _place_random_bridges(world: World, rng: RandomNumberGenerator, target_count: int, min_dist: int) -> void:
	var river_tiles: Array[Vector2i] = []
	for y in range(world.height):
		for x in range(world.width):
			if world.get_biome(x, y) == Biome.RIO:
				river_tiles.append(Vector2i(x, y))
	if river_tiles.is_empty():
		return
	# Fisher-Yates shuffle determinístico
	for i in range(river_tiles.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Vector2i = river_tiles[i]
		river_tiles[i] = river_tiles[j]
		river_tiles[j] = tmp
	var placed: Array[Vector2i] = []
	for t in river_tiles:
		if placed.size() >= target_count:
			break
		var too_close: bool = false
		for p in placed:
			var dx: int = t.x - p.x
			var dy: int = t.y - p.y
			if dx * dx + dy * dy < min_dist * min_dist:
				too_close = true
				break
		if too_close:
			continue
		if world.get_biome(t.x, t.y) != Biome.RIO:
			continue
		# Detectar orientación local del río
		var horiz: int = 0
		var vert: int = 0
		for dx in [-1, 1]:
			if world.in_bounds(t.x + dx, t.y) and world.get_biome(t.x + dx, t.y) == Biome.RIO:
				horiz += 1
		for dy in [-1, 1]:
			if world.in_bounds(t.x, t.y + dy) and world.get_biome(t.x, t.y + dy) == Biome.RIO:
				vert += 1
		if horiz + vert == 0:
			continue
		# Puente PERPENDICULAR al flujo, expandiendo hasta cubrir TODO el ancho del río
		# (ríos pueden ser 5-7 tiles de ancho, bridge debe alcanzar ambos bancos).
		var bridge_cells: Array[Vector2i] = []
		if horiz >= vert:
			# Río corre E-W → puente N-S: walk hacia arriba y abajo desde t
			bridge_cells.append(t)
			var y_up: int = t.y - 1
			while world.in_bounds(t.x, y_up) and world.get_biome(t.x, y_up) == Biome.RIO:
				bridge_cells.append(Vector2i(t.x, y_up))
				y_up -= 1
			var y_dn: int = t.y + 1
			while world.in_bounds(t.x, y_dn) and world.get_biome(t.x, y_dn) == Biome.RIO:
				bridge_cells.append(Vector2i(t.x, y_dn))
				y_dn += 1
		else:
			# Río corre N-S → puente E-W
			bridge_cells.append(t)
			var x_l: int = t.x - 1
			while world.in_bounds(x_l, t.y) and world.get_biome(x_l, t.y) == Biome.RIO:
				bridge_cells.append(Vector2i(x_l, t.y))
				x_l -= 1
			var x_r: int = t.x + 1
			while world.in_bounds(x_r, t.y) and world.get_biome(x_r, t.y) == Biome.RIO:
				bridge_cells.append(Vector2i(x_r, t.y))
				x_r += 1
		# Marcar cada celda del puente: bioma cambia (libera la "impasable RIO") + trackeo
		for bc in bridge_cells:
			world.set_biome(bc.x, bc.y, Biome.BARRANCA)
			world.bridges.append(bc)
		placed.append(t)


func _make_poi(pos: Vector2i, type: int) -> POI:
	var p := POI.new(); p.pos = pos; p.type = type
	return p


func _place_pois_chihuahua(world: World, rng: RandomNumberGenerator) -> void:
	# === ANCHORS handcrafted (priorizar bioma natural + _too_close vs anchors previos) ===
	# Mata Ortiz: NW Llanos (prefiere LLANOS, fallback DESIERTO)
	var mata_center := Vector2i(int(world.width * 0.25), int(world.height * 0.22))
	var mata := _find_biome_near(world, Biome.LLANOS, mata_center, 30)
	if mata == Vector2i(-1, -1):
		mata = _find_biome_near(world, Biome.DESIERTO, mata_center, 30)
	if mata != Vector2i(-1, -1) and not _too_close(mata, world.pois, 25):
		world.pois.append(_make_poi(mata, POIType.MATA_ORTIZ))

	# Paquimé anchor (NW Desierto)
	var paq_center := Vector2i(int(world.width * 0.30), int(world.height * 0.18))
	var paq := _find_biome_near(world, Biome.DESIERTO, paq_center, 30)
	if paq == Vector2i(-1, -1):
		paq = _find_passable_near(world, paq_center, 30)
	if paq != Vector2i(-1, -1) and not _too_close(paq, world.pois, 22):
		world.pois.append(_make_poi(paq, POIType.ENTRADA_PAQUIME))

	# Parral (S) misión handcrafted (prefiere LLANOS)
	var parral_center := Vector2i(int(world.width * 0.45), int(world.height * 0.85))
	var parral := _find_biome_near(world, Biome.LLANOS, parral_center, 30)
	if parral == Vector2i(-1, -1):
		parral = _find_passable_near(world, parral_center, 30)
	if parral != Vector2i(-1, -1) and not _too_close(parral, world.pois, 25):
		world.pois.append(_make_poi(parral, POIType.MISION))

	# Naica anchor — solo si hay MINERO o DESIERTO cerca (no plopear mina en grassland)
	var naica_center := Vector2i(int(world.width * 0.72), int(world.height * 0.62))
	var naica := _find_biome_near(world, Biome.MINERO, naica_center, 30)
	if naica == Vector2i(-1, -1):
		naica = _find_biome_near(world, Biome.DESIERTO, naica_center, 30)
	if naica != Vector2i(-1, -1) and not _too_close(naica, world.pois, 22):
		world.pois.append(_make_poi(naica, POIType.ENTRADA_NAICA))

	# === SCATTER procgen (random + min-distance, NO grids) ===
	# Tarahumara: prioritariamente en sierra/barranca del SW
	_scatter_random(world, [Biome.SIERRA, Biome.BARRANCA], POIType.ENTRADA_TARAHUMARA,
		20, 22, rng, 0.0, 0.45, 0.35, 1.0)
	# Más Paquimé en el NW
	_scatter_random(world, [Biome.DESIERTO], POIType.ENTRADA_PAQUIME,
		12, 28, rng, 0.05, 0.55, 0.05, 0.55)
	# Naica en el E/SE
	_scatter_random(world, [Biome.MINERO, Biome.DESIERTO], POIType.ENTRADA_NAICA,
		15, 26, rng, 0.50, 1.0, 0.35, 1.0)
	# Misiones dispersas (sin región específica)
	_scatter_random(world, [Biome.LLANOS, Biome.DESIERTO], POIType.MISION,
		6, 40, rng, 0.15, 0.85, 0.15, 0.90)
	# Mata Ortiz extras (raros)
	_scatter_random(world, [Biome.LLANOS], POIType.MATA_ORTIZ,
		4, 60, rng, 0.10, 0.90, 0.10, 0.90)
	# Cementerios sembrados — min_dist 35 (stamps 17x17, evitar overlap)
	_scatter_random(world, [Biome.LLANOS, Biome.DESIERTO], POIType.CEMENTERIO,
		10, 35, rng, 0.05, 0.95, 0.05, 0.95)


# Scatter aleatorio con min-distance — distribución natural tipo Poisson disk simplificada.
func _scatter_random(world: World, biomes_ok: Array, type: int,
		target_count: int, min_dist: int, rng: RandomNumberGenerator,
		rx_min: float, rx_max: float, ry_min: float, ry_max: float) -> void:
	var x_lo: int = maxi(4, int(world.width * rx_min))
	var x_hi: int = mini(world.width - 5, int(world.width * rx_max))
	var y_lo: int = maxi(4, int(world.height * ry_min))
	var y_hi: int = mini(world.height - 5, int(world.height * ry_max))
	var placed: int = 0
	var attempts: int = 0
	var max_attempts: int = target_count * 300
	while placed < target_count and attempts < max_attempts:
		attempts += 1
		var x: int = rng.randi_range(x_lo, x_hi)
		var y: int = rng.randi_range(y_lo, y_hi)
		if not biomes_ok.has(world.get_biome(x, y)):
			continue
		if _too_close(Vector2i(x, y), world.pois, min_dist):
			continue
		world.pois.append(_make_poi(Vector2i(x, y), type))
		placed += 1


# --- Stamps multi-tile ---

func _stamp_poi(world: World, poi) -> void:
	match poi.type:
		POIType.ENTRADA_PAQUIME:
			_stamp_paquime(world, poi.pos)
		POIType.ENTRADA_TARAHUMARA:
			_stamp_tarahumara(world, poi.pos)
		POIType.ENTRADA_NAICA:
			_stamp_naica(world, poi.pos)
		POIType.MATA_ORTIZ:
			_stamp_mata_ortiz(world, poi.pos)
		POIType.MISION:
			_stamp_mision(world, poi.pos)
		POIType.CEMENTERIO:
			_stamp_cementerio(world, poi.pos)
		_:
			world.set_tile(poi.pos.x, poi.pos.y, POI_TILE[poi.type])


# === Mata Ortiz: pueblo de cerámica procedural ===
# Tamaño total ~25x25: plaza grande + chozas variadas + alambrada perimetral + decoración densa
func _stamp_mata_ortiz(world: World, center: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world.seed_value + center.x * 1031 + center.y * 2069

	var VR: int = 12  # village radius

	# 1) Plaza central 5x5 cream floor con fogata
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if world.in_bounds(x, y):
				world.set_tile(x, y, T_CREAM_FLOOR)
	world.set_tile(center.x, center.y, POI_TILE[POIType.MATA_ORTIZ])
	# Fogata comunitaria al lado norte de la plaza
	if world.in_bounds(center.x, center.y - 2):
		world.set_tile(center.x, center.y - 2, Vector2i(4, 5))  # fogata

	# 2) Chozas — 7-11 estructuras de tamaños variados
	var num_houses: int = 7 + rng.randi() % 5
	var placed: Array[Vector2i] = []
	var attempts: int = 0
	while placed.size() < num_houses and attempts < 120:
		attempts += 1
		var angle: float = rng.randf() * TAU
		var dist: float = 5.0 + rng.randf() * (VR - 3)
		var hx: int = center.x + int(cos(angle) * dist)
		var hy: int = center.y + int(sin(angle) * dist)
		if not world.in_bounds(hx, hy):
			continue
		# No muy cerca de otra choza ni del perímetro
		var too_close: bool = false
		for hp in placed:
			if absi(hp.x - hx) < 5 and absi(hp.y - hy) < 5:
				too_close = true
				break
		if too_close:
			continue
		# Tamaño variado: chozas pequeñas (half=1, 3x3) o medianas (half=2, 5x5)
		var house_half: int = 1 if rng.randf() < 0.5 else 2
		# 25% probabilidad de ruina (rancho quemado)
		var ruined: bool = rng.randf() < 0.25
		_build_house_v2(world, Vector2i(hx, hy), house_half, rng, ruined)
		placed.append(Vector2i(hx, hy))

	# 3) Caminos conectando chozas a la plaza
	for hp in placed:
		_draw_dirt_path(world, hp, center)

	# 4) Perímetro de alambrada (cerca)
	var fence_r: int = VR - 1
	for ang_i in range(0, 360, 8):
		var ang: float = deg_to_rad(ang_i + rng.randf() * 6.0)
		var fx: int = center.x + int(cos(ang) * fence_r)
		var fy: int = center.y + int(sin(ang) * fence_r)
		if not world.in_bounds(fx, fy):
			continue
		var raw_f: int = world.get_tile_raw(fx, fy)
		if not _is_structure(raw_f):
			world.set_tile(fx, fy, Vector2i(3, 5))  # alambrada

	# 5) Decoración densa: ollas Mata Ortiz, monolitos, fogatas
	for _i in range(rng.randi_range(8, 14)):
		var ox: int = center.x + rng.randi_range(-VR + 1, VR - 1)
		var oy: int = center.y + rng.randi_range(-VR + 1, VR - 1)
		if not world.in_bounds(ox, oy):
			continue
		var raw: int = world.get_tile_raw(ox, oy)
		if _is_structure(raw):
			continue
		var roll: float = rng.randf()
		if roll < 0.5:
			world.set_tile(ox, oy, Vector2i(7, 5))  # monolito (olla grande)
		elif roll < 0.75:
			world.set_tile(ox, oy, Vector2i(6, 5))  # huellas
		else:
			world.set_tile(ox, oy, Vector2i(4, 5))  # fogata pequeña


# === Misión jesuita procedural — iglesia CRUCIFORME + campanario + atrio ===
func _stamp_mision(world: World, center: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world.seed_value + center.x * 3041 + center.y * 4099

	# 1) Atrio exterior 13x13 — piso crema, perímetro de roca con apertura sur
	var R: int = 6
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			if absi(dx) == R and absi(dy) == R:
				continue
			if absi(dx) == R or absi(dy) == R:
				# Borde con apertura sur de 3 tiles
				if dy == R and absi(dx) <= 1:
					world.set_tile(x, y, T_DIRT_PATH)
				else:
					world.set_tile(x, y, Vector2i(6, 1))  # roca
			else:
				world.set_tile(x, y, T_CREAM_FLOOR)

	# 2) Iglesia CRUCIFORME (forma de cruz)
	# Nave central vertical: 3 ancho × 7 alto
	# Transepto horizontal: 7 ancho × 3 alto
	# Ambos cruzan en el centro
	var NW: int = 1  # ancho de la nave (1 → 3 tiles de ancho)
	var NH: int = 3  # alto desde centro hacia cada extremo de la nave (7 total)
	var TW: int = 3  # ancho desde centro hacia cada extremo del transepto (7 total)
	var TH: int = 1  # alto del transepto (3 tiles)

	# Pintar nave (vertical)
	for dy in range(-NH, NH + 1):
		for dx in range(-NW, NW + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			if absi(dx) == NW and absi(dy) > TH:
				world.set_tile(x, y, T_ADOBE_WALL)
			elif absi(dy) == NH:
				world.set_tile(x, y, T_ADOBE_WALL)
			else:
				world.set_tile(x, y, T_CREAM_FLOOR)

	# Pintar transepto (horizontal)
	for dy in range(-TH, TH + 1):
		for dx in range(-TW, TW + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			if absi(dx) == TW:
				world.set_tile(x, y, T_ADOBE_WALL)
			elif absi(dy) == TH and absi(dx) > NW:
				world.set_tile(x, y, T_ADOBE_WALL)
			else:
				world.set_tile(x, y, T_CREAM_FLOOR)

	# Esquinas internas del bounding box 7x7 (fuera de la cruz) → roca para
	# definir visualmente la silueta cruciforme contra el atrium crema.
	for cdy in [-3, -2, 2, 3]:
		for cdx in [-3, -2, 2, 3]:
			var ex: int = center.x + cdx
			var ey: int = center.y + cdy
			if world.in_bounds(ex, ey):
				world.set_tile(ex, ey, Vector2i(6, 1))  # roca sierra (banca/piedra)

	# Altar central
	world.set_tile(center.x, center.y, POI_TILE[POIType.MISION])

	# Puerta sur de la iglesia
	if world.in_bounds(center.x, center.y + NH):
		world.set_tile(center.x, center.y + NH, T_DIRT_PATH)

	# 3) Campanario al NE (2x2 monolitos darker)
	for dy in range(-NH - 2, -NH):
		for dx in range(NW + 1, NW + 3):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if world.in_bounds(x, y):
				world.set_tile(x, y, Vector2i(7, 5))  # monolito = piedra del campanario

	# 4) Sendero exterior al sur extendiendo hacia afuera
	for dy2 in range(R + 1, R + 6):
		for ddx in range(-1, 2):
			var px: int = center.x + ddx
			var py: int = center.y + dy2
			if world.in_bounds(px, py):
				world.set_tile(px, py, T_DIRT_PATH)

	# 5) Cruces (calaveras) y huesos dispersos como restos en el atrio
	for _i in range(rng.randi_range(3, 6)):
		var gx: int = center.x + rng.randi_range(-R + 1, R - 1)
		var gy: int = center.y + rng.randi_range(-R + 1, R - 1)
		if not world.in_bounds(gx, gy):
			continue
		var raw: int = world.get_tile_raw(gx, gy)
		if not _is_structure(raw):
			world.set_tile(gx, gy, Vector2i(4, 0) if rng.randf() < 0.5 else Vector2i(7, 0))


# === Cementerio procedural — barda doble + capilla + lápidas en clusters ===
func _stamp_cementerio(world: World, center: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = world.seed_value + center.x * 5051 + center.y * 6101

	# Perímetro 17x17 de roca DOBLE GROSOR
	var R: int = 8
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			var ad: int = maxi(absi(dx), absi(dy))
			# Esquinas exteriores libres
			if absi(dx) == R and absi(dy) == R:
				continue
			# Apertura sur de 3 tiles en barda (dirt path)
			if ad == R and dy == R and absi(dx) <= 1:
				world.set_tile(x, y, T_DIRT_PATH)
				continue
			if ad == R - 1 and dy == R - 1 and absi(dx) <= 1:
				world.set_tile(x, y, T_DIRT_PATH)
				continue
			# Barda doble (R y R-1)
			if ad == R:
				if absi(dx) == R - 1 and absi(dy) == R - 1:
					world.set_tile(x, y, Vector2i(7, 5))  # monolito esquina exterior
				else:
					world.set_tile(x, y, Vector2i(6, 1))  # roca exterior
			elif ad == R - 1:
				world.set_tile(x, y, Vector2i(6, 1))  # roca interior

	# Capilla 5x3 al norte
	var cap_y: int = center.y - 5
	for dy in range(-1, 2):
		for dx in range(-2, 3):
			var cx: int = center.x + dx
			var cy: int = cap_y + dy
			if not world.in_bounds(cx, cy):
				continue
			if absi(dx) == 2 or absi(dy) == 1:
				world.set_tile(cx, cy, T_ADOBE_WALL)
			else:
				world.set_tile(cx, cy, T_CREAM_FLOOR)
	# Altar en capilla (cementerio tile)
	world.set_tile(center.x, cap_y, POI_TILE[POIType.CEMENTERIO])
	# Puerta sur de la capilla
	if world.in_bounds(center.x, cap_y + 1):
		world.set_tile(center.x, cap_y + 1, T_DIRT_PATH)

	# Fogata ritual en el centro
	world.set_tile(center.x, center.y, Vector2i(4, 5))

	# Camino central N-S desde capilla a entrada
	# BUG fix: rango usaba `R` (relativo) en lugar de `center.y + R` (absoluto) → loop nunca iteraba.
	for dy_p in range(cap_y + 2, center.y + R):
		if world.in_bounds(center.x, dy_p):
			var raw: int = world.get_tile_raw(center.x, dy_p)
			if not _is_protected(raw):
				world.set_tile(center.x, dy_p, T_DIRT_PATH)

	# Lápidas en CLUSTERS organizados (filas paralelas, no aleatorio puro)
	var grave_tiles := [Vector2i(4, 0), Vector2i(7, 0), Vector2i(7, 5)]
	var placed_count: int = 0
	# 4-6 filas verticales de tumbas a ambos lados del camino central
	for row_i in range(4 + rng.randi() % 3):
		var side: int = -1 if row_i % 2 == 0 else 1
		var row_x: int = center.x + side * (2 + (row_i / 2) * 2)
		# 5-8 lápidas en esa fila
		var graves_in_row: int = 5 + rng.randi() % 4
		for g_i in range(graves_in_row):
			var gy: int = center.y + 2 - g_i + (rng.randi() % 2)
			if not world.in_bounds(row_x, gy):
				continue
			# Solo si el tile no es estructura
			var raw_g: int = world.get_tile_raw(row_x, gy)
			if _is_structure(raw_g):
				continue
			# Evitar pisar la fogata central
			if row_x == center.x and gy == center.y:
				continue
			world.set_tile(row_x, gy, grave_tiles[(g_i + row_i) % grave_tiles.size()])
			placed_count += 1
	# Algunas tumbas extra aleatorias — explicit skip de fogata ritual central
	for _i in range(rng.randi_range(3, 7)):
		var gx: int = center.x + rng.randi_range(-R + 2, R - 2)
		var gy2: int = center.y + rng.randi_range(-R + 2, R - 2)
		if not world.in_bounds(gx, gy2):
			continue
		if gx == center.x and gy2 == center.y:
			continue  # no pisar la fogata ritual
		var raw_e: int = world.get_tile_raw(gx, gy2)
		if _is_structure(raw_e):
			continue
		world.set_tile(gx, gy2, grave_tiles[rng.randi() % grave_tiles.size()])


# === Helpers ===

func _build_house_v2(world: World, center: Vector2i, half: int, rng: RandomNumberGenerator, ruined: bool) -> void:
	# Defensive: clamp half para evitar 1x1 houses con door = wall = mismo tile.
	half = maxi(1, half)
	# Casa con muros adobe + interior crema. Si ruined=true, ~35% de muros faltan (look quemado).
	for dy in range(-half, half + 1):
		for dx in range(-half, half + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			var is_wall: bool = absi(dx) == half or absi(dy) == half
			if is_wall:
				if ruined and rng.randf() < 0.35:
					# Muro caído: dejar el rancho_burn tile como escombro
					world.set_tile(x, y, Vector2i(2, 5))
				else:
					world.set_tile(x, y, T_ADOBE_WALL)
			else:
				world.set_tile(x, y, T_CREAM_FLOOR)
	# Puerta hacia un lado aleatorio (siempre, incluso ruined)
	var dir: int = rng.randi() % 4
	var door_dx: int = 0
	var door_dy: int = 0
	match dir:
		0: door_dy = -half
		1: door_dx = half
		2: door_dy = half
		3: door_dx = -half
	var dx_pos: int = center.x + door_dx
	var dy_pos: int = center.y + door_dy
	if world.in_bounds(dx_pos, dy_pos):
		world.set_tile(dx_pos, dy_pos, T_DIRT_PATH)
	# Para casas grandes (half=2), agregar un anexo pequeño al lado
	if half >= 2 and not ruined and rng.randf() < 0.5:
		var annex_side: int = rng.randi() % 4
		var ax: int = center.x
		var ay: int = center.y
		match annex_side:
			0: ay -= half + 2
			1: ax += half + 2
			2: ay += half + 2
			3: ax -= half + 2
		# Pequeño 1x1 anexo (corralito)
		if world.in_bounds(ax, ay):
			world.set_tile(ax, ay, Vector2i(3, 5))  # alambrada como cerca


func _draw_dirt_path(world: World, a: Vector2i, b: Vector2i) -> void:
	# Bresenham simple, NO sobrescribe ADOBE_WALL ni POI tiles
	var x0: int = a.x; var y0: int = a.y
	var x1: int = b.x; var y1: int = b.y
	var dx: int = absi(x1 - x0); var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	var steps: int = 0
	while (x0 != x1 or y0 != y1) and steps < 100:
		steps += 1
		if world.in_bounds(x0, y0):
			var raw: int = world.get_tile_raw(x0, y0)
			if not _is_protected(raw):
				world.set_tile(x0, y0, T_DIRT_PATH)
		var e2: int = 2 * err
		if e2 > -dy: err -= dy; x0 += sx
		if e2 < dx: err += dx; y0 += sy


func _is_structure(raw: int) -> bool:
	# True si el tile actual es parte de una estructura — incluye walls, floors,
	# paths, rocas perímetro, alambradas, fogatas, monolitos (todos tiles de stamps).
	var src: int = (raw >> 16) & 0xff
	if src != 0:
		return false
	var atlas := Vector2i((raw >> 8) & 0xff, raw & 0xff)
	return (
		atlas == T_ADOBE_WALL
		or atlas == T_CREAM_FLOOR
		or atlas == T_DIRT_PATH
		or atlas == Vector2i(6, 1)   # roca sierra (perímetros)
		or atlas == Vector2i(3, 5)   # alambrada
		or atlas == Vector2i(4, 5)   # fogata
		or atlas == Vector2i(7, 5)   # monolito
		or atlas == Vector2i(2, 5)   # rancho quemado
		or atlas == T_WOOD_FRAME
		or atlas == T_CAVE_ROCK
		or atlas == T_RAILS
	)


func _is_protected(raw: int) -> bool:
	# True si el path NO debe sobrescribir este tile (walls, rocas perimetrales, POIs)
	var src: int = (raw >> 16) & 0xff
	if src != 0:
		return false
	var atlas := Vector2i((raw >> 8) & 0xff, raw & 0xff)
	return (
		atlas == T_ADOBE_WALL
		or atlas == Vector2i(6, 1)
		or atlas == Vector2i(3, 5)   # alambrada
		or atlas == Vector2i(4, 5)   # fogata
		or atlas == Vector2i(7, 5)   # monolito
		or atlas == T_WOOD_FRAME
		or atlas == T_CAVE_ROCK
		or atlas == POI_TILE[POIType.MATA_ORTIZ]
		or atlas == POI_TILE[POIType.MISION]
		or atlas == POI_TILE[POIType.CEMENTERIO]
		or atlas == POI_TILE[POIType.ENTRADA_PAQUIME]
		or atlas == POI_TILE[POIType.ENTRADA_TARAHUMARA]
		or atlas == POI_TILE[POIType.ENTRADA_NAICA]
	)


func _stamp_paquime(world: World, center: Vector2i) -> void:
	# Estampa 9x9 — ruinas con apertura SUR. Interior: piso crema con escombros aleatorios.
	var R := 4
	var rng := RandomNumberGenerator.new()
	rng.seed = world.seed_value + center.x * 1217 + center.y * 4517
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			var ad: int = maxi(absi(dx), absi(dy))
			# Esquinas del 9x9 sin pintar (ruinas)
			if absi(dx) == R and absi(dy) == R:
				continue
			# ENTRADA al centro
			if dx == 0 and dy == 0:
				world.set_tile(x, y, POI_TILE[POIType.ENTRADA_PAQUIME])
				continue
			# APERTURA SUR: 3 tiles de ancho en el borde sur → dirt path
			if ad == R and dy == R and absi(dx) <= 1:
				world.set_tile(x, y, T_DIRT_PATH)
				continue
			if ad == R:
				# Borde exterior: muros adobe (con ocasionales huecos para look ruinoso)
				if rng.randf() < 0.10:
					world.set_tile(x, y, T_CREAM_FLOOR)
				else:
					world.set_tile(x, y, T_ADOBE_WALL)
			else:
				# INTERIOR: piso crema con escombros adobe esparcidos (ruinas).
				# IMPORTANTE: NO sembrar escombros en la columna dx==0 para garantizar
				# que el corredor desde la apertura sur al centro quede libre.
				if dx != 0 and ad <= 2 and rng.randf() < 0.18:
					world.set_tile(x, y, T_ADOBE_WALL)  # escombro pillar
				else:
					world.set_tile(x, y, T_CREAM_FLOOR)
	# Sendero de aproximación al sur (más largo)
	for dy in range(R + 1, R + 6):
		for dx in range(-1, 2):
			var px: int = center.x + dx
			var py: int = center.y + dy
			if world.in_bounds(px, py):
				world.set_tile(px, py, T_DIRT_PATH)


func _stamp_tarahumara(world: World, center: Vector2i) -> void:
	# Estampa 9x9 — formación rocosa con boca de cueva oscura, abertura al sur + sendero
	var R := 4
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			# Apertura sur — pintar shadow para garantizar transitable (no `continue`,
			# si no se quedaba con el bioma de abajo que podía ser BARRANCA/PICO).
			if dy == R and absi(dx) <= 1:
				world.set_tile(x, y, T_CAVE_SHADOW)
				continue
			if dy == R - 1 and absi(dx) <= 1:
				world.set_tile(x, y, T_CAVE_SHADOW)
				continue
			if dx == 0 and dy == 0:
				world.set_tile(x, y, POI_TILE[POIType.ENTRADA_TARAHUMARA])
			elif absi(dx) >= R - 1 or absi(dy) >= R - 1:
				world.set_tile(x, y, T_CAVE_ROCK)
			else:
				world.set_tile(x, y, T_CAVE_SHADOW)
	# Sendero de aproximación al sur (faltaba — como Paquimé/Naica)
	for dy2 in range(R + 1, R + 6):
		for ddx in range(-1, 2):
			var px: int = center.x + ddx
			var py: int = center.y + dy2
			if world.in_bounds(px, py):
				world.set_tile(px, py, T_DIRT_PATH)


func _stamp_naica(world: World, center: Vector2i) -> void:
	# Estampa 9x9 — marco simple de madera + rieles internos + apertura SUR + entrada centro
	var R := 4
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			var ad: int = maxi(absi(dx), absi(dy))
			# Esquinas exteriores libres
			if absi(dx) == R and absi(dy) == R:
				continue
			# ENTRADA centro
			if dx == 0 and dy == 0:
				world.set_tile(x, y, POI_TILE[POIType.ENTRADA_NAICA])
				continue
			# APERTURA SUR (3 tiles) → rails para que se pueda entrar caminando
			if ad == R and dy == R and absi(dx) <= 1:
				world.set_tile(x, y, T_RAILS)
				continue
			# Borde: marco de madera simple
			if ad == R:
				world.set_tile(x, y, T_WOOD_FRAME)
			else:
				# Interior completamente rails (transitable)
				world.set_tile(x, y, T_RAILS)
	# Rieles extendiéndose al sur 6 tiles
	for dy2 in range(R + 1, R + 7):
		for dx in range(-1, 2):
			var px: int = center.x + dx
			var py: int = center.y + dy2
			if world.in_bounds(px, py):
				world.set_tile(px, py, T_RAILS)


# --- Helpers ---

func _too_close(p: Vector2i, pois: Array, min_dist: int) -> bool:
	for poi in pois:
		var pp: POI = poi
		var dx: int = p.x - pp.pos.x
		var dy: int = p.y - pp.pos.y
		if dx * dx + dy * dy < min_dist * min_dist:
			return true
	return false


func _find_biome_near(world: World, biome: int, center: Vector2i, radius: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1_000_000
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if x < 4 or x >= world.width - 4 or y < 4 or y >= world.height - 4:
				continue
			if world.get_biome(x, y) != biome:
				continue
			var d: int = dx * dx + dy * dy
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
	return best


func _find_passable_near(world: World, center: Vector2i, radius: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 1_000_000
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if x < 4 or x >= world.width - 4 or y < 4 or y >= world.height - 4:
				continue
			var b: int = world.get_biome(x, y)
			if b == Biome.RIO or b == Biome.BARRANCA or b == Biome.PICO:
				continue
			var d: int = dx * dx + dy * dy
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
	return best


