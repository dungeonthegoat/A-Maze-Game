class_name GridEntity
extends Node2D

@export var smoothing: float = 20.0


var map: Map
var grid_pos: Vector2i:
	set(new):
		grid_pos = new
		_update_position(new)
var _target_pos: Vector2


func _ready() -> void:
	grid_pos = map.local_to_map(global_position)


func _process(delta: float) -> void:
	global_position = global_position.lerp(_target_pos, 1.0 - exp(-delta * smoothing))


func _update_position(new_grid_pos: Vector2i) -> void:
	_target_pos = map.map_to_local(new_grid_pos)
