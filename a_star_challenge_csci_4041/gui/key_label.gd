extends Label


func _ready():
    SignalBus.keys_updated.connect(_updated)


func _updated(keys: int, max_keys: int) -> void:
    text = "%d/%d" % [keys, max_keys]