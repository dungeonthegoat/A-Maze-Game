class_name Map
extends TileMapLayer
## A class that handles tiles and pathfinding

const PLAYER: PackedScene = preload("uid://ceu354p11d0if")
const ENEMY: PackedScene = preload("uid://cidtv8w4mv6nh")
const KEY: PackedScene = preload("uid://c5vy355ik3o2a")


@export_group("Config")
@export var debug: bool = false
@export var perfect_maze: bool = false

var neighbor_map: Dictionary[Vector2i, Array] = {}
var resolution: Vector2i = Vector2i(36, 20)
var _current_player: Player
var _current_enemy: Enemy

@onready var camera: PlayerCamera = get_tree().current_scene.get_node("%PlayerCamera")


func _unhandled_input(event: InputEvent) -> void:
	if not debug: return
	if event.is_action_pressed("debug_map"):
		get_tree().reload_current_scene()


## Checks whether a given cell is valid to traverse on
func is_cell_valid(coords: Vector2i) -> bool:
	return get_cell_atlas_coords(coords) == Vector2i.ZERO


## Updates the tile map to display a given grid graph
func display_edges(edges: Array[Edge]) -> void:
	# 1. Clear the existing tile map and replace it with all walls
	# (make sure to fill beyond the screen so the camera can pan around)
	clear()
	for x in range(-resolution.x, resolution.x):
		for y in range(-resolution.y, resolution.y):
			set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	# 2. Display the edges themselves
	for edge in edges:
		set_cell(edge.from * 2 - offset, 0, Vector2i.ZERO)
		set_cell(edge.to * 2 - offset, 0, Vector2i.ZERO)
		set_cell((edge.to + edge.from) - offset, 0, Vector2i.ZERO)


## Generates a procedural maze that is ready for pathfinding
func generate_maze(num_keys: int, custom_maze: Array[Edge] = []) -> void:
	# Display the edges and update the physical tile map 
	var maze_edges: Array[Edge]
	if not custom_maze.is_empty():
		maze_edges = custom_maze
	else:
		var maze: Maze = Maze.new()
		maze.size = resolution
		maze_edges = maze.generate_maze()
	
	display_edges(maze_edges)

	# Update the neighbors dictionary to prepare for pathfinding
	_init_neighbors(maze_edges)

	# Spawn in the player and enemy
	_spawn_entities(maze_edges)

	# Finally, spawn the keys in
	_spawn_keys(maze_edges, num_keys)



## Spawns the player and enemies into the maze
func _spawn_entities(maze: Array[Edge]) -> void:
	# Spawn player
	if _current_player:
		_current_player.queue_free()
	
	_current_player = PLAYER.instantiate()
	_current_player.map = self
	add_child.call(_current_player)

	var offset: Vector2i = resolution / 2 - Vector2i.ONE
	_current_player.grid_pos = maze[0].from * 2 - offset
	_current_player.position = map_to_local(_current_player.grid_pos)
	camera.player = _current_player
	if camera.follow_player:
		camera.position = map_to_local(_current_player.grid_pos)

	# Spawn enemy
	if _current_enemy:
		_current_enemy.queue_free()
	
	_current_enemy = ENEMY.instantiate()
	_current_enemy.map = self
	add_child.call(_current_enemy)

	_current_enemy.grid_pos = maze[-1].from * 2 - offset
	_current_enemy.player = _current_player


func _spawn_keys(maze: Array[Edge], key_count: int) -> void:
	# Place all of the possible vertex locations (excluding player and enemy spawn
	# points) into a dictionary which will later have its keys shuffled. A
	# dictionary is used here because it makes checking for duplicates faster
	var valid_positions: Dictionary
	for idx in range(1, maze.size() - 2):
		valid_positions[maze[idx].from] = true
		valid_positions[maze[idx].to] = true
	
	# Shuffle the keys of the valid spawn locations
	var spawn_points := valid_positions.keys()
	spawn_points.shuffle()

	# Spawn the keys
	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	for _i in range(key_count):
		if spawn_points.is_empty(): return # If there are fewer edges than keys, this is a problem

		var spawn_pos: Vector2 = map_to_local(spawn_points.pop_back() * 2  - offset)
		var key: MapKey = KEY.instantiate()
		key.global_position = spawn_pos
		add_child.call_deferred(key)


## Initializes the neighbors of every cell into a dictionary to allow for faster cell-neighbor lookup
func _init_neighbors(maze: Array[Edge]) -> void:
	neighbor_map.clear()
	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	for edge in maze:
		var from: Vector2i = edge.from * 2 - offset
		var to: Vector2i = edge.to * 2 - offset
		var mid: Vector2i = (edge.to + edge.from) - offset

		if not neighbor_map.get_or_add(from, []).has(mid): neighbor_map[from].append(mid)
		if not neighbor_map.get_or_add(mid, []).has(from): neighbor_map[mid].append(from)
		if not neighbor_map.get_or_add(to, []).has(mid): neighbor_map[to].append(mid)
		if not neighbor_map.get_or_add(mid, []).has(to): neighbor_map[mid].append(to)
