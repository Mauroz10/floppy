extends Area2D
class_name AirPickup

@export var restore_amount: float = 1.5
@export var full_refill: bool = false

var _consumed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _consumed or not (body is PlayerController):
		return
	var player := body as PlayerController
	var accepted := player.collect_full_balloon() if full_refill else player.consume_air_bubble(restore_amount)
	if not accepted:
		return
	_consumed = true
	queue_free()
