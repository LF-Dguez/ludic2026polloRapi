# IconGenerator — dibuja iconos 32x32 procedurales para cada item.
# Cachea Texture2D por id. Llamar IconGenerator.get_icon("tortilla").

class_name IconGenerator
extends RefCounted

const SIZE := 32
static var _cache: Dictionary = {}


static func get_icon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_draw_icon(img, id)
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _draw_icon(img: Image, id: String) -> void:
	match id:
		"tortilla":
			_fill_circle(img, 16, 16, 12, Color(0.95, 0.85, 0.55))
			_ring(img, 16, 16, 12, Color(0.65, 0.50, 0.25))
			# Puntitos tostados
			for i in range(6):
				var a: float = i * TAU / 6.0
				var px: int = 16 + int(cos(a) * 6)
				var py: int = 16 + int(sin(a) * 6)
				_px(img, px, py, Color(0.55, 0.40, 0.20))
		"olla_barro":
			# Cuerpo de olla
			_fill_circle(img, 16, 20, 10, Color(0.72, 0.40, 0.20))
			_ring(img, 16, 20, 10, Color(0.45, 0.22, 0.10))
			# Cuello
			_fill_rect(img, 12, 6, 8, 6, Color(0.72, 0.40, 0.20))
			_fill_rect(img, 11, 6, 10, 2, Color(0.55, 0.30, 0.15))
			# Patrón
			_fill_rect(img, 10, 18, 12, 2, Color(0.40, 0.20, 0.10))
		"mezcal":
			# Botella alargada
			_fill_rect(img, 13, 4, 6, 4, Color(0.30, 0.20, 0.10))  # corcho
			_fill_rect(img, 12, 8, 8, 22, Color(0.85, 0.78, 0.30))
			_outline_rect(img, 12, 8, 8, 22, Color(0.40, 0.30, 0.10))
			_fill_rect(img, 13, 14, 6, 4, Color(0.95, 0.95, 0.85))  # etiqueta
		"sotol":
			_fill_rect(img, 13, 5, 6, 3, Color(0.20, 0.15, 0.10))
			_fill_rect(img, 12, 8, 8, 22, Color(0.40, 0.65, 0.35))
			_outline_rect(img, 12, 8, 8, 22, Color(0.20, 0.40, 0.20))
		"carne_seca":
			# Tira de carne deshidratada
			_fill_rect(img, 4, 10, 24, 12, Color(0.50, 0.25, 0.15))
			_outline_rect(img, 4, 10, 24, 12, Color(0.25, 0.10, 0.05))
			# Veteado
			_hline(img, 4, 28, 14, Color(0.65, 0.35, 0.20))
			_hline(img, 4, 28, 18, Color(0.65, 0.35, 0.20))
		"agua_bendita":
			# Vial con cruz
			_fill_rect(img, 11, 4, 10, 24, Color(0.85, 0.95, 1.00, 0.85))
			_outline_rect(img, 11, 4, 10, 24, Color(0.50, 0.70, 0.85))
			# Cruz
			_fill_rect(img, 15, 12, 2, 12, Color(0.20, 0.30, 0.50))
			_fill_rect(img, 12, 16, 8, 2, Color(0.20, 0.30, 0.50))
		"machete":
			# Hoja diagonal larga + cabo café
			_diag_blade(img, 4, 28, 24, 8, Color(0.85, 0.85, 0.80), Color(0.45, 0.45, 0.40))
			# Cabo
			_fill_rect(img, 22, 24, 8, 6, Color(0.45, 0.25, 0.10))
		"cuchillo":
			_diag_blade(img, 8, 22, 20, 10, Color(0.80, 0.80, 0.80), Color(0.40, 0.40, 0.40))
			_fill_rect(img, 18, 18, 8, 6, Color(0.35, 0.20, 0.10))
		"pistola_villa":
			# L-shape revolver
			_fill_rect(img, 6, 12, 20, 5, Color(0.20, 0.20, 0.20))  # cañón
			_fill_rect(img, 14, 17, 6, 10, Color(0.30, 0.20, 0.15))  # mango
			_fill_circle(img, 18, 14, 3, Color(0.10, 0.10, 0.10))  # tambor
			_px(img, 25, 14, Color(0.05, 0.05, 0.05))  # punta
		"rifle_serrano":
			# Largo horizontal
			_fill_rect(img, 2, 13, 28, 4, Color(0.30, 0.30, 0.30))  # cañón
			_fill_rect(img, 22, 17, 8, 5, Color(0.40, 0.25, 0.15))  # culata
			_fill_rect(img, 18, 15, 4, 6, Color(0.40, 0.25, 0.15))  # empuñadura
		"corazon_sagrado":
			_heart(img, 16, 18, 10, Color(0.95, 0.20, 0.30), Color(0.55, 0.10, 0.15))
			# Halo
			_ring(img, 16, 12, 12, Color(1, 0.85, 0.20))
		"filo_obsidiana":
			# Triángulo punta arriba
			for y in range(4, 28):
				var w: int = (y - 4) * 14 / 24
				for x in range(16 - w / 2, 16 + w / 2):
					_px(img, x, y, Color(0.10, 0.05, 0.20))
			# Highlight diagonal
			for i in range(8):
				_px(img, 14 + i, 12 + i, Color(0.45, 0.30, 0.55))
		"botin_charro":
			# Bota lateral
			_fill_rect(img, 8, 6, 10, 16, Color(0.55, 0.35, 0.15))  # caña
			_fill_rect(img, 6, 20, 22, 8, Color(0.50, 0.30, 0.10))   # pie
			_outline_rect(img, 8, 6, 10, 16, Color(0.30, 0.15, 0.05))
			_outline_rect(img, 6, 20, 22, 8, Color(0.30, 0.15, 0.05))
			# Espuela
			_fill_circle(img, 27, 24, 2, Color(0.85, 0.85, 0.80))
		"llave_paquime":
			# Loop + tallo + dientes
			_ring(img, 9, 11, 5, Color(0.85, 0.65, 0.30))
			_ring(img, 9, 11, 4, Color(0.85, 0.65, 0.30))
			_fill_rect(img, 14, 10, 14, 3, Color(0.85, 0.65, 0.30))
			_fill_rect(img, 22, 13, 3, 5, Color(0.85, 0.65, 0.30))
			_fill_rect(img, 26, 13, 3, 5, Color(0.85, 0.65, 0.30))
		"cristal_naica":
			# Diamante/lozenge cyan
			for y in range(4, 28):
				var dy_n: int = absi(y - 16)
				var w: int = 12 - dy_n
				if w < 0: continue
				for x in range(16 - w, 16 + w):
					var alpha: float = 0.55 + 0.45 * (1.0 - float(dy_n) / 12.0)
					_px(img, x, y, Color(0.55, 0.85, 1.00, alpha))
			# Borde
			_line(img, 16, 4, 28, 16, Color(0.90, 1.00, 1.00))
			_line(img, 16, 4, 4, 16, Color(0.90, 1.00, 1.00))
			_line(img, 16, 28, 28, 16, Color(0.30, 0.55, 0.85))
			_line(img, 16, 28, 4, 16, Color(0.30, 0.55, 0.85))
		"mapa_raramuri":
			# Pergamino enrollado
			_fill_rect(img, 4, 6, 24, 20, Color(0.85, 0.75, 0.55))
			_outline_rect(img, 4, 6, 24, 20, Color(0.40, 0.25, 0.15))
			# Líneas mapa
			_line(img, 8, 12, 20, 16, Color(0.30, 0.15, 0.05))
			_line(img, 12, 20, 24, 22, Color(0.30, 0.15, 0.05))
			# Punto destino
			_fill_circle(img, 20, 18, 2, Color(0.85, 0.20, 0.10))
			# Enrollado lateral
			_fill_rect(img, 2, 6, 4, 20, Color(0.65, 0.55, 0.35))
			_fill_rect(img, 26, 6, 4, 20, Color(0.65, 0.55, 0.35))
		"pesos_plata":
			_fill_circle(img, 16, 16, 12, Color(0.85, 0.85, 0.90))
			_ring(img, 16, 16, 12, Color(0.45, 0.45, 0.50))
			_ring(img, 16, 16, 9, Color(0.55, 0.55, 0.60))
			# $
			_fill_rect(img, 15, 9, 2, 14, Color(0.20, 0.20, 0.25))
			_fill_rect(img, 12, 12, 8, 2, Color(0.20, 0.20, 0.25))
			_fill_rect(img, 12, 18, 8, 2, Color(0.20, 0.20, 0.25))
		"ceramica_mata_ortiz":
			# Vasija ovalada con motivos
			_fill_circle(img, 16, 18, 10, Color(0.82, 0.65, 0.40))
			_ring(img, 16, 18, 10, Color(0.40, 0.25, 0.10))
			_fill_rect(img, 13, 6, 6, 4, Color(0.82, 0.65, 0.40))
			_fill_rect(img, 12, 6, 8, 2, Color(0.55, 0.35, 0.15))
			# Patrón geométrico (estilo Quezada)
			for i in range(4):
				_px(img, 10 + i * 3, 18, Color(0.20, 0.10, 0.05))
				_px(img, 11 + i * 3, 20, Color(0.20, 0.10, 0.05))
		"vetas_cobre":
			# Roca con vetas naranjas
			_fill_circle(img, 16, 17, 11, Color(0.45, 0.42, 0.40))
			_ring(img, 16, 17, 11, Color(0.25, 0.22, 0.20))
			# Vetas
			for i in range(5):
				var a: float = i * TAU / 5.0 + 0.5
				var x0: int = 16 + int(cos(a) * 4)
				var y0: int = 17 + int(sin(a) * 4)
				var x1: int = 16 + int(cos(a) * 9)
				var y1: int = 17 + int(sin(a) * 9)
				_line(img, x0, y0, x1, y1, Color(0.85, 0.45, 0.15))
		"piedra_mineral":
			# Roca gris cluster
			_fill_circle(img, 12, 18, 7, Color(0.50, 0.48, 0.45))
			_fill_circle(img, 21, 16, 8, Color(0.55, 0.52, 0.48))
			_ring(img, 12, 18, 7, Color(0.25, 0.22, 0.20))
			_ring(img, 21, 16, 8, Color(0.25, 0.22, 0.20))
			# Brillos
			_px(img, 10, 16, Color(0.85, 0.85, 0.85))
			_px(img, 19, 14, Color(0.85, 0.85, 0.85))
		"calavera_villa":
			# Calavera frontal
			_fill_circle(img, 16, 14, 10, Color(0.95, 0.95, 0.85))
			# Mandíbula
			_fill_rect(img, 11, 22, 10, 6, Color(0.92, 0.92, 0.82))
			# Ojos
			_fill_circle(img, 12, 14, 2, Color(0.05, 0.05, 0.05))
			_fill_circle(img, 20, 14, 2, Color(0.05, 0.05, 0.05))
			# Nariz
			_fill_rect(img, 15, 18, 2, 3, Color(0.05, 0.05, 0.05))
			# Dientes
			_px(img, 13, 25, Color(0.05, 0.05, 0.05))
			_px(img, 15, 25, Color(0.05, 0.05, 0.05))
			_px(img, 17, 25, Color(0.05, 0.05, 0.05))
			_px(img, 19, 25, Color(0.05, 0.05, 0.05))
		"codice_paquime":
			# Códice plegado en zigzag
			for i in range(5):
				_fill_rect(img, 4 + i * 5, 6 + (i % 2) * 2, 6, 22 - (i % 2) * 4, Color(0.85, 0.70, 0.45))
				_outline_rect(img, 4 + i * 5, 6 + (i % 2) * 2, 6, 22 - (i % 2) * 4, Color(0.40, 0.25, 0.10))
			# Glifo
			_fill_rect(img, 14, 14, 4, 4, Color(0.85, 0.20, 0.10))
		"foto_parral":
			# Foto sepia rectangular
			_fill_rect(img, 4, 4, 24, 24, Color(0.85, 0.85, 0.80))
			_outline_rect(img, 4, 4, 24, 24, Color(0.30, 0.30, 0.25))
			# Borde blanco
			_outline_rect(img, 6, 6, 20, 20, Color(0.95, 0.95, 0.90))
			# Sujeto (silueta)
			_fill_circle(img, 16, 14, 3, Color(0.40, 0.30, 0.25))
			_fill_rect(img, 12, 17, 8, 8, Color(0.40, 0.30, 0.25))
		# ─── NUEVOS items ───
		"peyote":
			# Cactus circular verde
			_fill_circle(img, 16, 18, 10, Color(0.35, 0.55, 0.30))
			_ring(img, 16, 18, 10, Color(0.20, 0.35, 0.15))
			# Costillas
			for i in range(6):
				var a: float = i * TAU / 6.0
				var x0: int = 16 + int(cos(a) * 3)
				var y0: int = 18 + int(sin(a) * 3)
				var x1: int = 16 + int(cos(a) * 9)
				var y1: int = 18 + int(sin(a) * 9)
				_line(img, x0, y0, x1, y1, Color(0.20, 0.40, 0.20))
			# Flor rosa central
			_fill_circle(img, 16, 18, 2, Color(0.95, 0.55, 0.65))
		"polvora":
			# Bolsa oscura con chispa
			_fill_circle(img, 16, 20, 9, Color(0.15, 0.12, 0.10))
			_ring(img, 16, 20, 9, Color(0.05, 0.03, 0.02))
			# Cordón
			_fill_rect(img, 14, 6, 4, 8, Color(0.45, 0.30, 0.15))
			# Chispa
			_px(img, 18, 10, Color(1, 0.85, 0.20))
			_px(img, 19, 11, Color(1, 0.95, 0.30))
			_px(img, 20, 10, Color(1, 0.85, 0.20))
		"rosario":
			# Cadena de cuentas + cruz
			for i in range(8):
				var a: float = i * TAU / 8.0
				var px: int = 16 + int(cos(a) * 9)
				var py: int = 13 + int(sin(a) * 9)
				_fill_circle(img, px, py, 2, Color(0.45, 0.30, 0.15))
			# Cruz al fondo
			_fill_rect(img, 15, 24, 2, 6, Color(0.85, 0.65, 0.30))
			_fill_rect(img, 13, 26, 6, 2, Color(0.85, 0.65, 0.30))
		"herradura":
			# U de hierro
			for y in range(8, 24):
				_px(img, 8, y, Color(0.50, 0.50, 0.55))
				_px(img, 9, y, Color(0.65, 0.65, 0.70))
				_px(img, 23, y, Color(0.50, 0.50, 0.55))
				_px(img, 22, y, Color(0.65, 0.65, 0.70))
			for x in range(9, 24):
				_px(img, x, 23, Color(0.50, 0.50, 0.55))
				_px(img, x, 24, Color(0.65, 0.65, 0.70))
			# Agujeros para clavos
			for i in range(3):
				_px(img, 10, 12 + i * 4, Color(0.10, 0.10, 0.10))
				_px(img, 22, 12 + i * 4, Color(0.10, 0.10, 0.10))
		"sombrero_revolucion":
			# Sombrero ancho
			_fill_rect(img, 2, 16, 28, 4, Color(0.55, 0.35, 0.15))  # ala
			_outline_rect(img, 2, 16, 28, 4, Color(0.30, 0.15, 0.05))
			_fill_rect(img, 10, 8, 12, 12, Color(0.50, 0.30, 0.10))  # copa
			_outline_rect(img, 10, 8, 12, 12, Color(0.25, 0.10, 0.02))
			# Cordón
			_hline(img, 10, 22, 14, Color(0.85, 0.65, 0.30))
		# Boss reliquias
		"corona_paquime":
			# Corona dorada con gemas
			_fill_rect(img, 6, 18, 20, 8, Color(0.85, 0.65, 0.20))
			_outline_rect(img, 6, 18, 20, 8, Color(0.55, 0.35, 0.05))
			# Picos
			for i in range(3):
				var px: int = 9 + i * 7
				for y in range(8, 18):
					var w: int = (y - 8) / 2
					for x in range(px - w, px + w + 1):
						_px(img, x, y, Color(0.85, 0.65, 0.20))
			# Gema central
			_fill_circle(img, 16, 22, 2, Color(0.85, 0.20, 0.30))
		"colmillo_bestia":
			# Colmillo curvado blanco-marfil
			for y in range(4, 28):
				var x_base: int = 22 - (y - 4) / 2
				var w: int = 4 - (y - 4) / 8
				for x in range(x_base - w, x_base + w):
					_px(img, x, y, Color(0.95, 0.90, 0.80))
				_px(img, x_base - w, y, Color(0.55, 0.45, 0.30))
			# Sangre en la base
			_fill_circle(img, 24, 24, 2, Color(0.55, 0.10, 0.05))
		"esquirla_espectro":
			# Cristal punta abajo translucido morado
			for y in range(4, 28):
				var dy_n: int = absi(y - 16)
				var w: int = 10 - dy_n / 2
				if w < 0: continue
				for x in range(16 - w, 16 + w):
					_px(img, x, y, Color(0.65, 0.45, 0.85, 0.75))
			_line(img, 16, 4, 16, 28, Color(0.95, 0.85, 1.00))
			_line(img, 6, 16, 26, 16, Color(0.85, 0.65, 1.00))
		_:
			# Fallback genérico
			_fill_rect(img, 6, 6, 20, 20, Color(0.50, 0.50, 0.50))
			_outline_rect(img, 6, 6, 20, 20, Color(0.20, 0.20, 0.20))


# ─── PRIMITIVOS ──────────────────────────────────────────────────────────

static func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
		return
	# Blend con alpha si color tiene transparencia
	if color.a >= 0.99:
		img.set_pixel(x, y, color)
	else:
		var dst: Color = img.get_pixel(x, y)
		var a: float = color.a + dst.a * (1.0 - color.a)
		if a < 0.001:
			return
		var r: float = (color.r * color.a + dst.r * dst.a * (1.0 - color.a)) / a
		var g: float = (color.g * color.a + dst.g * dst.a * (1.0 - color.a)) / a
		var b: float = (color.b * color.a + dst.b * dst.a * (1.0 - color.a)) / a
		img.set_pixel(x, y, Color(r, g, b, a))


static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for dy in range(h):
		for dx in range(w):
			_px(img, x + dx, y + dy, color)


static func _outline_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for dx in range(w):
		_px(img, x + dx, y, color)
		_px(img, x + dx, y + h - 1, color)
	for dy in range(h):
		_px(img, x, y + dy, color)
		_px(img, x + w - 1, y + dy, color)


static func _fill_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	var r2: int = r * r
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r2:
				_px(img, cx + dx, cy + dy, color)


static func _ring(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	# Aproximación de Midpoint circle
	var x: int = r
	var y: int = 0
	var p: int = 1 - r
	while x >= y:
		for s in [[x, y], [y, x], [-x, y], [-y, x], [-x, -y], [-y, -x], [x, -y], [y, -x]]:
			_px(img, cx + s[0], cy + s[1], color)
		y += 1
		if p <= 0:
			p += 2 * y + 1
		else:
			x -= 1
			p += 2 * (y - x) + 1


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	# Bresenham
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		_px(img, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


static func _hline(img: Image, x0: int, x1: int, y: int, color: Color) -> void:
	for x in range(x0, x1 + 1):
		_px(img, x, y, color)


static func _diag_blade(img: Image, x0: int, y0: int, x1: int, y1: int, blade_color: Color, edge_color: Color) -> void:
	# Una hoja gruesa diagonal de (x0,y0) a (x1,y1), thickness ~3
	var dx: int = x1 - x0
	var dy: int = y1 - y0
	var len: float = sqrt(dx * dx + dy * dy)
	if len < 0.01:
		return
	var nx: float = -dy / len
	var ny: float = dx / len
	for t in range(int(len) + 1):
		var px: int = x0 + int(dx * t / len)
		var py: int = y0 + int(dy * t / len)
		for k in range(-2, 3):
			_px(img, px + int(nx * k), py + int(ny * k), blade_color)
		_px(img, px + int(nx * 3), py + int(ny * 3), edge_color)
		_px(img, px + int(nx * -3), py + int(ny * -3), edge_color)


static func _heart(img: Image, cx: int, cy: int, r: int, color: Color, outline: Color) -> void:
	# Corazón: dos circles + triángulo apuntando abajo
	_fill_circle(img, cx - r / 2, cy - r / 3, r / 2, color)
	_fill_circle(img, cx + r / 2, cy - r / 3, r / 2, color)
	for dy in range(r + 1):
		var w: int = r - dy
		for dx in range(-w, w + 1):
			_px(img, cx + dx, cy + dy, color)
	# Outline aproximado
	_ring(img, cx - r / 2, cy - r / 3, r / 2, outline)
	_ring(img, cx + r / 2, cy - r / 3, r / 2, outline)
