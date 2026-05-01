class_name Player
extends GridEntity

@onready var footsteps_sounds: AudioStreamPlayer2D = $FootstepsSounds


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left"): attempt_move(Vector2i.LEFT)
	if event.is_action_pressed("right"): attempt_move(Vector2i.RIGHT)
	if event.is_action_pressed("down"): attempt_move(Vector2i.DOWN)
	if event.is_action_pressed("up"): attempt_move(Vector2i.UP)


func attempt_move(direction: Vector2i) -> void:
	# Return early if the game is over
	if Game.is_game_over: return

	# If the tile you are trying to move into is a wall, return
	var next_grid_pos: Vector2i = direction + grid_pos
	if not map.is_cell_valid(next_grid_pos): return

	grid_pos = next_grid_pos
	Game.player_moved.emit(grid_pos)
	
	footsteps_sounds.play()
