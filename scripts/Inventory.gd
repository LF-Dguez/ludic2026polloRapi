# Inventory — estado del inventario del jugador.
# Slots fijos. Soporta stacking. Provee add/remove/use/serialize.

class_name Inventory
extends RefCounted

const ItemDBScript = preload("res://scripts/ItemDB.gd")

const SLOTS := 16

signal changed  # se emite al modificar (UI lo escucha)

# Array de length SLOTS. Cada slot es null o {"id": String, "count": int}
var items: Array = []


func _init() -> void:
	items.resize(SLOTS)
	for i in range(SLOTS):
		items[i] = null


# Agrega `count` del item `id`. Retorna cuántos NO se pudieron agregar (0 = todo OK).
func add(id: String, count: int = 1) -> int:
	if not ItemDBScript.exists(id) or count <= 0:
		return count
	var remaining: int = count
	var max_stack: int = ItemDBScript.get_max_stack(id)
	# 1. Llenar stacks existentes del mismo tipo
	for i in range(SLOTS):
		if items[i] != null and items[i]["id"] == id and items[i]["count"] < max_stack:
			var space: int = max_stack - items[i]["count"]
			var add_amt: int = mini(space, remaining)
			items[i]["count"] += add_amt
			remaining -= add_amt
			if remaining == 0:
				changed.emit()
				return 0
	# 2. Usar slots vacíos
	for i in range(SLOTS):
		if items[i] == null and remaining > 0:
			var add_amt: int = mini(max_stack, remaining)
			items[i] = {"id": id, "count": add_amt}
			remaining -= add_amt
	changed.emit()
	return remaining


# Usa 1 item del slot. Retorna el id usado o "" si vacío.
func use_slot(slot: int) -> String:
	if slot < 0 or slot >= SLOTS or items[slot] == null:
		return ""
	var used_id: String = items[slot]["id"]
	items[slot]["count"] -= 1
	if items[slot]["count"] <= 0:
		items[slot] = null
	changed.emit()
	return used_id


# Remueve `count` del item `id`. Retorna cuántos efectivamente removidos.
func remove(id: String, count: int = 1) -> int:
	var removed: int = 0
	for i in range(SLOTS):
		if items[i] != null and items[i]["id"] == id:
			var take: int = mini(items[i]["count"], count - removed)
			items[i]["count"] -= take
			removed += take
			if items[i]["count"] <= 0:
				items[i] = null
			if removed >= count:
				break
	if removed > 0:
		changed.emit()
	return removed


func count_of(id: String) -> int:
	var total: int = 0
	for i in range(SLOTS):
		if items[i] != null and items[i]["id"] == id:
			total += items[i]["count"]
	return total


func has(id: String, count: int = 1) -> bool:
	return count_of(id) >= count


# Serialización para SaveManager
func to_array() -> Array:
	var out: Array = []
	for slot in items:
		if slot == null:
			out.append({"id": "", "count": 0})
		else:
			out.append({"id": slot["id"], "count": slot["count"]})
	return out


func from_array(arr: Array) -> void:
	items.resize(SLOTS)
	for i in range(SLOTS):
		if i < arr.size():
			var s: Dictionary = arr[i]
			if s.get("id", "") != "" and s.get("count", 0) > 0:
				items[i] = {"id": s["id"], "count": int(s["count"])}
			else:
				items[i] = null
		else:
			items[i] = null
	changed.emit()
