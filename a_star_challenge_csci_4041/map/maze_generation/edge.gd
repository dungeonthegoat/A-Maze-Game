class_name Edge
extends RefCounted

var from: Vector2i
var to: Vector2i
var weight: float

func _init(v1: Vector2i, v2: Vector2i, w: float) -> void:
    from = v1
    to = v2
    weight = w