extends Node2D

@onready var player: PlayerController = $Player
@onready var camera: CameraTracker = $Camera2D
@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var hud: BalloonHUD = $HUD

var _pending_revive_position: Vector2

func _ready() -> void:
	camera.target = player
	world_generator.initialize(player, camera)
	hud.bind_player(player)
	player.died.connect(_on_player_died)
	GameManager.revive_granted.connect(_on_revive_granted)

func _on_player_died() -> void:
	_pending_revive_position = world_generator.get_safe_revive_position(player.global_position.y)
	GameManager.notify_player_died()

func _on_revive_granted() -> void:
	player.revive_at(_pending_revive_position)
