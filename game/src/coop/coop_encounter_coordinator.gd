class_name CoopEncounterCoordinator
extends RefCounted
## Cola transport-agnostica entre dois corpos, um encontro autoritativo e a
## ressurreicao. O dono de main.gd liga Input/HUD; aqui nao se assume cena.

signal revive_requested(profile_id: StringName, health_fraction: float,
	keeps_current_flasks: bool)

const ResurrectionScript = preload("res://src/coop/coop_resurrection.gd")

var _participants: Dictionary = {}
var _encounter: Object
var _resurrection = ResurrectionScript.new()
var _death_connections: Dictionary = {}


func configure(participants: Dictionary, encounter: Object,
		resurrection_config: Dictionary, channel_seconds: float,
		progress_policy: StringName) -> bool:
	close()
	if encounter == null or not encounter.has_method("configure_participants"):
		return false
	_participants = participants.duplicate()
	if not bool(encounter.call("configure_participants", _participants)):
		_participants.clear()
		return false
	if not _resurrection.configure(resurrection_config, channel_seconds, progress_policy):
		_participants.clear()
		return false
	if not _resurrection.begin_attempt(_participants.keys()):
		_participants.clear()
		return false
	_encounter = encounter
	for profile_value: Variant in _participants:
		var profile_id := StringName(String(profile_value))
		var body := _participants[profile_value] as Object
		if body != null and body.has_signal("died"):
			var callback := _on_body_died.bind(profile_id)
			body.connect("died", callback)
			_death_connections[profile_id] = callback
	return true


func close() -> void:
	for profile_value: Variant in _participants:
		var profile_id := StringName(String(profile_value))
		var body := _participants[profile_value] as Object
		var callback: Callable = _death_connections.get(profile_id, Callable())
		if body != null and callback.is_valid() and body.is_connected("died", callback):
			body.disconnect("died", callback)
	_death_connections.clear()
	_participants.clear()
	_encounter = null


func advance(delta: float) -> void:
	_resurrection.advance(delta)


func hold_interact(rescuer_id: StringName, fallen_id: StringName,
		delta: float) -> Dictionary:
	var result := _resurrection.contribute(rescuer_id, fallen_id, delta)
	if String(result.get("status", "")) != "revived":
		return result
	var body := _participants.get(fallen_id) as Object
	if body != null and body.has_method("revive_from_coop"):
		body.call("revive_from_coop", result.get("health_fraction"),
			result.get("keeps_current_flasks"))
	revive_requested.emit(fallen_id, result.get("health_fraction"),
		result.get("keeps_current_flasks"))
	return result


func interrupt_by_damage(rescuer_id: StringName, fallen_id: StringName) -> Dictionary:
	return _resurrection.interrupt(rescuer_id, fallen_id)


func down_player(profile_id: StringName) -> bool:
	return _resurrection.down(profile_id)


func resurrection() -> CoopResurrection:
	return _resurrection


func _on_body_died(profile_id: StringName) -> void:
	_resurrection.down(profile_id)
