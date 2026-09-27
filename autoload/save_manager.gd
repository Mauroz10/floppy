extends Node

const SAVE_PATH: String = "user://save_data.json"
const SAVE_VERSION: int = 2

var _data: Dictionary = {
	"version": SAVE_VERSION,
	"best_height": 0.0,
	"coins": 0,
	"remove_ads": false,
	"upgrades": {},
	"owned_skins": ["explorer"],
	"owned_balloons": ["basic_red"],
}

func _ready() -> void:
	load_save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open save file for reading.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is invalid. Defaults will be used.")
		return
	var loaded: Dictionary = parsed
	_data["version"] = SAVE_VERSION
	_data["best_height"] = maxf(0.0, float(loaded.get("best_height", 0.0)))
	_data["coins"] = maxi(0, int(loaded.get("coins", 0)))
	_data["remove_ads"] = bool(loaded.get("remove_ads", false))
	var loaded_upgrades: Variant = loaded.get("upgrades", {})
	_data["upgrades"] = loaded_upgrades if typeof(loaded_upgrades) == TYPE_DICTIONARY else {}
	_data["owned_skins"] = loaded.get("owned_skins", ["explorer"])
	_data["owned_balloons"] = loaded.get("owned_balloons", ["basic_red"])

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing.")
		return
	file.store_string(JSON.stringify(_data))

func get_best_height() -> float:
	return float(_data.get("best_height", 0.0))

func set_best_height(value: float) -> void:
	_data["best_height"] = maxf(0.0, value)
	save()

func get_coins() -> int:
	return int(_data.get("coins", 0))

func add_coins(amount: int) -> void:
	_data["coins"] = get_coins() + maxi(0, amount)
	save()

func has_removed_ads() -> bool:
	return bool(_data.get("remove_ads", false))

func set_remove_ads(enabled: bool) -> void:
	_data["remove_ads"] = enabled
	save()
