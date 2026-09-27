extends PlayerState
class_name FallingState

func enter(_previous_state: PlayerState) -> void:
	player.air.set_draining(false)
	player.set_balloon_visible(false)
	player.begin_fall_window()

func exit(next_state: PlayerState) -> void:
	if not (next_state is DeadState):
		player.end_fall_window()

func physics_update(delta: float) -> void:
	player.update_horizontal_velocity(delta)
	player.velocity.y = minf(
		player.velocity.y + player.balance.gravity * delta,
		player.balance.max_fall_speed
	)
	player.move_and_slide()
	player.constrain_to_world()
	player.tick_fall_window(delta)
