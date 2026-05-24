# DamageNumber — texto flotante de daño sobre enemigos / player.
# Float up + fade out.

class_name DamageNumber
extends Label

const LIFETIME := 0.7
const FLOAT_SPEED := 50.0  # pixels/sec hacia arriba

var _elapsed: float = 0.0


func _ready() -> void:
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	z_index = 100


func setup(amount: int, world_pos: Vector2, is_crit: bool = false) -> void:
	text = "-%d" % amount
	if is_crit:
		text = "-%d!" % amount
		add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
		add_theme_font_size_override("font_size", 28)
	else:
		add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	position = world_pos + Vector2(-12, -32)


func heal(amount: int, world_pos: Vector2) -> void:
	text = "+%d" % amount
	add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	position = world_pos + Vector2(-12, -32)


func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= FLOAT_SPEED * delta
	var t: float = _elapsed / LIFETIME
	modulate.a = 1.0 - t * t  # fade out cuadrático
	if _elapsed >= LIFETIME:
		queue_free()
