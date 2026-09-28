extends CanvasLayer
class_name BalloonHUD


@onready var altitude_label: Label = %AltitudeLabel
@onready var coins_label: Label = %CoinsLabel

@onready var air_bar: ProgressBar = %AirBar
@onready var air_label: Label = %AirLabel

@onready var low_air_label: Label = %LowAirLabel

@onready var fall_warning: PanelContainer = %FallWarning
@onready var fall_label: Label = %FallLabel

@onready var move_controls: Control = %MoveControls

@onready var left_move_button: Button = %LeftMoveButton
@onready var right_move_button: Button = %RightMoveButton

@onready var death_panel: Control = %DeathPanel

@onready var death_title: Label = %DeathTitle
@onready var death_stats: Label = %DeathStats

@onready var revive_button: Button = %ReviveButton
@onready var end_run_button: Button = %EndRunButton
@onready var retry_button: Button = %RetryButton

@onready var status_label: Label = %StatusLabel


const ZONE_1_TARGET_METERS: int = 300


var player: PlayerController


# ============================================================
# INICIO
# ============================================================

func _ready() -> void:

	death_panel.visible = false

	fall_warning.visible = false

	low_air_label.visible = false

	move_controls.visible = true


	GameManager.altitude_changed.connect(
		_on_altitude_changed
	)


	GameManager.coins_changed.connect(
		_on_coins_changed
	)


	GameManager.death_pending.connect(
		_on_death_pending
	)


	GameManager.revive_granted.connect(
		_on_revive_granted
	)


	GameManager.revive_ad_failed.connect(
		_on_revive_ad_failed
	)


	GameManager.run_finished.connect(
		_on_run_finished
	)


	GameManager.zone_completed.connect(
		_on_zone_completed
	)


	left_move_button.button_down.connect(
		_on_left_move_button_down
	)


	left_move_button.button_up.connect(
		_on_left_move_button_up
	)


	right_move_button.button_down.connect(
		_on_right_move_button_down
	)


	right_move_button.button_up.connect(
		_on_right_move_button_up
	)


	_on_altitude_changed(
		0.0
	)


	_on_coins_changed(
		0
	)


func _exit_tree() -> void:

	_release_movement_inputs()


# ============================================================
# CONECTAR PLAYER
# ============================================================

func bind_player(
	target: PlayerController
) -> void:

	player = target


	if not player.air.air_changed.is_connected(
		_on_air_changed
	):
		player.air.air_changed.connect(
			_on_air_changed
		)


	if not player.air.low_air_started.is_connected(
		_on_low_air_started
	):
		player.air.low_air_started.connect(
			_on_low_air_started
		)


	if not player.air.low_air_ended.is_connected(
		_on_low_air_ended
	):
		player.air.low_air_ended.connect(
			_on_low_air_ended
		)


	if not player.fall_started.is_connected(
		_on_fall_started
	):
		player.fall_started.connect(
			_on_fall_started
		)


	if not player.fall_ended.is_connected(
		_on_fall_ended
	):
		player.fall_ended.connect(
			_on_fall_ended
		)


	if not player.fall_time_changed.is_connected(
		_on_fall_time_changed
	):
		player.fall_time_changed.connect(
			_on_fall_time_changed
		)


	_on_air_changed(
		player.air.current_air,
		player.air.maximum_air
	)


# ============================================================
# CONTROLES MÓVILES
# ============================================================

func _on_left_move_button_down() -> void:

	Input.action_press(
		"move_left"
	)


func _on_left_move_button_up() -> void:

	Input.action_release(
		"move_left"
	)


func _on_right_move_button_down() -> void:

	Input.action_press(
		"move_right"
	)


func _on_right_move_button_up() -> void:

	Input.action_release(
		"move_right"
	)


func _release_movement_inputs() -> void:

	Input.action_release(
		"move_left"
	)


	Input.action_release(
		"move_right"
	)


# ============================================================
# ALTURA
# ============================================================

func _on_altitude_changed(
	altitude: float
) -> void:

	var meters: int = int(
		floor(
			altitude
		)
	)


	meters = mini(
		meters,
		ZONE_1_TARGET_METERS
	)


	altitude_label.text = (
		"ALTURA  %d / %d m"
		% [
			meters,
			ZONE_1_TARGET_METERS
		]
	)


# ============================================================
# MONEDAS
# ============================================================

func _on_coins_changed(
	coins: int
) -> void:

	coins_label.text = (
		"MONEDAS  %d"
		% coins
	)


# ============================================================
# AIRE
# ============================================================

func _on_air_changed(
	current: float,
	maximum: float
) -> void:

	var ratio: float = 0.0


	if maximum > 0.0:
		ratio = current / maximum


	ratio = clampf(
		ratio,
		0.0,
		1.0
	)


	air_bar.value = (
		ratio * 100.0
	)


	air_label.text = (
		"AIRE  %d%%"
		% int(
			round(
				ratio * 100.0
			)
		)
	)


func _on_low_air_started() -> void:

	if player != null:

		if player.is_falling():
			return


	low_air_label.visible = true


func _on_low_air_ended() -> void:

	low_air_label.visible = false


# ============================================================
# CAÍDA
# ============================================================

func _on_fall_started() -> void:

	fall_warning.visible = true

	low_air_label.visible = false


func _on_fall_ended() -> void:

	fall_warning.visible = false


func _on_fall_time_changed(
	time_remaining: float,
	_total_time: float
) -> void:

	fall_label.text = (
		"SIN AIRE - ENCUENTRA UN GLOBO!  %.1f s"
		% time_remaining
	)


# ============================================================
# MUERTE
# ============================================================

func _on_death_pending(
	_can_revive: bool
) -> void:

	_release_movement_inputs()


	move_controls.visible = false

	fall_warning.visible = false

	low_air_label.visible = false

	death_panel.visible = true


	death_title.text = (
		"MILO NECESITA UN RESCATE"
	)


	death_stats.text = (
		"Altura maxima: %d m\nMonedas: %d"
		% [
			int(
				floor(
					GameManager.run_peak_height
				)
			),
			GameManager.run_coins
		]
	)


	status_label.text = (
		"Un solo revive por partida"
	)


	revive_button.visible = true

	revive_button.disabled = false

	revive_button.text = (
		"VER VIDEO Y REVIVIR"
	)


	end_run_button.visible = true

	retry_button.visible = false


# ============================================================
# REVIVE
# ============================================================

func _on_revive_granted() -> void:

	_release_movement_inputs()


	death_panel.visible = false

	fall_warning.visible = false

	low_air_label.visible = false


	move_controls.visible = true


	status_label.text = ""


func _on_revive_ad_failed() -> void:

	revive_button.disabled = false


	revive_button.text = (
		"VIDEO NO DISPONIBLE"
	)


	status_label.text = (
		"Puedes terminar la partida o intentar otra vez."
	)


# ============================================================
# FIN NORMAL DE PARTIDA
# ============================================================

func _on_run_finished(
	final_peak: float,
	coins: int,
	best_height: float
) -> void:

	_release_movement_inputs()


	move_controls.visible = false

	fall_warning.visible = false

	low_air_label.visible = false

	death_panel.visible = true


	death_title.text = (
		"FIN DE PARTIDA"
	)


	death_stats.text = (
		"Altura maxima: %d m\n"
		+ "Monedas: %d\n"
		+ "Record: %d m"
	) % [
		int(
			floor(
				final_peak
			)
		),
		coins,
		int(
			floor(
				best_height
			)
		)
	]


	status_label.text = (
		"Las monedas ya fueron guardadas."
	)


	revive_button.visible = false

	end_run_button.visible = false

	retry_button.visible = true

	retry_button.text = (
		"REINTENTAR"
	)


# ============================================================
# JARDINES DE NIMBO COMPLETADO
# ============================================================

func _on_zone_completed(
	final_peak: float,
	coins: int,
	best_height: float
) -> void:

	_release_movement_inputs()


	move_controls.visible = false

	fall_warning.visible = false

	low_air_label.visible = false


	death_panel.visible = true


	death_title.text = (
		"¡JARDINES DE NIMBO COMPLETADO!"
	)


	death_stats.text = (
		"Altura alcanzada: %d m\n"
		+ "Monedas: %d\n"
		+ "Record: %d m"
	) % [
		int(
			floor(
				final_peak
			)
		),
		coins,
		int(
			floor(
				best_height
			)
		)
	]


	status_label.text = (
		"¡Mundo 1 superado! Tus monedas fueron guardadas."
	)


	revive_button.visible = false

	end_run_button.visible = false

	retry_button.visible = true


	retry_button.text = (
		"JUGAR DE NUEVO"
	)


# ============================================================
# BOTONES
# ============================================================

func _on_revive_pressed() -> void:

	revive_button.disabled = true


	revive_button.text = (
		"CARGANDO VIDEO..."
	)


	GameManager.request_rewarded_revive()


func _on_end_run_pressed() -> void:

	GameManager.decline_revive()


func _on_retry_pressed() -> void:

	GameManager.restart_run()
