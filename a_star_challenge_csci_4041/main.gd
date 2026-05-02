class_name GameManager
extends Node2D

enum EndState {LOSS, WIN}

@export_group("Config")
@export var keys_required: int = 5
@export var enemy_count: int = 2
@export var lamp_count: int = 10
@export var maze_parameters: Maze
@export_range(0, 5, 1, "or_greater") var enemy_spawn_count_on_key_pickup: int = 0

@export_group("Nodes")
@export var map: Map

var keys_collected: int = 0

@onready var end_anim_player: AnimationPlayer = get_node("%EndGameAnimation")


func _ready() -> void:
	# Initialize signal connections
	Game.keys_updated.emit(keys_collected, keys_required)
	Game.key_collected.connect(_key_collected)
	Game.player_caught.connect(_game_lost)
	
	_start_game()


func _start_game() -> void:
	# Generate the map
	maze_parameters.GenerateMaze()
	map.resolution = maze_parameters.Size
	map.generate_maze(keys_required, lamp_count, enemy_count, maze_parameters)
	
	Game.game_started.emit()


func _key_collected() -> void:
	keys_collected += 1
	if keys_collected >= keys_required:
		_game_won()
	
	if enemy_spawn_count_on_key_pickup > 0 and keys_collected < keys_required:
		map.spawn_enemies(enemy_spawn_count_on_key_pickup, map.maze.GetGodotEdges())
	
	Game.keys_updated.emit(keys_collected, keys_required)


func _game_lost() -> void:
	Game.game_ended.emit(EndState.LOSS)
	end_anim_player.play("jumpscare")
	_queue_restart_game()


func _game_won() -> void:
	Game.game_ended.emit(EndState.WIN)
	end_anim_player.play("victory")
	_queue_restart_game()


func _queue_restart_game() -> void:
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()
