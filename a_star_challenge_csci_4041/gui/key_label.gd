extends Label


var curr_keys: int = 0


func _ready() -> void:
	SignalBus.keys_updated.connect(_updated)


func _updated(keys: int, max_keys: int) -> void:
	text = "%d/%d" % [keys, max_keys]

	if keys > curr_keys:
		$KeyAnimation.play("collect")

	curr_keys = keys