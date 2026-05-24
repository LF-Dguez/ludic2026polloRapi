# ItemDB — registro central de todos los items del juego.
# Cada item: id → {name, category, max_stack, color, label, effect data}

class_name ItemDB
extends RefCounted

# ─── Categorías ──────────────────────────────────────────────────────────
const CAT_CONSUMABLE := "consumable"  # uso 1 vez
const CAT_WEAPON     := "weapon"      # equipable (cambia arma actual)
const CAT_UPGRADE    := "upgrade"     # mejora permanente al usar
const CAT_KEY        := "key"         # llaves / progresión
const CAT_CURRENCY   := "currency"    # dinero/moneda
const CAT_RESOURCE   := "resource"    # crafting/venta
const CAT_RELIC      := "relic"       # lore/achievement

# Letra del icono (placeholder visual hasta tener sprites)
const ITEMS := {
	# ─── CONSUMIBLES (curan / buffean) ───────────────────────────────────
	"tortilla": {
		"name": "Tortilla",
		"category": "consumable",
		"max_stack": 12,
		"color": Color(0.92, 0.82, 0.52),
		"label": "T",
		"cure": 1,
	},
	"olla_barro": {
		"name": "Olla de barro",
		"category": "consumable",
		"max_stack": 5,
		"color": Color(0.72, 0.40, 0.20),
		"label": "O",
		"cure": 3,
	},
	"mezcal": {
		"name": "Mezcal",
		"category": "consumable",
		"max_stack": 4,
		"color": Color(0.85, 0.78, 0.30),
		"label": "M",
		"cure": 5,
		"invuln_seconds": 5.0,
	},
	"sotol": {
		"name": "Sotol",
		"category": "consumable",
		"max_stack": 4,
		"color": Color(0.55, 0.70, 0.40),
		"label": "S",
		"speed_boost": 1.5,
		"speed_seconds": 30.0,
	},
	"carne_seca": {
		"name": "Carne seca",
		"category": "consumable",
		"max_stack": 8,
		"color": Color(0.50, 0.30, 0.20),
		"label": "C",
		"cure": 2,
	},
	"agua_bendita": {
		"name": "Agua bendita",
		"category": "consumable",
		"max_stack": 2,
		"color": Color(0.80, 0.90, 1.00),
		"label": "A",
		"cure": 99,  # full heal
	},
	# ─── ARMAS (cambian arma equipada) ───────────────────────────────────
	"machete": {
		"name": "Machete",
		"category": "weapon",
		"max_stack": 1,
		"color": Color(0.85, 0.85, 0.75),
		"label": "♦",
		"weapon_id": "machete",
	},
	"cuchillo": {
		"name": "Cuchillo",
		"category": "weapon",
		"max_stack": 1,
		"color": Color(0.70, 0.70, 0.80),
		"label": "♣",
		"weapon_id": "cuchillo",
	},
	"pistola_villa": {
		"name": "Pistola de Villa",
		"category": "weapon",
		"max_stack": 1,
		"color": Color(0.30, 0.30, 0.30),
		"label": "♠",
		"weapon_id": "pistola_villa",
	},
	"rifle_serrano": {
		"name": "Rifle serrano",
		"category": "weapon",
		"max_stack": 1,
		"color": Color(0.40, 0.25, 0.15),
		"label": "♥",
		"weapon_id": "rifle_serrano",
	},
	# ─── MEJORAS PERMANENTES ─────────────────────────────────────────────
	"corazon_sagrado": {
		"name": "Corazón sagrado",
		"category": "upgrade",
		"max_stack": 5,
		"color": Color(0.95, 0.20, 0.30),
		"label": "♥",
		"upgrade_max_hp": 1,
	},
	"filo_obsidiana": {
		"name": "Filo de obsidiana",
		"category": "upgrade",
		"max_stack": 3,
		"color": Color(0.10, 0.05, 0.20),
		"label": "▲",
		"upgrade_damage": 1,
	},
	"botin_charro": {
		"name": "Botín del charro",
		"category": "upgrade",
		"max_stack": 1,
		"color": Color(0.60, 0.45, 0.20),
		"label": "▼",
		"upgrade_speed": 40.0,
	},
	# ─── LLAVES / PROGRESIÓN ─────────────────────────────────────────────
	"llave_paquime": {
		"name": "Llave de Paquimé",
		"category": "key",
		"max_stack": 1,
		"color": Color(0.85, 0.65, 0.30),
		"label": "ǂ",
	},
	"cristal_naica": {
		"name": "Cristal de Naica",
		"category": "key",
		"max_stack": 1,
		"color": Color(0.70, 0.90, 1.00),
		"label": "◆",
	},
	"mapa_raramuri": {
		"name": "Mapa rarámuri",
		"category": "key",
		"max_stack": 1,
		"color": Color(0.78, 0.70, 0.50),
		"label": "▣",
	},
	# ─── MONEDA / RECURSOS ───────────────────────────────────────────────
	"pesos_plata": {
		"name": "Pesos de plata",
		"category": "currency",
		"max_stack": 999,
		"color": Color(0.85, 0.85, 0.90),
		"label": "$",
	},
	"ceramica_mata_ortiz": {
		"name": "Cerámica de Mata Ortiz",
		"category": "resource",
		"max_stack": 8,
		"color": Color(0.82, 0.65, 0.40),
		"label": "ψ",
	},
	"vetas_cobre": {
		"name": "Vetas de cobre",
		"category": "resource",
		"max_stack": 20,
		"color": Color(0.75, 0.40, 0.20),
		"label": "ω",
	},
	"piedra_mineral": {
		"name": "Piedra mineral",
		"category": "resource",
		"max_stack": 20,
		"color": Color(0.45, 0.42, 0.40),
		"label": "○",
	},
	# ─── RELIQUIAS / LORE ─────────────────────────────────────────────────
	"calavera_villa": {
		"name": "Calavera de Pancho Villa",
		"category": "relic",
		"max_stack": 1,
		"color": Color(0.95, 0.95, 0.85),
		"label": "☠",
		"upgrade_max_hp": 1,
	},
	"codice_paquime": {
		"name": "Códice de Paquimé",
		"category": "relic",
		"max_stack": 1,
		"color": Color(0.80, 0.65, 0.30),
		"label": "✦",
	},
	"foto_parral": {
		"name": "Foto de Hidalgo del Parral",
		"category": "relic",
		"max_stack": 1,
		"color": Color(0.50, 0.50, 0.50),
		"label": "▭",
	},
	# ─── NUEVOS items (consumibles/recursos) ─────────────────────────────
	"peyote": {
		"name": "Peyote",
		"category": "consumable",
		"max_stack": 3,
		"color": Color(0.35, 0.55, 0.30),
		"label": "✦",
		"invuln_seconds": 8.0,
		"speed_boost": 1.3,
		"speed_seconds": 12.0,
	},
	"polvora": {
		"name": "Pólvora serrana",
		"category": "resource",
		"max_stack": 30,
		"color": Color(0.20, 0.15, 0.10),
		"label": "●",
	},
	"rosario": {
		"name": "Rosario bendito",
		"category": "consumable",
		"max_stack": 3,
		"color": Color(0.65, 0.45, 0.20),
		"label": "⊕",
		"cure": 4,
		"invuln_seconds": 3.0,
	},
	"herradura": {
		"name": "Herradura",
		"category": "upgrade",
		"max_stack": 2,
		"color": Color(0.55, 0.55, 0.60),
		"label": "U",
		"upgrade_speed": 25.0,
	},
	"sombrero_revolucion": {
		"name": "Sombrero revolucionario",
		"category": "upgrade",
		"max_stack": 1,
		"color": Color(0.55, 0.35, 0.15),
		"label": "∩",
		"upgrade_max_hp": 2,
		"upgrade_damage": 1,
	},
	# ─── BOSS RELIQUIAS ───────────────────────────────────────────────────
	"corona_paquime": {
		"name": "Corona del Señor de Casas Grandes",
		"category": "relic",
		"max_stack": 1,
		"color": Color(0.85, 0.65, 0.20),
		"label": "♛",
		"upgrade_max_hp": 3,
	},
	"colmillo_bestia": {
		"name": "Colmillo de la Bestia",
		"category": "relic",
		"max_stack": 1,
		"color": Color(0.95, 0.90, 0.80),
		"label": "▼",
		"upgrade_damage": 2,
	},
	"esquirla_espectro": {
		"name": "Esquirla del Espectro",
		"category": "relic",
		"max_stack": 1,
		"color": Color(0.65, 0.45, 0.85),
		"label": "◈",
		"upgrade_speed": 50.0,
	},
}


static func get_def(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func get_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


static func get_max_stack(id: String) -> int:
	return ITEMS.get(id, {}).get("max_stack", 1)


static func get_color(id: String) -> Color:
	return ITEMS.get(id, {}).get("color", Color.WHITE)


static func get_label(id: String) -> String:
	return ITEMS.get(id, {}).get("label", "?")


static func get_category(id: String) -> String:
	return ITEMS.get(id, {}).get("category", "")


static func exists(id: String) -> bool:
	return ITEMS.has(id)


# Tabla de drops por tipo de enemigo
const DROP_TABLES := {
	"bandido": [
		{"id": "tortilla", "chance": 0.35, "count": 1},
		{"id": "pesos_plata", "chance": 0.55, "count": 3},
		{"id": "carne_seca", "chance": 0.15, "count": 1},
		{"id": "cuchillo", "chance": 0.05, "count": 1},
		{"id": "filo_obsidiana", "chance": 0.02, "count": 1},
		{"id": "polvora", "chance": 0.12, "count": 2},
		{"id": "rosario", "chance": 0.04, "count": 1},
		{"id": "sombrero_revolucion", "chance": 0.015, "count": 1},
	],
	"fantasma": [
		{"id": "agua_bendita", "chance": 0.20, "count": 1},
		{"id": "pesos_plata", "chance": 0.40, "count": 2},
		{"id": "calavera_villa", "chance": 0.01, "count": 1},
		{"id": "corazon_sagrado", "chance": 0.06, "count": 1},
		{"id": "peyote", "chance": 0.05, "count": 1},
		{"id": "herradura", "chance": 0.03, "count": 1},
	],
}


static func roll_drop(enemy_type: String) -> Array:
	# Retorna Array de {id, count} con drops
	var table: Array = DROP_TABLES.get(enemy_type, [])
	var drops: Array = []
	for entry in table:
		if randf() < entry["chance"]:
			drops.append({"id": entry["id"], "count": entry["count"]})
	return drops
