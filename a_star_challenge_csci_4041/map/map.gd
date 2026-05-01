class_name Map
extends TileMapLayer
## A class that handles tiles and pathfinding

const PLAYER: PackedScene = preload("uid://ceu354p11d0if")
const ENEMY: PackedScene = preload("uid://cidtv8w4mv6nh")
const KEY: PackedScene = preload("uid://c5vy355ik3o2a")
const LAMP: PackedScene = preload("uid://ge4h8fa17kpc")


@export_group("Config")
@export var debug: bool = false
@export var perfect_maze: bool = false

var neighbor_map: Dictionary[Vector2i, Array] = {}
var resolution: Vector2i = Vector2i(36, 20)
var maze: Maze
var enemies: Array[Enemy]
var player: Player

@onready var camera: PlayerCamera = get_tree().current_scene.get_node("%PlayerCamera")


func _unhandled_input(event: InputEvent) -> void:
	if not debug: return
	if event.is_action_pressed("debug_map"):
		get_tree().reload_current_scene()


## Checks whether a given cell is valid to traverse on
func is_cell_valid(coords: Vector2i) -> bool:
	return get_cell_atlas_coords(coords) == Vector2i.ZERO


## Updates the tile map to display a given grid graph
func display_edges() -> void:
	# 1. Clear the existing tile map and replace it with all walls
	# (make sure to fill beyond the screen so the camera can pan around)
	clear()
	for x in range(-resolution.x, resolution.x):
		for y in range(-resolution.y, resolution.y):
			set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	# 2. Display the edges themselves
	for edge in maze._maze:
		set_cell(edge.from * 2 - offset, 0, Vector2i.ZERO)
		set_cell(edge.to * 2 - offset, 0, Vector2i.ZERO)
		set_cell((edge.to + edge.from) - offset, 0, Vector2i.ZERO)


## Generates a procedural maze that is ready for pathfinding
func generate_maze(num_keys: int, light_count: int, enemy_count: int, custom_maze: Maze) -> void:
	# Display the edges and update the physical tile map 
	var maze_edges: Array[Edge]
	if custom_maze:
		maze_edges = custom_maze._maze
		maze = custom_maze
	else:
		maze = Maze.new()
		maze.size = resolution
		maze_edges = maze.generate_maze()
	
	display_edges()

	# Update the neighbors dictionary to prepare for pathfinding
	_init_neighbors()

	# Spawn in the player and enemy
	_spawn_player()
	spawn_enemies(enemy_count)

	# Finally, spawn the keys in
	_spawn_keys(num_keys)
	_spawn_lamps(light_count)


## Returns a dictionary representing every tile that an enemy is trying to
## walk over to get to the player
func get_penalty_map(enemy: Enemy) -> Dictionary[Vector2i, int]:
	var penalty_map: Dictionary[Vector2i, int] = {}

	for other_enemy in enemies:
		if other_enemy == enemy: continue

		for vertex in other_enemy.current_path:
			if not penalty_map.has(vertex):
				penalty_map[vertex] = 1
			else:
				penalty_map[vertex] += 1

	return penalty_map


## Spawns the player and enemies into the maze
func _spawn_player() -> void:
	player = PLAYER.instantiate()
	player.map = self
	get_tree().current_scene.add_child.call(player)

	var offset: Vector2i = resolution / 2 - Vector2i.ONE
	player.grid_pos = maze._maze[0].from * 2 - offset
	player.position = map_to_local(player.grid_pos)
	camera.player = player
	if camera.follow_player:
		camera.position = map_to_local(player.grid_pos)


## Spawns some amount of enemies on the map
func spawn_enemies(count: int) -> void:
	var offset: Vector2i = resolution / 2 - Vector2i.ONE
	var min_dist_from_player: int = maxi(1, float(resolution.length()) * 0.2)

	for _i in count:
		var spawn_point: Vector2i = Vector2i.ZERO
		var dist: int = 0
		
		while dist <= min_dist_from_player:
			spawn_point = maze._maze[randi_range(1, maze._maze.size() - 1)].from * 2 - offset
			dist = _taxi_dist(spawn_point, player.grid_pos)

		var enemy: Enemy = ENEMY.instantiate()
		enemy.map = self
		get_tree().current_scene.add_child.call(enemy)

		enemy.grid_pos = spawn_point
		enemy.position = map_to_local(enemy.grid_pos)
		enemy.player = player

		enemies.append(enemy)


func _spawn_keys(key_count: int) -> void:
	# Place all of the possible vertex locations (excluding player and enemy spawn
	# points) into a dictionary which will later have its keys shuffled. A
	# dictionary is used here because it makes checking for duplicates faster
	var valid_positions: Dictionary
	for idx in range(1, maze._maze.size() - 2):
		valid_positions[maze._maze[idx].from] = true
		valid_positions[maze._maze[idx].to] = true
	
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


func _spawn_lamps(count: int) -> void:
	var valid_positions: Dictionary
	for idx in range(1, maze._maze.size() - 2):
		valid_positions[maze._maze[idx].from] = true
		valid_positions[maze._maze[idx].to] = true
	
	var spawn_points := valid_positions.keys()
	spawn_points.shuffle()

	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	for _i in range(count):
		if spawn_points.is_empty(): return

		var spawn_pos: Vector2 = map_to_local(spawn_points.pop_back() * 2  - offset)
		var lamp: Node2D = LAMP.instantiate()
		lamp.global_position = spawn_pos
		get_tree().current_scene.add_child.call_deferred(lamp)


## Initializes the neighbors of every cell into a dictionary to allow for faster cell-neighbor lookup
func _init_neighbors() -> void:
	neighbor_map.clear()
	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	for edge in maze._maze:
		var from: Vector2i = edge.from * 2 - offset
		var to: Vector2i = edge.to * 2 - offset
		var mid: Vector2i = (edge.to + edge.from) - offset

		if not neighbor_map.get_or_add(from, []).has(mid): neighbor_map[from].append(mid)
		if not neighbor_map.get_or_add(mid, []).has(from): neighbor_map[mid].append(from)
		if not neighbor_map.get_or_add(to, []).has(mid): neighbor_map[to].append(mid)
		if not neighbor_map.get_or_add(mid, []).has(to): neighbor_map[mid].append(to)


## Returns the taxicab distance between two points on the map
func _taxi_dist(p1: Vector2i, p2:Vector2i) -> int:
	return absi(p1.x - p2.x) + absi(p1.y - p2.y)
