class_name Map
extends TileMapLayer
## A class that handles tiles and pathfinding

@export_group("Config")
@export var resolution: Vector2i = Vector2i(36, 20)

var _neighbors: Dictionary[Vector2i, Array] = {}


func _ready():
	_init_neighbors()

	display_tree(GridTree.new(Vector2i.ZERO, [GridTree.new(Vector2i(2, 0), [])]))


## Returns an array dictating the path of cells to take to get from start to goal
func pathfind(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open_cells: CellHeap = CellHeap.new().insert(Cell.new(start, 0, absi(start.x - goal.x) + absi(start.y - goal.y), null))
	var closed_positions: Dictionary = {}
	var current: Cell

	while not open_cells.is_empty():
		current = open_cells.pop()

		if current.pos == goal: # Reached the end
			return _reconstruct_path(current)
		
		closed_positions[current.pos] = true

		for neighbor_pos: Vector2i in _neighbors[current.pos]:
			if closed_positions.has(neighbor_pos): continue

			var g: int = current.g_cost + 1
			var h: int = absi(neighbor_pos.x - goal.x) + absi(neighbor_pos.y - goal.y)
			var neighbor_cell = Cell.new(neighbor_pos, g, h, current)

			if open_cells.map.has(neighbor_pos):
				open_cells.update_cell(neighbor_cell)
			else:
				open_cells.insert(neighbor_cell)

	return []


## Checks whether a given cell is valid to traverse on
func is_cell_valid(coords: Vector2i) -> bool:
	return get_cell_atlas_coords(coords) == Vector2i.ZERO


## Updates the tile map to display a given grid graph
func display_tree(tree: GridTree) -> void:
	clear()
	for x in range(-resolution.x / 2, resolution.x / 2):
		for y in range(-resolution.y / 2, resolution.y / 2):
			set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

	_display_sub_tree(tree)


func _display_sub_tree(tree: GridTree) -> void:
	set_cell(tree.position, 0, Vector2i.ZERO)

	for other in tree.trees:
		set_cell((tree.position + other.position) / 2, 0, Vector2i.ZERO)
		_display_sub_tree(other)



## Initializes the neighbors of every cell into a dictionary to allow for faster cell-neighbor lookup
func _init_neighbors():
	for pos in get_used_cells():
		_neighbors[pos] = []
		var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

		for dir in dirs:
			if not is_cell_valid(pos + dir): continue
			_neighbors[pos].append(pos + dir)


## Returns the path from the start of a pathfind to the given cell
func _reconstruct_path(cell: Cell) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: Cell = cell

	while current != null:
		path.append(current.pos)
		current = current.prev
	
	path.reverse()
	return path

class GridTree:
	var position: Vector2i
	var trees: Array[GridTree]

	func _init(pos: Vector2i, new_trees: Array[GridTree]) -> void:
		position = pos
		trees = new_trees

class GridGraph:
	var vertices: Array[Vertex]
	var edges: Array[Edge]

class Vertex:
	var position: Vector2i

class Edge:
	var from: Vertex
	var to: Vertex
	var weight: float

class Cell:
	var prev: Cell
	var pos: Vector2i
	var heap_idx: int

	var f_cost: int
	var h_cost: int
	var g_cost: int

	func _init(new_pos: Vector2i, g: int, h: int, prev_cell: Cell) -> void:
		pos = new_pos
		prev = prev_cell

		g_cost = g
		h_cost = h
		f_cost = g + h

class CellHeap:
	var heap: Array[Cell] = []
	var map: Dictionary[Vector2i, Cell] = {}

	func is_empty() -> bool:
		return heap.is_empty()

	## Inserts a cell at the very end of the array and shifts it up into place
	func insert(cell: Cell) -> CellHeap:
		heap.append(cell)
		cell.heap_idx = heap.size() - 1
		map[cell.pos] = cell
		_shift_up(cell.heap_idx)
		return self
	
	## Removes the top cell of the array and readjusts the rest of the heap
	func pop() -> Cell:
		if heap.is_empty(): return null
		var root: Cell = heap[0]
		map.erase(root.pos)

		# The last cell is removed and then replaces where the first cell was
		# so that the heap does not blow up
		var last: Cell = heap.pop_back()
		if not heap.is_empty():
			heap[0] = last
			last.heap_idx = 0
			_shift_down(0)
		
		return root

	## Attempts to replace a cell in the heap with another cell (at the same 
	## position) with a better g_cost
	func update_cell(new: Cell) -> void:
		var old: Cell = map[new.pos]
		if old and new.g_cost < old.g_cost:
			old.g_cost = new.g_cost
			old.f_cost = new.f_cost
			old.prev = new.prev
			# Since the new cell is guaranteed to have a higher f_cost,
			# you only have to worry about shifting it up
			_shift_up(old.heap_idx)

	func _shift_up(idx: int) -> void:
		while idx > 0:
			var parent_i: int = _get_parent(idx)
			if _higher_priority(heap[idx], heap[parent_i]):
				_swap(idx, parent_i)
				idx = parent_i
			else: return
			
	func _shift_down(idx: int) -> void:
		var smallest: int = idx
		var size = heap.size()

		while true:
			var left: int = _get_left_child(idx)
			var right: int = _get_right_child(idx)

			if left < size and _higher_priority(heap[left], heap[smallest]): smallest = left
			if right < size and _higher_priority(heap[right], heap[smallest]): smallest = right

			if smallest != idx:
				_swap(smallest, idx)
				idx = smallest
			else: return

	func _get_parent(idx: int) -> int:
		return floori((idx - 1) / 2.0)

	func _get_left_child(idx: int) -> int:
		return 2 * idx + 1
	
	func _get_right_child(idx: int) -> int:
		return 2 * idx + 2
	
	func _higher_priority(l: Cell, r: Cell) -> bool:
		if l.f_cost == r.f_cost:
			return l.h_cost < r.h_cost
		return l.f_cost < r.f_cost

	func _swap(l: int, r: int) -> void:
		var temp = heap[l]
		heap[l] = heap[r]
		heap[r] = temp
		heap[l].heap_idx = l
		heap[r].heap_idx = r
