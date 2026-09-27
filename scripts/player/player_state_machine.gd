extends Node
class_name PlayerStateMachine

signal state_changed(previous_name: StringName, current_name: StringName)

@export var initial_state: PlayerState
var current_state: PlayerState
var player: PlayerController

func initialize(owner_player: PlayerController) -> void:
	player = owner_player
	for child in get_children():
		if child is PlayerState:
			(child as PlayerState).setup(player, self)
	if initial_state == null:
		push_error("PlayerStateMachine requires an initial_state.")
		return
	change_state(initial_state)

func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

func change_state(next_state: PlayerState) -> void:
	if next_state == null or next_state == current_state:
		return
	var previous := current_state
	if previous != null:
		previous.exit(next_state)
	current_state = next_state
	current_state.enter(previous)
	state_changed.emit(
		previous.name if previous != null else &"None",
		current_state.name
	)

func change_state_by_name(state_name: StringName) -> void:
	var node := get_node_or_null(NodePath(String(state_name)))
	if node is PlayerState:
		change_state(node as PlayerState)
	else:
		push_warning("Unknown player state: %s" % state_name)
