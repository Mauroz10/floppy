extends Node2D
class_name WorldGenerator

@export var balance: GameBalance
@export var player: PlayerController
@export var camera: Camera2D
@export var coin_scene: PackedScene
@export var bubble_scene: PackedScene
@export var full_balloon_scene: PackedScene
@export var hazard_block_scene: PackedScene
@export var spike_scene: PackedScene
@export var drone_scene: PackedScene
@export var world_seed: int = 73129

var _start_y: float = 0.0
var _active_chunks: Dictionary = {}
var _safe_lane_by_row: Dictionary = {0: 2}
var _max_safe_row: int = 0
var _rescue_balloon: Node2D
var _initialized: bool = false

func _ready() -> void:
	if balance == null:
		balance = GameBalance.new()
	if player != null:
		initialize(player, camera)

func initialize(target_player: PlayerController, target_camera: Camera2D) -> void:
	if _initialized:
		return
	player = target_player
	camera = target_camera
	_start_y = player.global_position.y
	_safe_lane_by_row = {0: int(balance.lane_count / 2)}
	_max_safe_row = 0
	player.fall_started.connect(_on_player_fall_started)
	player.recovered_while_falling.connect(_on_player_recovered)
	_generate_initial_chunks()
	_initialized = true

func _process(_delta: float) -> void:
	if not _initialized or player == null:
		return
	var current_chunk := _chunk_index_for_y(player.global_position.y)
	_ensure_chunk_range(
		current_chunk - balance.chunks_below_player,
		current_chunk + balance.chunks_above_player
	)
	_prune_chunks(
		current_chunk - balance.chunks_below_player - 1,
		current_chunk + balance.chunks_above_player + 1
	)

func get_safe_revive_position(near_y: float) -> Vector2:
	var row := _nearest_row_for_y(near_y)
	var safe_lane := _safe_lane_for_row(row)
	return Vector2(_lane_x(safe_lane), _row_center_y(row))

func _generate_initial_chunks() -> void:
	_ensure_chunk_range(-1, balance.chunks_above_player)

func _ensure_chunk_range(min_index: int, max_index: int) -> void:
	for index in range(min_index, max_index + 1):
		if not _active_chunks.has(index):
			_active_chunks[index] = _build_chunk(index)

func _prune_chunks(min_keep: int, max_keep: int) -> void:
	var to_remove: Array[int] = []
	for key in _active_chunks.keys():
		var index := int(key)
		if index < min_keep or index > max_keep:
			to_remove.append(index)
	for index in to_remove:
		var chunk := _active_chunks[index] as Node
		if is_instance_valid(chunk):
			chunk.queue_free()
		_active_chunks.erase(index)

func _build_chunk(index: int) -> Node2D:
	var chunk := Node2D.new()
	chunk.name = "Chunk_%d" % index
	chunk.position = Vector2(0.0, _start_y - float(index) * balance.chunk_height)
	add_child(chunk)
	var row_spacing := balance.chunk_height / float(balance.rows_per_chunk + 1)
	for local_row in range(balance.rows_per_chunk):
		var global_row := index * balance.rows_per_chunk + local_row
		var local_y := -row_spacing * float(local_row + 1)
		_populate_row(chunk, global_row, local_y)
	return chunk

func _populate_row(chunk: Node2D, global_row: int, local_y: float) -> void:
	if global_row < 0:
		return
	var safe_lane := _safe_lane_for_row(global_row)
	var altitude_m := maxf(0.0, (_start_y - (chunk.global_position.y + local_y)) / balance.pixels_per_meter)
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(world_seed + global_row * 104729)
	var hazard_count := 0 if altitude_m < 25.0 else 1
	if altitude_m >= 75.0 and rng.randf() > 0.45:
		hazard_count = mini(balance.max_hazards_per_row, 2)
	var candidate_lanes: Array[int] = []
	for lane in range(balance.lane_count):
		if lane != safe_lane:
			candidate_lanes.append(lane)
	_shuffle_int_array(candidate_lanes, rng)
	for i in range(mini(hazard_count, candidate_lanes.size())):
		var lane := candidate_lanes[i]
		_spawn_hazard(chunk, Vector2(_lane_x(lane), local_y), altitude_m, rng)

	if global_row % 6 == 4 and bubble_scene != null:
		var bubble_lane := _adjacent_lane(safe_lane, 1 if rng.randf() > 0.5 else -1)
		_spawn_scene(chunk, bubble_scene, Vector2(_lane_x(bubble_lane), local_y - 62.0))

	if global_row > 0 and global_row % 13 == 7 and full_balloon_scene != null:
		var balloon_lane := _adjacent_lane(safe_lane, 1 if rng.randf() > 0.5 else -1)
		_spawn_scene(chunk, full_balloon_scene, Vector2(_lane_x(balloon_lane), local_y - 84.0))

	_spawn_coin_pattern(chunk, global_row, local_y, safe_lane, rng)

func _spawn_hazard(chunk: Node2D, local_position: Vector2, altitude_m: float, rng: RandomNumberGenerator) -> void:
	var chosen: PackedScene = hazard_block_scene
	var roll := rng.randf()
	if altitude_m >= balance.drone_start_height_meters and drone_scene != null and roll > 0.72:
		chosen = drone_scene
	elif spike_scene != null and roll > 0.38:
		chosen = spike_scene
	if chosen != null:
		_spawn_scene(chunk, chosen, local_position)

func _spawn_coin_pattern(chunk: Node2D, global_row: int, local_y: float, safe_lane: int, rng: RandomNumberGenerator) -> void:
	if coin_scene == null:
		return
	var reward_lane := _adjacent_lane(safe_lane, 1 if rng.randf() > 0.5 else -1)
	if reward_lane == safe_lane:
		reward_lane = safe_lane
	var x := _lane_x(reward_lane)
	var coin_count := 3 if global_row % 3 == 0 else 2
	for i in range(coin_count):
		_spawn_scene(chunk, coin_scene, Vector2(x, local_y + 62.0 + float(i) * 54.0))

func _spawn_scene(parent: Node, scene: PackedScene, local_position: Vector2) -> Node:
	var instance := scene.instantiate()
	parent.add_child(instance)
	if instance is Node2D:
		(instance as Node2D).position = local_position
	return instance

func _on_player_fall_started() -> void:
	_spawn_rescue_balloon()

func _on_player_recovered() -> void:
	if is_instance_valid(_rescue_balloon):
		_rescue_balloon.queue_free()
	_rescue_balloon = null

func _spawn_rescue_balloon() -> void:
	if full_balloon_scene == null or player == null:
		return
	if is_instance_valid(_rescue_balloon):
		_rescue_balloon.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(world_seed + int(GameManager.run_peak_height * 100.0) + 991)
	var drop := rng.randf_range(balance.rescue_balloon_min_drop, balance.rescue_balloon_max_drop)
	var target_y := player.global_position.y + drop
	var target_row := _nearest_row_for_y(target_y)
	var safe_lane := _safe_lane_for_row(target_row)
	var lane_shift := -1 if player.global_position.x > 0.0 else 1
	var rescue_lane := _adjacent_lane(safe_lane, lane_shift)
	_rescue_balloon = full_balloon_scene.instantiate() as Node2D
	add_child(_rescue_balloon)
	_rescue_balloon.global_position = Vector2(_lane_x(rescue_lane), target_y)

func _chunk_index_for_y(y: float) -> int:
	return int(floor((_start_y - y) / balance.chunk_height))

func _nearest_row_for_y(y: float) -> int:
	var spacing := balance.chunk_height / float(balance.rows_per_chunk + 1)
	return maxi(0, int(round((_start_y - y) / spacing)) - 1)

func _row_center_y(global_row: int) -> float:
	var spacing := balance.chunk_height / float(balance.rows_per_chunk + 1)
	return _start_y - spacing * float(global_row + 1)

func _safe_lane_for_row(row: int) -> int:
	if row <= 0:
		return int(balance.lane_count / 2)
	_ensure_safe_rows(row)
	return int(_safe_lane_by_row.get(row, int(balance.lane_count / 2)))

func _ensure_safe_rows(target_row: int) -> void:
	if target_row <= _max_safe_row:
		return
	for row in range(_max_safe_row + 1, target_row + 1):
		var previous := int(_safe_lane_by_row.get(row - 1, int(balance.lane_count / 2)))
		var rng := RandomNumberGenerator.new()
		rng.seed = abs(world_seed * 17 + row * 8191)
		var step := rng.randi_range(-1, 1)
		var lane := clampi(previous + step, 0, balance.lane_count - 1)
		_safe_lane_by_row[row] = lane
	_max_safe_row = target_row

func _lane_x(lane: int) -> float:
	if balance.lane_count <= 1:
		return 0.0
	var usable_width := balance.world_width - balance.lane_side_margin * 2.0
	var step := usable_width / float(balance.lane_count - 1)
	return -usable_width * 0.5 + float(lane) * step

func _shuffle_int_array(values: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := values[i]
		values[i] = values[j]
		values[j] = temp

func _adjacent_lane(lane: int, direction: int) -> int:
	return clampi(lane + direction, 0, balance.lane_count - 1)
