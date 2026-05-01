@tool
class_name Maze
extends Resource

## The smallest size a maze can be generated at in either dimension
const MIN_SIZE: int = 5


## A preview of the maze
@export var preview: ImageTexture

@export_tool_button("Generate") var _generate_maze: Callable = generate_maze

@export_group("Config")

## The size of the maze to be generated (minimum 5x5)
@export var size: Vector2i = Vector2i(16, 16)

## Whether or not the maze generated should be "perfect" (i.e., no loops)
@export var make_perfect: bool = false

## The minimum length a loop can be in an imperfect maze
## (Only applies to imperfect mazes)
@export_range(0, 30, 1.0, "or_greater", "suffix:tiles") var min_loop_size: int = 10

## The number of loops relative to how many edges there are in an imperfect maze
## (Only applies to imperfect mazes)
@export_range(0, 1, 0.05, "suffix:loops/edge") var loop_count_scale: float = 0.1


var _vertices: Array[Vector2i]
var _edges: Array[Edge]
## A list of edges making up the generated maze
var _maze: Array[Edge]


## Generates the maze from its parameters and returns the result
func generate_maze() -> Array[Edge]:
	if size.x < MIN_SIZE or size.y < MIN_SIZE:
		push_warning("Cannot generate maze; both size dimensions must be at least %d" % MIN_SIZE)
		return []
	
	_maze.clear()

	_generate_weighted_lattice()
	find_minimum_spanning_edges()
	if Engine.is_editor_hint():
		_display_maze()
	return _maze


## Finds the minimum spanning tree of a GridGraph using Prim's algorithm and
## returns the tree as an array of edges
func find_minimum_spanning_edges() -> Array[Edge]:
	# Initialize the cheapest cost and edge dictionaries
	var cheapest_cost: MinHeap = MinHeap.new()
	var cheapest_edge: Dictionary[Vector2i, Edge] = {}

	# A dictionary of every vertex that has been explored
	var explored: Dictionary[Vector2i, bool] = {}

	# The dictionary containing a vertex and all of its connected edges
	var adj_edges: Dictionary[Vector2i, Array] = {}

	# Each vertex should be initialized as:
		# 1. A cost of ∞
		# 2. No adjacent edges
		# 3. Unexplored
	for vertex in _vertices:
		cheapest_cost.insert(MinHeap.Vert.new(vertex, INF))
		adj_edges[vertex] = []
		explored[vertex] = false
	
	# Store the adjecent edges for each vertex of the grid
	for edge in _edges:
		adj_edges[edge.from].append(edge)
		adj_edges[edge.to].append(edge)

	# Pick the starting vertex (either randomly or a specific index like [0])
	var start_vert: Vector2i = _vertices.pick_random()
	# var start_vert: Vector2i = vertices[0]
	cheapest_cost.insert(MinHeap.Vert.new(start_vert, 0))

	var current_vert: Vector2i

	while not cheapest_cost.is_empty():
		# Set the current vertex to the cheapest one
		current_vert = cheapest_cost.pop().position
		explored[current_vert] = true

		for edge: Edge in adj_edges[current_vert]:
			var neighbor: Vector2i = edge.from if edge.from != current_vert else edge.to
			if explored[neighbor]: continue

			var neighbor_vert: MinHeap.Vert = cheapest_cost.map[neighbor]

			# If the current edge is cheaper than the neighbor vertex,
			# set the current edge as its cheapest edge
			if edge.weight < neighbor_vert.weight:
				neighbor_vert.weight = edge.weight
				cheapest_cost._shift_up(neighbor_vert.idx)
				cheapest_edge[neighbor] = edge

	_maze = []

	## A dictionary respresenting if an edge was used in the maze
	## (allows for construction of the array of unused edges in
	## O(N) time)
	var used_edges: Dictionary[Edge, bool] = {}

	for edge: Edge in cheapest_edge.values():
		_maze.append(edge)
		used_edges[edge] = true

	# Prim's algorithm is done here if generating a perfect maze

	if not make_perfect:
		_add_loops(used_edges)
	
	return _maze


## Adds loops to the current perfect maze based on config parameters
func _add_loops(used_edges: Dictionary[Edge, bool]) -> void:
	# Build a dictionary of every vertex and its adjacent vertices in the 
	# maze (different from adj_edges)
	var current_adj: Dictionary[Vector2i, Array] = {}
	for v in _vertices: current_adj[v] = []
	for edge in _maze: # Only make connections between vertices that are edges in the perfect maze
		current_adj[edge.from].append(edge.to)
		current_adj[edge.to].append(edge.from)
	
	# Build a list of the edges that did NOT make it into the maze using the
	# used_edges dictionary we made earlier
	var extra_edges: Array[Edge] = []
	for edge in _edges:
		if not used_edges.has(edge):
			extra_edges.append(edge)
	extra_edges.shuffle()

	var target_loop_count: int = maxi(1, _edges.size() * loop_count_scale)
	var loop_count: int = 0

	# Loop through every unused edge and try to find a loop larger than the
	# minimum loop distance using a breadth-first search
	while loop_count < target_loop_count and not extra_edges.is_empty():
		# Select a random edge to search on (extra_edges is shuffled)
		var curr_edge: Edge = extra_edges.pop_back()

		# Perform a breadth-first search from the chosen edge.from to edge.to
		var below_min_dist: bool = false
		var dist: int = 0
		var search: Array[Vector2i] = [curr_edge.from]
		var visited: Dictionary[Vector2i, bool] = {curr_edge.from: true}

		# Breadth-first search
		while not search.is_empty() and dist < min_loop_size:
			# Every next iteration should search through all of the current
			# iteration's neighbors
			var next_search: Array[Vector2i] = []
			for node in search:
				# If any path is too short, then adding an edge will make
				# a loop too short, so you have to end the search early
				if node == curr_edge.to:
					below_min_dist = true
					break

				# Otherwise, add all of the neighbors (that haven't been
				# searched) to be searched in the next pass
				for neighbor: Vector2i in current_adj[node]:
					if not visited.has(neighbor):
						visited[neighbor] = true
						next_search.append(neighbor)

			search = next_search
			dist += 1

		# If no loop was found that's shorter than the minimum distance, we
		# are free to add that edge to the final maze
		if not below_min_dist:
			loop_count += 1
			# Add the new edge to the result AND the adjacency dictionary
			_maze.append(curr_edge)
			current_adj[curr_edge.from].append(curr_edge.to)
			current_adj[curr_edge.to].append(curr_edge.from)


## Generates the weighted lattice graph
func _generate_weighted_lattice() -> void:
	# Clear everything in the graph before generating
	_vertices.clear()
	_edges.clear()

	# Since the lattice grid is spaced out, we space out the resolution
	# to account for this
	var scaled_resolution: Vector2i = (size - Vector2i.ONE) / 2

	# A dictionary to temporarily store the vertices for easy access when
	# creating edges
	var temp_verts: Dictionary[Vector2i, bool]

	for x in range(scaled_resolution.x):
		for y in range(scaled_resolution.y):
			temp_verts[Vector2i(x, y)] = true
			_vertices.append(Vector2i(x, y))

			# Because we move from top left to bottom right, we construct the
			# edges to the vertices to the left and top of the current vertex
			# if one exists
			if temp_verts.has(Vector2i(x - 1, y)): # Left edge
				_edges.append(Edge.new(Vector2i(x, y), Vector2i(x - 1, y), randf()))
			if temp_verts.has(Vector2i(x, y - 1)): # Top edge
				_edges.append(Edge.new(Vector2i(x, y), Vector2i(x, y - 1), randf()))


## Generates a preview image of the maze in the inspector
func _display_maze() -> void:
	var maze_image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	maze_image.fill(Color.BLACK)

	for edge in _maze:
		maze_image.set_pixelv(edge.from * 2 + Vector2i.ONE, Color.WHITE)
		maze_image.set_pixelv(edge.to * 2 + Vector2i.ONE, Color.WHITE)
		maze_image.set_pixelv((edge.to + edge.from) + Vector2i.ONE, Color.WHITE)
	
	preview = ImageTexture.create_from_image(maze_image)