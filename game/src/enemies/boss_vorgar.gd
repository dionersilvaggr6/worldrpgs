class_name BossVorgar
extends Enemy
## Vorgar continua a herdar os cinco ataques provados de Enemy. Esta subclasse
## apenas intercala as duas perguntas espaciais declaradas na ficha e instala o
## controlador da arena/ressurreicao.

const ArenaVorgarScript = preload("res://src/world/arena_vorgar.gd")

var _arena_vorgar: ArenaVorgar
var _active_coop_sequence: Dictionary = {}
var _coop_sequence_frame := 0
var _normal_patterns_since_sequence := 0


func setup(p_enemy_id: String, palette: Dictionary, coop := false, pattern_seed := 0) -> void:
	super.setup(p_enemy_id, palette, coop, pattern_seed)
	call_deferred("_install_vorgar_arena")


func arena_controller() -> ArenaVorgar:
	return _arena_vorgar


func _install_vorgar_arena() -> void:
	if is_instance_valid(_arena_vorgar) or not is_inside_tree() or get_parent() == null:
		return
	# O harness de Lei 4 usa exactamente a mesma cena com e sem este controlador.
	# A flag existe apenas na linha de comandos e nunca altera uma sessão jogada.
	if "--vorgar-controller=off" in OS.get_cmdline_user_args():
		return
	var encounter := data.get("vorgar_encounter", {}) as Dictionary
	if encounter.is_empty():
		push_error("Vorgar: ficha vorgar_encounter em falta")
		return
	_arena_vorgar = ArenaVorgarScript.new()
	_arena_vorgar.name = "ArenaVorgar"
	_arena_vorgar.controller_only = true
	get_parent().add_child(_arena_vorgar)
	_arena_vorgar.global_position = home
	var local_player: Node3D
	for node: Node in get_tree().get_nodes_in_group("player"):
		local_player = node as Node3D
		if local_player != null:
			break
	_arena_vorgar.setup(self, encounter, local_player)


func _tick_boss_phase() -> void:
	var before := _phase
	super._tick_boss_phase()
	if _phase != before:
		_normal_patterns_since_sequence = 0


func _begin_pattern() -> void:
	if _anti_kite_ready() or not is_instance_valid(_arena_vorgar):
		_normal_patterns_since_sequence += 1
		super._begin_pattern()
		return
	var plan := _phase_plan()
	var required_normal_patterns := int(plan.get("normal_patterns_before"))
	if _normal_patterns_since_sequence < required_normal_patterns:
		_normal_patterns_since_sequence += 1
		super._begin_pattern()
		return
	var sequence := _sequence_by_id(String(plan.get("sequence_id", "")))
	if sequence.is_empty():
		_normal_patterns_since_sequence += 1
		super._begin_pattern()
		return
	_start_coop_sequence(sequence)


func _start_coop_sequence(sequence: Dictionary) -> void:
	_active_coop_sequence = sequence.duplicate(true)
	_coop_sequence_frame = 0
	_normal_patterns_since_sequence = 0
	_queue.clear()
	_atk = sequence
	_atk_frame = 0
	_atk_hit = false
	if is_instance_valid(_active_gameplay_cue):
		_active_gameplay_cue.cancel()
	_arena_vorgar.begin_sequence(sequence)
	_change_state(State.ATTACK)


func _tick_attack(delta: float) -> void:
	if _active_coop_sequence.is_empty():
		super._tick_attack(delta)
		return
	_coop_sequence_frame += 1
	_atk_frame = _coop_sequence_frame
	var startup := int(_active_coop_sequence.get("startup"))
	var active := int(_active_coop_sequence.get("active"))
	var recovery := int(_active_coop_sequence.get("recovery"))
	var phase_1 := int(_active_coop_sequence.get("phase_1_frames"))
	var tracking := _active_coop_sequence.get("curva_seguimento", {}) as Dictionary

	if _coop_sequence_frame <= startup:
		_brake(delta)
		var tracking_speed := float(tracking.get(
			"fase_1_deg_s" if _coop_sequence_frame <= phase_1 else "fase_2_deg_s"))
		_face_sequence_anchor(delta, tracking_speed)
	else:
		_brake(delta)
	_arena_vorgar.tick_sequence(_coop_sequence_frame)

	if _coop_sequence_frame >= startup + active + recovery:
		_finish_coop_sequence()


func _face_sequence_anchor(delta: float, max_degrees_per_second: float) -> void:
	if max_degrees_per_second <= 0.0:
		return
	var point := target.global_position if _target_valid() else global_position - global_transform.basis.z
	if String(_active_coop_sequence.get("objectivo_coop", "")) == "juntar" \
			and is_instance_valid(_arena_vorgar):
		point = _arena_vorgar.join_safe_center_global()
	var direction := point - global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		return
	var desired := atan2(-direction.x, -direction.z)
	var max_step := deg_to_rad(max_degrees_per_second) * delta
	rotation.y += clampf(angle_difference(rotation.y, desired), -max_step, max_step)


func _finish_coop_sequence() -> void:
	if is_instance_valid(_arena_vorgar):
		_arena_vorgar.end_sequence()
	_active_coop_sequence = {}
	_coop_sequence_frame = 0
	_atk = {}
	var phase := _current_phase_data()
	_gap_timer = float(phase.get("gap_between_patterns"))
	_change_state(State.CHASE)


func take_damage(info: DamageInfo) -> void:
	super.take_damage(info)
	if not _active_coop_sequence.is_empty() and state != State.ATTACK:
		_cancel_coop_sequence()


func full_reset() -> void:
	super.full_reset()
	_active_coop_sequence = {}
	_coop_sequence_frame = 0
	_normal_patterns_since_sequence = 0
	if is_instance_valid(_arena_vorgar):
		_arena_vorgar.reset_attempt()


func _cancel_coop_sequence() -> void:
	if is_instance_valid(_arena_vorgar):
		_arena_vorgar.end_sequence()
	_active_coop_sequence = {}
	_coop_sequence_frame = 0


func _phase_plan() -> Dictionary:
	var encounter := data.get("vorgar_encounter", {}) as Dictionary
	var plans := encounter.get("coop_phase_plan", {}) as Dictionary
	return plans.get(str(_phase), {}) as Dictionary


func _sequence_by_id(id: String) -> Dictionary:
	var encounter := data.get("vorgar_encounter", {}) as Dictionary
	var sequences := encounter.get("coop_sequences", {}) as Dictionary
	return sequences.get(id, {}) as Dictionary


func _exit_tree() -> void:
	if is_instance_valid(_arena_vorgar):
		_arena_vorgar.queue_free()
