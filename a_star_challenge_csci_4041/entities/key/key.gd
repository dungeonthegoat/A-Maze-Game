class_name MapKey
extends Area2D

var _collected: bool = false


@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var outer_sprite: Sprite2D = get_node("%OuterSprite")
@onready var light: PointLight2D = get_node("%Glow")

func _ready() -> void:
	anim_player.animation_finished.connect(_animation_ended)
	area_entered.connect(_area_entered)

	outer_sprite.modulate = Color.from_hsv(randf(), 1.0, 1.0)
	light.color = outer_sprite.modulate


func _area_entered(area: Area2D) -> void:
	if _collected: return

	_collected = true
	SignalBus.key_collected.emit()
	anim_player.play("collect")


func _animation_ended(anim: String) -> void:
	if anim != "collect": return
	queue_free()
