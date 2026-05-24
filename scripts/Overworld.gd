# Generación basada en geografía REAL de Chihuahua.
# Multi-source tile encoding: (source_id << 16) | (atlas_x << 8) | atlas_y

class_name Overworld
extends RefCounted

# Source IDs (orden de adds al TileSet)
const SRC_OVERWORLD := 0
const SRC_DESERT := 1

enum Biome {
	DESIERTO, LLANOS, SIERRA, BARRANCA, MINERO, RIO, MESA, PICO,
}

enum POIType {
	MATA_ORTIZ, MISION, CEMENTERIO,
	ENTRADA_PAQUIME, ENTRADA_TARAHUMARA, ENTRADA_NAICA,
}

# Tile primario {src, atlas}
const BIOME_PRIMARY := {
	Biome.DESIERTO: {"src": SRC_DESERT, "atlas": Vector2i(0, 0)},  # nuevo atlas dorado
	Biome.LLANOS:   {"src": SRC_OVERWORLD, "atlas": Vector2i(0, 1)},
	Biome.SIERRA:   {"src": SRC_OVERWORLD, "atlas": Vector2i(3, 1)},
	Biome.BARRANCA: {"src": SRC_OVERWORLD, "atlas": Vector2i(0, 2)},
	Biome.MINERO:   {"src": SRC_OVERWORLD, "atlas": Vector2i(3, 2)},
	Biome.RIO:      {"src": SRC_OVERWORLD, "atlas": Vector2i(6, 2)},
	Biome.MESA:     {"src": SRC_OVERWORLD, "atlas": Vector2i(7, 4)},
	Biome.PICO:     {"src": SRC_OVERWORLD, "atlas": Vector2i(0, 5)},
}

# Decoraciones por bioma
const BIOME_DECORS := {
	Biome.DESIERTO: [
		# Variantes del nuevo atlas dorado (rows 0-3 = stone fill)
		{"src": SRC_DESERT, "atlas": Vector2i(1, 0)},
		{"src": SRC_DESERT, "atlas": Vector2i(2, 0)},
		{"src": SRC_DESERT, "atlas": Vector2i(3, 0)},
		{"src": SRC_DESERT, "atlas": Vector2i(0, 1)},
		{"src": SRC_DESERT, "atlas": Vector2i(1, 1)},
		{"src": SRC_DESERT, "atlas": Vector2i(2, 1)},
		{"src": SRC_DESERT, "atlas": Vector2i(0, 2)},
		{"src": SRC_DESERT, "atlas": Vector2i(1, 2)},
		# + decoraciones atmosféricas del atlas viejo
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 0)},  # sotol
		{"src": SRC_OVERWORLD, "atlas": Vector2i(3, 0)},  # lechuguilla
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 0)},  # calavera
		{"src": SRC_OVERWORLD, "atlas": Vector2i(6, 0)},  # cactus muerto
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 0)},  # huesos
		{"src": SRC_OVERWORLD, "atlas": Vector2i(1, 5)},  # cardón
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 5)},  # rancho quemado
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 5)},  # monolito
	],
	Biome.LLANOS: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(1, 1)},  # mezquite
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 1)},  # pasto alto
		{"src": SRC_OVERWORLD, "atlas": Vector2i(3, 5)},  # alambrada
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 5)},  # fogata
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 5)},  # rancho quemado
		{"src": SRC_OVERWORLD, "atlas": Vector2i(6, 5)},  # huellas
	],
	Biome.SIERRA: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 1)},  # pino
		{"src": SRC_OVERWORLD, "atlas": Vector2i(5, 1)},  # pino seco
		{"src": SRC_OVERWORLD, "atlas": Vector2i(6, 1)},  # roca
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 1)},  # árbol muerto
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 5)},  # monolito
	],
	Biome.BARRANCA: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(1, 2)},
		{"src": SRC_OVERWORLD, "atlas": Vector2i(2, 2)},
	],
	Biome.MINERO: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(4, 2)},
		{"src": SRC_OVERWORLD, "atlas": Vector2i(5, 2)},
	],
	Biome.RIO: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(7, 2)},
	],
	Biome.MESA: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(5, 0)},
	],
	Biome.PICO: [
		{"src": SRC_OVERWORLD, "atlas": Vector2i(0, 5)},
	],
}

const DECOR_PROBS := {
	Biome.DESIERTO: 0.40,  # MUY VARIADO — el atlas dorado tiene muchas variantes
	Biome.LLANOS:   0.20,
	Biome.SIERRA:   0.28,
	Biome.BARRANCA: 0.18,
	Biome.MINERO:   0.30,
	Biome.RIO:      0.08,
	Biome.MESA:     0.12,
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
	var tiles: PackedInt32Array  # packed: (src<<16) | (x<<8) | y
	var pois: Array = []
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
	world.pois = []

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

	var n_mesa := FastNoiseLite.new()
	n_mesa.seed = seed_value + 5077
	n_mesa.noise_type = FastNoiseLite.TYPE_CELLULAR
	n_mesa.frequency = 0.012

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
			if elev > 0.95:
				biome = Biome.PICO
			elif elev > 0.78:
				if absf(noise) > 0.15:
					biome = Biome.BARRANCA
				else:
					biome = Biome.SIERRA
			elif elev > 0.62:
				biome = Biome.SIERRA
			elif elev > 0.48:
				if humid > 0.55:
					biome = Biome.SIERRA
				else:
					biome = Biome.LLANOS
			elif elev > 0.30:
				if m > 0.40:
					biome = Biome.MINERO
				elif ms > 0.50 and humid < 0.5:
					biome = Biome.MESA
				else:
					biome = Biome.LLANOS
			elif elev > 0.15:
				if m > 0.45:
					biome = Biome.MINERO
				elif ms > 0.55:
					biome = Biome.MESA
				elif humid > 0.65:
					biome = Biome.LLANOS
				else:
					biome = Biome.DESIERTO
			else:
				biome = Biome.DESIERTO

			world.set_biome(x, y, biome)

	# === Pase 2: Ríos (angostos) ===
	_carve_river(world, [
		Vector2i(int(w * 0.12), int(h * 0.85)),
		Vector2i(int(w * 0.22), int(h * 0.72)),
		Vector2i(int(w * 0.32), int(h * 0.65)),
		Vector2i(int(w * 0.42), int(h * 0.58)),
		Vector2i(int(w * 0.52), int(h * 0.50)),
		Vector2i(int(w * 0.62), int(h * 0.45)),
		Vector2i(int(w * 0.72), int(h * 0.38)),
		Vector2i(int(w * 0.82), int(h * 0.30)),
		Vector2i(int(w * 0.95), int(h * 0.18)),
	], 1)
	_carve_river(world, [
		Vector2i(int(w * 0.58), int(h * 0.92)),
		Vector2i(int(w * 0.58), int(h * 0.80)),
		Vector2i(int(w * 0.60), int(h * 0.68)),
		Vector2i(int(w * 0.60), int(h * 0.55)),
	], 0)
	_carve_river(world, [
		Vector2i(int(w * 0.18), int(h * 0.08)),
		Vector2i(int(w * 0.25), int(h * 0.12)),
		Vector2i(int(w * 0.32), int(h * 0.18)),
		Vector2i(int(w * 0.32), int(h * 0.25)),
	], 0)
	_carve_river(world, [
		Vector2i(int(w * 0.45), int(h * 0.10)),
		Vector2i(int(w * 0.52), int(h * 0.30)),
		Vector2i(int(w * 0.55), int(h * 0.48)),
	], 0)

	# === Pase 3: variantes (decoraciones) ===
	var n_decor := FastNoiseLite.new()
	n_decor.seed = seed_value + 4099
	n_decor.noise_type = FastNoiseLite.TYPE_VALUE
	n_decor.frequency = 0.7

	for y in range(h):
		for x in range(w):
			var biome: int = world.get_biome(x, y)
			var primary: Dictionary = BIOME_PRIMARY[biome]
			var src: int = primary["src"]
			var atlas: Vector2i = primary["atlas"]
			var roll: float = (n_decor.get_noise_2d(x, y) + 1.0) * 0.5
			var prob: float = DECOR_PROBS.get(biome, 0.0)
			if roll < prob and BIOME_DECORS.has(biome) and not BIOME_DECORS[biome].is_empty():
				var decors: Array = BIOME_DECORS[biome]
				var idx: int = int(roll * 10000.0) % decors.size()
				var d: Dictionary = decors[idx]
				src = d["src"]
				atlas = d["atlas"]
			world.set_tile_pair(x, y, src, atlas)

	# === Pase 4: POIs + stamps ===
	_place_pois_chihuahua(world, rng)
	for poi in world.pois:
		_stamp_poi(world, poi)

	return world


func _carve_river(world: World, waypoints: Array, width: int) -> void:
	for i in range(waypoints.size() - 1):
		_draw_line_river(world, waypoints[i], waypoints[i + 1], width)


func _draw_line_river(world: World, a: Vector2i, b: Vector2i, width: int) -> void:
	var x0: int = a.x; var y0: int = a.y
	var x1: int = b.x; var y1: int = b.y
	var dx: int = absi(x1 - x0); var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	while true:
		for ny in range(-width, width + 1):
			for nx in range(-width, width + 1):
				if nx * nx + ny * ny > width * width:
					continue
				var px: int = x0 + nx; var py: int = y0 + ny
				if world.in_bounds(px, py):
					world.set_biome(px, py, Biome.RIO)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 > -dy: err -= dy; x0 += sx
		if e2 < dx: err += dx; y0 += sy


func _make_poi(pos: Vector2i, type: int) -> POI:
	var p := POI.new(); p.pos = pos; p.type = type
	return p


func _place_pois_chihuahua(world: World, rng: RandomNumberGenerator) -> void:
	# === ANCHORS handcrafted (siempre intentar primero) ===
	# Mata Ortiz: NW Llanos
	var mata := _find_passable_near(world, Vector2i(int(world.width * 0.25), int(world.height * 0.22)), 30)
	if mata != Vector2i(-1, -1):
		world.pois.append(_make_poi(mata, POIType.MATA_ORTIZ))

	# Paquimé anchor (NW Desierto)
	var paq := _find_biome_near(world, Biome.DESIERTO,
		Vector2i(int(world.width * 0.30), int(world.height * 0.18)), 30)
	if paq == Vector2i(-1, -1):
		paq = _find_passable_near(world, Vector2i(int(world.width * 0.30), int(world.height * 0.18)), 30)
	if paq != Vector2i(-1, -1):
		world.pois.append(_make_poi(paq, POIType.ENTRADA_PAQUIME))

	# Parral (S) misión handcrafted
	var parral := _find_passable_near(world, Vector2i(int(world.width * 0.45), int(world.height * 0.85)), 30)
	if parral != Vector2i(-1, -1):
		world.pois.append(_make_poi(parral, POIType.MISION))

	# Naica anchor
	var naica := _find_biome_near(world, Biome.MINERO,
		Vector2i(int(world.width * 0.72), int(world.height * 0.62)), 30)
	if naica == Vector2i(-1, -1):
		naica = _find_passable_near(world, Vector2i(int(world.width * 0.72), int(world.height * 0.62)), 30)
	if naica != Vector2i(-1, -1):
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
	# Cementerios sembrados
	_scatter_random(world, [Biome.LLANOS, Biome.DESIERTO], POIType.CEMENTERIO,
		12, 18, rng, 0.05, 0.95, 0.05, 0.95)


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
		_:
			world.set_tile(poi.pos.x, poi.pos.y, POI_TILE[poi.type])


func _stamp_paquime(world: World, center: Vector2i) -> void:
	# Estampa 9x9 — ruinas masivas con muros gruesos, piso crema, entrada central, sendero
	var R := 4
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			var ad: int = maxi(absi(dx), absi(dy))
			# Esquinas del 9x9 las dejamos sin pintar (ruinas)
			if ad == R and absi(dx) == R and absi(dy) == R:
				continue
			if dx == 0 and dy == 0:
				world.set_tile(x, y, POI_TILE[POIType.ENTRADA_PAQUIME])
			elif ad == R:
				# Borde exterior: muros adobe
				world.set_tile(x, y, T_ADOBE_WALL)
			elif ad == R - 1:
				# Anillo interior: piso crema (patio)
				world.set_tile(x, y, T_CREAM_FLOOR)
			elif ad == 1:
				# Anillo cercano al centro: muros derruidos
				world.set_tile(x, y, T_ADOBE_WALL)
			else:
				world.set_tile(x, y, T_CREAM_FLOOR)
	# Sendero de aproximación al sur (más largo)
	for dy in range(R + 1, R + 5):
		for dx in range(-1, 2):
			var px: int = center.x + dx
			var py: int = center.y + dy
			if world.in_bounds(px, py):
				world.set_tile(px, py, T_DIRT_PATH)


func _stamp_tarahumara(world: World, center: Vector2i) -> void:
	# Estampa 9x9 — formación rocosa con boca de cueva oscura, abertura al sur
	var R := 4
	for dy in range(-R, R + 1):
		for dx in range(-R, R + 1):
			var x: int = center.x + dx
			var y: int = center.y + dy
			if not world.in_bounds(x, y):
				continue
			# La parte sur (la boca) deja salida
			if dy == R and absi(dx) <= 1:
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


func _stamp_naica(world: World, center: Vector2i) -> void:
	# Estampa 9x9 — marco grueso de madera + rieles internos + entrada central
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
			if dx == 0 and dy == 0:
				world.set_tile(x, y, POI_TILE[POIType.ENTRADA_NAICA])
			elif ad == R:
				world.set_tile(x, y, T_WOOD_FRAME)
			elif ad == R - 1:
				world.set_tile(x, y, T_WOOD_FRAME)
			else:
				world.set_tile(x, y, T_RAILS)
	# Rieles extendiéndose al sur 5 tiles
	for dy2 in range(R + 1, R + 6):
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


func _find_random_in_any_of(world: World, biomes_ok: Array, existing: Array, min_dist: int, rng: RandomNumberGenerator) -> Vector2i:
	for _i in range(400):
		var x: int = rng.randi_range(5, world.width - 6)
		var y: int = rng.randi_range(5, world.height - 6)
		if not biomes_ok.has(world.get_biome(x, y)):
			continue
		var ok: bool = true
		for p in existing:
			var pp: POI = p
			var dx: int = x - pp.pos.x
			var dy: int = y - pp.pos.y
			if dx * dx + dy * dy < min_dist * min_dist:
				ok = false
				break
		if ok:
			return Vector2i(x, y)
	return Vector2i(-1, -1)
