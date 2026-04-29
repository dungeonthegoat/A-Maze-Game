class_name Player
extends Sprite2D

@export var map: Map

var grid_pos: Vector2i:
	set(new):
		grid_pos = new
		_update_position(new)

func _ready() -> void:
	grid_pos = map.local_to_map(global_position)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left"): attempt_move(Vector2i.LEFT)
	if event.is_action_pressed("right"): attempt_move(Vector2i.RIGHT)
	if event.is_action_pressed("down"): attempt_move(Vector2i.DOWN)
	if event.is_action_pressed("up"): attempt_move(Vector2i.UP)

func attempt_move(direction: Vector2i) -> void:
	var next_grid_pos: Vector2i = direction + grid_pos
	if not map.is_cell_valid(next_grid_pos): return

	grid_pos = next_grid_pos
	SignalBus.player_moved.emit(grid_pos)

func _update_position(new_grid_pos: Vector2i) -> void:
	global_position = map.map_to_local(new_grid_pos)
