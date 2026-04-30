class_name MinHeap
extends RefCounted


class Vert:
	var position: Vector2i
	var weight: float
	var idx: int

	func _init(pos, w, i = 0) -> void:
		position = pos
		weight = w
		idx = i


var heap: Array[Vert] = []
var map: Dictionary[Vector2i, Vert] = {}

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

func get_weight(position: Vector2i) -> float:
	return map[position].weight


func update_weight(pos: Vector2i, new_weight: float) -> void:
	var old: Vert = map[pos]
	if old and new_weight < old.weight:
		old.weight = new_weight
		_shift_up(old.idx)


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

func _higher_priority(l: Vert, r: Vert) -> bool:
	return l.weight < r.weight

func _swap(l: int, r: int) -> void:
	var temp = heap[l]
	heap[l] = heap[r]
	heap[r] = temp
	heap[l].idx = l
	heap[r].idx = r
