# Generador de mina NAICA con SET-PIECE: la CÁMARA DE CRISTALES.
#
# Estructura forzada (Zelda critical path + Disney "weenie"):
#   1. ENTRADA al norte (vestíbulo con marco de madera)
#   2. POZO PRINCIPAL: corredor vertical descendiendo
#   3. RAMAS LATERALES con depósitos de mineral
#   4. CÁMARA DE CRISTALES al sur (set-piece final, círculo grande con cristales gigantes)
#   5. La cámara de cristales es la SALIDA (vuelta al overworld)

class_name MineGenerator
extends RefCounted

const FILL_VARIANTS: Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0),
	Vector2i(4,0), Vector2i(5,0),
	Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1),
	Vector2i(4,1), Vector2i(5,1),
	Vector2i(0,2), Vector2i(1,2), Vector2i(3,2), Vector2i(5,2),
	Vector2i(0,3), Vector2i(3,3),
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
	Vector2i(4,6), Vector2i(5,6),
]
const ISOLATED_VARIANTS: Array[Vector2i] = [
	Vector2i(3,7), Vector2i(4,7), Vector2i(5,7),
]

# Decoraciones especiales del atlas mines
const T_MINE_CART := Vector2i(0, 6)
const T_LADDER := Vector2i(1, 6)
const T_CRATE := Vector2i(2, 6)
const T_ROCKS := Vector2i(3, 6)
const T_ORE := Vector2i(4, 6)
const T_LANTERN := Vector2i(1, 8)
const T_WATER_POOL := Vector2i(2, 8)
const T_GOLD_ORE := Vector2i(6, 8)
const T_COPPER_ORE := Vector2i(7, 8)
const T_CRYSTAL_BIG := Vector2i(7, 7)   # cristal grande (set-piece chamber)
const T_CRYSTAL_SMALL := Vector2i(5, 7) # cristales pequeños


class Mine:
	var width: int
	var height: int
	var walls: PackedByteArray  # 1=wall, 0=floor
	var decor: Dictionary = {}  # Vector2i → atlas
	var crystal_chamber: Rect2i
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


func generate(w: int, h: int, seed_value: int) -> Mine:
	rng.seed = seed_value
	var mine := Mine.new()
	mine.width = w; mine.height = h; mine.seed_value = seed_value
	mine.walls = PackedByteArray()
	mine.walls.resize(w * h)

	# Init todo wall
	for i in range(w * h):
		mine.walls[i] = 1

	# === SET PIECE: CÁMARA DE CRISTALES al sur ===
	var crystal_cx: int = w / 2
	var crystal_cy: int = int(h * 0.8)
	# Clamp crystal_r para que el chamber no salga del mapa
	var crystal_r: int = mini(mini(w, h) / 4, mini(crystal_cx - 3, mini(w - crystal_cx - 3, h - crystal_cy - 3)))
	crystal_r = maxi(4, crystal_r)
	_carve_chamber(mine, crystal_cx, crystal_cy, crystal_r, 0.3)
	mine.crystal_chamber = Rect2i(
		maxi(0, crystal_cx - crystal_r),
		maxi(0, crystal_cy - crystal_r),
		mini(crystal_r * 2, w),
		mini(crystal_r * 2, h)
	)

	# === ENTRADA: vestíbulo al norte ===
	var entry_x: int = w / 2
	var entry_y: int = maxi(2, int(h * 0.10))  # clamp para no pisar el borde
	_carve_chamber(mine, entry_x, entry_y, 4, 0.2)

	# === POZO PRINCIPAL: corredor recto del vestíbulo a la cámara ===
	for y in range(entry_y, crystal_cy):
		for dx in range(-2, 3):
			var x: int = entry_x + dx
			if x > 0 and x < w - 1:
				mine.set_wall(x, y, 0)
		# Asegurar conexión con cámara
		if y > crystal_cy - crystal_r and absi(y - crystal_cy) <= crystal_r:
			for dx in range(-3, 4):
				var x: int = entry_x + dx
				if x > 0 and x < w - 1:
					mine.set_wall(x, y, 0)

	# === RAMAS LATERALES proporcionales al tamaño del shaft ===
	var shaft_h: int = crystal_cy - entry_y
	var num_branches: int = clampi(shaft_h / 10, 1, 6)
	var branch_ys: Array[int] = []
	for i in range(num_branches):
		branch_ys.append(entry_y + int(shaft_h * (i + 1) / float(num_branches + 1)))
	for by in branch_ys:
		if by >= crystal_cy - 4:
			continue
		# Rama izquierda — guard contra randi_range con rango inválido
		if entry_x - 8 >= 5:
			var ex_l: int = rng.randi_range(5, entry_x - 8)
			_carve_corridor(mine, Vector2i(entry_x - 2, by), Vector2i(ex_l, by), 1)
			_carve_chamber(mine, ex_l, by, 3 + rng.randi() % 2, 0.2)
		# Rama derecha — guard
		if entry_x + 8 <= w - 5:
			var ex_r: int = rng.randi_range(entry_x + 8, w - 5)
			_carve_corridor(mine, Vector2i(entry_x + 2, by), Vector2i(ex_r, by), 1)
			_carve_chamber(mine, ex_r, by, 3 + rng.randi() % 2, 0.2)

	# Bordes wall
	for x in range(w):
		mine.set_wall(x, 0, 1)
		mine.set_wall(x, h - 1, 1)
	for y in range(h):
		mine.set_wall(0, y, 1)
		mine.set_wall(w - 1, y, 1)

	# Spawn y exit
	mine.spawn = Vector2i(entry_x, entry_y)
	mine.exit_pos = Vector2i(crystal_cx, crystal_cy)
	mine.set_wall(mine.spawn.x, mine.spawn.y, 0)
	mine.set_wall(mine.exit_pos.x, mine.exit_pos.y, 0)

	# === DECORACIONES ===
	# Cristales en la cámara de cristales (5-8 cristales grandes)
	var num_crystals: int = 6 + rng.randi() % 3
	for _i in range(num_crystals):
		var cx: int = crystal_cx + rng.randi_range(-crystal_r + 2, crystal_r - 2)
		var cy: int = crystal_cy + rng.randi_range(-crystal_r + 2, crystal_r - 2)
		if not mine.is_wall(cx, cy):
			mine.decor[Vector2i(cx, cy)] = T_CRYSTAL_BIG if rng.randf() < 0.6 else T_CRYSTAL_SMALL
	# Mine carts en el pozo principal — guard contra rango inválido en mapas chicos
	if crystal_cy - 5 > entry_y + 5:
		for _i in range(3):
			var dy: int = rng.randi_range(entry_y + 5, crystal_cy - 5)
			var dx: int = entry_x + rng.randi_range(-1, 1)
			if not mine.is_wall(dx, dy):
				mine.decor[Vector2i(dx, dy)] = T_MINE_CART
	# Linternas dispersas
	for _i in range(8):
		var ly: int = rng.randi_range(entry_y, crystal_cy)
		var lx: int = rng.randi_range(1, w - 2)
		if not mine.is_wall(lx, ly):
			mine.decor[Vector2i(lx, ly)] = T_LANTERN
	# Oro y cobre en ramas
	for by in branch_ys:
		if by >= crystal_cy - 4: continue
		for _i in range(2):
			var ox: int = rng.randi_range(2, w - 3)
			if not mine.is_wall(ox, by):
				mine.decor[Vector2i(ox, by)] = T_GOLD_ORE if rng.randf() < 0.5 else T_COPPER_ORE

	return mine


func _carve_chamber(mine: Mine, cx: int, cy: int, r: int, noise_amp: float) -> void:
	var n := FastNoiseLite.new()
	n.seed = mine.seed_value + cx * 41 + cy * 23
	n.frequency = 0.18
	for dy in range(-r - 2, r + 3):
		for dx in range(-r - 2, r + 3):
			var x: int = cx + dx
			var y: int = cy + dy
			if x < 1 or x >= mine.width - 1 or y < 1 or y >= mine.height - 1:
				continue
			var off: float = n.get_noise_2d(x, y) * (r * noise_amp)
			var dist: float = sqrt(dx * dx + dy * dy) + off
			if dist <= r:
				mine.set_wall(x, y, 0)


func _carve_corridor(mine: Mine, a: Vector2i, b: Vector2i, width: int) -> void:
	var x0: int = a.x; var y0: int = a.y
	var x1: int = b.x; var y1: int = b.y
	var dx: int = absi(x1 - x0); var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	while true:
		for ddy in range(-width, width + 1):
			for ddx in range(-width, width + 1):
				if ddx * ddx + ddy * ddy > width * width:
					continue
				var px: int = x0 + ddx; var py: int = y0 + ddy
				if px > 0 and py > 0 and px < mine.width - 1 and py < mine.height - 1:
					mine.set_wall(px, py, 0)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 > -dy: err -= dy; x0 += sx
		if e2 < dx: err += dx; y0 += sy


# --- AUTOTILE ---

static func count_wall_neighbors(mine: Mine, x: int, y: int) -> int:
	var n: int = 0
	if mine.is_wall(x, y - 1): n += 1
	if mine.is_wall(x + 1, y): n += 1
	if mine.is_wall(x, y + 1): n += 1
	if mine.is_wall(x - 1, y): n += 1
	return n


static func get_tile_for(mine: Mine, x: int, y: int) -> Vector2i:
	var n: int = count_wall_neighbors(mine, x, y)
	var h: int = ((x * 73856093) ^ (y * 19349663) ^ (mine.seed_value * 83492791))
	h = (h ^ (h >> 13)) & 0x7fffffff
	var seed_idx: int = h % 8
	match n:
		4:
			return FILL_VARIANTS[h % FILL_VARIANTS.size()]
		3:
			return EDGE_VARIANTS[seed_idx]
		2:
			return CORNER_VARIANTS[seed_idx]
		1:
			return CAP_VARIANTS[seed_idx % CAP_VARIANTS.size()]
		_:
			return ISOLATED_VARIANTS[seed_idx % ISOLATED_VARIANTS.size()]
