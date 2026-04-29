class_name Enemy
extends Sprite2D

@export var map: Map
@export var player: Player
@export var line: Line2D

var grid_pos: Vector2i:
	set(new):
		grid_pos = new
		_update_position(new)

func _ready() -> void:
	SignalBus.player_moved.connect(_player_moved)
	grid_pos = map.local_to_map(global_position)

func _player_moved(new_pos: Vector2i) -> void:
	if new_pos == grid_pos:
		get_tree().reload_current_scene()
		return
	
	var path: Array[Vector2i] = map.pathfind(grid_pos, new_pos)
	grid_pos = path[1]
	_update_line(path)

func _update_line(path: Array[Vector2i]) -> void:
	line.clear_points()
	for idx in range(1, path.size()):
		line.add_point(map.map_to_local(path[idx]))

func _update_position(new_grid_pos: Vector2i) -> void:
	global_position = map.map_to_local(new_grid_pos)
