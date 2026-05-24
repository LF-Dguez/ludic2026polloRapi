# Generador BSP de mazmorra Paquimé.
# Reparte el espacio en leaves, mete un cuarto en cada leaf, conecta con corredores L.
# Etiqueta cuartos por tamaño/distancia: plaza, cancha, macaw, efigies, etc.

class_name BSPGenerator
extends RefCounted

# Tile IDs en paquime_tiles.png (4x4)
const T_VOID := Vector2i(0, 0)
const T_FLOOR := Vector2i(1, 0)
const T_WALL := Vector2i(2, 0)
const T_DOOR := Vector2i(3, 0)
const T_PLAZA := Vector2i(0, 1)
const T_MACAW := Vector2i(1, 1)
const T_WORKSHOP := Vector2i(2, 1)
const T_WATER := Vector2i(3, 1)
const T_EFFIGY_CROSS := Vector2i(0, 2)
const T_EFFIGY_BIRD := Vector2i(1, 2)
const T_EFFIGY_SERPENT := Vector2i(2, 2)
const T_BALL := Vector2i(3, 2)
const T_ENTRANCE := Vector2i(0, 3)
const T_EXIT := Vector2i(1, 3)
const T_POT := Vector2i(2, 3)

const MIN_LEAF := 12
const MAX_LEAF := 28
const ROOM_MARGIN := 1


class Dungeon:
	var width: int
	var height: int
	var tiles: PackedInt32Array     # encoded Vector2i (x<<8)|y
	var rooms: Array = []           # Array[Rect2i]
	var room_tags: Array = []       # parallel string tags
	var seed_value: int

	func get_tile(x: int, y: int) -> Vector2i:
		var v: int = tiles[y * width + x]
		return Vector2i(v >> 8, v & 0xff)

	func set_tile(x: int, y: int, t: Vector2i) -> void:
		tiles[y * width + x] = (t.x << 8) | t.y


class Leaf:
	var rect: Rect2i
	var left: Leaf = null
	var right: Leaf = null
	var room: Rect2i = Rect2i(0, 0, 0, 0)

	func _init(r: Rect2i) -> void:
		rect = r

	func is_leaf() -> bool:
		return left == null and right == null


var rng := RandomNumberGenerator.new()
var d: Dungeon = null


func generate(w: int, h: int, seed_value: int) -> Dungeon:
	rng.seed = seed_value
	d = Dungeon.new()
	d.width = w
	d.height = h
	d.seed_value = seed_value
	d.tiles = PackedInt32Array()
	d.tiles.resize(w * h)

	# Lleno todo con muro
	for y in range(h):
		for x in range(w):
			d.set_tile(x, y, T_WALL)

	# BSP recursivo
	var root := Leaf.new(Rect2i(2, 2, w - 4, h - 4))
	_split(root)
	_make_rooms(root)

	# Marco con muro toda la periferia
	_seal_border()

	# Etiqueta cuartos
	_tag_rooms()

	# Pinta floors según etiqueta + decora cuartos
	_paint_room_floors()
	_decorate_rooms()

	# Marca puertas T donde corredor toca cuarto
	_place_doors()

	return d


func _split(leaf: Leaf) -> void:
	if leaf.rect.size.x <= MAX_LEAF and leaf.rect.size.y <= MAX_LEAF:
		if rng.randf() < 0.25:
			return

	var horizontal: bool = rng.randf() < 0.5
	if leaf.rect.size.x > leaf.rect.size.y * 1.25:
		horizontal = false
	elif leaf.rect.size.y > leaf.rect.size.x * 1.25:
		horizontal = true

	var dim_size: int = leaf.rect.size.y if horizontal else leaf.rect.size.x
	if dim_size - MIN_LEAF <= MIN_LEAF:
		return
	var split: int = rng.randi_range(MIN_LEAF, dim_size - MIN_LEAF)

	if horizontal:
		leaf.left = Leaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, leaf.rect.size.x, split))
		leaf.right = Leaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y + split, leaf.rect.size.x, leaf.rect.size.y - split))
	else:
		leaf.left = Leaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, split, leaf.rect.size.y))
		leaf.right = Leaf.new(Rect2i(leaf.rect.position.x + split, leaf.rect.position.y, leaf.rect.size.x - split, leaf.rect.size.y))

	_split(leaf.left)
	_split(leaf.right)


func _make_rooms(leaf: Leaf) -> void:
	if leaf.is_leaf():
		var r: Rect2i = leaf.rect
		var max_w: int = r.size.x - 2
		var max_h: int = r.size.y - 2
		var room_w: int = rng.randi_range(maxi(5, max_w - 6), max_w)
		var room_h: int = rng.randi_range(maxi(5, max_h - 6), max_h)
		var ox: int = r.position.x + rng.randi_range(1, r.size.x - room_w - 1)
		var oy: int = r.position.y + rng.randi_range(1, r.size.y - room_h - 1)
		leaf.room = Rect2i(ox, oy, room_w, room_h)
		d.rooms.append(leaf.room)
		# Tallar cuarto como FLOOR
		for x in range(leaf.room.position.x, leaf.room.position.x + leaf.room.size.x):
			for y in range(leaf.room.position.y, leaf.room.position.y + leaf.room.size.y):
				d.set_tile(x, y, T_FLOOR)
	else:
		_make_rooms(leaf.left)
		_make_rooms(leaf.right)
		var lc: Vector2i = _center_of(leaf.left)
		var rc: Vector2i = _center_of(leaf.right)
		_carve_corridor(lc, rc)


func _center_of(leaf: Leaf) -> Vector2i:
	if leaf.is_leaf():
		return leaf.room.position + leaf.room.size / 2
	return _center_of(leaf.left if rng.randf() < 0.5 else leaf.right)


func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	# Corredor en L, 1 tile de ancho
	if rng.randf() < 0.5:
		# Horizontal primero, luego vertical
		var x0: int = mini(a.x, b.x)
		var x1: int = maxi(a.x, b.x)
		for x in range(x0, x1 + 1):
			d.set_tile(x, a.y, T_FLOOR)
		var y0: int = mini(a.y, b.y)
		var y1: int = maxi(a.y, b.y)
		for y in range(y0, y1 + 1):
			d.set_tile(b.x, y, T_FLOOR)
	else:
		var y0: int = mini(a.y, b.y)
		var y1: int = maxi(a.y, b.y)
		for y in range(y0, y1 + 1):
			d.set_tile(a.x, y, T_FLOOR)
		var x0: int = mini(a.x, b.x)
		var x1: int = maxi(a.x, b.x)
		for x in range(x0, x1 + 1):
			d.set_tile(x, b.y, T_FLOOR)


func _seal_border() -> void:
	for x in range(d.width):
		d.set_tile(x, 0, T_WALL)
		d.set_tile(x, d.height - 1, T_WALL)
	for y in range(d.height):
		d.set_tile(0, y, T_WALL)
		d.set_tile(d.width - 1, y, T_WALL)


func _tag_rooms() -> void:
	var n: int = d.rooms.size()
	d.room_tags.resize(n)
	for i in range(n):
		d.room_tags[i] = "dwelling"
	if n < 4:
		return

	# Construyo adyacencia: cuartos comparten corredor si la línea de un corredor toca ambos rects grown(1)
	var adj: Array = []
	for i in range(n):
		adj.append([])

	# Aproximación: rooms adyacentes si sus rects grown(2) se intersectan
	for i in range(n):
		var ri: Rect2i = d.rooms[i].grow(3)
		for j in range(i + 1, n):
			if ri.intersects(d.rooms[j].grow(3)):
				adj[i].append(j)
				adj[j].append(i)

	# Entrada = cuarto más cerca de la esquina superior-izquierda
	var entrance_idx: int = 0
	var best_d: int = 1_000_000
	for i in range(n):
		var rr: Rect2i = d.rooms[i]
		var sc: int = rr.position.x + rr.position.y
		if sc < best_d:
			best_d = sc
			entrance_idx = i

	# BFS de distancias
	var dist: Array = []
	dist.resize(n)
	for i in range(n):
		dist[i] = -1
	dist[entrance_idx] = 0
	var q: Array = [entrance_idx]
	while not q.is_empty():
		var cur: int = q.pop_front()
		for nb in adj[cur]:
			if dist[nb] == -1:
				dist[nb] = dist[cur] + 1
				q.append(nb)

	# Salida = más lejano
	var exit_idx: int = 0
	var max_d: int = -1
	for i in range(n):
		if dist[i] > max_d:
			max_d = dist[i]
			exit_idx = i

	d.room_tags[entrance_idx] = "entrance"
	d.room_tags[exit_idx] = "exit"

	# Cuarto más grande no-entrada/salida = plaza
	var by_area: Array = []
	for i in range(n):
		by_area.append(i)
	by_area.sort_custom(func(a, b): return _area(d.rooms[a]) > _area(d.rooms[b]))

	for i in by_area:
		if d.room_tags[i] == "dwelling":
			d.room_tags[i] = "plaza"
			break

	# Cuarto más alargado = cancha de pelota
	var best_ratio: float = 1.6
	var ball_idx: int = -1
	for i in range(n):
		if d.room_tags[i] != "dwelling":
			continue
		var rr2: Rect2i = d.rooms[i]
		var sx: float = float(rr2.size.x)
		var sy: float = float(rr2.size.y)
		var ratio: float = maxf(sx, sy) / minf(sx, sy)
		if ratio > best_ratio:
			best_ratio = ratio
			ball_idx = i
	if ball_idx != -1:
		d.room_tags[ball_idx] = "ball"

	# 2 jaulas de macaw (medianos)
	var macaws: int = 0
	for i in by_area:
		if d.room_tags[i] != "dwelling":
			continue
		if macaws >= 2:
			break
		if rng.randf() < 0.5:
			d.room_tags[i] = "macaw"
			macaws += 1

	# 1 taller de cobre
	for i in by_area:
		if d.room_tags[i] == "dwelling":
			d.room_tags[i] = "workshop"
			break

	# 1 reservorio de agua
	for i in by_area:
		if d.room_tags[i] == "dwelling":
			d.room_tags[i] = "water"
			break

	# 3 efigies (pequeños, scattered) — cruz, pájaro, serpiente
	var small_first: Array = []
	for i in range(n):
		small_first.append(i)
	small_first.sort_custom(func(a, b): return _area(d.rooms[a]) < _area(d.rooms[b]))
	var placed_eff: int = 0
	var eff_tags: Array = ["effigy_cross", "effigy_bird", "effigy_serpent"]
	for i in small_first:
		if d.room_tags[i] == "dwelling" and placed_eff < 3:
			d.room_tags[i] = eff_tags[placed_eff]
			placed_eff += 1


func _area(r: Rect2i) -> int:
	return r.size.x * r.size.y


func _paint_room_floors() -> void:
	for i in range(d.rooms.size()):
		var r: Rect2i = d.rooms[i]
		var tag: String = d.room_tags[i]
		var floor_tile: Vector2i = T_FLOOR
		match tag:
			"plaza": floor_tile = T_PLAZA
			"ball": floor_tile = T_BALL
		for x in range(r.position.x, r.position.x + r.size.x):
			for y in range(r.position.y, r.position.y + r.size.y):
				d.set_tile(x, y, floor_tile)


func _decorate_rooms() -> void:
	for i in range(d.rooms.size()):
		var r: Rect2i = d.rooms[i]
		var tag: String = d.room_tags[i]
		var cx: int = r.position.x + r.size.x / 2
		var cy: int = r.position.y + r.size.y / 2
		match tag:
			"entrance":
				d.set_tile(cx, cy, T_ENTRANCE)
			"exit":
				d.set_tile(cx, cy, T_EXIT)
			"effigy_cross":
				d.set_tile(cx, cy, T_EFFIGY_CROSS)
			"effigy_bird":
				d.set_tile(cx, cy, T_EFFIGY_BIRD)
			"effigy_serpent":
				d.set_tile(cx, cy, T_EFFIGY_SERPENT)
			"workshop":
				d.set_tile(cx, cy, T_WORKSHOP)
				# extra pots near workshop
				var n_extra: int = mini(3, (r.size.x * r.size.y) / 30)
				for _i in range(n_extra):
					var px: int = r.position.x + 1 + rng.randi() % maxi(1, r.size.x - 2)
					var py: int = r.position.y + 1 + rng.randi() % maxi(1, r.size.y - 2)
					if d.get_tile(px, py) == T_FLOOR:
						d.set_tile(px, py, T_POT)
			"macaw":
				var n_nests: int = mini(5, (r.size.x * r.size.y) / 16)
				for _i in range(n_nests):
					var px2: int = r.position.x + 1 + rng.randi() % maxi(1, r.size.x - 2)
					var py2: int = r.position.y + 1 + rng.randi() % maxi(1, r.size.y - 2)
					if d.get_tile(px2, py2) == T_FLOOR:
						d.set_tile(px2, py2, T_MACAW)
			"water":
				# Charco central de agua
				var pad: int = 2
				for x in range(r.position.x + pad, r.position.x + r.size.x - pad):
					for y in range(r.position.y + pad, r.position.y + r.size.y - pad):
						d.set_tile(x, y, T_WATER)


func _place_doors() -> void:
	# Una puerta T es un tile FLOOR justo a la orilla de un cuarto cuyo vecino exterior
	# inmediato (a 1) sigue siendo FLOOR (corredor).
	for r in d.rooms:
		var rr: Rect2i = r
		var x0: int = rr.position.x
		var y0: int = rr.position.y
		var x1: int = rr.position.x + rr.size.x - 1
		var y1: int = rr.position.y + rr.size.y - 1
		# Top edge
		for x in range(x0, x1 + 1):
			_maybe_door_at(x, y0, x, y0 - 1)
		# Bottom edge
		for x in range(x0, x1 + 1):
			_maybe_door_at(x, y1, x, y1 + 1)
		# Left
		for y in range(y0, y1 + 1):
			_maybe_door_at(x0, y, x0 - 1, y)
		# Right
		for y in range(y0, y1 + 1):
			_maybe_door_at(x1, y, x1 + 1, y)


func _maybe_door_at(inner_x: int, inner_y: int, outer_x: int, outer_y: int) -> void:
	if outer_x < 0 or outer_x >= d.width or outer_y < 0 or outer_y >= d.height:
		return
	# El interior debe ser un floor de cuarto. El exterior es el corredor (también FLOOR).
	# Cuando ambos son floor → la transición es la puerta T en el TILE INTERIOR borde.
	var inner: Vector2i = d.get_tile(inner_x, inner_y)
	var outer: Vector2i = d.get_tile(outer_x, outer_y)
	if _is_floor(outer) and (inner == T_FLOOR or inner == T_PLAZA or inner == T_BALL):
		d.set_tile(inner_x, inner_y, T_DOOR)


func _is_floor(t: Vector2i) -> bool:
	return t == T_FLOOR or t == T_PLAZA or t == T_BALL
