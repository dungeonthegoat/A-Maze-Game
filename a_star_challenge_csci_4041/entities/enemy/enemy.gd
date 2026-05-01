class_name Enemy
extends GridEntity

const PATH_LINE: PackedScene = preload("uid://k0qw3ewluo02")

## When true, the enemy will move based on a tick rate instead of syncing with when the player moves
@export var independent_movement: bool = false
## The time (in seconds) between each movement when using independent movement
@export var move_tick_sec: float = 0.25
## Makes the calculated path from the enemy to the player visible
@export var line_visible: bool = false
## The interval (every x times) at which the enemy moves when the player does
## For example, if move_interval is 2, then the enemy moves with every other
## player movement.
@export var move_interval: int = 1
## The probability the enemy will move when attempting to, regardless of its movement type
@export var move_chance: float = 0.9
## The distance (in tiles) the enemy moves each movement
@export var move_distance: int = 1

## Whether or not the enemy should randomly switch between dependent/independent movement
@export var switch_modes: bool = true

@export var min_switch_delay_sec: float = 10.0
@export var max_switch_delay_sec: float = 30.0

## Higher value = less precise but much faster
@export_range(0.0, 2.0, 0.1, "or_greater") var heuristic_weight: float = 1.0


@export_group("Nodes")
@export var player: Player

var _line: Line2D
var _current_cycle: int = 0

## The timer that determines when to switch between dependent or independent
@onready var _switch_timer: Timer = Timer.new()
@onready var _move_timer: Timer = Timer.new()
@onready var _footsteps_sounds: AudioStreamPlayer2D = $FootstepsSounds


func _ready() -> void:
	Game.player_moved.connect(_player_moved)
	grid_pos = map.local_to_map(global_position)
	_move_timer.timeout.connect(_move_timeout)
	_switch_timer.timeout.connect(_switch_timer_timeout)

	_line = PATH_LINE.instantiate()
	get_tree().current_scene.add_child.call_deferred(_line)
	_line.visible = line_visible

	_move_timer.autostart = true
	_move_timer.wait_time = move_tick_sec
	_move_timer.one_shot = false
	add_child.call_deferred(_move_timer)

	if switch_modes:
		# Start on a random mode if independent
		independent_movement = randf() > 0.5
		
		_switch_timer.autostart = true
		_switch_timer.wait_time = _get_random_delay_time()
		_switch_timer.one_shot = true
		add_child.call_deferred(_switch_timer)


func _exit_tree() -> void:
	_line.queue_free()


func _switch_timer_timeout() -> void:
	independent_movement = not independent_movement
	_switch_timer.start(_get_random_delay_time())


func _move_timeout() -> void:
	if not independent_movement: return
	_move()


func _player_moved(_new_pos: Vector2i) -> void:
	if player.grid_pos == grid_pos:
		Game.player_caught.emit()
		return

	if independent_movement: return
	_current_cycle = (_current_cycle + 1) % move_interval
	if _current_cycle > 0: return
	_move()
	

## Attempts to move the enemy towards the player
func _move() -> void:
	if randf() > move_chance or Game.is_game_over:
		return

	var path: Array[Vector2i] = AStar.pathfind(grid_pos, player.grid_pos, map, heuristic_weight)
	if path.size() <= move_distance:
		Game.player_caught.emit()
		return
	
	grid_pos = path[move_distance]
	_update_line(path)
	_footsteps_sounds.play()

	if player.grid_pos == grid_pos:
		Game.player_caught.emit()
		return


func _update_line(path: Array[Vector2i]) -> void:
	_line.clear_points()
	for idx in range(1, path.size()):
		_line.add_point(map.map_to_local(path[idx]))


## Gets a random delay to switch movement types
func _get_random_delay_time() -> float:
	return randf_range(min_switch_delay_sec, max_switch_delay_sec)
