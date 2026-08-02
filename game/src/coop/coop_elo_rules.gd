class_name CoopEloRules
extends RefCounted
## Regra pura partilhada pelo inimigo real e pelo auto-teste local.

const REQUIRED_PARTICIPANTS := 2


static func can_accept_damage(attacker_id: StringName, target_id: StringName,
		alive_by_profile: Dictionary, attack_committed: bool,
		opening_consumed: bool) -> bool:
	if alive_by_profile.size() != REQUIRED_PARTICIPANTS or not attack_committed \
			or opening_consumed or attacker_id == StringName() \
			or target_id == StringName() or attacker_id == target_id:
		return false
	if not alive_by_profile.has(attacker_id) or not alive_by_profile.has(target_id):
		return false
	return bool(alive_by_profile.get(attacker_id, false)) \
		and bool(alive_by_profile.get(target_id, false))


static func lethal_is_unlocked(openings_by_profile: Dictionary,
		current_attacker_id: StringName) -> bool:
	var contributors := openings_by_profile.duplicate()
	contributors[current_attacker_id] = true
	return contributors.size() == REQUIRED_PARTICIPANTS
