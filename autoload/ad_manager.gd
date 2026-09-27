extends Node

signal rewarded_ad_completed(reward_id: StringName)
signal ad_failed(ad_type: StringName)

var ads_enabled: bool = true
var _rewarded_ready: bool = false

func _ready() -> void:
	ads_enabled = not SaveManager.has_removed_ads()
	_rewarded_ready = OS.is_debug_build()

func is_rewarded_available() -> bool:
	# Debug builds use a safe simulated reward. Production should return the
	# real provider availability after the AdMob integration is connected.
	return OS.is_debug_build() or _rewarded_ready

func show_rewarded(reward_id: StringName) -> void:
	if OS.is_debug_build():
		call_deferred("_complete_debug_reward", reward_id)
		return
	if not _rewarded_ready:
		ad_failed.emit(&"rewarded")
		return
	# Production integration point:
	# 1. Show the provider rewarded ad.
	# 2. Emit rewarded_ad_completed only from the provider reward callback.
	# 3. Never grant a revive from the ad-open callback.
	ad_failed.emit(&"rewarded")

func show_interstitial() -> void:
	if not ads_enabled:
		return
	# Kept intentionally disabled until the real provider is integrated.
	pass

func _complete_debug_reward(reward_id: StringName) -> void:
	rewarded_ad_completed.emit(reward_id)
