extends Resource
class_name GameBalance

@export_category("Horizontal Movement")
@export var horizontal_speed: float = 340.0
@export var horizontal_acceleration: float = 1500.0
@export var horizontal_deceleration: float = 1250.0
@export var horizontal_margin: float = 58.0

@export_category("Inflated Movement")
@export var rise_speed: float = 270.0
@export var max_air: float = 5.0
@export var air_drain_per_second: float = 1.0
@export_range(0.0, 1.0, 0.01) var low_air_threshold: float = 0.25

@export_category("Falling")
@export var gravity: float = 1180.0
@export var max_fall_speed: float = 760.0
@export var fall_rescue_window: float = 3.5
@export var rescue_balloon_min_drop: float = 560.0
@export var rescue_balloon_max_drop: float = 820.0

@export_category("Revive")
@export var revive_air_ratio: float = 1.0
@export var revive_invulnerability_seconds: float = 2.0

@export_category("World")
@export var pixels_per_meter: float = 12.0
@export var world_width: float = 1080.0
@export var chunk_height: float = 540.0
@export var chunks_above_player: int = 7
@export var chunks_below_player: int = 4
@export var lane_count: int = 5
@export var lane_side_margin: float = 120.0
@export var rows_per_chunk: int = 3

@export_category("Zone 1 Difficulty")
@export var drone_start_height_meters: float = 90.0
@export var max_hazards_per_row: int = 2
@export var bubble_restore_seconds: float = 1.5
