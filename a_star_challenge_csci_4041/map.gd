class_name Map
extends TileMapLayer

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

	func insert(cell: Cell) -> CellHeap:
		heap.append(cell)
		cell.heap_idx = heap.size() - 1
		map[cell.pos] = cell
		_shift_up(cell.heap_idx)
		return self
	
	func pop() -> Cell:
		if heap.is_empty(): return null
		var root: Cell = heap[0]
		map.erase(root.pos)

		var last: Cell = heap.pop_back()
		if not heap.is_empty():
			heap[0] = last
			last.heap_idx = 0
			_shift_down(0)
		
		return root

	func update_cell(new: Cell) -> void:
		var old: Cell = map[new.pos]
		if old and new.g_cost < old.g_cost:
			old.g_cost = new.g_cost
			old.f_cost = new.f_cost
			old.prev = new.prev
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
		return (idx - 1) / 2

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


var neighbors: Dictionary[Vector2i, Array] = {}

func _ready():
	_init_neighbors()

func _init_neighbors():
	for pos in get_used_cells():
		neighbors[pos] = []
		var dirs: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

		for dir in dirs:
			if not is_cell_valid(pos + dir): continue
			neighbors[pos].append(pos + dir)

func pathfind(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open_cells: CellHeap = CellHeap.new().insert(Cell.new(start, 0, absi(start.x - goal.x) + absi(start.y - goal.y), null))
	var closed_positions: Dictionary = {}
	var current: Cell

	while not open_cells.is_empty():
		current = open_cells.pop()

		if current.pos == goal: # Reached the end
			return _reconstruct_path(current)
		
		closed_positions[current.pos] = true

		for neighbor_pos: Vector2i in neighbors[current.pos]:
			if closed_positions.has(neighbor_pos): continue

			var g: int = current.g_cost + 1
			var h: int = absi(neighbor_pos.x - goal.x) + absi(neighbor_pos.y - goal.y)
			var neighbor_cell = Cell.new(neighbor_pos, g, h, current)

			if open_cells.map.has(neighbor_pos):
				open_cells.update_cell(neighbor_cell)
			else:
				open_cells.insert(neighbor_cell)

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
	return get_cell_atlas_coords(coords) == Vector2i.ZERO
