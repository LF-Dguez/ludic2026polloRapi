# AchievementSystem — track stats + popup al desbloquear logro.
# Sin persistencia separada (lo gestionamos via Main stats).

class_name AchievementSystem
extends Control

const ACHIEVEMENTS := {
	"first_blood": {"name": "Primera sangre", "desc": "Mata tu primer enemigo"},
	"ten_kills": {"name": "Implacable", "desc": "Mata 10 enemigos"},
	"fifty_kills": {"name": "Pistolero", "desc": "Mata 50 enemigos"},
	"clear_paquime": {"name": "Conquistador de Paquimé", "desc": "Derrota al Señor de Casas Grandes"},
	"clear_cave": {"name": "Domador de la Sierra", "desc": "Derrota a la Bestia del Cobre"},
	"clear_mine": {"name": "Cazafantasmas", "desc": "Derrota al Espectro del Cristal"},
	"all_bosses": {"name": "Liberador de Chihuahua", "desc": "Derrota a los 3 bosses"},
	"level_5": {"name": "Veterano", "desc": "Alcanza nivel 5"},
	"level_10": {"name": "Leyenda del Norte", "desc": "Alcanza nivel 10"},
	"rich": {"name": "Hacendado", "desc": "Acumula 200 pesos de plata"},
}

var unlocked: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func unlock(id: String) -> void:
	if unlocked.has(id) or not ACHIEVEMENTS.has(id):
		return
	unlocked[id] = true
	_show_popup(id)


func _show_popup(id: String) -> void:
	var def: Dictionary = ACHIEVEMENTS[id]
	var vp: Vector2 = get_viewport_rect().size
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.07, 0.04, 0.92)
	sb.border_color = Color(0.95, 0.75, 0.30)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = Vector2(340, 70)
	panel.position = Vector2(vp.x - 360, 140)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	# Trofeo (estrella)
	var trophy := Label.new()
	trophy.text = "★"
	trophy.add_theme_font_size_override("font_size", 36)
	trophy.add_theme_color_override("font_color", Color(0.95, 0.85, 0.30))
	trophy.position = Vector2(10, 14)
	trophy.size = Vector2(50, 50)
	panel.add_child(trophy)
	# Título logro
	var title := Label.new()
	title.text = "Logro: " + def["name"]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.position = Vector2(60, 8)
	title.size = Vector2(270, 22)
	panel.add_child(title)
	# Descripción
	var desc := Label.new()
	desc.text = def["desc"]
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	desc.position = Vector2(60, 30)
	desc.size = Vector2(270, 36)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(desc)
	# Slide-in + fade-out
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tw.finished
	if is_instance_valid(panel):
		panel.queue_free()


func get_state() -> Dictionary:
	return {"unlocked": unlocked.keys()}


func set_state(d: Dictionary) -> void:
	unlocked.clear()
	for id in d.get("unlocked", []):
		unlocked[id] = true
