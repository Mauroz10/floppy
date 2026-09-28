extends CharacterBody2D
class_name PlayerController


signal died

signal fall_started

signal fall_ended

signal fall_time_changed(
	time_remaining: float,
	total_time: float
)

signal recovered_while_falling

signal coin_collected(
	amount: int
)

signal invulnerability_changed(
	active: bool
)


@export var balance: GameBalance


@onready var air: AirComponent = $AirComponent

@onready var state_machine: PlayerStateMachine = $StateMachine

@onready var balloon_visual: Node2D = $BalloonVisual

@onready var body_visual: CanvasItem = $BodyVisual


var _touch_direction: float = 0.0

var _spawn_y: float = 0.0

var _dead: bool = false

var _zone_completed: bool = false

var _fall_time_remaining: float = 0.0

var _invulnerability_remaining: float = 0.0


# ============================================================
# INICIO
# ============================================================

func _ready() -> void:

	if balance == null:
		balance = GameBalance.new()


	_spawn_y = global_position.y


	air.configure(
		balance.max_air,
		balance.air_drain_per_second,
		balance.low_air_threshold
	)


	air.air_depleted.connect(
		_on_air_depleted
	)


	state_machine.initialize(
		self
	)


	GameManager.start_run()


# ============================================================
# FÍSICA
# ============================================================

func _physics_process(
	delta: float
) -> void:

	if _zone_completed:
		return


	_update_invulnerability(
		delta
	)


	state_machine.physics_update(
		delta
	)


	_update_altitude()


# ============================================================
# CONTROLES TÁCTILES
# ============================================================

func _unhandled_input(
	event: InputEvent
) -> void:

	if _dead:
		return


	if _zone_completed:
		return


	if event is InputEventScreenTouch:

		var touch: InputEventScreenTouch = (
			event as InputEventScreenTouch
		)


		if touch.pressed:

			_touch_direction = (
				_direction_from_screen_x(
					touch.position.x
				)
			)

		else:

			_touch_direction = 0.0


	elif event is InputEventScreenDrag:

		var drag: InputEventScreenDrag = (
			event as InputEventScreenDrag
		)


		_touch_direction = (
			_direction_from_screen_x(
				drag.position.x
			)
		)


# ============================================================
# MOVIMIENTO HORIZONTAL
# ============================================================

func update_horizontal_velocity(
	delta: float
) -> void:

	if _zone_completed:

		velocity.x = 0.0

		return


	var keyboard_direction: float = (
		Input.get_axis(
			"move_left",
			"move_right"
		)
	)


	if (
		Input.is_key_pressed(KEY_A)
		or Input.is_key_pressed(KEY_LEFT)
	):

		keyboard_direction -= 1.0


	if (
		Input.is_key_pressed(KEY_D)
		or Input.is_key_pressed(KEY_RIGHT)
	):

		keyboard_direction += 1.0


	keyboard_direction = clampf(
		keyboard_direction,
		-1.0,
		1.0
	)


	var desired_direction: float = (
		keyboard_direction
		if absf(keyboard_direction) > 0.01
		else _touch_direction
	)


	var target_velocity: float = (
		desired_direction
		* balance.horizontal_speed
	)


	var rate: float = (
		balance.horizontal_acceleration
		if absf(desired_direction) > 0.01
		else balance.horizontal_deceleration
	)


	velocity.x = move_toward(
		velocity.x,
		target_velocity,
		rate * delta
	)


# ============================================================
# LÍMITES DEL MUNDO
# ============================================================

func constrain_to_world() -> void:

	var half_width: float = (
		balance.world_width
		* 0.5
	)


	var min_x: float = (
		-half_width
		+ balance.horizontal_margin
	)


	var max_x: float = (
		half_width
		- balance.horizontal_margin
	)


	global_position.x = clampf(
		global_position.x,
		min_x,
		max_x
	)


# ============================================================
# BURBUJA DE AIRE
# ============================================================

func consume_air_bubble(
	amount: float
) -> bool:

	if _dead:
		return false


	if _zone_completed:
		return false


	if is_falling():
		return false


	if (
		air.current_air
		>= air.maximum_air - 0.01
	):
		return false


	air.add_air(
		amount
	)


	return true


# ============================================================
# GLOBO COMPLETO
# ============================================================

func collect_full_balloon() -> bool:

	if _dead:
		return false


	if _zone_completed:
		return false


	var was_falling: bool = (
		is_falling()
	)


	if (
		not was_falling
		and air.current_air
		>= air.maximum_air - 0.01
	):

		return false


	air.refill()


	if was_falling:

		state_machine.change_state_by_name(
			&"Inflated"
		)


		recovered_while_falling.emit()


	return true


# ============================================================
# MONEDAS
# ============================================================

func collect_coin(
	amount: int = 1
) -> void:

	if _dead:
		return


	if _zone_completed:
		return


	GameManager.add_coin(
		amount
	)


	coin_collected.emit(
		amount
	)


# ============================================================
# MUERTE
# ============================================================

func kill() -> void:

	if _dead:
		return


	if _zone_completed:
		return


	if is_invulnerable():
		return


	_dead = true


	state_machine.change_state_by_name(
		&"Dead"
	)


	died.emit()


# ============================================================
# REVIVIR
# ============================================================

func revive_at(
	world_position: Vector2
) -> void:

	global_position = world_position


	velocity = Vector2.ZERO


	_dead = false

	_zone_completed = false

	_touch_direction = 0.0


	air.set_ratio(
		balance.revive_air_ratio
	)


	set_physics_process(
		true
	)


	set_process_unhandled_input(
		true
	)


	_start_invulnerability(
		balance.revive_invulnerability_seconds
	)


	state_machine.change_state_by_name(
		&"Inflated"
	)


	_update_altitude()


# ============================================================
# COMPLETAR JARDINES DE NIMBO
# ============================================================

func complete_zone() -> void:

	if _zone_completed:
		return


	_zone_completed = true


	_touch_direction = 0.0


	velocity = Vector2.ZERO


	air.set_draining(
		false
	)


	set_physics_process(
		false
	)


	set_process_unhandled_input(
		false
	)


# ============================================================
# VISUAL DEL GLOBO
# ============================================================

func set_balloon_visible(
	value: bool
) -> void:

	balloon_visual.visible = value


# ============================================================
# CAÍDA
# ============================================================

func begin_fall_window() -> void:

	_fall_time_remaining = (
		balance.fall_rescue_window
	)


	fall_started.emit()


	fall_time_changed.emit(
		_fall_time_remaining,
		balance.fall_rescue_window
	)


func tick_fall_window(
	delta: float
) -> void:

	if _dead:
		return


	if _zone_completed:
		return


	_fall_time_remaining = maxf(
		0.0,
		_fall_time_remaining - delta
	)


	fall_time_changed.emit(
		_fall_time_remaining,
		balance.fall_rescue_window
	)


	if _fall_time_remaining <= 0.0:

		kill()


func end_fall_window() -> void:

	if _fall_time_remaining > 0.0:

		_fall_time_remaining = 0.0


		fall_ended.emit()


# ============================================================
# ESTADOS
# ============================================================

func is_falling() -> bool:

	return (
		state_machine.current_state
		is FallingState
	)


func is_dead() -> bool:

	return _dead


func is_invulnerable() -> bool:

	return (
		_invulnerability_remaining > 0.0
	)


func is_zone_completed() -> bool:

	return _zone_completed


# ============================================================
# SIN AIRE
# ============================================================

func _on_air_depleted() -> void:

	if _dead:
		return


	if _zone_completed:
		return


	state_machine.change_state_by_name(
		&"Falling"
	)


# ============================================================
# ALTURA
# ============================================================

func _update_altitude() -> void:

	var climbed_pixels: float = (
		_spawn_y
		- global_position.y
	)


	var meters: float = maxf(
		0.0,
		climbed_pixels
		/ maxf(
			1.0,
			balance.pixels_per_meter
		)
	)


	GameManager.update_altitude(
		meters
	)


# ============================================================
# DIRECCIÓN SEGÚN PANTALLA
# ============================================================

func _direction_from_screen_x(
	screen_x: float
) -> float:

	var viewport_width: float = (
		get_viewport_rect().size.x
	)


	if screen_x < viewport_width * 0.5:

		return -1.0


	return 1.0


# ============================================================
# INVULNERABILIDAD
# ============================================================

func _start_invulnerability(
	seconds: float
) -> void:

	_invulnerability_remaining = maxf(
		0.0,
		seconds
	)


	if _invulnerability_remaining > 0.0:

		body_visual.modulate.a = 0.55

	else:

		body_visual.modulate.a = 1.0


	invulnerability_changed.emit(
		_invulnerability_remaining > 0.0
	)


func _update_invulnerability(
	delta: float
) -> void:

	if _invulnerability_remaining <= 0.0:
		return


	_invulnerability_remaining = maxf(
		0.0,
		_invulnerability_remaining - delta
	)


	if _invulnerability_remaining <= 0.0:

		body_visual.modulate.a = 1.0


		invulnerability_changed.emit(
			false
		)
