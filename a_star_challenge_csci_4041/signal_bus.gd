extends Node

signal key_collected()
signal keys_updated(keys: int, max_keys: int)
signal player_moved(to: Vector2i)
signal player_caught()
signal game_ended(state: GameManager.EndState)
signal game_started()


var is_game_over: bool = false


func _ready() -> void:
	game_ended.connect(_game_ended)
	game_started.connect(_game_started)


func _game_ended(_state: GameManager.EndState) -> void:
	is_game_over = true


func _game_started() -> void:
	is_game_over = false