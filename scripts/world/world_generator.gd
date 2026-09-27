extends Node2D
class_name WorldGenerator


# ============================================================
# TRAMOS DEL MUNDO 1 - JARDINES DE NIMBO
# ============================================================

const INTRO_END_METERS: float = 60.0
const EARLY_END_METERS: float = 120.0
const MID_END_METERS: float = 180.0
const HARD_END_METERS: float = 240.0
const WORLD_1_END_METERS: float = 300.0

const BREATHER_INTERVAL: int = 9


# ============================================================
# RECURSOS
# ============================================================

@export var balance: GameBalance
@export var player: PlayerController
@export var camera: Camera2D

@export var coin_scene: PackedScene
@export var bubble_scene: PackedScene
@export var full_balloon_scene: PackedScene

@export var hazard_block_scene: PackedScene
@export var spike_scene: PackedScene
@export var moving_block_scene: PackedScene
@export var drone_scene: PackedScene

@export var world_seed: int = 73129


# ============================================================
# ESTADO INTERNO
# ============================================================

var _start_y: float = 0.0

var _active_chunks: Dictionary = {}

var _safe_lane_by_row: Dictionary = {
	0: 2
}

var _max_safe_row: int = 0

var _rescue_balloon: Node2D

var _initialized: bool = false


# ============================================================
# INICIALIZACIÓN
# ============================================================

func _ready() -> void:
	if balance == null:
		balance = GameBalance.new()

	if player != null:
		initialize(
			player,
			camera
		)


func initialize(
	target_player: PlayerController,
	target_camera: Camera2D
) -> void:
	if _initialized:
		return

	player = target_player
	camera = target_camera

	_start_y = player.global_position.y

	var center_lane: int = int(
		balance.lane_count / 2
	)

	_safe_lane_by_row = {
		0: center_lane
	}

	_max_safe_row = 0

	player.fall_started.connect(
		_on_player_fall_started
	)

	player.recovered_while_falling.connect(
		_on_player_recovered
	)

	_generate_initial_chunks()

	_initialized = true


# ============================================================
# ACTUALIZACIÓN DEL MUNDO
# ============================================================

func _process(
	_delta: float
) -> void:
	if not _initialized:
		return

	if player == null:
		return

	var current_chunk: int = _chunk_index_for_y(
		player.global_position.y
	)

	_ensure_chunk_range(
		current_chunk
		- balance.chunks_below_player,

		current_chunk
		+ balance.chunks_above_player
	)

	_prune_chunks(
		current_chunk
		- balance.chunks_below_player
		- 1,

		current_chunk
		+ balance.chunks_above_player
		+ 1
	)


# ============================================================
# POSICIÓN SEGURA PARA REVIVE
# ============================================================

func get_safe_revive_position(
	near_y: float
) -> Vector2:
	var row: int = _nearest_row_for_y(
		near_y
	)

	var safe_lane: int = _safe_lane_for_row(
		row
	)

	return Vector2(
		_lane_x(safe_lane),
		_row_center_y(row)
	)


# ============================================================
# CHUNKS
# ============================================================

func _generate_initial_chunks() -> void:
	_ensure_chunk_range(
		-1,
		balance.chunks_above_player
	)


func _ensure_chunk_range(
	min_index: int,
	max_index: int
) -> void:
	for index in range(
		min_index,
		max_index + 1
	):
		if not _active_chunks.has(index):
			_active_chunks[index] = _build_chunk(
				index
			)


func _prune_chunks(
	min_keep: int,
	max_keep: int
) -> void:
	var to_remove: Array[int] = []

	for key in _active_chunks.keys():
		var index: int = int(key)

		if (
			index < min_keep
			or index > max_keep
		):
			to_remove.append(
				index
			)

	for index in to_remove:
		var chunk: Node = (
			_active_chunks[index]
			as Node
		)

		if is_instance_valid(chunk):
			chunk.queue_free()

		_active_chunks.erase(
			index
		)


func _build_chunk(
	index: int
) -> Node2D:
	var chunk: Node2D = Node2D.new()

	chunk.name = (
		"Chunk_%d"
		% index
	)

	chunk.position = Vector2(
		0.0,
		_start_y
		- float(index)
		* balance.chunk_height
	)

	add_child(
		chunk
	)

	var row_spacing: float = (
		balance.chunk_height
		/ float(
			balance.rows_per_chunk + 1
		)
	)

	for local_row in range(
		balance.rows_per_chunk
	):
		var global_row: int = (
			index
			* balance.rows_per_chunk
			+ local_row
		)

		var local_y: float = (
			-row_spacing
			* float(
				local_row + 1
			)
		)

		_populate_row(
			chunk,
			global_row,
			local_y
		)

	return chunk


# ============================================================
# CREACIÓN DE CADA FILA
# ============================================================

func _populate_row(
	chunk: Node2D,
	global_row: int,
	local_y: float
) -> void:
	if global_row < 0:
		return

	var safe_lane: int = _safe_lane_for_row(
		global_row
	)

	var world_y: float = (
		chunk.global_position.y
		+ local_y
	)

	var altitude_m: float = maxf(
		0.0,
		(
			_start_y
			- world_y
		)
		/ balance.pixels_per_meter
	)

	var rng: RandomNumberGenerator = (
		RandomNumberGenerator.new()
	)

	rng.seed = abs(
		world_seed
		+ global_row
		* 104729
	)

	var hazard_count: int = (
		_get_hazard_count(
			altitude_m,
			global_row,
			rng
		)
	)

	var hazard_lanes: Array[int] = (
		_choose_hazard_lanes(
			safe_lane,
			hazard_count,
			rng
		)
	)

	for lane in hazard_lanes:
		_spawn_hazard(
			chunk,
			lane,
			safe_lane,
			local_y,
			altitude_m,
			rng
		)

	_spawn_air_pickups(
		chunk,
		global_row,
		local_y,
		safe_lane,
		altitude_m,
		rng
	)

	_spawn_coin_pattern(
		chunk,
		global_row,
		local_y,
		safe_lane,
		altitude_m,
		rng
	)


# ============================================================
# DIFICULTAD SEGÚN LA ALTURA
# ============================================================

func _get_hazard_count(
	altitude_m: float,
	global_row: int,
	rng: RandomNumberGenerator
) -> int:

	# 0 - 20 m:
	# tutorial prácticamente libre.

	if altitude_m < 20.0:
		return 0


	# 20 - 60 m:
	# pocas amenazas.

	if altitude_m < INTRO_END_METERS:
		if rng.randf() < 0.25:
			return 1

		return 0


	# 60 - 120 m:
	# empieza realmente el juego.

	if altitude_m < EARLY_END_METERS:
		if rng.randf() < 0.72:
			return 1

		return 0


	# 120 - 180 m:
	# normalmente uno.
	# algunas filas tienen dos.

	if altitude_m < MID_END_METERS:
		if rng.randf() < 0.38:
			return mini(
				2,
				balance.max_hazards_per_row
			)

		return 1


	# 180 - 240 m:
	# más intensidad,
	# con pequeños descansos.

	if altitude_m < HARD_END_METERS:
		if (
			global_row > 0
			and global_row
			% BREATHER_INTERVAL
			== 0
		):
			return 0

		if rng.randf() < 0.68:
			return mini(
				2,
				balance.max_hazards_per_row
			)

		return 1


	# 240 - 300 m:
	# tramo más intenso del Mundo 1.

	if altitude_m <= WORLD_1_END_METERS:
		if (
			global_row > 0
			and global_row % 8 == 0
		):
			return 1

		if rng.randf() < 0.82:
			return mini(
				2,
				balance.max_hazards_per_row
			)

		return 1


	# Temporalmente mantenemos esta dificultad
	# hasta implementar el final real del Mundo 1.

	return mini(
		2,
		balance.max_hazards_per_row
	)


# ============================================================
# DISTRIBUCIÓN DE OBSTÁCULOS
# ============================================================

func _choose_hazard_lanes(
	safe_lane: int,
	hazard_count: int,
	rng: RandomNumberGenerator
) -> Array[int]:

	var result: Array[int] = []

	if hazard_count <= 0:
		return result


	var left_lanes: Array[int] = []
	var right_lanes: Array[int] = []


	for lane in range(
		balance.lane_count
	):
		if lane < safe_lane:
			left_lanes.append(
				lane
			)

		elif lane > safe_lane:
			right_lanes.append(
				lane
			)


	_shuffle_int_array(
		left_lanes,
		rng
	)

	_shuffle_int_array(
		right_lanes,
		rng
	)


	# Si tenemos dos obstáculos,
	# intentamos poner uno a cada lado.

	if (
		hazard_count >= 2
		and not left_lanes.is_empty()
		and not right_lanes.is_empty()
	):
		result.append(
			left_lanes[0]
		)

		result.append(
			right_lanes[0]
		)


	# Si tenemos uno,
	# alternamos aleatoriamente izquierda/derecha.

	elif hazard_count >= 1:
		var choose_left: bool = (
			rng.randf() < 0.5
		)

		if (
			choose_left
			and not left_lanes.is_empty()
		):
			result.append(
				left_lanes[0]
			)

		elif not right_lanes.is_empty():
			result.append(
				right_lanes[0]
			)

		elif not left_lanes.is_empty():
			result.append(
				left_lanes[0]
			)


	# Completamos si todavía faltan obstáculos.

	if result.size() < hazard_count:
		var remaining: Array[int] = []

		for lane in range(
			balance.lane_count
		):
			if lane == safe_lane:
				continue

			if lane in result:
				continue

			remaining.append(
				lane
			)

		_shuffle_int_array(
			remaining,
			rng
		)

		for lane in remaining:
			if result.size() >= hazard_count:
				break

			result.append(
				lane
			)


	return result


# ============================================================
# CREACIÓN DEL TIPO DE OBSTÁCULO
# ============================================================

func _spawn_hazard(
	chunk: Node2D,
	lane: int,
	safe_lane: int,
	local_y: float,
	altitude_m: float,
	rng: RandomNumberGenerator
) -> void:

	var chosen: PackedScene = hazard_block_scene

	var moving_chance: float = 0.0
	var drone_chance: float = 0.0
	var spike_chance: float = 0.30


	# ========================================================
	# BLOQUE MÓVIL VERTICAL
	# ========================================================

	# Empieza a aparecer después de 60 m.

	if altitude_m >= INTRO_END_METERS:
		if altitude_m < EARLY_END_METERS:
			moving_chance = 0.16

		elif altitude_m < MID_END_METERS:
			moving_chance = 0.22

		elif altitude_m < HARD_END_METERS:
			moving_chance = 0.28

		else:
			moving_chance = 0.32


	# ========================================================
	# DRONES HORIZONTALES
	# ========================================================

	if altitude_m >= balance.drone_start_height_meters:
		if altitude_m < MID_END_METERS:
			drone_chance = 0.18

		elif altitude_m < HARD_END_METERS:
			drone_chance = 0.26

		else:
			drone_chance = 0.32


	# ========================================================
	# PINCHOS
	# ========================================================

	if altitude_m >= HARD_END_METERS:
		spike_chance = 0.24

	elif altitude_m >= MID_END_METERS:
		spike_chance = 0.28


	# ========================================================
	# ELEGIR OBSTÁCULO
	# ========================================================

	var roll: float = rng.randf()


	if (
		moving_block_scene != null
		and roll < moving_chance
	):
		chosen = moving_block_scene

	elif (
		drone_scene != null
		and roll
		< moving_chance
		+ drone_chance
	):
		chosen = drone_scene

	elif (
		spike_scene != null
		and roll
		< moving_chance
		+ drone_chance
		+ spike_chance
	):
		chosen = spike_scene

	else:
		chosen = hazard_block_scene


	if chosen == null:
		return


	var instance: Node = _spawn_scene(
		chunk,
		chosen,
		Vector2(
			_lane_x(lane),
			local_y
		)
	)


	# ========================================================
	# CONFIGURAR OBSTÁCULOS MÓVILES
	# ========================================================

	if instance is PatrolHazard:
		var patrol: PatrolHazard = (
			instance as PatrolHazard
		)


		# ----------------------------------------------------
		# DRONES - MOVIMIENTO HORIZONTAL
		# ----------------------------------------------------

		if (
			patrol.movement_mode
			== PatrolHazard.MovementMode.HORIZONTAL
		):

			var lane_distance: int = abs(
				lane - safe_lane
			)


			# Si está junto al carril seguro,
			# reducimos cuánto puede invadirlo.

			if lane_distance <= 1:
				patrol.travel_distance = minf(
					patrol.travel_distance,
					72.0
				)

			else:
				patrol.travel_distance = minf(
					patrol.travel_distance + 20.0,
					140.0
				)


			# Velocidad progresiva.

			if altitude_m >= HARD_END_METERS:
				patrol.speed += 30.0

			elif altitude_m >= MID_END_METERS:
				patrol.speed += 18.0

			elif altitude_m >= EARLY_END_METERS:
				patrol.speed += 8.0


		# ----------------------------------------------------
		# BLOQUES - MOVIMIENTO VERTICAL
		# ----------------------------------------------------

		else:

			# 60 - 120 m

			if altitude_m < EARLY_END_METERS:
				patrol.travel_distance = minf(
					patrol.travel_distance,
					95.0
				)

				patrol.speed = minf(
					patrol.speed,
					78.0
				)


			# 120 - 180 m

			elif altitude_m < MID_END_METERS:
				patrol.travel_distance = minf(
					patrol.travel_distance,
					110.0
				)

				patrol.speed += 8.0


			# 180 - 240 m

			elif altitude_m < HARD_END_METERS:
				patrol.travel_distance = minf(
					patrol.travel_distance,
					125.0
				)

				patrol.speed += 14.0


			# 240 - 300 m

			else:
				patrol.travel_distance = minf(
					patrol.travel_distance + 15.0,
					140.0
				)

				patrol.speed += 24.0


# ============================================================
# AIRE Y GLOBOS
# ============================================================

func _spawn_air_pickups(
	chunk: Node2D,
	global_row: int,
	local_y: float,
	safe_lane: int,
	altitude_m: float,
	rng: RandomNumberGenerator
) -> void:

	# Burbuja aproximadamente cada 7 filas.

	if (
		global_row % 7 == 4
		and bubble_scene != null
	):
		var bubble_lane: int = safe_lane

		if altitude_m >= INTRO_END_METERS:
			bubble_lane = _pick_adjacent_lane(
				safe_lane,
				rng
			)

		_spawn_scene(
			chunk,
			bubble_scene,
			Vector2(
				_lane_x(
					bubble_lane
				),
				local_y - 62.0
			)
		)


	# Globo completo menos frecuente.

	if (
		global_row > 0
		and global_row % 22 == 13
		and full_balloon_scene != null
	):
		var balloon_lane: int = (
			_pick_adjacent_lane(
				safe_lane,
				rng
			)
		)

		_spawn_scene(
			chunk,
			full_balloon_scene,
			Vector2(
				_lane_x(
					balloon_lane
				),
				local_y - 84.0
			)
		)


# ============================================================
# MONEDAS
# ============================================================

func _spawn_coin_pattern(
	chunk: Node2D,
	global_row: int,
	local_y: float,
	safe_lane: int,
	altitude_m: float,
	rng: RandomNumberGenerator
) -> void:

	if coin_scene == null:
		return


	var reward_lane: int = safe_lane


	# 0 - 60 m:
	# monedas enseñan la ruta.

	if altitude_m < INTRO_END_METERS:
		reward_lane = safe_lane


	# 60 - 120 m:
	# empezamos a pedir pequeños movimientos.

	elif altitude_m < EARLY_END_METERS:
		reward_lane = _pick_adjacent_lane(
			safe_lane,
			rng
		)


	# 120 m en adelante:
	# algunas monedas requieren más riesgo.

	else:
		var risk_roll: float = rng.randf()

		if risk_roll < 0.42:
			reward_lane = _pick_far_lane(
				safe_lane,
				rng
			)

		else:
			reward_lane = _pick_adjacent_lane(
				safe_lane,
				rng
			)


	var x: float = _lane_x(
		reward_lane
	)

	var coin_count: int = 2

	if global_row % 3 == 0:
		coin_count = 3


	for i in range(
		coin_count
	):
		_spawn_scene(
			chunk,
			coin_scene,
			Vector2(
				x,
				local_y
				+ 62.0
				+ float(i)
				* 54.0
			)
		)


# ============================================================
# CREAR ESCENA
# ============================================================

func _spawn_scene(
	parent: Node,
	scene: PackedScene,
	local_position: Vector2
) -> Node:

	var instance: Node = (
		scene.instantiate()
	)

	parent.add_child(
		instance
	)

	if instance is Node2D:
		var node_2d: Node2D = (
			instance as Node2D
		)

		node_2d.position = local_position


	return instance


# ============================================================
# CAÍDA Y RESCATE
# ============================================================

func _on_player_fall_started() -> void:
	_spawn_rescue_balloon()


func _on_player_recovered() -> void:
	if is_instance_valid(
		_rescue_balloon
	):
		_rescue_balloon.queue_free()

	_rescue_balloon = null


func _spawn_rescue_balloon() -> void:
	if full_balloon_scene == null:
		return

	if player == null:
		return

	if is_instance_valid(
		_rescue_balloon
	):
		_rescue_balloon.queue_free()


	var rng: RandomNumberGenerator = (
		RandomNumberGenerator.new()
	)

	rng.seed = abs(
		world_seed
		+ int(
			GameManager.run_peak_height
			* 100.0
		)
		+ 991
	)


	var drop: float = rng.randf_range(
		balance.rescue_balloon_min_drop,
		balance.rescue_balloon_max_drop
	)

	var target_y: float = (
		player.global_position.y
		+ drop
	)

	var target_row: int = (
		_nearest_row_for_y(
			target_y
		)
	)

	var safe_lane: int = (
		_safe_lane_for_row(
			target_row
		)
	)


	var lane_shift: int = 1

	if player.global_position.x > 0.0:
		lane_shift = -1


	var rescue_lane: int = (
		_adjacent_lane(
			safe_lane,
			lane_shift
		)
	)


	var instance: Node = (
		full_balloon_scene.instantiate()
	)

	if not instance is Node2D:
		instance.queue_free()
		return


	_rescue_balloon = (
		instance as Node2D
	)

	add_child(
		_rescue_balloon
	)

	_rescue_balloon.global_position = Vector2(
		_lane_x(
			rescue_lane
		),
		target_y
	)


# ============================================================
# FILAS Y CHUNKS
# ============================================================

func _chunk_index_for_y(
	y: float
) -> int:

	return int(
		floor(
			(
				_start_y - y
			)
			/ balance.chunk_height
		)
	)


func _nearest_row_for_y(
	y: float
) -> int:

	var spacing: float = (
		balance.chunk_height
		/ float(
			balance.rows_per_chunk + 1
		)
	)

	return maxi(
		0,
		int(
			round(
				(
					_start_y - y
				)
				/ spacing
			)
		)
		- 1
	)


func _row_center_y(
	global_row: int
) -> float:

	var spacing: float = (
		balance.chunk_height
		/ float(
			balance.rows_per_chunk + 1
		)
	)

	return (
		_start_y
		- spacing
		* float(
			global_row + 1
		)
	)


# ============================================================
# RUTA SEGURA
# ============================================================

func _safe_lane_for_row(
	row: int
) -> int:

	var center_lane: int = int(
		balance.lane_count / 2
	)

	if row <= 0:
		return center_lane


	_ensure_safe_rows(
		row
	)


	return int(
		_safe_lane_by_row.get(
			row,
			center_lane
		)
	)


func _ensure_safe_rows(
	target_row: int
) -> void:

	if target_row <= _max_safe_row:
		return


	for row in range(
		_max_safe_row + 1,
		target_row + 1
	):
		var center_lane: int = int(
			balance.lane_count / 2
		)

		var previous: int = int(
			_safe_lane_by_row.get(
				row - 1,
				center_lane
			)
		)


		var rng: RandomNumberGenerator = (
			RandomNumberGenerator.new()
		)

		rng.seed = abs(
			world_seed * 17
			+ row * 8191
		)


		var lane: int = (
			_choose_next_safe_lane(
				row,
				previous,
				rng
			)
		)


		_safe_lane_by_row[row] = lane


	_max_safe_row = target_row


# ============================================================
# RUTA SEGURA EQUILIBRADA
# ============================================================

func _choose_next_safe_lane(
	row: int,
	previous: int,
	rng: RandomNumberGenerator
) -> int:

	var center_lane: int = int(
		balance.lane_count / 2
	)

	var last_lane: int = (
		balance.lane_count - 1
	)

	var choices: Array[int] = []


	for offset in range(
		-1,
		2
	):
		var candidate: int = (
			previous + offset
		)

		if (
			candidate >= 0
			and candidate <= last_lane
		):
			choices.append(
				candidate
			)


	var same_lane_streak: int = (
		_count_same_lane_streak(
			row - 1,
			previous
		)
	)


	# No dejamos que el camino seguro
	# permanezca demasiado tiempo igual.

	if (
		same_lane_streak >= 2
		and choices.size() > 1
	):
		choices.erase(
			previous
		)


	var previous_side: int = (
		_lane_side(
			previous
		)
	)

	var side_streak: int = (
		_count_side_streak(
			row - 1,
			previous_side
		)
	)


	# Si llevamos demasiado tiempo
	# en izquierda o derecha,
	# regresamos gradualmente al centro.

	if (
		previous_side != 0
		and side_streak >= 3
	):
		var inward_lane: int = previous

		if previous_side < 0:
			inward_lane += 1

		else:
			inward_lane -= 1


		if inward_lane in choices:
			return inward_lane


	# Evitamos permanecer demasiado
	# tiempo pegados a los extremos.

	if (
		previous == 0
		or previous == last_lane
	):
		if same_lane_streak >= 1:
			var inward_from_edge: int = previous

			if previous == 0:
				inward_from_edge = 1

			else:
				inward_from_edge = (
					last_lane - 1
				)


			if inward_from_edge in choices:
				return inward_from_edge


	# Pequeño sesgo hacia el centro.

	if (
		previous != center_lane
		and rng.randf() < 0.28
	):
		var center_direction: int = 1

		if previous > center_lane:
			center_direction = -1


		var toward_center: int = (
			previous
			+ center_direction
		)


		if toward_center in choices:
			return toward_center


	if choices.is_empty():
		return center_lane


	var choice_index: int = (
		rng.randi_range(
			0,
			choices.size() - 1
		)
	)

	return choices[
		choice_index
	]


func _count_same_lane_streak(
	last_row: int,
	lane: int
) -> int:

	var count: int = 0

	var center_lane: int = int(
		balance.lane_count / 2
	)


	for offset in range(4):
		var row: int = (
			last_row - offset
		)

		if row < 0:
			break


		var previous_lane: int = int(
			_safe_lane_by_row.get(
				row,
				center_lane
			)
		)

		if previous_lane != lane:
			break


		count += 1


	return count


func _count_side_streak(
	last_row: int,
	side: int
) -> int:

	if side == 0:
		return 0


	var count: int = 0

	var center_lane: int = int(
		balance.lane_count / 2
	)


	for offset in range(5):
		var row: int = (
			last_row - offset
		)

		if row < 0:
			break


		var lane: int = int(
			_safe_lane_by_row.get(
				row,
				center_lane
			)
		)

		if _lane_side(
			lane
		) != side:
			break


		count += 1


	return count


func _lane_side(
	lane: int
) -> int:

	var center_lane: int = int(
		balance.lane_count / 2
	)

	if lane < center_lane:
		return -1

	if lane > center_lane:
		return 1

	return 0


# ============================================================
# POSICIÓN DE LOS CARRILES
# ============================================================

func _lane_x(
	lane: int
) -> float:

	if balance.lane_count <= 1:
		return 0.0


	var usable_width: float = (
		balance.world_width
		- balance.lane_side_margin
		* 2.0
	)

	var lane_step: float = (
		usable_width
		/ float(
			balance.lane_count - 1
		)
	)


	return (
		-usable_width * 0.5
		+ float(lane)
		* lane_step
	)


# ============================================================
# RUTAS DE RECOMPENSA
# ============================================================

func _pick_adjacent_lane(
	lane: int,
	rng: RandomNumberGenerator
) -> int:

	var options: Array[int] = []


	if lane > 0:
		options.append(
			lane - 1
		)


	if lane < balance.lane_count - 1:
		options.append(
			lane + 1
		)


	if options.is_empty():
		return lane


	var index: int = rng.randi_range(
		0,
		options.size() - 1
	)


	return options[index]


func _pick_far_lane(
	safe_lane: int,
	rng: RandomNumberGenerator
) -> int:

	var far_lanes: Array[int] = []
	var other_lanes: Array[int] = []


	for lane in range(
		balance.lane_count
	):
		if lane == safe_lane:
			continue


		var distance: int = abs(
			lane - safe_lane
		)


		if distance >= 2:
			far_lanes.append(
				lane
			)

		else:
			other_lanes.append(
				lane
			)


	if not far_lanes.is_empty():
		var far_index: int = (
			rng.randi_range(
				0,
				far_lanes.size() - 1
			)
		)

		return far_lanes[
			far_index
		]


	if not other_lanes.is_empty():
		var other_index: int = (
			rng.randi_range(
				0,
				other_lanes.size() - 1
			)
		)

		return other_lanes[
			other_index
		]


	return safe_lane


# ============================================================
# UTILIDADES
# ============================================================

func _shuffle_int_array(
	values: Array[int],
	rng: RandomNumberGenerator
) -> void:

	for i in range(
		values.size() - 1,
		0,
		-1
	):
		var j: int = rng.randi_range(
			0,
			i
		)

		var temp: int = values[i]

		values[i] = values[j]

		values[j] = temp


func _adjacent_lane(
	lane: int,
	direction: int
) -> int:

	return clampi(
		lane + direction,
		0,
		balance.lane_count - 1
	)
