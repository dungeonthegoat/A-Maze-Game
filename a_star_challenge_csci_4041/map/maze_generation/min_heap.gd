class_name MinHeap
extends RefCounted
## A class representing a min heap that stores Verts and prioritizes the smallest weight

var heap: Array[Vert] = []
var map: Dictionary[Vector2i, Vert] = {}


## Returns whether or not a min heap is empty
func is_empty() -> bool:
	return heap.is_empty()


## Inserts a cell at the very end of the array and shifts it up into place
func insert(cell: Vert) -> MinHeap:
	heap.append(cell)
	cell.idx = heap.size() - 1
	map[cell.position] = cell
	_shift_up(cell.idx)
	return self


## Removes the top cell of the array and readjusts the rest of the heap
func pop() -> Vert:
	if heap.is_empty(): return null
	var root: Vert = heap[0]
	map.erase(root.position)

	# The last cell is removed and then replaces where the first cell was
	# so that the heap does not blow up
	var last: Vert = heap.pop_back()
	if not heap.is_empty():
		heap[0] = last
		last.idx = 0
		_shift_down(0)
	
	return root


## Shifts a Vert from a specific index up the heap
func _shift_up(idx: int) -> void:
    # Repeatedly swap with parent if the parent is a higher weight
	while idx > 0:
		var parent_i: int = (idx - 1) / 2
		if heap[idx].weight < heap[parent_i].weight:
			var temp: Vert = heap[idx]
			heap[idx] = heap[parent_i]
			heap[parent_i] = temp
			heap[idx].idx = idx
			heap[parent_i].idx = parent_i

			idx = parent_i
		else:
			return


## Shifts a Vert from a specific index down the heap
func _shift_down(idx: int) -> void:
	var size: int = heap.size()
	
    # Repeatedly swap the current Vert its smaller child
	while true:
		var smallest: int = idx
		var smallest_weight: float = heap[idx].weight

		var left: int = 2 * idx + 1
		var right: int = 2 * idx + 2

		if left < size and heap[left].weight < smallest_weight:
			smallest = left
			smallest_weight = heap[left].weight
		
		if right < size and heap[right].weight < smallest_weight:
			smallest = right
			smallest_weight = heap[right].weight

        # If one of the children are smaller than the current vertex, swap the two
		if smallest != idx:
			var temp: Vert = heap[smallest]
			heap[smallest] = heap[idx]
			heap[idx] = temp
			heap[smallest].idx = smallest
			heap[idx].idx = idx

			idx = smallest
		else:
			return


class Vert:
    ## A class that represents a vertex to be stored in a MinHeap
	var position: Vector2i
	var weight: float
	var idx: int

	func _init(pos: Vector2i, w: float, i: int = 0) -> void:
		position = pos
		weight = w
		idx = i