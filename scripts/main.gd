extends Node2D


@onready var player: PlayerController = $Player

@onready var camera: CameraTracker = $Camera2D

@onready var world_generator: WorldGenerator = $WorldGenerator

@onready var hud: BalloonHUD = $HUD


var _pending_revive_position: Vector2


# ============================================================
# INICIO
# ============================================================

func _ready() -> void:

	camera.target = player


	world_generator.initialize(
		player,
		camera
	)


	hud.bind_player(
		player
	)


	player.died.connect(
		_on_player_died
	)


	GameManager.revive_granted.connect(
		_on_revive_granted
	)


	GameManager.zone_completed.connect(
		_on_zone_completed
	)


# ============================================================
# MUERTE
# ============================================================

func _on_player_died() -> void:

	_pending_revive_position = (
		world_generator.get_safe_revive_position(
			player.global_position.y
		)
	)


	GameManager.notify_player_died()


# ============================================================
# REVIVE
# ============================================================

func _on_revive_granted() -> void:

	player.revive_at(
		_pending_revive_position
	)


# ============================================================
# JARDINES DE NIMBO COMPLETADO
# ============================================================

func _on_zone_completed(
	_final_peak_height: float,
	_coins_earned: int,
	_best_height: float
) -> void:

	player.complete_zone()


	world_generator.set_process(
		false
	)
