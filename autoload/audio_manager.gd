extends Node

var music_enabled: bool = true
var sfx_enabled: bool = true

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled

func play_sfx(_stream: AudioStream) -> void:
	# Placeholder API. Real pooled players are added when final audio assets arrive.
	pass
