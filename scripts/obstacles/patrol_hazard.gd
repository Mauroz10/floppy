extends Hazard
class_name PatrolHazard


enum MovementMode {
	HORIZONTAL,
	VERTICAL
}


# ============================================================
# CONFIGURACIÓN
# ============================================================

@export_category("Movement")

# HORIZONTAL = izquierda / derecha
# VERTICAL   = arriba / abajo
@export var movement_mode: MovementMode = MovementMode.HORIZONTAL


# Distancia máxima desde el punto inicial.
#
# Ejemplo:
# travel_distance = 150
#
# puede viajar:
#
# -150 <---- ORIGEN ----> +150
@export var travel_distance: float = 150.0


# Velocidad en píxeles por segundo.
@export var speed: float = 95.0


# Pequeña pausa al llegar a cada extremo.
@export var pause_at_edge: float = 0.15


# Permite que algunos enemigos comiencen
# moviéndose en dirección contraria.
@export var random_start_direction: bool = true


# ============================================================
# ESTADO INTERNO
# ============================================================

var _origin: Vector2 = Vector2.ZERO

var _direction: float = 1.0

var _pause_remaining: float = 0.0


func _ready() -> void:
	super._ready()

	_origin = position

	if random_start_direction:
		if randf() < 0.5:
			_direction = -1.0
		else:
			_direction = 1.0


func _physics_process(delta: float) -> void:
	if travel_distance <= 0.0:
		return

	if speed <= 0.0:
		return

	if _pause_remaining > 0.0:
		_pause_remaining = maxf(
			0.0,
			_pause_remaining - delta
		)

		return

	var axis: Vector2 = _get_movement_axis()

	position += (
		axis
		* speed
		* _direction
		* delta
	)

	var offset: float = (
		position - _origin
	).dot(axis)

	if absf(offset) >= travel_distance:
		offset = clampf(
			offset,
			-travel_distance,
			travel_distance
		)

		position = (
			_origin
			+ axis * offset
		)

		_direction *= -1.0

		_pause_remaining = maxf(
			0.0,
			pause_at_edge
		)


func _get_movement_axis() -> Vector2:
	match movement_mode:
		MovementMode.VERTICAL:
			return Vector2.DOWN

		MovementMode.HORIZONTAL:
			return Vector2.RIGHT

	return Vector2.RIGHT
