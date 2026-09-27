extends Node
class_name PlayerState

var player: PlayerController
var state_machine: PlayerStateMachine

func setup(owner_player: PlayerController, machine: PlayerStateMachine) -> void:
	player = owner_player
	state_machine = machine

func enter(_previous_state: PlayerState) -> void:
	pass

func exit(_next_state: PlayerState) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
