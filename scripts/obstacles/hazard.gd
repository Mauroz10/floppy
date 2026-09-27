extends Area2D
class_name Hazard

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is PlayerController:
		(body as PlayerController).kill()
