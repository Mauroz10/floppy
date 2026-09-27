extends PlayerState
class_name DeadState

func enter(previous_state: PlayerState) -> void:
	player.air.set_draining(false)
	if previous_state is FallingState:
		player.end_fall_window()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
