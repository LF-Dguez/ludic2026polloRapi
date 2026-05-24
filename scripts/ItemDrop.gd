# ItemDrop — Area2D que aparece al matar enemigo, player lo recoge al caminar encima.

class_name ItemDrop
extends Area2D

const ItemDBScript = preload("res://scripts/ItemDB.gd")
const IconGenScript = preload("res://scripts/IconGenerator.gd")

const PICKUP_RADIUS := 28.0

var item_id: String = ""
var count: int = 1
var _bob_t: float = 0.0
var _sprite: Sprite2D = null


func _ready() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = PICKUP_RADIUS
	col.shape = shape
	add_child(col)
	# Visual: Sprite2D con icono procedural (32x32 → scale 0.7 = 22px display)
	_sprite = Sprite2D.new()
	_sprite.texture = IconGenScript.get_icon(item_id)
	_sprite.centered = true
	_sprite.scale = Vector2(0.85, 0.85)
	add_child(_sprite)
	z_index = 6


func setup(id: String, c: int) -> void:
	item_id = id
	count = c


func _process(delta: float) -> void:
	# Bob arriba-abajo
	_bob_t += delta * 4.0
	if _sprite != null:
		_sprite.position.y = sin(_bob_t) * 3.0
		_sprite.rotation = sin(_bob_t * 0.5) * 0.1
	# Check pickup: player cerca
	var player := get_tree().get_first_node_in_group("player")
	if player != null and global_position.distance_to(player.global_position) < PICKUP_RADIUS:
		if "inventory" in player and player.inventory != null:
			var remaining: int = player.inventory.add(item_id, count)
			if remaining < count:
				queue_free()
