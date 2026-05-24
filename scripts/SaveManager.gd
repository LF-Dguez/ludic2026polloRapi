# SaveManager — sistema de save/load roguelike + RPG persistence.
# Guarda en user://save.cfg via ConfigFile (formato INI legible).
#
# DATOS PERSISTENTES:
#   world.seed       — seed del overworld (regenera el mismo mapa al cargar)
#   player.hp        — HP actual
#   player.max_hp    — HP máximo (puede subir con upgrades)
#   player.tile_x/y  — última posición tile del player
#   progress.cleared — Array de "x,y" strings de POIs de mazmorra completados
#   progress.kills   — total de enemigos derrotados (carrera global)
#   progress.runs    — total de runs/intentos de dungeon
#   inventory.items  — Array de Dictionary {type: String, count: int}

class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://save.cfg"


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# data = Dictionary con: seed, hp, max_hp, tile_pos (Vector2i), cleared (Array[Vector2i]),
# kills (int), runs (int), inventory (Array[Dictionary])
static func save_to_disk(data: Dictionary) -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("world", "seed", int(data.get("seed", 0)))
	cfg.set_value("player", "hp", int(data.get("hp", 10)))
	cfg.set_value("player", "max_hp", int(data.get("max_hp", 10)))
	var tp: Vector2i = data.get("tile_pos", Vector2i.ZERO)
	cfg.set_value("player", "tile_x", tp.x)
	cfg.set_value("player", "tile_y", tp.y)
	# Cleared dungeons: serializa como Array[String] "x,y"
	var cleared_arr: Array = []
	for c in data.get("cleared", []):
		var cp: Vector2i = c
		cleared_arr.append("%d,%d" % [cp.x, cp.y])
	cfg.set_value("progress", "cleared", cleared_arr)
	cfg.set_value("progress", "kills", int(data.get("kills", 0)))
	cfg.set_value("progress", "runs", int(data.get("runs", 0)))
	# Inventory
	cfg.set_value("inventory", "items", data.get("inventory", []))
	# XP / Level
	cfg.set_value("xp", "level", int(data.get("xp_level", 1)))
	cfg.set_value("xp", "current", int(data.get("xp_current", 0)))
	# Upgrades permanentes
	cfg.set_value("upgrades", "max_hp_bonus", int(data.get("max_hp_bonus", 0)))
	cfg.set_value("upgrades", "damage_bonus", int(data.get("damage_bonus", 0)))
	cfg.set_value("upgrades", "speed_bonus", float(data.get("speed_bonus", 0.0)))
	cfg.set_value("upgrades", "crit_chance", float(data.get("crit_chance", 0.10)))
	# Achievements
	cfg.set_value("achievements", "unlocked", data.get("achievements", []))
	var err := cfg.save(SAVE_PATH)
	return err == OK


# Retorna null si no hay save válido.
static func load_from_disk():
	if not has_save():
		return null
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return null
	var data: Dictionary = {}
	data["seed"] = cfg.get_value("world", "seed", 0)
	data["hp"] = cfg.get_value("player", "hp", 10)
	data["max_hp"] = cfg.get_value("player", "max_hp", 10)
	data["tile_pos"] = Vector2i(
		cfg.get_value("player", "tile_x", 0),
		cfg.get_value("player", "tile_y", 0)
	)
	# Reconstruir cleared list
	var cleared_arr: Array = cfg.get_value("progress", "cleared", [])
	var cleared: Array = []
	for s in cleared_arr:
		var parts: PackedStringArray = String(s).split(",")
		if parts.size() == 2:
			cleared.append(Vector2i(int(parts[0]), int(parts[1])))
	data["cleared"] = cleared
	data["kills"] = cfg.get_value("progress", "kills", 0)
	data["runs"] = cfg.get_value("progress", "runs", 0)
	data["inventory"] = cfg.get_value("inventory", "items", [])
	data["xp_level"] = cfg.get_value("xp", "level", 1)
	data["xp_current"] = cfg.get_value("xp", "current", 0)
	data["max_hp_bonus"] = cfg.get_value("upgrades", "max_hp_bonus", 0)
	data["damage_bonus"] = cfg.get_value("upgrades", "damage_bonus", 0)
	data["speed_bonus"] = cfg.get_value("upgrades", "speed_bonus", 0.0)
	data["crit_chance"] = cfg.get_value("upgrades", "crit_chance", 0.10)
	data["achievements"] = cfg.get_value("achievements", "unlocked", [])
	return data
