class_name Enemy
extends Sprite2D

class Cell:
	var goal: Vector2i
	var prev: Cell
	var pos: Vector2i

	var f_cost: float
	var h_cost: float
	var g_cost: float

	func _init(new_goal: Vector2i, new_pos: Vector2i, new_prev_cell: Cell) -> void:
		self.goal = new_goal
		self.pos = new_pos
		self.prev = new_prev_cell

		if prev:
			self.g_cost = prev.g_cost + 1.0
		else:
			self.g_cost = 0.0

		self.h_cost = abs(pos.x - goal.x) + abs(pos.y - goal.y)
		self.f_cost = self.g_cost + self.h_cost

@export var tile_map: TileMapLayer
@export var player: Player
@export var line: Line2D

var grid_pos: Vector2i:
	set(new):
		grid_pos = new
		_update_position(new)

func _ready() -> void:
	SignalBus.player_moved.connect(_player_moved)
	grid_pos = tile_map.local_to_map(global_position)

func _player_moved(new_pos: Vector2i) -> void:
	if new_pos == grid_pos:
		get_tree().reload_current_scene()
		return
	
	var path: Array[Vector2i] = a_star(grid_pos, new_pos)
	grid_pos = path[1]
	_update_line(path)

func _update_line(path: Array[Vector2i]) -> void:
	line.clear_points()
	for idx in range(1, path.size()):
		line.add_point(tile_map.map_to_local(path[idx]))

func _update_position(new_grid_pos: Vector2i) -> void:
	global_position = tile_map.map_to_local(new_grid_pos)

func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

	for dir in dirs:
		if not is_cell_valid(pos + dir): continue
		neighbors.append(pos + dir)

	return neighbors


func get_best_f_cost(cells: Array[Cell]) -> Cell:
	var best_cell = null
	var best_cost = INF

	for cell in cells:
		var f_cost: float = cell.f_cost
		if f_cost < best_cost:
			best_cell = cell
			best_cost = f_cost

	return best_cell

func get_neighboring_cells(cell: Cell) -> Array[Cell]:
	var neighbors: Array[Cell] = []

	for pos in get_neighbors(cell.pos):
		neighbors.append(Cell.new(cell.goal, pos, cell))

	return neighbors

func a_star(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open_cells: Array[Cell] = [Cell.new(goal, start, null)]
	var closed_positions: Dictionary = {}
	var current: Cell

	while not open_cells.is_empty():
		current = get_best_f_cost(open_cells)
		if current.pos == goal: # Reached the end
			return _reconstruct_path(current)
		
		open_cells.erase(current)
		closed_positions[current.pos] = true

		for neighbor: Cell in get_neighboring_cells(current):
			if closed_positions.has(neighbor.pos): continue

			var is_open: bool = false
			for cell in open_cells:
				if cell.pos == neighbor.pos:
					is_open = true
					# Here, we check if the same position is already occupied in the set, 
					# and if there exists a better path, use that one instead
					if neighbor.g_cost < cell.g_cost:
						open_cells.erase(cell)
						open_cells.append(neighbor)

			if not is_open:
				open_cells.append(neighbor)

	return []

func _reconstruct_path(cell: Cell) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: Cell = cell

	while current != null:
		path.append(current.pos)
		current = current.prev
	
	path.reverse()
	return path

func is_cell_valid(coords: Vector2i) -> bool:
	return tile_map.get_cell_atlas_coords(coords) == Vector2i.ZERO
