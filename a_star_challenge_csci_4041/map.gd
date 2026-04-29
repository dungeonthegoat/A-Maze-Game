class_name Map
extends TileMapLayer
## A class that handles tiles and pathfinding

@export_group("Config")
@export var resolution: Vector2i = Vector2i(36, 20)

var _neighbors: Dictionary[Vector2i, Array] = {}


func _ready():
	generate_maze(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_map"):
		generate_maze(randi())


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
func display_edges(edges: Array[Edge]) -> void:
	# 1. Clear the existing tile map and replace it with all walls
	clear()
	for x in range(-resolution.x / 2, resolution.x / 2):
		for y in range(-resolution.y / 2, resolution.y / 2):
			set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

	var offset: Vector2i = resolution / 2 - Vector2i.ONE

	# 2. Display the edges themselves
	for edge in edges:
		set_cell(edge.from.position * 2 - offset, 0, Vector2i.ZERO)
		set_cell(edge.to.position * 2 - offset, 0, Vector2i.ZERO)
		set_cell((edge.to.position + edge.from.position) - offset, 0, Vector2i.ZERO)


## Generates a procedural maze that is ready for pathfinding
func generate_maze(seed: int) -> void:
	# 1. Generate a grid graph of the desired resolution
	var grid_graph: GridGraph = GridGraph.new(resolution, seed)
	# 2. Display the edges and update the physical tile map
	display_edges(_prim(grid_graph.vertices, grid_graph.edges))
	# 3. Update the neighbors dictionary to prepare for pathfinding
	_init_neighbors()


func _prim(vertices: Array[Vertex], edges: Array[Edge]) -> Array[Edge]:
	# Initialize the cheapest cost and edge dictionaries
	var cheapest_cost: Dictionary[Vertex, float]
	var cheapest_edge: Dictionary[Vertex, Edge]
	for vertex in vertices:
		cheapest_cost[vertex] = INF
	
	var explored = []
	var unexplored = vertices.duplicate_deep()

	var start_vert = vertices[0]
	cheapest_cost[start_vert] = 0

	var current_vert: Vertex

	while not unexplored.is_empty():
		current_vert = _get_cheapest_cost_vertex(cheapest_cost, unexplored)
		unexplored.erase(current_vert)
		explored.append(current_vert)

		for edge in edges:
			# Only worry about relevant edges
			if edge.from != current_vert and edge.to != current_vert: continue
			var neighbor: Vertex = edge.from if edge.from != current_vert else edge.to

			if unexplored.has(neighbor) and edge.weight < cheapest_cost[neighbor]:
				cheapest_cost[neighbor] = edge.weight
				cheapest_edge[neighbor] = edge

	var result_edges: Array[Edge] = []
	for edge in cheapest_edge.values():
		result_edges.append(edge)

	return result_edges


func _get_cheapest_cost_vertex(costs: Dictionary[Vertex, float], unexplored: Array[Vertex]) -> Vertex:
	var cheapest_cost: float = INF
	var cheapest_vert: Vertex = null

	for vertex in unexplored:
		if costs[vertex] < cheapest_cost:
			cheapest_cost = costs[vertex]
			cheapest_vert = vertex
	
	return cheapest_vert


## Initializes the neighbors of every cell into a dictionary to allow for faster cell-neighbor lookup
func _init_neighbors():
	_neighbors.clear()

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

class GridGraph:
	var vertices: Array[Vertex]
	var edges: Array[Edge]

	func _init(resolution: Vector2i, seed: int) -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed
		# Since the lattice grid is spaced out, we space out the resolution
		# to account for this
		var scaled_resolution: Vector2i = (resolution - Vector2i.ONE) / 2
		# A dictionary to temporarily store the vertices for easy access when
		# creating edges
		var temp_verts: Dictionary[Vector2i, Vertex]

		for x in range(scaled_resolution.x):
			for y in range(scaled_resolution.y):
				temp_verts[Vector2i(x, y)] = Vertex.new(Vector2i(x, y))
				vertices.append(temp_verts[Vector2i(x, y)])
				if temp_verts.has(Vector2i(x - 1, y)):
					edges.append(Edge.new(temp_verts[Vector2i(x, y)], temp_verts[Vector2i(x - 1, y)], rng.randf()))
				if temp_verts.has(Vector2i(x, y - 1)):
					edges.append(Edge.new(temp_verts[Vector2i(x, y)], temp_verts[Vector2i(x, y - 1)], rng.randf()))

class Vertex:
	var position: Vector2i

	func _init(pos: Vector2i) -> void:
		position = pos

class Edge:
	var from: Vertex
	var to: Vertex
	var weight: float

	func _init(v1: Vertex, v2: Vertex, w: float) -> void:
		from = v1
		to = v2
		weight = w

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
