extends CharacterBody2D
class_name PlayerController

signal died
signal fall_started
signal fall_ended
signal fall_time_changed(time_remaining: float, total_time: float)
signal recovered_while_falling
signal coin_collected(amount: int)
signal invulnerability_changed(active: bool)

@export var balance: GameBalance

@onready var air: AirComponent = $AirComponent
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var balloon_visual: Node2D = $BalloonVisual
@onready var body_visual: CanvasItem = $BodyVisual

var _touch_direction: float = 0.0
var _spawn_y: float = 0.0
var _dead: bool = false
var _fall_time_remaining: float = 0.0
var _invulnerability_remaining: float = 0.0

func _ready() -> void:
	if balance == null:
		balance = GameBalance.new()
	_spawn_y = global_position.y
	air.configure(balance.max_air, balance.air_drain_per_second, balance.low_air_threshold)
	air.air_depleted.connect(_on_air_depleted)
	state_machine.initialize(self)
	GameManager.start_run()

func _physics_process(delta: float) -> void:
	_update_invulnerability(delta)
	state_machine.physics_update(delta)
	_update_altitude()

func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_touch_direction = _direction_from_screen_x(touch.position.x) if touch.pressed else 0.0
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touch_direction = _direction_from_screen_x(drag.position.x)

func update_horizontal_velocity(delta: float) -> void:
	var keyboard_direction := Input.get_axis("move_left", "move_right")
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard_direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard_direction += 1.0
	keyboard_direction = clampf(keyboard_direction, -1.0, 1.0)
	var desired_direction := keyboard_direction if absf(keyboard_direction) > 0.01 else _touch_direction
	var target_velocity := desired_direction * balance.horizontal_speed
	var rate := balance.horizontal_acceleration if absf(desired_direction) > 0.01 else balance.horizontal_deceleration
	velocity.x = move_toward(velocity.x, target_velocity, rate * delta)

func constrain_to_world() -> void:
	var half_width := balance.world_width * 0.5
	var min_x := -half_width + balance.horizontal_margin
	var max_x := half_width - balance.horizontal_margin
	global_position.x = clampf(global_position.x, min_x, max_x)

func consume_air_bubble(amount: float) -> bool:
	if _dead or is_falling() or air.current_air >= air.maximum_air - 0.01:
		return false
	air.add_air(amount)
	return true

func collect_full_balloon() -> bool:
	if _dead:
		return false
	var was_falling := is_falling()
	if not was_falling and air.current_air >= air.maximum_air - 0.01:
		return false
	air.refill()
	if was_falling:
		state_machine.change_state_by_name(&"Inflated")
		recovered_while_falling.emit()
	return true

func collect_coin(amount: int = 1) -> void:
	if _dead:
		return
	GameManager.add_coin(amount)
	coin_collected.emit(amount)

func kill() -> void:
	if _dead or is_invulnerable():
		return
	_dead = true
	state_machine.change_state_by_name(&"Dead")
	died.emit()

func revive_at(world_position: Vector2) -> void:
	global_position = world_position
	velocity = Vector2.ZERO
	_dead = false
	_touch_direction = 0.0
	air.set_ratio(balance.revive_air_ratio)
	set_physics_process(true)
	_start_invulnerability(balance.revive_invulnerability_seconds)
	state_machine.change_state_by_name(&"Inflated")
	_update_altitude()

func set_balloon_visible(value: bool) -> void:
	balloon_visual.visible = value

func begin_fall_window() -> void:
	_fall_time_remaining = balance.fall_rescue_window
	fall_started.emit()
	fall_time_changed.emit(_fall_time_remaining, balance.fall_rescue_window)

func tick_fall_window(delta: float) -> void:
	if _dead:
		return
	_fall_time_remaining = maxf(0.0, _fall_time_remaining - delta)
	fall_time_changed.emit(_fall_time_remaining, balance.fall_rescue_window)
	if _fall_time_remaining <= 0.0:
		kill()

func end_fall_window() -> void:
	if _fall_time_remaining > 0.0:
		_fall_time_remaining = 0.0
		fall_ended.emit()

func is_falling() -> bool:
	return state_machine.current_state is FallingState

func is_dead() -> bool:
	return _dead

func is_invulnerable() -> bool:
	return _invulnerability_remaining > 0.0

func _on_air_depleted() -> void:
	if not _dead:
		state_machine.change_state_by_name(&"Falling")

func _update_altitude() -> void:
	var climbed_pixels := _spawn_y - global_position.y
	var meters := maxf(0.0, climbed_pixels / maxf(1.0, balance.pixels_per_meter))
	GameManager.update_altitude(meters)

func _direction_from_screen_x(screen_x: float) -> float:
	var viewport_width := get_viewport_rect().size.x
	return -1.0 if screen_x < viewport_width * 0.5 else 1.0

func _start_invulnerability(seconds: float) -> void:
	_invulnerability_remaining = maxf(0.0, seconds)
	body_visual.modulate.a = 0.55 if _invulnerability_remaining > 0.0 else 1.0
	invulnerability_changed.emit(_invulnerability_remaining > 0.0)

func _update_invulnerability(delta: float) -> void:
	if _invulnerability_remaining <= 0.0:
		return
	_invulnerability_remaining = maxf(0.0, _invulnerability_remaining - delta)
	if _invulnerability_remaining <= 0.0:
		body_visual.modulate.a = 1.0
		invulnerability_changed.emit(false)
