class_name Enemy
extends Sprite2D

const PATH_LINE: PackedScene = preload("uid://k0qw3ewluo02")

## When true, the enemy will move based on a tick rate instead of when the player moves
@export var independent_movement: bool = false
## The time (in seconds) between each movement when independent
@export var move_tick_sec: float = 0.25
## Whether or not the line of the path to the player is visible
@export var line_visible: bool = false
## The interval (every x times) at which the enemy moves when the player does
@export var move_interval: int = 1
## The probability the enemy will move when attempting to, regardless of its movement type
@export var move_chance: float = 0.9

@export_group("Nodes")
@export var map: Map
@export var player: Player

var smoothing: float = 30.0
var _target_pos: Vector2
var _line: Line2D
var _current_cycle: int = 0

@onready var _move_timer: Timer = Timer.new()
@onready var _footsteps_sounds: AudioStreamPlayer2D = $FootstepsSounds

var grid_pos: Vector2i:
	set(new):
		grid_pos = new
		_update_position(new)

func _ready() -> void:
	SignalBus.player_moved.connect(_player_moved)
	grid_pos = map.local_to_map(global_position)
	_move_timer.timeout.connect(_timeout)

	_line = PATH_LINE.instantiate()
	get_tree().current_scene.add_child.call_deferred(_line)
	_line.visible = line_visible

	if independent_movement:
		_move_timer.autostart = true
		_move_timer.wait_time = move_tick_sec
		_move_timer.one_shot = false
		add_child.call_deferred(_move_timer)


func _process(delta):
	global_position = global_position.lerp(_target_pos, 1.0 - exp(-delta * smoothing))


func _exit_tree() -> void:
	_line.queue_free()


func _timeout() -> void:
	if not independent_movement: return
	_move()


func _player_moved(_new_pos: Vector2i) -> void:
	if player.grid_pos == grid_pos:
		SignalBus.end_game()
		return

	if independent_movement: return
	_current_cycle = (_current_cycle + 1) % move_interval
	if _current_cycle > 0: return
	_move()
	

## Attempts to move the enemy towards the player
func _move() -> void:
	if randf() > move_chance or SignalBus.is_game_over:
		return

	var path: Array[Vector2i] = AStar.pathfind(grid_pos, player.grid_pos, map)
	if path.size() <= 1:
		SignalBus.end_game()
		return
	
	grid_pos = path[1]
	_update_line(path)
	_footsteps_sounds.play()

	if player.grid_pos == grid_pos:
		SignalBus.end_game()
		return

func _update_line(path: Array[Vector2i]) -> void:
	_line.clear_points()
	for idx in range(1, path.size()):
		_line.add_point(map.map_to_local(path[idx]))

func _update_position(new_grid_pos: Vector2i) -> void:
	_target_pos = map.map_to_local(new_grid_pos)
