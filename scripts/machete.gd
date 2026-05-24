extends Area2D

@export var speed: float = 400.0
var direction: Vector2 = Vector2.ZERO

func inicializar(dir: Vector2) -> void:
	direction = dir
	rotation = direction.angle()
	$AnimatedSprite2D.play("default")
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemigo"):
		body.queue_free()
		queue_free()
