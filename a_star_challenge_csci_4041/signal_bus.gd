extends Node

signal key_collected()
signal keys_updated(keys: int, max_keys: int)
signal player_moved(to: Vector2i)
signal game_ended()

var is_game_over: bool = false


func end_game() -> void:
    # Don't allow ending the game multiple times
    if is_game_over:
        return
    
    is_game_over = true
    game_ended.emit()


func restart_game() -> void:
    is_game_over = false
    get_tree().reload_current_scene()