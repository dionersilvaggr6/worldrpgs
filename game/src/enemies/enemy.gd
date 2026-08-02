class_name Enemy
extends CharacterBody3D
## Inimigo generico, todo definido por dados (data/enemies.json).
##
## IA SIMPLES E LEGIVEL VENCE IA ESPERTA. O jogador tem de conseguir prever o que
## vem a seguir — e isso que faz a esquiva e o parry serem habilidade e nao sorte.
##
## Contrato que a spec impoe e que este ficheiro cumpre:
##  - todo o ataque telegrafa >= 0,5 s, e o telegrafo e VISIVEL (amarelo)
##  - cada ataque e 'aparavel' ou 'so esquiva', vindo dos dados
##  - postura 0-100: dano de postura = MV x 10; a zero, cambaleio 1,2 s
##  - anti-kite: 4 s sem alcancar o alvo -> comportamento de fecho
##  - perseguicao sempre abaixo dos 5,0 m/s do correr do jogador (fugir e sempre possivel)

signal died(enemy: Enemy)
signal state_changed(current: int, previous: int)
signal attack_phase_changed(phase: int, progress: float, parryable: bool, attack_id: String)
signal health_changed(current: float, maximum: float, delta: float, source: Node3D)
signal hit_landed(victim: Node3D, damage: float, origin: Vector3)

const GameplayCueRenderer = preload("res://src/combat/gameplay_cue.gd")
const EnemyVisualRenderer = preload("res://src/enemies/enemy_visual.gd")
const EnemyAttackAudio = preload("res://src/enemies/enemy_attack_audio.gd")
const CrowdSteering = preload("res://src/ai/enemy_crowd_steering.gd")
const AttackCoordinator = preload("res://src/ai/enemy_attack_coordinator.gd")
const ATTACK_ESCAPE_VECTORS: Array[String] = [
	"sair_da_linha", "rolar_para_dentro", "rolar_para_fora", "afastar_se",
	"aproximar_se", "quebrar_a_visao", "sair_da_area", "aparar",
	"bloquear_e_aguentar",
]

enum State { IDLE, PATROL, CHASE, ATTACK, STAGGER, BROKEN, DEAD }
enum AttackPhase { NONE, PREPARATION, STRIKE, RECOVERY }

var enemy_id := "orc_spearman"
var data: Dictionary = {}
var is_boss := false

var health := 0.0
var max_health := 0.0
var defense := 0.0
var posture := 0.0
var max_posture := 0.0
var posture_mult := 0.0
var body_radius := 0.0
var hitstop_frames := 0

var target: Node3D
var home := Vector3.ZERO
## Ha quanto tempo o alvo esta fora de vista (spec/15: desiste aos 6 s).
var _unseen_for := 0.0

var state := State.IDLE
var _state_frame := 0
var _state_time := 0.0

var _attacks: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _active_gameplay_cue: Node
var _last_attack_hit_frame := -9999
var _queue: Array = []
var _atk: Dictionary = {}
var _atk_frame := 0
var _atk_hit := false
var _attack_phase := AttackPhase.NONE
var _attack_phase_progress := 0.0
var _planned_false_recovery: Dictionary = {}
var _gap_timer := 0.0
var _no_reach_time := 0.0
var _phase := 1
var _spawn_offset := Vector3.ZERO

var _patrol_points: Array[Vector3] = []
var _patrol_index := 0

var _visual: Node3D
var _attack_audio: Node3D
var _palette: Dictionary = {}
var _presentation: Dictionary = {}
var _visual_profile: Dictionary = {}
var _visual_animation_request := ""

static var _presentation_catalogue_validated := false
static var _attack_grammar_catalogue_validated := false


func _reference_fps() -> float:
	return float(GameData.combat["reference_fps"])


func setup(p_enemy_id: String, palette: Dictionary, coop := false, pattern_seed := 0) -> void:
	enemy_id = p_enemy_id
	_rng.seed = pattern_seed if pattern_seed != 0 else hash(enemy_id)
	data = GameData.enemy(enemy_id)
	_palette = palette
	is_boss = bool(data.get("is_boss", false))
	_presentation = GameData.enemies.get("_presentation", {}) as Dictionary
	_visual_profile = _profile_for_enemy(enemy_id, data, _presentation)
	_validate_presentation_catalogue()
	if not _validate_attack_grammar_catalogue():
		return

	max_health = float(data["health"])
	if is_boss and coop:
		max_health *= float(data["coop_health_multiplier"])
	health = max_health
	defense = float(data["defense"])
	max_posture = float(data["posture"])
	posture = max_posture
	posture_mult = float(data["posture_damage_taken_multiplier"])
	body_radius = float(_visual_profile["collision_radius_m"])

	for a: Variant in data.get("attacks", []):
		var d := a as Dictionary
		_attacks[String(d.get("id", ""))] = d
		if d.get("followup") != null:
			var f := d.get("followup") as Dictionary
			_attacks[String(f.get("id", ""))] = f

	var requested_home := global_position
	_build_body()
	CrowdSteering.resolve_spawn_overlap(self, get_tree().get_nodes_in_group("enemies"),
		data.get("crowd", {}) as Dictionary)
	_spawn_offset = global_position - requested_home
	home = requested_home
	_make_patrol_route()
	_change_state(State.PATROL if float(data.get("patrol_speed", 0.0)) > 0.0 else State.IDLE)
	health_changed.emit(health, max_health, 0.0, null)


func _profile_for_enemy(id: String, enemy_data: Dictionary,
		presentation: Dictionary) -> Dictionary:
	var profiles: Dictionary = presentation.get("visual_profiles", {}) as Dictionary
	var profile_key := id
	if not profiles.has(profile_key):
		profile_key = "%s:%s" % [enemy_data.get("race_id", ""), enemy_data.get("role", "")]
	var profile := (profiles.get(profile_key, {}) as Dictionary).duplicate(true)
	profile["animation_blend_s"] = float(presentation.get("animation_blend_s", 0.0))
	return profile


func _validate_presentation_catalogue() -> void:
	if _presentation_catalogue_validated:
		return
	_presentation_catalogue_validated = true
	var visual_profiles: Dictionary = _presentation.get("visual_profiles", {}) as Dictionary
	var audio_profiles: Dictionary = _presentation.get("audio_profiles", {}) as Dictionary
	for id: String in GameData.enemies.keys():
		if id.begins_with("_"):
			continue
		var enemy_data := GameData.enemy(id)
		var fallback_key := "%s:%s" % [enemy_data.get("race_id", ""), enemy_data.get("role", "")]
		if not visual_profiles.has(id) and not visual_profiles.has(fallback_key):
			push_error("[enemy-visual] ficha sem perfil distante: %s" % id)
		var race_id := String(enemy_data.get("race_id", ""))
		if not audio_profiles.has(race_id):
			push_error("[enemy-audio] ficha sem família sonora: %s (%s)" % [id, race_id])


## Guarda executavel da lacuna que deixou 31 fichas comuns sem gramatica. O
## primeiro inimigo criado valida o catalogo inteiro, incluindo o chefe por fase;
## uma lista vazia, um golpe fantasma ou danos repintados param a build de teste.
static func attack_grammar_contract_errors(catalogue: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var attack_damages := {}
	for id_value: Variant in catalogue.keys():
		var id := String(id_value)
		if id.begins_with("_"):
			continue
		var enemy_data: Dictionary = catalogue.get(id, {}) as Dictionary
		var attack_ids := {}
		for attack_value: Variant in enemy_data.get("attacks", []):
			var attack := attack_value as Dictionary
			var attack_id := String(attack.get("id", ""))
			var label := "%s/%s" % [id, attack_id if attack_id != "" else "?"]
			if attack_id == "":
				errors.append("%s tem ataque sem id" % id)
				continue
			attack_ids[attack_id] = true
			if not attack.has("damage") or float(attack.get("damage")) <= 0.0:
				errors.append("%s nao declara dano proprio positivo" % label)
			else:
				var damage_key := str(attack.get("damage"))
				if attack_damages.has(damage_key):
					errors.append("%s repinta o dano de %s" % [label, attack_damages[damage_key]])
				attack_damages[damage_key] = label
			if not attack.has("momento_compromisso_frame"):
				errors.append("%s nao declara momento de compromisso" % label)
			var tracking_curve: Dictionary = attack.get("curva_seguimento", {}) as Dictionary
			for phase_key: String in ["fase_1_deg_s", "fase_2_deg_s", "fase_3_deg_s"]:
				if not tracking_curve.has(phase_key):
					errors.append("%s fica sem curva de seguimento em %s" % [label, phase_key])
			var escape_vectors: Array = attack.get("vectores_fuga", []) as Array
			if escape_vectors.is_empty():
				errors.append("%s fica sem vector de fuga" % label)
			for escape_vector: Variant in escape_vectors:
				if String(escape_vector) not in ATTACK_ESCAPE_VECTORS:
					errors.append("%s usa vector de fuga fora da lista: %s" % [
						label, escape_vector])
			var sound_cue: Dictionary = attack.get("som_anuncio", {}) as Dictionary
			if String(sound_cue.get("cue_id", "")) == "" \
					or String(sound_cue.get("descricao", "")) == "":
				errors.append("%s fica sem anuncio sonoro" % label)
			var visual_cue: Dictionary = attack.get("sinal_visual_equivalente", {}) as Dictionary
			for cue_key: String in ["ancora", "forma", "inicio", "compromisso", "fim", "fora_ecra"]:
				if String(visual_cue.get(cue_key, "")) == "":
					errors.append("%s fica sem equivalente visual em %s" % [label, cue_key])
			var false_recovery: Dictionary = attack.get("false_recovery", {}) as Dictionary
			if not false_recovery.is_empty():
				if not bool(false_recovery.get("chosen_before_tell", false)):
					errors.append("%s escolhe a finta depois do aviso" % label)
				if String(false_recovery.get("optional_followup", "")) == "":
					errors.append("%s tem finta sem optional_followup" % label)
				if not false_recovery.has("trigger_range_m") \
						or float(false_recovery.get("trigger_range_m")) <= 0.0:
					errors.append("%s tem finta sem distancia executavel" % label)
				if not false_recovery.has("variant_roll_max") \
						or float(false_recovery.get("variant_roll_max")) <= 0.0:
					errors.append("%s tem finta sem escala do sorteio" % label)

		for attack_value: Variant in enemy_data.get("attacks", []):
			var attack := attack_value as Dictionary
			var false_recovery: Dictionary = attack.get("false_recovery", {}) as Dictionary
			if not false_recovery.is_empty():
				var followup_id := String(false_recovery.get("optional_followup", ""))
				if followup_id != "" and not attack_ids.has(followup_id):
					errors.append("%s/%s aponta finta para golpe inexistente '%s'" % [
						id, attack.get("id", "?"), followup_id])

		var patterned_attack_ids := {}
		if bool(enemy_data.get("is_boss", false)):
			var phases: Dictionary = enemy_data.get("phases", {}) as Dictionary
			if phases.is_empty():
				errors.append("%s nao declara fases com padroes" % id)
			for phase_id: String in phases.keys():
				var phase: Dictionary = phases.get(phase_id, {}) as Dictionary
				_collect_pattern_attack_ids(phase.get("patterns", null), patterned_attack_ids)
				errors.append_array(_pattern_set_errors(
					"%s/fase_%s" % [id, phase_id], phase.get("patterns", null),
					phase.get("gap_between_patterns", null), attack_ids))
		else:
			_collect_pattern_attack_ids(enemy_data.get("patterns", null), patterned_attack_ids)
			errors.append_array(_pattern_set_errors(
				id, enemy_data.get("patterns", null),
				enemy_data.get("gap_between_patterns", null), attack_ids))
		for attack_value: Variant in enemy_data.get("attacks", []):
			var attack := attack_value as Dictionary
			var attack_id := String(attack.get("id", ""))
			if attack_id != "" and not bool(attack.get("anti_kite_only", false)) \
					and not patterned_attack_ids.has(attack_id):
				errors.append("%s/%s nao entra em nenhum padrao" % [id, attack_id])
	return errors


static func _collect_pattern_attack_ids(patterns_value: Variant, output: Dictionary) -> void:
	if not (patterns_value is Array):
		return
	for pattern_value: Variant in patterns_value as Array:
		if not (pattern_value is Array):
			continue
		for attack_id_value: Variant in pattern_value as Array:
			output[String(attack_id_value)] = true


static func _pattern_set_errors(label: String, patterns_value: Variant,
		gap_value: Variant, attack_ids: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not (patterns_value is Array) or (patterns_value as Array).is_empty():
		errors.append("%s fica sem padroes" % label)
		return errors
	if gap_value == null or float(gap_value) <= 0.0:
		errors.append("%s fica sem pausa entre padroes" % label)
	var lengths := {}
	for pattern_index: int in (patterns_value as Array).size():
		var pattern_value: Variant = (patterns_value as Array)[pattern_index]
		if not (pattern_value is Array) or (pattern_value as Array).is_empty():
			errors.append("%s/padrao_%d fica vazio" % [label, pattern_index])
			continue
		var pattern := pattern_value as Array
		lengths[pattern.size()] = true
		for attack_id_value: Variant in pattern:
			var attack_id := String(attack_id_value)
			if not attack_ids.has(attack_id):
				errors.append("%s/padrao_%d aponta golpe inexistente '%s'" % [
					label, pattern_index, attack_id])
	if lengths.size() < 2:
		errors.append("%s nao varia o comprimento dos combos" % label)
	return errors


func _validate_attack_grammar_catalogue() -> bool:
	if _attack_grammar_catalogue_validated:
		return true
	var errors := attack_grammar_contract_errors(GameData.enemies)
	for error: String in errors:
		push_error("[enemy-grammar] %s" % error)
	if not errors.is_empty():
		assert(false, "[enemy-grammar] catalogo invalido:\n%s" % "\n".join(errors))
		return false
	_attack_grammar_catalogue_validated = true
	return true


func _build_body() -> void:
	var height := float(_visual_profile.get("collision_height_m", 0.0))
	if height <= 0.0 or body_radius <= 0.0:
		push_error("[enemy-visual] colisao sem perfil: %s" % enemy_id)
		return

	var shape := CapsuleShape3D.new()
	shape.height = height
	shape.radius = body_radius
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, height * 0.5, 0)
	add_child(col)

	# A malha e visual; a CapsuleShape3D acima continua a ser a unica colisao.
	# Os tres papeis usam criaturas CC0 distintas; escala e cor nao voltam a
	# transformar um corpo humano despido num monstro.
	_visual = EnemyVisualRenderer.new()
	add_child(_visual)
	# No preset médio a luz direccional já não desenha sombras, portanto esta
	# flag não custa um passe. No alto conserva-se o contacto com o chão em vez
	# de cortar qualidade silenciosamente.
	_visual.call("setup", enemy_id, data, _visual_profile, true, int(get_instance_id()))

	_attack_audio = EnemyAttackAudio.new()
	add_child(_attack_audio)
	_attack_audio.call("setup", enemy_id, String(data.get("race_id", "")), _presentation)

	collision_layer = 4
	collision_mask = 1
	add_to_group("enemies")


func _make_patrol_route() -> void:
	var speed := float(data.get("patrol_speed", 0.0))
	if speed <= 0.0:
		return
	var route_centre := global_position
	for i in 3:
		var a := TAU * float(i) / 3.0
		_patrol_points.append(route_centre + Vector3(sin(a), 0, cos(a)) * 6.0)


# --- Ciclo --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_refresh_target_actionability()
	# Paragem de impacto (spec/25-controlo.md): congela este corpo, nao o mundo.
	if hitstop_frames > 0:
		hitstop_frames -= 1
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	_state_frame += 1
	_state_time += delta

	if state != State.DEAD:
		_tick_boss_phase()
		_tick_anti_kite(delta)

	match state:
		State.IDLE:   _tick_idle(delta)
		State.PATROL: _tick_patrol(delta)
		State.CHASE:  _tick_chase(delta)
		State.ATTACK: _tick_attack(delta)
		State.STAGGER, State.BROKEN: _tick_downed(delta)
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0
	if state in [State.IDLE, State.PATROL, State.CHASE]:
		var maximum_speed := maxf(float(data.get("chase_speed", 0.0)),
			float(data.get("patrol_speed", 0.0)))
		velocity = CrowdSteering.separate_velocity(self, velocity,
			get_tree().get_nodes_in_group("enemies"), data.get("crowd", {}) as Dictionary,
			maximum_speed)

	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 20.0) * delta
	else:
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()
	_refresh_colour()
	_refresh_animation()


func _change_state(next: int) -> void:
	var previous := state
	state = next
	_state_frame = 0
	_state_time = 0.0
	if next != State.ATTACK:
		_set_attack_phase(AttackPhase.NONE, 0.0)
	if previous != next:
		state_changed.emit(next, previous)


func _set_attack_phase(next: int, progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	if _attack_phase == next and is_equal_approx(_attack_phase_progress, clamped_progress):
		return
	_attack_phase = next
	_attack_phase_progress = clamped_progress
	attack_phase_changed.emit(_attack_phase, _attack_phase_progress,
		bool(_atk.get("parryable", false)), String(_atk.get("id", "")))


func _target_valid() -> bool:
	return is_instance_valid(target) and (not target.has_method("is_alive") or target.call("is_alive"))


## Larga o alvo e volta ao posto. spec/15: "regressa, e cura ao chegar".
## A cura ao chegar e do dono do bestiario — aqui trata-se so de largar,
## que e a metade que impedia fugir.
func _give_up_chase() -> void:
	_unseen_for = 0.0
	target = null
	_change_state(State.PATROL if not _patrol_points.is_empty() else State.IDLE)


## Ve o alvo? Um raio simples do peito ao peito, contra o cenario.
##
## NAO usa cone de visao nem memoria de posicao: isso e IA cara, e a Lei 4
## manda numa Iris Xe. Um raio por inimigo por frame, com no maximo 5 inimigos
## em cena (o tecto do WP12), custa o que nao se mede.
func _has_line_of_sight() -> bool:
	if not _target_valid():
		return false
	var space := get_world_3d().direct_space_state
	if space == null:
		return true  # sem mundo fisico (testes headless) assume-se que ve
	var from := global_position + Vector3.UP * 1.2
	var to: Vector3 = (target as Node3D).global_position + Vector3.UP * 1.2
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	# So o cenario tapa a vista. Sem esta mascara, o proprio corpo do jogador
	# contava como parede e o inimigo desistia com o alvo a frente do nariz.
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	var blocker: Variant = hit.get("collider")
	return blocker == target


func _refresh_target_actionability() -> void:
	if not _target_valid() or not target.has_method("state_name"):
		return
	var target_state := String(target.call("state_name"))
	# A indisponibilidade que importa aqui e forcada pelo ataque anterior. Ataque,
	# esquiva e conjuracao continuam a ser escolhas do jogador, nao hit-stun.
	var can_act := target_state not in ["hit-stun", "guarda quebrada", "morto"]
	AttackCoordinator.update_target_actionability(target, can_act,
		data.get("attack_coordination", {}) as Dictionary,
		float(GameData.combat.get("reference_fps")))


func _distance_to_target() -> float:
	if not _target_valid():
		return INF
	var d := target.global_position - global_position
	d.y = 0.0
	return d.length()


func _tick_idle(delta: float) -> void:
	_brake(delta)
	if _target_valid() and _distance_to_target() <= float(data["aggro_range"]):
		_change_state(State.CHASE)


func _tick_patrol(delta: float) -> void:
	if _target_valid() and _distance_to_target() <= float(data["aggro_range"]):
		_change_state(State.CHASE)
		return
	if _patrol_points.is_empty():
		_brake(delta)
		return
	var goal := _patrol_points[_patrol_index]
	if global_position.distance_to(goal) < 1.2:
		_patrol_index = (_patrol_index + 1) % _patrol_points.size()
	_walk_towards(goal, float(data["patrol_speed"]))


func _tick_chase(delta: float) -> void:
	if not _target_valid():
		_change_state(State.PATROL if not _patrol_points.is_empty() else State.IDLE)
		return

	var dist := _distance_to_target()

	# A TRELA MEDE-SE DO POSTO, NAO DO ALVO. spec/15-inimigos.md: "Desistencia:
	# 6 s sem ver o alvo, ou a 30 m DO POSTO: regressa, e cura ao chegar".
	#
	# ⚠️ Estava a medir a distancia ao JOGADOR, e por isso ninguem desistia
	# nunca. A conta: o jogador corre a 5,0 m/s e o lanceiro persegue a 4,6 —
	# ganham-se 0,4 m/s, logo eram precisos ~85 s a correr em linha recta para
	# abrir os 34 m. Uma curva, um obstaculo ou uma pausa de stamina e a
	# distancia fecha-se outra vez. Na pratica seguiam pelo mapa inteiro, que
	# foi o que o Rico apanhou a jogar (02-08).
	#
	# Medida do posto, a trela passa a ser o que a spec quer: um territorio.
	# Sair dele e uma decisao do jogador que FUNCIONA — e "fugir tem de
	# funcionar sempre" e a regra do soft gating (spec/04).
	if home.distance_to(global_position) > float(data["leash_range"]):
		_give_up_chase()
		return

	# A segunda metade da regra de desistencia, que nao existia de todo:
	# 6 s sem ver o alvo. Sem isto, um inimigo que perde o jogador atras de
	# uma rocha fica a persegui-lo ate ao fim da trela, em vez de voltar ao
	# posto — e o jogador nunca aprende que se pode quebrar a perseguicao.
	if _has_line_of_sight():
		_unseen_for = 0.0
	else:
		_unseen_for += delta
		if _unseen_for >= float(data.get("give_up_seconds", 6.0)):
			_give_up_chase()
			return

	_face_target(delta)
	_gap_timer -= delta

	var preferred := float(data["preferred_distance"])
	if dist > preferred:
		_walk_towards(target.global_position, float(data["chase_speed"]))
	else:
		_brake(delta)

	if _gap_timer <= 0.0 and dist <= float(data["attack_range"]) \
			+ float(data["attack_entry_padding_m"]):
		_begin_pattern()


func _tick_downed(delta: float) -> void:
	_brake(delta)
	var seconds: float
	if state == State.BROKEN:
		seconds = float(GameData.section("parry")["broken_posture_duration"])
	else:
		seconds = float(GameData.section("poise")["stagger_duration"])
	if _state_time >= seconds:
		posture = max_posture      # a postura volta ao maximo (spec)
		_change_state(State.CHASE)


func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 18.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 18.0)


func _walk_towards(point: Vector3, speed: float) -> void:
	var dir := point - global_position
	dir.y = 0.0
	if dir.length() < 0.1:
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.12)


func _face_target(delta: float, max_degrees_per_second := 180.0) -> void:
	if not _target_valid():
		return
	var d := target.global_position - global_position
	d.y = 0.0
	if d.length_squared() > 0.01:
		var desired := atan2(-d.x, -d.z)
		var max_step := deg_to_rad(max_degrees_per_second) * delta
		rotation.y += clampf(angle_difference(rotation.y, desired), -max_step, max_step)


# --- Anti-kite ----------------------------------------------------------------

func _tick_anti_kite(delta: float) -> void:
	if state != State.CHASE and state != State.ATTACK:
		_no_reach_time = 0.0
		return
	if _distance_to_target() <= float(data["attack_range"]) \
			+ float(data["anti_kite_reach_padding_m"]):
		_no_reach_time = 0.0
	else:
		_no_reach_time += delta


func _anti_kite_ready() -> bool:
	var limit := float(GameData.section("anti_kite")["seconds_without_reaching"])
	return _no_reach_time >= limit


# --- Ataques ------------------------------------------------------------------

func _current_phase_data() -> Dictionary:
	if not is_boss:
		return data
	var phases: Dictionary = data.get("phases", {})
	return phases.get(str(_phase), data) as Dictionary


func _tick_boss_phase() -> void:
	if not is_boss or _phase >= 2:
		return
	var threshold := float(data["phase_2_at_health_fraction"])
	if health / maxf(max_health, 1.0) <= threshold:
		_phase = 2
		_queue.clear()   # a fase 2 muda PADROES, nao numeros


func _begin_pattern() -> void:
	# Anti-kite tem prioridade: 4 s sem alcancar o alvo -> golpe de fecho.
	if _anti_kite_ready():
		for id: String in _attacks.keys():
			if bool(_attacks[id].get("anti_kite_only", false)):
				_queue = [id]
				_no_reach_time = 0.0
				_start_next_attack()
				return

	var phase := _current_phase_data()
	var patterns: Array = phase.get("patterns", [])
	if patterns.is_empty():
		return
	var chosen: Array = patterns[_rng.randi_range(0, patterns.size() - 1)]
	_queue = []
	for id: Variant in chosen:
		# Um golpe so-anti-kite nunca entra num padrao normal.
		if not bool(_attacks.get(String(id), {}).get("anti_kite_only", false)):
			_queue.append(String(id))
	_start_next_attack()


func _start_next_attack() -> void:
	if _queue.is_empty():
		var phase := _current_phase_data()
		_gap_timer = float(phase["gap_between_patterns"])
		_change_state(State.CHASE)
		return
	var id: String = _queue.pop_front()
	var next_attack: Dictionary = _attacks.get(id, {}) as Dictionary
	if next_attack.is_empty():
		_start_next_attack()
		return
	_begin_attack(next_attack)


func _begin_attack(attack: Dictionary) -> void:
	_cancel_attack_presentation()
	_atk = attack
	_plan_false_recovery(attack)
	_atk_frame = 0
	_atk_hit = false
	_last_attack_hit_frame = -9999
	_active_gameplay_cue = GameplayCueRenderer.new()
	# O GameplayCue externo conserva a geometria, mas o perfil genérico de cinco
	# sons fica vazio: a assinatura sintetizada abaixo é específica deste golpe.
	var visual_attack := _atk.duplicate(true)
	var visual_sound := (visual_attack.get("som_anuncio", {}) as Dictionary).duplicate(true)
	visual_sound["profile"] = ""
	visual_attack["som_anuncio"] = visual_sound
	_active_gameplay_cue.call("configure", self, visual_attack)
	add_child(_active_gameplay_cue)
	if is_instance_valid(_attack_audio):
		_attack_audio.call("announce", _atk)
	_change_state(State.ATTACK)
	_set_attack_phase(AttackPhase.PREPARATION, 0.0)


func _cancel_attack_presentation() -> void:
	_planned_false_recovery = {}
	if is_instance_valid(_active_gameplay_cue):
		_active_gameplay_cue.call("cancel")
	if is_instance_valid(_attack_audio):
		_attack_audio.call("cancel")


func _tick_attack(delta: float) -> void:
	_atk_frame += 1
	var startup := int(_atk["startup"])
	var active := int(_atk["active"])
	var recovery := int(_atk["recovery"])

	if _atk_frame <= startup:
		_set_attack_phase(AttackPhase.PREPARATION,
			float(_atk_frame) / float(maxi(startup, 1)))
		_brake(delta)
		var commitment_frame := int(_atk.get("momento_compromisso_frame"))
		var tracking_curve: Dictionary = _atk.get("curva_seguimento") as Dictionary
		var tracking_phase := "fase_1_deg_s" if _atk_frame <= commitment_frame \
			else "fase_2_deg_s"
		_face_target(delta, float(tracking_curve.get(tracking_phase)))
		return

	if _atk_frame == startup + 1 and not AttackCoordinator.can_enter_active(target, self, active):
		# A cunha quebra antes da hitbox: cancelar é honesto; deixar o segundo
		# golpe entrar durante hit-stun seria stunlock (spec/38 §3).
		_cancel_attack_presentation()
		_gap_timer = float((data.get("attack_coordination", {}) as Dictionary).get(
			"retry_delay_s", 0.0))
		_atk = {}
		_change_state(State.CHASE)
		return

	if _atk_frame <= startup + active:
		_set_attack_phase(AttackPhase.STRIKE,
			float(_atk_frame - startup) / float(maxi(active, 1)))
		var lunge := float(_atk["lunge_distance"])
		if lunge > 0.0:
			var f := -global_transform.basis.z
			var lunge_speed := lunge / (float(active) / _reference_fps()) \
				* float(_atk["lunge_velocity_multiplier"])
			velocity.x = f.x * lunge_speed
			velocity.z = f.z * lunge_speed
		else:
			_brake(delta)
		var persistent := String(_atk.get("tipo_contacto", "")) == "volume_persistente"
		var interval := int(_atk["damage_interval_frames"]) if persistent else 1
		if not _atk_hit or (persistent and _atk_frame - _last_attack_hit_frame >= interval):
			_try_hit()
		return

	_set_attack_phase(AttackPhase.RECOVERY,
		float(_atk_frame - startup - active) / float(maxi(recovery, 1)))
	_brake(delta)
	if _atk_frame >= startup + active + recovery:
		if _try_begin_false_recovery_followup():
			return
		var follow: Variant = _atk.get("followup", null)
		if follow != null:
			_begin_attack(follow as Dictionary)
			return
		_start_next_attack()


func _plan_false_recovery(attack: Dictionary) -> void:
	_planned_false_recovery = {}
	var rule: Dictionary = attack.get("false_recovery", {}) as Dictionary
	if rule.is_empty() or not bool(rule.get("chosen_before_tell", false)):
		return
	if _rng.randf_range(0.0, float(rule.get("variant_roll_max"))) \
			< float(rule.get("variant_weight_pct")):
		_planned_false_recovery = rule.duplicate(true)


func _try_begin_false_recovery_followup() -> bool:
	if _planned_false_recovery.is_empty() or not _target_valid():
		_planned_false_recovery = {}
		return false
	var rule := _planned_false_recovery
	_planned_false_recovery = {}
	if _distance_to_target() > float(rule.get("trigger_range_m")):
		return false
	var followup_id := String(rule.get("optional_followup", ""))
	var followup: Dictionary = _attacks.get(followup_id, {}) as Dictionary
	if followup.is_empty():
		return false
	_begin_attack(followup)
	return true


func _try_hit() -> void:
	if not _target_valid():
		return
	var weight := String(_atk.get("weight", "light"))
	var raw := float(_atk.get("damage"))
	if raw <= 0.0:
		return

	# A forma que o jogador vê é a única hitbox. Sem cue visível, ou fora do
	# polígono exacto que o cue desenhou a partir da ficha, não existe contacto.
	if not is_instance_valid(_active_gameplay_cue) \
			or not _active_gameplay_cue.has_method("covers_world_point") \
			or not bool(_active_gameplay_cue.call(
				"covers_world_point", target.global_position)):
		# ⚠️ 02-08: o merge deixou este `if` SEM CORPO e o ficheiro deixou de
		# compilar — o auto-teste passou de 3 minutos a nunca acabar. O que
		# faltava era esta linha, e ela e a regra toda: fora da forma que o
		# jogador VE, nao ha contacto nenhum. E o achado nº1 da revisao de
		# codigo — "a geometria de dano mente ao jogador" — fechado aqui.
		return

	# ⛔ O cone abaixo deixou de ser autoridade: e apenas um segundo travao.
	# Um golpe tem de passar NAS DUAS coisas — a forma visivel primeiro.
	var hit := false
	if bool(_atk.get("is_aoe", false)):
		hit = _distance_to_target() <= float(_atk["radius"])
	else:
		var to := target.global_position - global_position
		to.y = 0.0
		var reach := float(_atk["range"]) + body_radius
		if to.length() <= reach:
			var facing := -global_transform.basis.z
			hit = facing.angle_to(to.normalized()) <= deg_to_rad(float(
				_atk["arc_degrees"]) * 0.5)

	if not hit:
		return
	_atk_hit = true
	_last_attack_hit_frame = _atk_frame

	var info := DamageInfo.make(raw, self, weight)
	info.parryable = bool(_atk.get("parryable", false))
	info.is_aoe = bool(_atk.get("is_aoe", false))
	info.shield_pierce_fraction = clampf(float(_atk["shield_pierce_fraction"]), 0.0, 1.0)
	info.guard_stamina_multiplier = maxf(float(_atk["guard_stamina_multiplier"]), 1.0)
	info.attack_id = String(_atk.get("id", ""))
	if target.has_method("take_damage"):
		var health_before := float(target.get("health")) if target.get("health") != null else -1.0
		target.call("take_damage", info)
		var health_after := float(target.get("health")) if target.get("health") != null else -1.0
		if health_before >= 0.0 and health_after < health_before:
			hit_landed.emit(target, health_before - health_after, global_position)
		_refresh_target_actionability()
		if target.has_method("state_name") and String(target.call("state_name")) == "hit-stun":
			var reference_fps := _reference_fps()
			var hitstun_frames := ceili(info.hitstun_seconds(GameData.section("hitstun")) * reference_fps)
			AttackCoordinator.record_hitstun(target, hitstun_frames,
				data.get("attack_coordination", {}) as Dictionary, reference_fps)


# --- Levar dano ---------------------------------------------------------------

func take_damage(info: DamageInfo) -> void:
	if state == State.DEAD:
		return

	var previous_health := health
	health = maxf(0.0, health - info.amount)
	health_changed.emit(health, max_health, health - previous_health, info.attacker)
	if health <= 0.0:
		_die()
		return

	# Postura: so cai quando o inimigo esta a agir ou de pe; o cambaleio devolve o turno.
	posture = maxf(0.0, posture - info.posture_damage * posture_mult)
	if posture <= 0.0 and state != State.BROKEN:
		Sfx.play("posture_break", global_position, -2.0)
		_cancel_attack_presentation()
		_change_state(State.STAGGER)


func _die() -> void:
	_cancel_attack_presentation()
	_change_state(State.DEAD)
	velocity = Vector3.ZERO
	hitstop_frames = 0
	collision_layer = 0
	remove_from_group("enemies")

	# O cadáver é um estado persistente para a necromancia. Aplica a pose e a
	# apresentação uma vez antes de parar este CharacterBody: os filhos continuam
	# a processar Death01 até ao fim, mas a IA, a gravidade e a navegação deixam de
	# deslocar o corpo e a animação não volta a arrancar em ciclo.
	_refresh_colour()
	_refresh_animation()
	set_physics_process(false)
	Sfx.play("enemy_death", global_position)
	died.emit(self)


## O parry acertou: postura quebrada 2,0 s, exposto ao riposte.
func on_parried() -> void:
	if state == State.DEAD:
		return
	posture = 0.0
	_cancel_attack_presentation()
	_change_state(State.BROKEN)


func is_posture_broken() -> bool:
	return state == State.BROKEN or state == State.STAGGER


func is_alive() -> bool:
	return state != State.DEAD


func full_reset() -> void:
	_cancel_attack_presentation()
	set_physics_process(true)
	var previous_health := health
	health = max_health
	health_changed.emit(health, max_health, health - previous_health, null)
	posture = max_posture
	_phase = 1
	_queue.clear()
	_atk = {}
	_gap_timer = 0.0
	_no_reach_time = 0.0
	global_position = home + _spawn_offset
	velocity = Vector3.ZERO
	collision_layer = 4
	if not is_in_group("enemies"):
		add_to_group("enemies")
	_change_state(State.PATROL if not _patrol_points.is_empty() else State.IDLE)


# --- Leitura visual -----------------------------------------------------------

func _refresh_colour() -> void:
	if _visual == null:
		return
	# Os monstros ja trazem pele, couro e metal pintados na textura. O tom plano
	# usado pelos antigos corpos-base escurecia todos esses materiais e apagava a
	# leitura da silhueta. Branco preserva a arte; os estados continuam a tingir.
	var colour := Color.WHITE

	match state:
		State.DEAD:
			# A textura já comunica o corpo. Escurecê-la 70% fazia a pele, couro e
			# metal parecerem pretos, sobretudo fora da luz directa.
			colour = Color.WHITE
		State.BROKEN:
			colour = Color(String(_palette.get("enemy_broken_posture", "#ffffff")))
		State.STAGGER:
			colour = Color(String(_palette.get("enemy_stagger", "#f2f2f2")))
		State.ATTACK:
			var startup := int(_atk["startup"])
			if _atk_frame <= startup:
				# Amarelo a crescer: quanto mais perto do golpe, mais forte o aviso.
				var t := clampf(float(_atk_frame) / float(maxi(startup, 1)), 0.0, 1.0)
				colour = colour.lerp(Color(String(_palette.get("enemy_telegraph", "#e8c33a"))), 0.35 + 0.65 * t)
			elif _atk_frame <= startup + int(_atk["active"]):
				colour = Color(String(_palette.get("enemy_attacking", "#d64545")))
	_visual.call("set_tint", colour)


func _refresh_animation() -> void:
	if _visual == null:
		return
	match state:
		State.DEAD:
			_play_state_animation("death")
		State.ATTACK:
			var attack_frames := int(_atk["startup"]) \
				+ int(_atk["active"]) + int(_atk["recovery"])
			_play_state_animation("attack", attack_frames, String(_atk.get("id", "")))
		State.STAGGER, State.BROKEN:
			_play_state_animation("hit", 0, str(state))
		State.CHASE:
			_play_state_animation("chase")
		State.PATROL:
			_play_state_animation("patrol")
		_:
			_play_state_animation("idle")


func _play_state_animation(state_key: String, target_frames := 0,
		request_suffix := "") -> void:
	var profile := CharacterVisual.animation_state_profile("enemy", state_key, enemy_id)
	var animation_name := String(profile.get("clip", ""))
	if animation_name.is_empty():
		return
	var request := "%s|%s|%d|%s" % [state_key, enemy_id, target_frames, request_suffix]
	var looped := bool(profile.get("loop", false))
	if request == _visual_animation_request and not looped:
		return
	_visual_animation_request = request
	var speed := CharacterVisual.animation_playback_speed(profile, target_frames)
	_visual.call("play_animation", animation_name, speed)


## Para o HUD: o golpe em preparacao da-se para aparar?
func telegraphing_parryable() -> int:
	if state != State.ATTACK or _atk_frame > int(_atk["startup"]):
		return -1
	return 1 if bool(_atk.get("parryable", false)) else 0


func state_name() -> String:
	match state:
		State.IDLE: return "livre"
		State.PATROL: return "patrulha"
		State.CHASE: return "persegue"
		State.ATTACK:
			match _attack_phase:
				AttackPhase.PREPARATION: return "preparacao"
				AttackPhase.STRIKE: return "golpe"
				AttackPhase.RECOVERY: return "recuperacao"
			return "ataque"
		State.STAGGER: return "cambaleio"
		State.BROKEN: return "postura quebrada"
		State.DEAD: return "morto"
	return "?"


func display_name() -> String:
	return String(data.get("display_name", enemy_id))


## Provocacao do Tanque (WP3): atencao forcada no provocador. A solo acorda
## quem patrulha; em co-op sera a fixacao de alvo. Simples e legivel.
func taunt(by: Node3D, _seconds: float) -> void:
	if state == State.DEAD:
		return
	target = by
	if state == State.IDLE or state == State.PATROL:
		_change_state(State.CHASE)
