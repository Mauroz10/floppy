extends Camera2D
class_name CameraTracker

@export var target: Node2D
@export var vertical_lead: float = -220.0
@export var follow_speed: float = 7.0

func _process(delta: float) -> void:
	if target == null:
		return
	var desired := Vector2(0.0, target.global_position.y + vertical_lead)
	global_position.y = lerpf(global_position.y, desired.y, 1.0 - exp(-follow_speed * delta))
