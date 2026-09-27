extends Node


const ZONE_1_TARGET_METERS: float = 300.0


enum RunState {
	IDLE,
	PLAYING,
	AWAITING_REVIVE,
	FINISHED,
	COMPLETED,
}


signal run_started

signal altitude_changed(
	current_altitude: float
)

signal peak_height_changed(
	peak_height: float
)

signal coins_changed(
	run_coins: int
)

signal death_pending(
	can_revive: bool
)

signal revive_granted

signal revive_ad_failed

signal run_finished(
	final_peak_height: float,
	coins_earned: int,
	best_height: float
)

signal zone_completed(
	final_peak_height: float,
	coins_earned: int,
	best_height: float
)


var state: int = RunState.IDLE

var current_altitude: float = 0.0

var run_peak_height: float = 0.0

var run_coins: int = 0

var best_height: float = 0.0

var revive_used: bool = false

var _run_saved: bool = false


func _ready() -> void:
	best_height = SaveManager.get_best_height()

	AdManager.rewarded_ad_completed.connect(
		_on_rewarded_ad_completed
	)

	AdManager.ad_failed.connect(
		_on_ad_failed
	)


# ============================================================
# INICIAR PARTIDA
# ============================================================

func start_run() -> void:
	state = RunState.PLAYING

	current_altitude = 0.0
	run_peak_height = 0.0
	run_coins = 0

	revive_used = false
	_run_saved = false

	altitude_changed.emit(
		current_altitude
	)

	peak_height_changed.emit(
		run_peak_height
	)

	coins_changed.emit(
		run_coins
	)

	run_started.emit()


# ============================================================
# ALTURA
# ============================================================

func update_altitude(
	altitude: float
) -> void:

	if state != RunState.PLAYING:
		return


	var reached_target: bool = (
		altitude >= ZONE_1_TARGET_METERS
	)


	current_altitude = clampf(
		altitude,
		0.0,
		ZONE_1_TARGET_METERS
	)


	altitude_changed.emit(
		current_altitude
	)


	if current_altitude > run_peak_height:
		run_peak_height = current_altitude

		peak_height_changed.emit(
			run_peak_height
		)


	if reached_target:
		_complete_zone()


# ============================================================
# MONEDAS
# ============================================================

func add_coin(
	amount: int = 1
) -> void:

	if state != RunState.PLAYING:
		return


	run_coins += maxi(
		0,
		amount
	)


	coins_changed.emit(
		run_coins
	)


# ============================================================
# MUERTE
# ============================================================

func notify_player_died() -> void:

	if state != RunState.PLAYING:
		return


	if revive_used:
		_finish_run()
		return


	state = RunState.AWAITING_REVIVE


	death_pending.emit(
		true
	)


# ============================================================
# REVIVE
# ============================================================

func request_rewarded_revive() -> void:

	if (
		state != RunState.AWAITING_REVIVE
		or revive_used
	):
		return


	if not AdManager.is_rewarded_available():
		revive_ad_failed.emit()
		return


	AdManager.show_rewarded(
		&"revive"
	)


func decline_revive() -> void:

	if state == RunState.AWAITING_REVIVE:
		_finish_run()


# ============================================================
# REINICIAR PARTIDA
# ============================================================

func restart_run() -> void:

	get_tree().reload_current_scene()


# ============================================================
# COMPLETAR JARDINES DE NIMBO
# ============================================================

func _complete_zone() -> void:

	if state != RunState.PLAYING:
		return


	if _run_saved:
		return


	current_altitude = ZONE_1_TARGET_METERS


	run_peak_height = maxf(
		run_peak_height,
		ZONE_1_TARGET_METERS
	)


	_save_run_results()


	state = RunState.COMPLETED


	zone_completed.emit(
		run_peak_height,
		run_coins,
		best_height
	)


# ============================================================
# TERMINAR PARTIDA POR MUERTE
# ============================================================

func _finish_run() -> void:

	if _run_saved:
		return


	_save_run_results()


	state = RunState.FINISHED


	run_finished.emit(
		run_peak_height,
		run_coins,
		best_height
	)


# ============================================================
# GUARDAR RESULTADOS
# ============================================================

func _save_run_results() -> void:

	if _run_saved:
		return


	_run_saved = true


	if run_peak_height > best_height:
		best_height = run_peak_height

		SaveManager.set_best_height(
			best_height
		)


	SaveManager.add_coins(
		run_coins
	)


# ============================================================
# VIDEO RECOMPENSADO
# ============================================================

func _on_rewarded_ad_completed(
	reward_id: StringName
) -> void:

	if reward_id != &"revive":
		return


	if (
		state != RunState.AWAITING_REVIVE
		or revive_used
	):
		return


	revive_used = true

	state = RunState.PLAYING


	revive_granted.emit()


func _on_ad_failed(
	ad_type: StringName
) -> void:

	if (
		ad_type == &"rewarded"
		and state == RunState.AWAITING_REVIVE
	):
		revive_ad_failed.emit()
