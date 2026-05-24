extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.ZERO
var _alive_time: float = 0.0
const MAX_LIFE := 1.2
const HIT_RADIUS := 28.0


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true


func inicializar(dir: Vector2) -> void:
	direction = dir
	if dir != Vector2.ZERO:
		rotation = direction.angle()
	var spr := get_node_or_null("AnimatedSprite2D")
	if spr != null:
		spr.play("default")


func _physics_process(delta: float) -> void:
	_alive_time += delta
	position += direction * speed * delta
	# Fallback manual: por si el signal no dispara, iterar enemigos cercanos
	for e in get_tree().get_nodes_in_group("enemigo"):
		if not is_instance_valid(e):
			continue
		if global_position.distance_to(e.global_position) < HIT_RADIUS:
			if e.has_method("take_damage"):
				e.take_damage(2)
			else:
				e.queue_free()
			queue_free()
			return
	if _alive_time >= MAX_LIFE:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemigo"):
		if body.has_method("take_damage"):
			body.take_damage(2)
		else:
			body.queue_free()
		queue_free()
