extends Node2D

@export_group("Config")
@export var keys_required: int = 5
@export var maze_parameters: Maze

@export_group("Nodes")
@export var map: Map

var keys_collected: int = 0

@onready var anim_player: AnimationPlayer = get_node("%JumpscareAnimation")


func _ready() -> void:
	# Initialize signal connections
	SignalBus.keys_updated.emit(keys_collected, keys_required)
	SignalBus.game_ended.connect(_game_ended)
	SignalBus.key_collected.connect(_key_collected)
	anim_player.animation_finished.connect( # When the jumpscare animation ends, reset the game
		func (anim_name: String) -> void: 
		if anim_name == "jumpscare": SignalBus.restart_game())
	
	# Generate the map
	maze_parameters.generate_maze()
	map.generate_maze(keys_required, maze_parameters._maze)


func _key_collected() -> void:
	keys_collected += 1
	if keys_collected >= keys_required:
		# End the game here (victory)
		get_tree().quit()
	
	SignalBus.keys_updated.emit(keys_collected, keys_required)


func _game_ended() -> void:
	anim_player.play("jumpscare")
