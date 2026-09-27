extends Node
class_name AirComponent

signal air_changed(current: float, maximum: float)
signal air_depleted
signal low_air_started
signal low_air_ended

@export var maximum_air: float = 5.0
@export var drain_per_second: float = 1.0
@export_range(0.0, 1.0, 0.01) var low_air_ratio: float = 0.25

var current_air: float = 0.0
var draining: bool = false
var _was_low: bool = false

func _ready() -> void:
	current_air = maximum_air
	_emit_state()

func configure(max_air: float, drain_rate: float, low_ratio: float) -> void:
	maximum_air = maxf(0.1, max_air)
	drain_per_second = maxf(0.0, drain_rate)
	low_air_ratio = clampf(low_ratio, 0.0, 1.0)
	current_air = maximum_air
	_was_low = false
	_emit_state()

func set_draining(enabled: bool) -> void:
	draining = enabled

func tick(delta: float) -> void:
	if not draining or current_air <= 0.0:
		return
	set_air(current_air - drain_per_second * delta)

func add_air(amount: float) -> void:
	set_air(current_air + maxf(0.0, amount))

func refill() -> void:
	set_air(maximum_air)

func set_ratio(value: float) -> void:
	set_air(maximum_air * clampf(value, 0.0, 1.0))

func set_air(value: float) -> void:
	var previous := current_air
	current_air = clampf(value, 0.0, maximum_air)
	_emit_state()
	if previous > 0.0 and current_air <= 0.0:
		air_depleted.emit()

func ratio() -> float:
	return current_air / maximum_air if maximum_air > 0.0 else 0.0

func _emit_state() -> void:
	air_changed.emit(current_air, maximum_air)
	var is_low := ratio() <= low_air_ratio and current_air > 0.0
	if is_low and not _was_low:
		low_air_started.emit()
	elif not is_low and _was_low:
		low_air_ended.emit()
	_was_low = is_low
