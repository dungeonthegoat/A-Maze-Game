class_name Grid
extends RefCounted


## Finds the minimum spanning tree of a GridGraph using Prim's algorithm and
## returns the tree as an array of edges
static func find_minimum_spanning_edges(vertices: Array[Vector2i], edges: Array[Edge], make_perfect: bool = false) -> Array[Edge]:
	# Initialize the cheapest cost and edge dictionaries
	var cheapest_cost: MinHeap = MinHeap.new()
	var cheapest_edge: Dictionary[Vector2i, Edge]

	var explored: Dictionary[Vector2i, bool] = {}

	# Store all of the adjacent edges
	var adj_edges: Dictionary[Vector2i, Array] = {}

	for vertex in vertices:
		cheapest_cost.insert(MinHeap.Vert.new(vertex, INF))
		adj_edges[vertex] = []
		explored[vertex] = false
	
	for edge in edges:
		adj_edges[edge.from].append(edge)
		adj_edges[edge.to].append(edge)

	var start_vert: Vector2i = vertices.pick_random()
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

	if not make_perfect:
		# After getting all of the edges, we want to add some extra edges
		# to ensure that there are loops so the player can outmaneuver the
		# enemy while being chased
		var extra_edges: Array[Edge] = []

		for edge in edges:
			if not used_edges.has(edge):
				extra_edges.append(edge)

		var num_loops: int = maxi(1, edges.size() / 20)
		extra_edges.shuffle()
		for i in range(num_loops):
			if extra_edges.is_empty(): break
			result_edges.append(extra_edges.pop_back())

	return result_edges


# static func _get_cheapest_cost_vertex(costs: Dictionary[Vector2i, float], unexplored: Array[Vector2i]) -> Vector2i:
# 	var cheapest_cost: float = INF
# 	var cheapest_vert: Vector2i

# 	for vertex in unexplored:
# 		if costs[vertex] < cheapest_cost:
# 			cheapest_cost = costs[vertex]
# 			cheapest_vert = vertex
	
# 	return cheapest_vert


class GridGraph:
	var vertices: Array[Vector2i]
	var edges: Array[Edge]

	func _init(resolution: Vector2i, seed: int) -> void:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed
		# Since the lattice grid is spaced out, we space out the resolution
		# to account for this
		var scaled_resolution: Vector2i = (resolution - Vector2i.ONE) / 2
		# A dictionary to temporarily store the vertices for easy access when
		# creating edges
		var temp_verts: Dictionary[Vector2i, bool]

		for x in range(scaled_resolution.x):
			for y in range(scaled_resolution.y):
				temp_verts[Vector2i(x, y)] = true
				vertices.append(Vector2i(x, y))

				# Construct the edges to the top and left of the current vertex if possible
				if temp_verts.has(Vector2i(x - 1, y)):
					edges.append(Edge.new(Vector2i(x, y), Vector2i(x - 1, y), rng.randf()))
				if temp_verts.has(Vector2i(x, y - 1)):
					edges.append(Edge.new(Vector2i(x, y), Vector2i(x, y - 1), rng.randf()))
