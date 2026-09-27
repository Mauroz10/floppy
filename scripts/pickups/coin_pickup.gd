extends Area2D
class_name CoinPickup

@export var amount: int = 1
var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _collected or not (body is PlayerController):
		return
	_collected = true
	(body as PlayerController).collect_coin(amount)
	queue_free()
