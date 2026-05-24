# Generador de cueva CON:
# - Set piece (cámara principal) carved con perlin agresivo
# - Corredores DRUNKARD'S WALK (orgánicos, no Bresenham)
# - Autotile bitmask
# - Decoración en pisos

class_name CaveGenerator
extends RefCounted

# Filas 0-3: 32 fill tiles
const FILL_VARIANTS: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),
	Vector2i(4,0), Vector2i(5,0), Vector2i(6,0), Vector2i(7,0),
	Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1),
	Vector2i(4,1), Vector2i(5,1), Vector2i(6,1), Vector2i(7,1),
	Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2),
	Vector2i(4,2), Vector2i(5,2), Vector2i(6,2), Vector2i(7,2),
	Vector2i(0,3), Vector2i(1,3), Vector2i(2,3), Vector2i(3,3),
	Vector2i(4,3), Vector2i(5,3), Vector2i(6,3), Vector2i(7,3),
]
const EDGE_VARIANTS: Array[Vector2i] = [
	Vector2i(0,4), Vector2i(1,4), Vector2i(2,4), Vector2i(3,4),
	Vector2i(4,4), Vector2i(5,4), Vector2i(6,4), Vector2i(7,4),
]
const CORNER_VARIANTS: Array[Vector2i] = [
	Vector2i(0,5), Vector2i(1,5), Vector2i(2,5), Vector2i(3,5),
	Vector2i(4,5), Vector2i(5,5), Vector2i(6,5), Vector2i(7,5),
]
const CAP_VARIANTS: Array[Vector2i] = [
	Vector2i(0,6), Vector2i(1,6), Vector2i(2,6), Vector2i(3,6),
	Vector2i(4,6), Vector2i(5,6), Vector2i(6,6), Vector2i(7,6),
]
const ISOLATED_VARIANTS: Array[Vector2i] = [
	Vector2i(0,7), Vector2i(1,7), Vector2i(2,7), Vector2i(3,7),
	Vector2i(4,7), Vector2i(5,7), Vector2i(6,7), Vector2i(7,7),
]


class Cave:
	var width: int
	var height: int
	var walls: PackedByteArray
	var floor_decor: Dictionary = {}  # Vector2i → variant index 0-3
	var floor_scatter: Dictionary = {}  # Vector2i → small rock atlas
	var spawn: Vector2i
	var exit_pos: Vector2i
	var seed_value: int

	func is_wall(x: int, y: int) -> bool:
		if x < 0 or x >= width or y < 0 or y >= height:
			return true
		return walls[y * width + x] == 1

	func set_wall(x: int, y: int, v: int) -> void:
		walls[y * width + x] = v


var rng := RandomNumberGenerator.new()


func generate(w: int, h: int, seed_value: int) -> Cave:
	rng.seed = seed_value
	var cave := Cave.new()
	cave.width = w; cave.height = h; cave.seed_value = seed_value
	cave.walls = PackedByteArray()
	cave.walls.resize(w * h)
	for i in range(w * h):
		cave.walls[i] = 1

	# === SET PIECE: cámara principal irregular ===
	var chamber_cx: int = w / 2
	var chamber_cy: int = h / 2
	var chamber_r: int = mini(w, h) / 4
	_carve_chamber(cave, chamber_cx, chamber_cy, chamber_r, 4.0)  # mucho noise

	# === Cámara secundaria SE (exit) ===
	var sec_cx: int = int(w * 0.82)
	var sec_cy: int = int(h * 0.78)
	_carve_chamber(cave, sec_cx, sec_cy, chamber_r / 2 + 2, 3.0)

	# === Vestíbulo NW (entrada) ===
	var entry_x: int = int(w * 0.12)
	var entry_y: int = int(h * 0.18)
	_carve_chamber(cave, entry_x, entry_y, 5, 2.0)

	# === CORREDORES DRUNKARD (no Bresenham) ===
	_drunk_walk(cave, Vector2i(entry_x, entry_y), Vector2i(chamber_cx, chamber_cy), 2)
	_drunk_walk(cave, Vector2i(chamber_cx, chamber_cy), Vector2i(sec_cx, sec_cy), 2)

	# === 6 ramas radiales desde la cámara principal ===
	var num_branches: int = 6
	for i in range(num_branches):
		var angle: float = (TAU / num_branches) * i + rng.randf() * 0.5
		var dist: float = chamber_r + 6 + rng.randf() * 8
		var ex: int = chamber_cx + int(cos(angle) * dist)
		var ey: int = chamber_cy + int(sin(angle) * dist)
		_drunk_walk(cave, Vector2i(chamber_cx, chamber_cy), Vector2i(ex, ey), 1 + rng.randi() % 2)
		# Pequeña cámara al final
		if rng.randf() < 0.6:
			_carve_chamber(cave, ex, ey, 2 + rng.randi() % 3, 1.5)

	# Bordes
	for x in range(w):
		cave.set_wall(x, 0, 1)
		cave.set_wall(x, h - 1, 1)
	for y in range(h):
		cave.set_wall(0, y, 1)
		cave.set_wall(w - 1, y, 1)

	cave.spawn = Vector2i(entry_x, entry_y)
	cave.exit_pos = Vector2i(sec_cx, sec_cy)
	cave.set_wall(cave.spawn.x, cave.spawn.y, 0)
	cave.set_wall(cave.exit_pos.x, cave.exit_pos.y, 0)

	# === DECORACIONES de piso (rocas, charcos) ===
	# Floor cells dispersos: poner una "isolated rock" del atlas (row 7) sobre piso
	for _i in range(int(w * h * 0.008)):
		var fx: int = rng.randi_range(2, w - 3)
		var fy: int = rng.randi_range(2, h - 3)
		if cave.walls[fy * w + fx] == 0:
			cave.floor_scatter[Vector2i(fx, fy)] = ISOLATED_VARIANTS[rng.randi() % ISOLATED_VARIANTS.size()]

	# === Variantes de piso (4 variants seed determinístico) ===
	for y in range(h):
		for x in range(w):
			if cave.walls[y * w + x] == 0:
				cave.floor_decor[Vector2i(x, y)] = (x * 17 + y * 13) % 4

	return cave


func _carve_chamber(cave: Cave, cx: int, cy: int, r: int, noise_amp: float) -> void:
	# Cámara con perlin MUY agresivo (forma irregular)
	var n := FastNoiseLite.new()
	n.seed = cave.seed_value + cx * 17 + cy * 31
	n.frequency = 0.15
	n.fractal_octaves = 3
	for dy in range(-r - 4, r + 5):
		for dx in range(-r - 4, r + 5):
			var x: int = cx + dx
			var y: int = cy + dy
			if x < 1 or x >= cave.width - 1 or y < 1 or y >= cave.height - 1:
				continue
			var off: float = n.get_noise_2d(x, y) * noise_amp
			var dist: float = sqrt(dx * dx + dy * dy) + off
			if dist <= r:
				cave.set_wall(x, y, 0)


func _drunk_walk(cave: Cave, a: Vector2i, b: Vector2i, width: int) -> void:
	# Drunkard's walk: 70% paso hacia target, 30% paso aleatorio. Genera corredores orgánicos.
	var x: int = a.x; var y: int = a.y
	var max_steps: int = (absi(a.x - b.x) + absi(a.y - b.y)) * 5
	var steps: int = 0
	while steps < max_steps and (x != b.x or y != b.y):
		# Pinta área alrededor del paso actual
		for dy in range(-width, width + 1):
			for dx in range(-width, width + 1):
				if dx * dx + dy * dy > width * width + 1:
					continue
				var px: int = x + dx
				var py: int = y + dy
				if px > 0 and py > 0 and px < cave.width - 1 and py < cave.height - 1:
					cave.set_wall(px, py, 0)
		# Decide siguiente paso
		if rng.randf() < 0.68:
			# hacia target
			if x < b.x: x += 1
			elif x > b.x: x -= 1
			elif y < b.y: y += 1
			elif y > b.y: y -= 1
		else:
			# aleatorio
			match rng.randi() % 4:
				0: x += 1
				1: x -= 1
				2: y += 1
				3: y -= 1
		x = clampi(x, 2, cave.width - 3)
		y = clampi(y, 2, cave.height - 3)
		steps += 1


# --- AUTOTILE ---

static func count_wall_neighbors(cave: Cave, x: int, y: int) -> int:
	var n: int = 0
	if cave.is_wall(x, y - 1): n += 1
	if cave.is_wall(x + 1, y): n += 1
	if cave.is_wall(x, y + 1): n += 1
	if cave.is_wall(x - 1, y): n += 1
	return n


static func get_tile_for(cave: Cave, x: int, y: int) -> Vector2i:
	var n: int = count_wall_neighbors(cave, x, y)
	var seed_idx: int = (x * 73 + y * 19) % 8
	match n:
		4:
			return FILL_VARIANTS[(x * 73 + y * 19) % FILL_VARIANTS.size()]
		3:
			return EDGE_VARIANTS[seed_idx]
		2:
			return CORNER_VARIANTS[seed_idx]
		1:
			return CAP_VARIANTS[seed_idx]
		_:
			return ISOLATED_VARIANTS[seed_idx]
