extends Hazard
class_name PatrolHazard

@export var travel_distance: float = 150.0
@export var speed: float = 95.0

var _origin_x: float
var _phase: float = 0.0

func _ready() -> void:
	super._ready()
	_origin_x = position.x
	_phase = randf() * TAU

func _physics_process(delta: float) -> void:
	_phase += delta * speed / maxf(1.0, travel_distance)
	position.x = _origin_x + sin(_phase) * travel_distance
