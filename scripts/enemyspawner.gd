class_name EnemySpawner
extends RefCounted

const ENEMIGO_SCRIPT := preload("res://scripts/enemigo.gd")

# Builds SpriteFrames para bandido (4 direcciones × 4 frames, 48x64 cada uno)
static func build_bandido_frames(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var anims := ["abajo", "izquierda", "derecha", "arriba"]
	var fw := 48; var fh := 64
	for row in range(4):
		var anim_name: String = anims[row]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 8.0)
		sf.set_animation_loop(anim_name, true)
		for col in range(4):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, row * fh, fw, fh)
			sf.add_frame(anim_name, at)
	return sf


# Builds SpriteFrames para fantasma (1 animación, 7 frames de 64x64)
static func build_fantasma_frames(tex: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	sf.add_animation("default")
	sf.set_animation_speed("default", 6.0)
	sf.set_animation_loop("default", true)
	var fw := 64; var fh := 64
	for col in range(7):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, 0, fw, fh)
		sf.add_frame("default", at)
	return sf


static func spawn_bandido(parent: Node, pos: Vector2, frames: SpriteFrames, layer: TileMapLayer = null, mode: int = 1) -> CharacterBody2D:
	var enemy := CharacterBody2D.new()
	enemy.set_script(ENEMIGO_SCRIPT)
	enemy.position = pos
	enemy.set("four_directions", true)
	enemy.set("tile_layer", layer)
	enemy.set("mode", mode)
	enemy.set("enemy_type", "bandido")
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	col.name = "CollisionShape2D"
	enemy.add_child(col)
	var spr := AnimatedSprite2D.new()
	spr.name = "AnimatedSprite2D"
	spr.sprite_frames = frames
	spr.animation = "abajo"
	spr.centered = true
	enemy.add_child(spr)
	parent.add_child(enemy)
	return enemy


static func spawn_fantasma(parent: Node, pos: Vector2, frames: SpriteFrames, layer: TileMapLayer = null, mode: int = 2) -> CharacterBody2D:
	var enemy := CharacterBody2D.new()
	enemy.set_script(ENEMIGO_SCRIPT)
	enemy.position = pos
	enemy.set("four_directions", false)
	enemy.set("anim_default", "default")
	enemy.set("speed_chase", 70.0)
	enemy.set("speed_patrol", 30.0)
	enemy.set("tile_layer", layer)
	enemy.set("mode", mode)
	enemy.set("enemy_type", "fantasma")
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	col.name = "CollisionShape2D"
	enemy.add_child(col)
	var spr := AnimatedSprite2D.new()
	spr.name = "AnimatedSprite2D"
	spr.sprite_frames = frames
	spr.animation = "default"
	spr.centered = true
	spr.modulate = Color(1, 1, 1, 0.85)
	enemy.add_child(spr)
	parent.add_child(enemy)
	return enemy
