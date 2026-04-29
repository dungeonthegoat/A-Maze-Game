class_name Enemy
extends Sprite2D

@export var independent_movement: bool = false
@export var move_tick_sec: float = 0.25

@export_group("Nodes")
@export var map: Map
@export var player: Player
@export var line: Line2D

@onready var _move_timer: Timer = Timer.new()

var grid_pos: Vector2i:
	set(new):
		grid_pos = new
		_update_position(new)

func _ready() -> void:
	SignalBus.player_moved.connect(_player_moved)
	grid_pos = map.local_to_map(global_position)
	_move_timer.timeout.connect(_timeout)
	if independent_movement:
		_move_timer.autostart = true
		_move_timer.wait_time = move_tick_sec
		_move_timer.one_shot = false
		add_child.call_deferred(_move_timer)

func _timeout() -> void:
	if not independent_movement: return
	_move()


func _player_moved(_new_pos: Vector2i) -> void:
	if independent_movement: return
	_move()
	

func _move() -> void:
	var path: Array[Vector2i] = map.pathfind(grid_pos, player.grid_pos)
	grid_pos = path[1]
	_update_line(path)

	if player.grid_pos == grid_pos:
		get_tree().reload_current_scene()
		return

func _update_line(path: Array[Vector2i]) -> void:
	line.clear_points()
	for idx in range(1, path.size()):
		line.add_point(map.map_to_local(path[idx]))

func _update_position(new_grid_pos: Vector2i) -> void:
	global_position = map.map_to_local(new_grid_pos)
