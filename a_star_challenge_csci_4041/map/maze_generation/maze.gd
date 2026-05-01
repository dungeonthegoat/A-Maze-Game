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

	_vertices.clear()
	_edges.clear()
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

			if edge.weight < neighbor_vert.weight:
				neighbor_vert.weight = edge.weight
				cheapest_cost._shift_up(neighbor_vert.idx)
				cheapest_edge[neighbor] = edge

	var result_edges: Array[Edge] = []
	var used_edges: Dictionary[Edge, bool] = {}

	for edge: Edge in cheapest_edge.values():
		result_edges.append(edge)
		used_edges[edge] = true

	# Prim's algorithm is done here if the maze is perfect

	if not make_perfect:
		# After getting all of the edges, we want to add some extra edges
		# to ensure that there are loops so the player can outmaneuver the
		# enemy while being chased. These loops should have a minimum loop
		# distance of some integer to prevent tiny 3x3 loops.

		# The dictionary of every vertex and its adjacent vertices in the MAZE (different from adj_edges)
		var current_adj: Dictionary[Vector2i, Array] = {}
		for v in _vertices: current_adj[v] = []
		for edge in result_edges:
			current_adj[edge.from].append(edge.to)
			current_adj[edge.to].append(edge.from)
		
		var extra_edges: Array[Edge] = [] # Edges excluded from the MST
		for edge in _edges:
			if not used_edges.has(edge):
				extra_edges.append(edge)
		extra_edges.shuffle()

		var target_loop_count: int = maxi(1, _edges.size() * loop_count_scale)
		var loop_count: int = 0

		# Loop through every extraneous edge and try to find a loop larger than the minimum distance
		while loop_count < target_loop_count and not extra_edges.is_empty():
			# Select an edge to search on
			var curr_edge: Edge = extra_edges.pop_back()

			# Perform a breadth-first search from edge.from to edge.to
			var below_min_dist: bool = false
			var dist: int = 0
			var search: Array[Vector2i] = [curr_edge.from]
			var visited: Dictionary[Vector2i, bool] = {curr_edge.from: true}

			while not search.is_empty() and dist < min_loop_size:
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

			if not below_min_dist:
				loop_count += 1
				# Add the new edge to the result AND the adjacency dictionary
				result_edges.append(curr_edge)
				current_adj[curr_edge.from].append(curr_edge.to)
				current_adj[curr_edge.to].append(curr_edge.from)

	_maze = result_edges
	return result_edges


## Generates the lattice graph from the maze's resolution
func _generate_weighted_lattice() -> void:
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

			# Construct the edges to the top and left of the current vertex if possible
			if temp_verts.has(Vector2i(x - 1, y)):
				_edges.append(Edge.new(Vector2i(x, y), Vector2i(x - 1, y), randf()))
			if temp_verts.has(Vector2i(x, y - 1)):
				_edges.append(Edge.new(Vector2i(x, y), Vector2i(x, y - 1), randf()))


## Generates an image displaying the current maze
func _display_maze() -> void:
	var maze_image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	maze_image.fill(Color.BLACK)

	for edge in _maze:
		maze_image.set_pixelv(edge.from * 2 + Vector2i.ONE, Color.WHITE)
		maze_image.set_pixelv(edge.to * 2 + Vector2i.ONE, Color.WHITE)
		maze_image.set_pixelv((edge.to + edge.from) + Vector2i.ONE, Color.WHITE)
	
	preview = ImageTexture.create_from_image(maze_image)