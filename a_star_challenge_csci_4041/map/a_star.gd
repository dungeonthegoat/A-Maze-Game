class_name AStar
extends RefCounted


## Returns an array dictating the path of cells to take to get from start to goal
static func pathfind(start: Vector2i, goal: Vector2i, map: Map, greediness: float = 1.0) -> Array[Vector2i]:
	var open_cells: CellHeap = CellHeap.new().insert(Cell.new(start, 0, absi(start.x - goal.x) + absi(start.y - goal.y), null))
	var closed_positions: Dictionary = {}
	var current: Cell

	while not open_cells.is_empty():
		current = open_cells.pop()

		if current.pos == goal: # Reached the end
			return _reconstruct_path(current)
		
		closed_positions[current.pos] = true

		for neighbor_pos: Vector2i in map.neighbor_map[current.pos]:
			if closed_positions.has(neighbor_pos): continue

			var g: float = current.g_cost + 1
			var h: float = (absf(neighbor_pos.x - goal.x) + absf(neighbor_pos.y - goal.y)) * greediness

			# Check if there already exists the neighbor in the open cells
			var existing_cell: Cell = open_cells.map.get(neighbor_pos)

			if existing_cell:
				if g < existing_cell.g_cost:
					existing_cell.g_cost = g
					existing_cell.f_cost = g + h
					existing_cell.prev = current
					open_cells._shift_up(existing_cell.heap_idx)
			else:
				open_cells.insert(Cell.new(neighbor_pos, g, h, current))

	return []


## Returns the path from the start of a pathfind to the given cell
static func _reconstruct_path(cell: Cell) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: Cell = cell

	while current != null:
		path.append(current.pos)
		current = current.prev
	
	path.reverse()
	return path


class Cell:
	var prev: Cell
	var pos: Vector2i
	var heap_idx: int

	var f_cost: float
	var h_cost: float
	var g_cost: float

	func _init(new_pos: Vector2i, g: float, h: float, prev_cell: Cell) -> void:
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
	

	func _shift_up(idx: int) -> void:
		while idx > 0:
			var parent_i: int = (idx - 1) / 2
			
			var curr_f: int = heap[idx].f_cost
			var curr_h: int = heap[idx].h_cost
			var par_f: int = heap[parent_i].f_cost
			var par_h: int = heap[parent_i].h_cost
			
			if curr_f < par_f or (curr_f == par_f and curr_h < par_h):
				var temp: Cell = heap[idx]
				heap[idx] = heap[parent_i]
				heap[parent_i] = temp
				heap[idx].heap_idx = idx
				heap[parent_i].heap_idx = parent_i
				idx = parent_i
			else: 
				return
	
	func _shift_down(idx: int) -> void:
		var size: int = heap.size()

		while true:
			var smallest: int = idx
			var left: int = 2 * idx + 1
			var right: int = left + 1
			
			var s_f: int = heap[smallest].f_cost
			var s_h: int = heap[smallest].h_cost

			if left < size:
				var l_f: int = heap[left].f_cost
				if l_f < s_f or (l_f == s_f and heap[left].h_cost < s_h): # If f_costs are the same, compare h_costs
					# If the left child exists and is smaller, mark it as the smallest node
					smallest = left
					s_f = l_f
					s_h = heap[left].h_cost

			if right < size:
				var r_f: int = heap[right].f_cost
				if r_f < s_f or (r_f == s_f and heap[right].h_cost < s_h): # If f_costs are the same, compare h_costs
					# If the right child exists and is smaller, mark it as the smallest node
					smallest = right

			# If there was a smaller node, swap with it. Otherwise, you are done
			if smallest != idx:
				var temp: Cell = heap[smallest]
				heap[smallest] = heap[idx]
				heap[idx] = temp
				heap[smallest].heap_idx = smallest
				heap[idx].heap_idx = idx
				idx = smallest
			else: 
				return
