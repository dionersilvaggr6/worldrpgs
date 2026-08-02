class_name CoopResurrection
extends RefCounted
## Estado puro da ressurreicao co-op. Todos os tempos, usos e fraccoes chegam
## de progression.json; este ficheiro escolhe apenas transicoes.

signal player_downed(profile_id: StringName)
signal player_expired(profile_id: StringName)
signal progress_changed(profile_id: StringName, progress_seconds: float,
	channel_seconds: float)
signal revive_requested(profile_id: StringName, health_fraction: float,
	keeps_current_flasks: bool)

const REQUIRED_PARTICIPANTS := 2
const POLICY_CUMULATIVE := &"cumulative"
const POLICY_RESET_ON_INTERRUPT := &"reset_on_interrupt"

var _config: Dictionary = {}
var _participants: Dictionary = {}
var _alive: Dictionary = {}
var _downed: Dictionary = {}
var _expired: Dictionary = {}
var _progress: Dictionary = {}
var _elapsed: Dictionary = {}
var _uses_remaining := 0
var _channel_seconds := 0.0
var _policy := StringName()
var _configured := false


func configure(config: Dictionary, channel_seconds: float, policy: StringName) -> bool:
	var channel_range: Array = config.get("channel_seconds_range", []) as Array
	if channel_range.size() != REQUIRED_PARTICIPANTS:
		return false
	var channel_min := float(channel_range.front())
	var channel_max := float(channel_range.back())
	if channel_seconds < channel_min or channel_seconds > channel_max:
		return false
	if float(config.get("window_seconds", 0.0)) <= 0.0 \
			or int(config.get("shared_uses_per_attempt_or_rest", 0)) <= 0 \
			or float(config.get("revived_health_fraction", 0.0)) <= 0.0:
		return false
	if policy != POLICY_CUMULATIVE and policy != POLICY_RESET_ON_INTERRUPT:
		return false
	_config = config.duplicate(true)
	_channel_seconds = channel_seconds
	_policy = policy
	_configured = true
	return true


func begin_attempt(participant_ids: Array) -> bool:
	if not _configured or participant_ids.size() != REQUIRED_PARTICIPANTS:
		return false
	_participants.clear()
	_alive.clear()
	_downed.clear()
	_expired.clear()
	_progress.clear()
	_elapsed.clear()
	for profile_value: Variant in participant_ids:
		var profile_id := StringName(String(profile_value))
		if profile_id == StringName() or _participants.has(profile_id):
			_participants.clear()
			_alive.clear()
			return false
		_participants[profile_id] = true
		_alive[profile_id] = true
	_uses_remaining = int(_config.get("shared_uses_per_attempt_or_rest"))
	return true


func down(profile_id: StringName) -> bool:
	if not _participants.has(profile_id) or not bool(_alive.get(profile_id, false)):
		return false
	_alive[profile_id] = false
	_downed[profile_id] = true
	_expired.erase(profile_id)
	_progress[profile_id] = 0.0
	_elapsed[profile_id] = 0.0
	player_downed.emit(profile_id)
	return true


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	var window_seconds := float(_config.get("window_seconds"))
	for profile_value: Variant in _downed.keys():
		var profile_id := StringName(String(profile_value))
		if bool(_expired.get(profile_id, false)):
			continue
		_elapsed[profile_id] = float(_elapsed.get(profile_id, 0.0)) + delta
		if float(_elapsed[profile_id]) >= window_seconds:
			_expired[profile_id] = true
			player_expired.emit(profile_id)


func contribute(rescuer_id: StringName, fallen_id: StringName, delta: float) -> Dictionary:
	if not _participants.has(rescuer_id) or not _participants.has(fallen_id) \
			or rescuer_id == fallen_id or delta <= 0.0:
		return {"status": "invalid"}
	if not bool(_alive.get(rescuer_id, false)):
		return {"status": "rescuer_down"}
	if not bool(_downed.get(fallen_id, false)):
		return {"status": "not_downed"}
	if bool(_expired.get(fallen_id, false)):
		return {"status": "expired"}
	if _uses_remaining <= 0:
		return {"status": "exhausted"}

	_progress[fallen_id] = minf(
		float(_progress.get(fallen_id, 0.0)) + delta, _channel_seconds)
	progress_changed.emit(fallen_id, float(_progress[fallen_id]), _channel_seconds)
	if float(_progress[fallen_id]) < _channel_seconds:
		return {
			"status": "progress",
			"progress_seconds": float(_progress[fallen_id]),
			"channel_seconds": _channel_seconds,
		}

	_uses_remaining -= 1
	_downed.erase(fallen_id)
	_expired.erase(fallen_id)
	_alive[fallen_id] = true
	var health_fraction := float(_config.get("revived_health_fraction"))
	var keeps_flasks := bool(_config.get("keeps_current_flasks"))
	revive_requested.emit(fallen_id, health_fraction, keeps_flasks)
	return {
		"status": "revived",
		"profile_id": fallen_id,
		"health_fraction": health_fraction,
		"keeps_current_flasks": keeps_flasks,
	}


func interrupt(rescuer_id: StringName, fallen_id: StringName) -> Dictionary:
	if not _participants.has(rescuer_id) or not bool(_downed.get(fallen_id, false)):
		return {"status": "invalid"}
	if not bool(_config.get("damage_interrupts")):
		return {"status": "ignored", "progress_seconds": progress_for(fallen_id)}
	if _policy == POLICY_RESET_ON_INTERRUPT:
		_progress[fallen_id] = 0.0
		progress_changed.emit(fallen_id, 0.0, _channel_seconds)
	return {"status": "interrupted", "progress_seconds": progress_for(fallen_id)}


func progress_for(profile_id: StringName) -> float:
	return float(_progress.get(profile_id, 0.0))


func is_alive(profile_id: StringName) -> bool:
	return bool(_alive.get(profile_id, false))


func is_downed(profile_id: StringName) -> bool:
	return bool(_downed.get(profile_id, false))


func uses_remaining() -> int:
	return _uses_remaining


func policy() -> StringName:
	return _policy
