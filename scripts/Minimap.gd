# Minimapa custom-drawn: renderiza el mundo como pixels coloreados + marcadores de POI + jugador.
# Toggle de tamaño con M (chico/grande).

class_name Minimap
extends Control

const OverworldScript := preload("res://scripts/Overworld.gd")

const BIOME_COLORS := {
	OverworldScript.Biome.DESIERTO: Color(0.78, 0.62, 0.38),
	OverworldScript.Biome.LLANOS:   Color(0.55, 0.55, 0.30),
	OverworldScript.Biome.SIERRA:   Color(0.16, 0.32, 0.18),
	OverworldScript.Biome.BARRANCA: Color(0.10, 0.07, 0.06),
	OverworldScript.Biome.MINERO:   Color(0.40, 0.28, 0.18),
	OverworldScript.Biome.RIO:      Color(0.25, 0.45, 0.62),
	OverworldScript.Biome.MESA:     Color(0.62, 0.45, 0.30),
	OverworldScript.Biome.PICO:     Color(0.85, 0.85, 0.92),
}

const POI_COLORS := {
	OverworldScript.POIType.MATA_ORTIZ:         Color(1.00, 1.00, 1.00),
	OverworldScript.POIType.MISION:             Color(0.95, 0.78, 0.30),
	OverworldScript.POIType.CEMENTERIO:         Color(0.55, 0.55, 0.55),
	OverworldScript.POIType.ENTRADA_PAQUIME:    Color(1.00, 0.30, 0.30),
	OverworldScript.POIType.ENTRADA_TARAHUMARA: Color(0.30, 0.95, 0.30),
	OverworldScript.POIType.ENTRADA_NAICA:      Color(0.40, 0.65, 1.00),
}

const POI_NAMES := {
	OverworldScript.POIType.MATA_ORTIZ:         "Mata Ortiz — pueblo de cerámica",
	OverworldScript.POIType.MISION:             "Misión jesuita",
	OverworldScript.POIType.CEMENTERIO:         "Cementerio",
	OverworldScript.POIType.ENTRADA_PAQUIME:    "Ruinas de Paquimé",
	OverworldScript.POIType.ENTRADA_TARAHUMARA: "Cueva Tarahumara",
	OverworldScript.POIType.ENTRADA_NAICA:      "Mina de Naica",
}

var biome_texture: ImageTexture = null
var world = null
var player_ref: Node2D = null
# Tile display efectivo en world coords (32px porque layer scale = 2 sobre tile 16px)
var tile_display: int = 32

var hover_poi = null
var tooltip_label: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # recibimos mouse hover
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Crea label de tooltip como child propio
	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 13)
	tooltip_label.add_theme_color_override("font_color", Color(1, 1, 1))
	tooltip_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	tooltip_label.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_label.add_theme_constant_override("shadow_offset_y", 1)
	# Background usando StyleBoxFlat
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.04, 0.92)
	sb.border_color = Color(0.95, 0.85, 0.55, 0.9)
	sb.set_border_width_all(1)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	tooltip_label.add_theme_stylebox_override("normal", sb)
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_label.visible = false
	tooltip_label.z_index = 100
	add_child(tooltip_label)


func render(w) -> void:
	world = w
	if w == null:
		return
	var img := Image.create(w.width, w.height, false, Image.FORMAT_RGBA8)
	for y in range(w.height):
		for x in range(w.width):
			var b: int = w.get_biome(x, y)
			img.set_pixel(x, y, BIOME_COLORS.get(b, Color.BLACK))
	biome_texture = ImageTexture.create_from_image(img)
	queue_redraw()


func _process(_d: float) -> void:
	if not visible:
		return
	_update_hover()
	if player_ref != null:
		queue_redraw()


func _update_hover() -> void:
	if world == null:
		tooltip_label.visible = false
		return
	var mouse_local: Vector2 = get_local_mouse_position()
	# Si el mouse no está sobre el minimapa, ocultar
	if mouse_local.x < 0 or mouse_local.y < 0 or mouse_local.x > size.x or mouse_local.y > size.y:
		hover_poi = null
		tooltip_label.visible = false
		return
	# Convertir mouse_local → coordenadas de mundo
	var wx: float = (mouse_local.x / size.x) * world.width
	var wy: float = (mouse_local.y / size.y) * world.height
	# Buscar el POI más cercano dentro de radio (en pixeles del minimapa, equivale a ~3-5 tiles)
	var hover_radius_tiles: float = maxf(world.width, world.height) / minf(size.x, size.y) * 5.0
	var hover_radius_sq: float = hover_radius_tiles * hover_radius_tiles
	var best = null
	var best_d: float = 1e12
	for poi in world.pois:
		var dx: float = poi.pos.x - wx
		var dy: float = poi.pos.y - wy
		var d: float = dx * dx + dy * dy
		if d < hover_radius_sq and d < best_d:
			best_d = d
			best = poi
	hover_poi = best
	if hover_poi != null:
		var name_str: String = POI_NAMES.get(hover_poi.type, "?")
		tooltip_label.text = "%s\n(%d, %d)" % [name_str, hover_poi.pos.x, hover_poi.pos.y]
		# Posicionar tooltip cerca del cursor, evitando salir del minimapa
		var pos: Vector2 = mouse_local + Vector2(14, 8)
		# Estimar tamaño y ajustar si se sale
		var est_w: float = 220.0
		var est_h: float = 38.0
		if pos.x + est_w > size.x:
			pos.x = mouse_local.x - est_w - 8
		if pos.y + est_h > size.y:
			pos.y = mouse_local.y - est_h - 4
		tooltip_label.position = pos
		tooltip_label.visible = true
	else:
		tooltip_label.visible = false


func _draw() -> void:
	if biome_texture == null or world == null:
		return
	# Fondo semi-translucido + borde
	draw_rect(Rect2(Vector2(-4, -4), size + Vector2(8, 8)), Color(0, 0, 0, 0.7), true)
	# Mapa
	draw_texture_rect(biome_texture, Rect2(Vector2.ZERO, size), false)
	# POIs
	var sx: float = size.x / float(world.width)
	var sy: float = size.y / float(world.height)
	var dot_r: float = clampf(mini(int(sx), int(sy)), 2.0, 5.0)
	for poi in world.pois:
		var c: Color = POI_COLORS.get(poi.type, Color.WHITE)
		var px: float = poi.pos.x * sx
		var py: float = poi.pos.y * sy
		# Halo oscuro para legibilidad
		draw_circle(Vector2(px, py), dot_r + 0.8, Color(0, 0, 0, 0.85))
		draw_circle(Vector2(px, py), dot_r, c)
		# Anillo extra si está hovered
		if hover_poi == poi:
			draw_arc(Vector2(px, py), dot_r + 3.0, 0, TAU, 24, Color(1.0, 1.0, 0.6, 1.0), 1.5)
	# Player marker
	if player_ref:
		var wx_total: float = world.width * tile_display
		var wy_total: float = world.height * tile_display
		var ppx: float = (player_ref.position.x / wx_total) * size.x
		var ppy: float = (player_ref.position.y / wy_total) * size.y
		draw_circle(Vector2(ppx, ppy), 6.0, Color(0, 0, 0, 0.9))
		draw_circle(Vector2(ppx, ppy), 4.0, Color(1.0, 1.0, 0.4))
		# Cruz para localización rápida
		draw_line(Vector2(ppx - 8, ppy), Vector2(ppx + 8, ppy), Color(1.0, 1.0, 0.4, 0.5), 1.0)
		draw_line(Vector2(ppx, ppy - 8), Vector2(ppx, ppy + 8), Color(1.0, 1.0, 0.4, 0.5), 1.0)
	# Borde
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.85, 0.6, 0.8), false, 2.0)
