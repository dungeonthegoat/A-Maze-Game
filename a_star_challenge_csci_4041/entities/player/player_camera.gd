class_name PlayerCamera
extends Camera2D

var player: Player
var smoothing: float = 3.0


func _process(delta):
    if not player: return
    global_position = global_position.lerp(player.global_position, 1.0 - exp(-delta * smoothing))