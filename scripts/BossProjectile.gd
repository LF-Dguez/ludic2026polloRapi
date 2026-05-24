# BossProjectile — proyectil esférico simple (fuego, cristal) que daña al player.

class_name BossProjectile
extends Area2D

const SIZE := 32
const MAX_LIFE := 4.0

var damage: int = 3
var speed: float = 220.0
var travel_dir: Vector2 = Vector2.RIGHT
var color: Color = Color(1, 0.5, 0.1)
var radius: int = 16

var _life: float = 0.0
var _sprite: Sprite2D = null


func _ready() -> void:
	# Sprite procedural circular brillante
	var size: int = radius * 2 + 4
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: int = size / 2
	var cy: int = size / 2
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var d2: int = dx * dx + dy * dy
			if d2 <= radius * radius:
				var t: float = 1.0 - sqrt(float(d2)) / float(radius)
				var c: Color = color
				c.a = 0.6 + 0.4 * t
				img.set_pixel(cx + dx, cy + dy, c)
	# Núcleo blanco
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			if dx * dx + dy * dy <= 9:
				img.set_pixel(cx + dx, cy + dy, Color(1, 1, 1, 0.95))
	var tex := ImageTexture.create_from_image(img)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = true
	add_child(_sprite)
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = float(radius)
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)
	z_index = 10


func _physics_process(delta: float) -> void:
	_life += delta
	if _life > MAX_LIFE:
		queue_free()
		return
	global_position += travel_dir * speed * delta
	# Manual collision: distancia con player
	var p := get_tree().get_first_node_in_group("player")
	if p != null and global_position.distance_to(p.global_position) < float(radius) + 10.0:
		if p.has_method("take_damage"):
			p.take_damage(damage)
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
