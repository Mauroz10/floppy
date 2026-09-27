extends PlayerState
class_name InflatedState

func enter(previous_state: PlayerState) -> void:
	player.air.set_draining(true)
	player.set_balloon_visible(true)
	if previous_state is FallingState:
		player.end_fall_window()

func exit(_next_state: PlayerState) -> void:
	player.air.set_draining(false)

func physics_update(delta: float) -> void:
	player.update_horizontal_velocity(delta)
	player.velocity.y = -player.balance.rise_speed
	player.air.tick(delta)
	player.move_and_slide()
	player.constrain_to_world()
