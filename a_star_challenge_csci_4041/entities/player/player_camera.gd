class_name PlayerCamera
extends Camera2D

@export var follow_player: bool = false

var player: Player
var smoothing: float = 3.0


func _process(delta: float) -> void:
	if not follow_player or not player: return
	global_position = global_position.lerp(player.global_position, 1.0 - exp(-delta * smoothing))
