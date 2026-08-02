class_name Player
extends CharacterBody3D
## O jogador — a maquina de estados de spec/01-combate.md, frame a frame.
##
## PORQUE E QUE ISTO CORRE EM _physics_process:
## a spec escreve o combate em frames a 60 fps ("arranque 16 / activo 6 / recuperacao 18").
## O projecto fixa a fisica em 60 Hz, por isso 1 tick de fisica == 1 frame da spec, e as
## janelas ficam exactas mesmo que o render oscile. Um souls-like nao pode ter janelas
## que encolhem quando o fps cai — isso e injustica, nao estetica (Lei 4).
##
## Nenhum numero deste ficheiro esta escrito a mao: vem todo de res://data/.

const WorldBoundsTracker = preload("res://src/world/bounds.gd")
const WorldBoundsWarningScene = preload("res://src/world/bounds_warning.gd")
const SpellDeliveryFactoryScript = preload("res://src/spells/spell_delivery_factory.gd")
const SpellVfxResidencyScript = preload("res://src/vfx/spell_vfx_residency.gd")
const SpellCastVfxScript = preload("res://src/vfx/spell_cast_vfx.gd")
const CastingWeaponAttachScript = preload("res://src/visual/weapon_attach.gd")

signal died
signal state_changed(state: int)
signal casting_fallback(reason: String)
signal raise_requested(spell_id: String)

enum State { FREE, ATTACK, DODGE, BLOCK, PARRY, CASTING, HITSTUN, GUARD_BREAK, RIPOSTE, DEAD, USING_ITEM, ABILITY, MEDITATING, GRIP_SWITCH }

# Guarda de entrada: os valores vem de spec/25-controlo.md (WP1B), via data/combat.json.
var _buffer_life := 0
var _buffer_life_parry := 0
var hitstop_frames := 0

# --- Estado -------------------------------------------------------------------
var state := State.FREE
var state_frame := 0

var health := 0.0
var max_health := 0.0
var defense := 0.0
var flask_uses := 0
var flask_max := 0
var _ability: Dictionary = {}
var _ability_cd := 0.0
var _fury_time := 0.0
var attrs: Dictionary = {}
var class_id := "warrior"

var stamina := Stamina.new()
var mana := 0
var max_mana := 0
var meditation_uses := 0
var meditation_uses_max := 0
var selected_spell := ""
var favorite_spells: Array[String] = []

var main_weapon := ""
var offhand_weapon := ""
var _loadout_index := 0
var is_two_handed := false

var camera: PlayerCamera
var lock_on: LockOn
var input_enabled := true

# --- Ataque em curso ----------------------------------------------------------
var _atk: Dictionary = {}
var _atk_kind := ""          # light | heavy | bash | riposte
var _atk_weapon := ""
var _atk_startup := 0
var _atk_active := 0
var _atk_recovery := 0
var _atk_mv := 0.0
var _atk_hit: Array = []
var _charging := false
var _charge_frames := 0
var _combo_index := 0
var _attack_feedback := ""

# --- Esquiva ------------------------------------------------------------------
var _dodge_dir := Vector3.FORWARD
var _dodge_travelled := 0.0
var _dodge_recovery_extra := 0
var _load_can_dodge := true
var _load_can_run := true
var _load_can_sprint := true
var _load_max_speed := INF

# --- Magia --------------------------------------------------------------------
var _cast_spell: Dictionary = {}
var _cast_instrument: Dictionary = {}
var _cast_frames_total := 0
var _spell_vfx_residency: RefCounted
var _cast_flash: Node3D
var _casting_weapon_visual: Node3D
var _egide_shield := 0.0
var _egide_time := 0.0
var _meditation_start_mana := 0
var _meditation_frames_total := 0

# --- Entrada ------------------------------------------------------------------
var _buffered := ""
var _buffer_at := -999
var _space_held_frames := 0
var _sprinting := false
var _hitstun_frames := 0

var _visual: CharacterVisual
var _palette: Dictionary = {}
var _frame := 0
var _waking_up := false
var _resting := false
var _sitting_visual_started_at := 0
var _visual_previous_state := State.FREE
var _visual_transition_state := ""
var _visual_transition_started_at := 0
static var _casting_attack_self_test_ran := false

# --- Queda --------------------------------------------------------------------
var _fall_tracker: WorldBounds = WorldBoundsTracker.new()
var _fall_tracking_ready := false
var _load_fraction := 0.0
var death_stain_position := Vector3.ZERO
var _last_supported_position := Vector3.ZERO
var _has_supported_position := false


# --- Arranque -----------------------------------------------------------------

func _ready() -> void:
	if "--casting-attack-self-test" in OS.get_cmdline_user_args() \
			and not _casting_attack_self_test_ran:
		_casting_attack_self_test_ran = true
		_run_casting_attack_self_test()


func _reference_fps() -> float:
	return float(GameData.combat["reference_fps"])


func setup(p_class_id: String, palette: Dictionary, body_id := "body_male") -> void:
	class_id = p_class_id
	_palette = palette
	attrs = GameData.class_attributes(class_id).duplicate()

	max_health = GameData.max_health_for(int(attrs["vida"]))
	health = max_health
	defense = GameData.defense_for(int(attrs["constituicao"]))
	stamina.configure(GameData.section("stamina"), GameData.max_stamina_for(int(attrs["stamina"])))
	max_mana = GameData.max_mana_for(attrs)
	mana = max_mana
	var meditation: Dictionary = GameData.spells.get("_rules", {}).get("meditation", {}) as Dictionary
	meditation_uses_max = int(meditation["uses_per_rest"])
	meditation_uses = meditation_uses_max
	_meditation_frames_total = int(float(meditation["seconds"]) * _reference_fps())
	favorite_spells.clear()
	var spell_rules: Dictionary = GameData.spells.get("_rules", {}) as Dictionary
	for spell_id: Variant in spell_rules.get("default_favorites", []):
		favorite_spells.append(String(spell_id))
	if not selected_spell in favorite_spells and not favorite_spells.is_empty():
		selected_spell = favorite_spells[0]
	flask_max = int(GameData.section("flask")["uses"])
	flask_uses = flask_max
	_ability = GameData.ability(class_id)
	_ability_cd = 0.0
	_fury_time = 0.0

	var loadout: Dictionary = (GameData.weapons.get("loadouts", {}) as Dictionary).get(class_id, {})
	main_weapon = equipment_weapon_id(loadout.get("main"))
	offhand_weapon = equipment_weapon_id(loadout.get("offhand", ""))
	is_two_handed = _loadout_uses_two_hands(main_weapon, offhand_weapon)

	var buf := GameData.section("input_buffer")
	_buffer_life = int(float(buf["life_ms"]) * _reference_fps() / 1000.0)
	_buffer_life_parry = int(float(buf["parry_life_ms"]) * _reference_fps() / 1000.0)

	_build_body(body_id)
	_build_children()
	call_deferred("_install_world_bounds_warning")


func _build_body(body_id: String) -> void:
	var cfg := GameData.section("player")
	var height := float(cfg["capsule_height"])
	var radius := float(cfg["capsule_radius"])

	var capsule := CapsuleShape3D.new()
	capsule.height = height
	capsule.radius = radius
	var col := CollisionShape3D.new()
	col.shape = capsule
	col.position = Vector3(0, height * 0.5, 0)
	add_child(col)

	# A capsula acima continua a ser TODA a fisica. O corpo Quaternius e visual,
	# mede os mesmos 1,8 m e usa animacao sem root motion.
	_visual = CharacterVisual.new()
	add_child(_visual)
	_visual.setup(height, Color.WHITE, true, body_id)

	collision_layer = 2
	collision_mask = 1
	add_to_group("player")


func _build_children() -> void:
	lock_on = LockOn.new()
	lock_on.name = "LockOn"
	add_child(lock_on)
	lock_on.setup(self, GameData.section("lock_on"))


# --- Ciclo --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_frame += 1

	# Paragem de impacto: congela ESTE corpo, nao o mundo. O frame continua a
	# desenhar-se, so a logica e que espera — e dai vir a sensacao de peso.
	if hitstop_frames > 0:
		hitstop_frames -= 1
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		evaluate_fall_sample(global_position.y, is_on_floor())
		return

	state_frame += 1

	if state != State.DEAD:
		if input_enabled:
			_read_input()
			lock_on.tick(delta)
		else:
			_buffered = ""
		stamina.tick(delta, state == State.BLOCK)
		if _ability_cd > 0.0:
			_ability_cd = maxf(0.0, _ability_cd - delta)
		if _fury_time > 0.0:
			_fury_time = maxf(0.0, _fury_time - delta)
		if _egide_time > 0.0:
			_egide_time -= delta
			if _egide_time <= 0.0:
				_egide_shield = 0.0

	_tick_state(delta)
	_apply_gravity(delta)
	move_and_slide()
	evaluate_fall_sample(global_position.y, is_on_floor())
	_refresh_colour()
	_refresh_animation()

	if camera != null:
		camera.lock_target = lock_on.target


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 20.0) * delta
	else:
		velocity.y = minf(velocity.y, 0.0)


func reset_fall_tracking(height_m: float, fall_config := {}) -> void:
	var config: Dictionary = fall_config as Dictionary
	if config.is_empty():
		config = GameData.progression.get("fall", {}) as Dictionary
	_fall_tracker.reset(height_m, config)
	_fall_tracking_ready = true


func evaluate_fall_sample(height_m: float, grounded: bool) -> void:
	if state == State.DEAD:
		return
	if not _fall_tracking_ready:
		reset_fall_tracking(height_m)
	var outcome := _fall_tracker.sample(height_m, grounded)
	if grounded:
		_last_supported_position = global_position
		_has_supported_position = true
	match outcome:
		WorldBounds.Outcome.DAMAGE:
			var amount := GameData.fall_damage(
				_fall_tracker.last_drop_m, max_health, _load_fraction)
			_apply_raw_health_loss(amount)
		WorldBounds.Outcome.FATAL:
			_die(_last_supported_position if _has_supported_position else global_position)


func _install_world_bounds_warning() -> void:
	if "--bounds-warning=off" in OS.get_cmdline_user_args():
		return
	var gameplay := get_parent()
	if gameplay == null:
		return
	var world := gameplay.get_node_or_null("World") as Node3D
	if world == null or world.has_node("WorldBoundsWarning"):
		return
	var path_value: Variant = world.get("path_points")
	if not path_value is Array or (path_value as Array).is_empty():
		return
	var map_reading: Dictionary = GameData.world.get("map_reading", {}) as Dictionary
	var runtime: Dictionary = map_reading.get("runtime", {}) as Dictionary
	var traversal: Dictionary = GameData.world.get("_traversal_rules", {}) as Dictionary
	var warning: WorldBoundsWarning = WorldBoundsWarningScene.new()
	warning.name = "WorldBoundsWarning"
	world.add_child(warning)
	warning.setup(runtime, _palette, traversal)


# --- Entrada ------------------------------------------------------------------

func _read_input() -> void:
	if Input.is_action_just_pressed("attack"):
		_buffer("heavy" if Input.is_action_pressed("heavy_mod") else "light")
	if Input.is_action_just_pressed("parry"):
		_buffer("parry")
	if Input.is_action_just_pressed("cast"):
		_buffer("cast")
	if Input.is_action_just_pressed("meditate"):
		_buffer("meditate")
	if Input.is_action_just_pressed("use_item"):
		_buffer("flask")
	if Input.is_action_just_pressed("ability"):
		_buffer("ability")
	var raise_input_action := String(_ability.get("raise_input_action", ""))
	if not raise_input_action.is_empty() \
			and Input.is_action_just_pressed(raise_input_action):
		_buffer("raise_dead")
	if Input.is_action_just_pressed("toggle_grip"):
		_buffer("toggle_grip")
	if Input.is_action_just_pressed("lock_on"):
		lock_on.toggle()
	if Input.is_action_just_pressed("loadout_next"):
		_cycle_loadout(1)
	if Input.is_action_just_pressed("loadout_prev"):
		_cycle_loadout(-1)

	# Space: toque = esquiva, segurar = sprint (spec/01-combate.md, tabela de comandos).
	if Input.is_action_pressed("dodge_sprint"):
		_space_held_frames += 1
		if _space_held_frames > 9 and _move_input().length() > 0.1 and _load_can_sprint:
			_sprinting = true
	else:
		if _space_held_frames > 0 and _space_held_frames <= 9:
			_buffer("dodge")
		_space_held_frames = 0
		_sprinting = false

	# O pesado do machadao carrega-se enquanto se segura o botao.
	if _charging and not Input.is_action_pressed("attack"):
		_charging = false


## Capacidade 1: a entrada mais recente substitui a anterior — EXCEPTO que a
## esquiva no buffer nunca e substituida por um ataque. O pedido de sobrevivencia
## vence o pedido de dano (spec/25-controlo.md).
func _buffer(action: String) -> void:
	if _peek_buffer() == "dodge" and action != "dodge":
		return
	_buffered = action
	_buffer_at = _frame


func _buffer_expired() -> bool:
	if _buffered == "":
		return true
	var life := _buffer_life_parry if _buffered == "parry" else _buffer_life
	return _frame - _buffer_at > life


func _take_buffered() -> String:
	if _buffer_expired():
		return ""
	var a := _buffered
	_buffered = ""
	return a


func _move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")


# --- Maquina de estados -------------------------------------------------------

func _change_state(next: int) -> void:
	state = next
	state_frame = 0
	state_changed.emit(next)


func _tick_state(delta: float) -> void:
	match state:
		State.FREE:      _tick_free(delta)
		State.BLOCK:     _tick_block(delta)
		State.ATTACK:    _tick_attack(delta)
		State.DODGE:     _tick_dodge(delta)
		State.PARRY:     _tick_parry(delta)
		State.CASTING:   _tick_casting(delta)
		State.RIPOSTE:   _tick_riposte(delta)
		State.USING_ITEM: _tick_flask(delta)
		State.ABILITY:   _tick_ability(delta)
		State.MEDITATING: _tick_meditating(delta)
		State.GRIP_SWITCH: _tick_grip_switch(delta)
		State.HITSTUN:   _tick_locked(delta, _hitstun_frames)
		State.GUARD_BREAK:
			_tick_locked(delta, int(float(GameData.section("block")["guard_break_duration"]) \
				* _reference_fps()))
		State.DEAD:
			velocity.x = 0.0
			velocity.z = 0.0


func _tick_free(delta: float) -> void:
	_move(delta, _speed_for_mode())

	if Input.is_action_pressed("block") and _can_block():
		_change_state(State.BLOCK)
		return

	match _take_buffered():
		"light":  use_primary_attack()
		"heavy":  _start_attack("heavy")
		"dodge":  _start_dodge()
		"parry":  _start_parry()
		"cast":   _start_cast()
		"meditate": _start_meditation()
		"flask":  _start_flask()
		"ability": _start_ability()
		"raise_dead": _request_raise_dead()
		"toggle_grip": _start_grip_switch()


func _tick_block(delta: float) -> void:
	_move(delta, float(GameData.section("movement")["walk_speed"]))
	if not Input.is_action_pressed("block") or not _can_block():
		_change_state(State.FREE)
		return
	# Ataque leve com o escudo levantado = bash (spec da o bash ao escudo mas nao lhe da botao).
	match _take_buffered():
		"light":
			if offhand_weapon == "shield" and not is_two_handed:
				_start_attack("bash")
			else:
				use_primary_attack()
		"heavy": _start_attack("heavy")
		"dodge": _start_dodge()
		"parry": _start_parry()


func _tick_locked(delta: float, total_frames: int) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)
	if state_frame >= total_frames:
		_change_state(State.FREE)


# --- Movimento ----------------------------------------------------------------

func _speed_for_mode() -> float:
	var m := GameData.section("movement")
	if _sprinting and stamina.can_act() and _load_can_sprint:
		return minf(float(m["sprint_speed"]), _load_max_speed)
	if is_instance_valid(lock_on.target):
		var input := _move_input()
		# Andar de lado ou para tras com alvo engatado e mais lento — e o strafe da spec.
		if absf(input.x) > 0.3 or input.y > 0.3:
			return minf(float(m["strafe_speed"]), _load_max_speed)
	var free_speed := float(m["run_speed"] if _load_can_run else m["walk_speed"])
	return minf(free_speed, _load_max_speed)


var _step_accum := 0.0

func _move(delta: float, speed: float) -> void:
	var input := _move_input()
	# Passos: um toque por ~2,1 m andados. O ritmo acelera sozinho com a velocidade.
	if is_on_floor():
		_step_accum += Vector2(velocity.x, velocity.z).length() * delta
		if _step_accum >= 2.1:
			_step_accum = 0.0
			Sfx.play("step", null, -6.0, 0.15)
	var dir := Vector3.ZERO
	if camera != null and input.length() > 0.05:
		dir = (camera.right_flat() * input.x + camera.forward_flat() * -input.y).normalized()

	if dir.length() > 0.05:
		if _sprinting and state == State.FREE:
			stamina.spend(float(GameData.section("movement")["sprint_stamina_per_second"]) * delta)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_face(dir if not is_instance_valid(lock_on.target) else _to_target())
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 40.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 40.0)
		if is_instance_valid(lock_on.target):
			_face(_to_target())


func _to_target() -> Vector3:
	if not is_instance_valid(lock_on.target):
		return -global_transform.basis.z
	var d := lock_on.target.global_position - global_position
	d.y = 0.0
	return d.normalized()


func _face(dir: Vector3) -> void:
	if dir.length_squared() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.35)


func _facing() -> Vector3:
	return -global_transform.basis.z


# --- Esquiva ------------------------------------------------------------------

func _start_dodge() -> void:
	if not stamina.can_act() or not _load_can_dodge:
		return
	var cfg := GameData.section("dodge")
	if _fury_time > 0.0:
		return   # Furia: sem esquiva — o preco da armadura
	stamina.spend(float(cfg["stamina_cost"]))
	Sfx.play("dodge", null, -6.0)

	var input := _move_input()
	if input.length() > 0.15 and camera != null:
		_dodge_dir = (camera.right_flat() * input.x + camera.forward_flat() * -input.y).normalized()
	else:
		_dodge_dir = -_facing()   # sem direccao: para tras (spec)
	_face(_dodge_dir if not is_instance_valid(lock_on.target) else _to_target())
	_dodge_travelled = 0.0
	_change_state(State.DODGE)


func _tick_dodge(delta: float) -> void:
	var cfg := GameData.section("dodge")
	var total := int(cfg["duration_frames"])
	var distance := float(cfg["distance"])

	# Curva de saida: rapido no arranque, a morrer no fim. O integral da exactamente 3,5 m.
	var t := clampf(float(state_frame) / float(total), 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 2.0)
	var wanted := distance * eased
	var step := wanted - _dodge_travelled
	_dodge_travelled = wanted

	velocity.x = _dodge_dir.x * (step / delta)
	velocity.z = _dodge_dir.z * (step / delta)

	if state_frame >= total + _dodge_recovery_extra:
		_change_state(State.FREE)
		return
	if state_frame >= total:
		velocity.x = move_toward(velocity.x, 0.0, delta * 40.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 40.0)
		return

	# Cancelavel a partir de 0,45 s, em ataque leve / bloqueio / nova esquiva.
	if state_frame >= int(cfg["cancel_from_frame"]):
		match _take_buffered():
			"light": _start_attack("light")
			"dodge": _start_dodge()
			_:
				if Input.is_action_pressed("block") and _can_block():
					_change_state(State.BLOCK)


func has_iframes() -> bool:
	if state == State.RIPOSTE:
		return true
	if state != State.DODGE:
		return false
	var cfg := GameData.section("dodge")
	return state_frame >= int(cfg["iframe_start_frame"]) \
		and state_frame <= int(cfg["iframe_end_frame"])


# --- Parry --------------------------------------------------------------------

func _can_parry() -> bool:
	var list: Array = GameData.section("parry").get("weapons_that_parry", [])
	return list.has(main_weapon) or (not is_two_handed and list.has(offhand_weapon))


func _start_parry() -> void:
	if not _can_parry() or not stamina.can_act():
		return
	stamina.spend(float(GameData.section("parry")["stamina_cost"]))
	_change_state(State.PARRY)


func parry_window_open() -> bool:
	if state != State.PARRY:
		return false
	var cfg := GameData.section("parry")
	var start := int(cfg["startup_frames"])
	return state_frame >= start and state_frame < start + int(cfg["active_frames"])


func _tick_parry(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 24.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 24.0)
	if is_instance_valid(lock_on.target):
		_face(_to_target())
	var cfg := GameData.section("parry")
	var total := int(cfg["startup_frames"]) + int(cfg["active_frames"]) \
		+ int(cfg["whiff_recovery_frames"])
	if state_frame >= total:
		_change_state(State.FREE)


func _start_riposte(target: Node3D) -> void:
	var cfg := GameData.section("parry")
	_atk_mv = float(cfg["riposte_mv"])
	_atk_weapon = main_weapon
	_atk_kind = "riposte"   # senao herdava o peso do golpe anterior no hit-stun
	_atk = {}
	_atk_hit = []
	if is_instance_valid(target):
		_face((target.global_position - global_position).normalized())
		# O riposte acerta de certeza: e a recompensa do parry.
		_deal_damage_to(target, _atk_mv, main_weapon, false)
	_change_state(State.RIPOSTE)


func _tick_riposte(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	var frames := int(float(GameData.section("parry")["riposte_duration"]) * _reference_fps())
	if state_frame >= frames:
		_change_state(State.FREE)


# --- Bloqueio -----------------------------------------------------------------

func _block_source() -> String:
	if not is_two_handed and offhand_weapon == "shield":
		return "shield"
	var w := GameData.weapon(main_weapon)
	if bool(w.get("can_block", false)):
		return "onehand"
	return ""


# --- Empunhadura --------------------------------------------------------------

func _start_grip_switch() -> void:
	# Armas de duas maos nao podem entrar num estado que viola o seu requisito.
	if int(GameData.weapon(main_weapon).get("hands", 1)) >= 2:
		return
	_change_state(State.GRIP_SWITCH)


func _tick_grip_switch(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)
	var frames := int(GameData.section("grip")["switch_frames"])
	if state_frame >= frames:
		is_two_handed = not is_two_handed
		_combo_index = 0
		_change_state(State.FREE)


func grip_uses_offhand() -> bool:
	return not is_two_handed and offhand_weapon != ""


func _can_block() -> bool:
	return _block_source() != "" and _fury_time <= 0.0


# --- Ataques ------------------------------------------------------------------

func _start_attack(kind: String, feedback := "") -> void:
	if not stamina.can_act():
		return
	_attack_feedback = feedback

	# Um leve sobre um inimigo de postura quebrada vira riposte (spec: MV 2,5, com i-frames).
	if kind == "light":
		var broken := _broken_posture_target()
		if broken != null:
			_start_riposte(broken)
			return

	var weapon_id := main_weapon
	var data: Dictionary
	if kind == "bash":
		weapon_id = "shield"
		data = GameData.weapon("shield").get("bash", {})
	else:
		data = GameData.weapon(main_weapon).get(kind, {})
	if data.is_empty():
		return

	_atk = data
	_atk_kind = kind
	_atk_weapon = weapon_id
	_atk_startup = int(data["startup"])
	_atk_active = int(data["active"])
	_atk_recovery = int(data["recovery"])
	_atk_mv = float(data["mv"])
	Sfx.play("swing_heavy" if kind == "heavy" else "swing_light", null, -4.0)
	_atk_hit = []
	_charge_frames = 0
	_charging = bool(data.get("chargeable", false)) and Input.is_action_pressed("attack")

	# Combo: encadear leves aumenta o indice; o ultimo golpe tem MV proprio.
	if kind == "light":
		var combo: Dictionary = GameData.weapon(main_weapon).get("combo", {})
		var max_combo := int(combo["max"])
		_combo_index = mini(_combo_index + 1, max_combo)
		if _combo_index >= max_combo and combo.get("final_mv") != null:
			_atk_mv = combo.get("final_mv")
	else:
		_combo_index = 0

	stamina.spend(float(data["stamina"]))
	if is_instance_valid(lock_on.target):
		_face(_to_target())
	_change_state(State.ATTACK)
	# Ha um unico escritor da pose durante o golpe. O controlador UAL recebe a
	# ficha agora (nao um frame de render depois) e sincroniza-a pelo state_frame;
	# os tres tempos continuam a vir exclusivamente de weapons.json.
	var attack_animation := _attack_animation_controller()
	if attack_animation != null:
		attack_animation.call("play_attack", _atk_weapon, _atk_kind,
			_combo_index, _sprinting, _atk)


func _tick_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 14.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 14.0)

	var startup := _atk_startup + _charge_frames

	# Carregar o pesado do machadao: +20 f no maximo, MV sobe de 2,4 para 3,0.
	if _charging and state_frame >= _atk_startup:
		var max_charge := int(_atk["charge_max_frames"])
		if _charge_frames < max_charge and Input.is_action_pressed("attack"):
			_charge_frames += 1
			var t := float(_charge_frames) / float(max_charge)
			_atk_mv = lerpf(float(_atk["mv"]), float(_atk["charge_max_mv"]), t)
			return
		_charging = false

	if state_frame > startup and state_frame <= startup + _atk_active:
		_hit_query()

	var total := startup + _atk_active + _atk_recovery
	if state_frame >= total:
		_combo_index = 0
		_change_state(State.FREE)
		return

	# Recuperacao: janela de combo nos ultimos 40%, cancelamento a partir dos 60%.
	if state_frame > startup + _atk_active:
		var into_recovery := state_frame - (startup + _atk_active)
		var rules := GameData.section("attack_rules")
		var combo_open := float(into_recovery) >= float(_atk_recovery) * (1.0 \
			- float(rules["combo_window_fraction_of_recovery"]))
		var cancel_open := float(into_recovery) >= float(_atk_recovery) \
			* float(rules["cancel_threshold_fraction_of_recovery"])

		var combo: Dictionary = GameData.weapon(main_weapon).get("combo", {})
		if combo_open and _atk_kind == "light" and _combo_index < int(combo["max"]):
			if _peek_buffer() == "light":
				_take_buffered()
				use_primary_attack()
				return

		# So o LEVE se cancela. O pesado e compromisso total (spec).
		if cancel_open and _atk_kind != "heavy":
			match _peek_buffer():
				"dodge":
					_take_buffered()
					_start_dodge()
					return
			if Input.is_action_pressed("block") and _can_block():
				_change_state(State.BLOCK)


func _peek_buffer() -> String:
	return "" if _buffer_expired() else _buffered


func has_hyper_armor() -> bool:
	if state == State.CASTING and bool(_cast_spell.get("hyper_armor_while_casting", false)):
		return true
	# A Egide da hiper-armadura enquanto a barreira durar, nao so a conjurar (WP4).
	if _egide_shield > 0.0 and _egide_time > 0.0:
		return true
	# Furia (Berserker, WP3): hiper-armadura em tudo enquanto durar — o preco e
	# nao poder bloquear nem esquivar. Troca defesa por avanco, nao da numeros.
	if _fury_time > 0.0:
		return true
	if state != State.ATTACK or not bool(_atk.get("chargeable", false)):
		return false
	# Hiper-armadura do frame 30 ate ao fim dos frames activos (30-48 sem carga, e acompanha a carga).
	var start := int(_atk["hyper_armor_start_frame"])
	var finish := _atk_startup + _charge_frames + _atk_active
	return state_frame >= start and state_frame <= finish


func _hit_query() -> void:
	var weapon := GameData.weapon(_atk_weapon)
	var reach := float(weapon["range"])
	var arc := deg_to_rad(float(weapon["arc_degrees"]))
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Node3D
		if e == null or _atk_hit.has(e):
			continue
		if e.has_method("is_alive") and not e.call("is_alive"):
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		var enemy_radius := float(e.get("body_radius"))
		if to.length() > reach + enemy_radius:
			continue
		if _facing().angle_to(to.normalized()) > arc * 0.5:
			continue
		_atk_hit.append(e)
		Sfx.play("hit_flesh", e.global_position)
		_deal_damage_to(e, _atk_mv, _atk_weapon, _atk_kind == "bash")


func _deal_damage_to(e: Node3D, mv: float, weapon_id: String, is_bash: bool) -> void:
	if not e.has_method("take_damage"):
		return
	var target_def: float = e.get("defense") if e.get("defense") != null else 0.0
	var info := DamageInfo.make(GameData.compute_damage(mv, weapon_id, attrs, target_def), self,
		"heavy" if _atk_kind == "heavy" else "light")
	var posture_mult := float(GameData.section("poise")["standard_posture_multiplier"])
	if is_bash:
		posture_mult = float(GameData.section("poise")["shield_bash_posture_multiplier"])
	info.posture_damage = GameData.posture_damage_from_mv(mv, posture_mult)
	e.call("take_damage", info)

	# Paragem de impacto: o peso do machadao vem daqui, nao do dano.
	var hs := GameData.section("hit_stop")
	var frames := int(hs["heavy_hit"] if info.weight == "heavy" else hs["light_hit"])
	if e.has_method("is_alive") and not e.call("is_alive"):
		frames = int(hs["killing_blow"])
	_freeze(frames)
	if e.get("hitstop_frames") != null:
		e.set("hitstop_frames", frames)


func _freeze(frames: int) -> void:
	hitstop_frames = maxi(hitstop_frames, frames)


func _broken_posture_target() -> Node3D:
	var parry := GameData.section("parry")
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Node3D
		if e == null or not e.has_method("is_posture_broken"):
			continue
		if not bool(e.call("is_posture_broken")):
			continue
		var to := e.global_position - global_position
		to.y = 0.0
		if to.length() <= float(parry["riposte_range_m"]) \
				and _facing().angle_to(to.normalized()) < deg_to_rad(float(
					parry["riposte_half_angle_degrees"])):
			return e
	return null


# --- Magia --------------------------------------------------------------------

func _start_meditation() -> void:
	if mana >= max_mana or meditation_uses <= 0:
		return
	meditation_uses -= 1
	_meditation_start_mana = mana
	_change_state(State.MEDITATING)


func _tick_meditating(delta: float) -> void:
	# A reserva volta de forma linear: se houver interrupcao, o que ja entrou fica.
	velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)
	var progress := clampf(float(state_frame) / maxf(float(_meditation_frames_total), 1.0), 0.0, 1.0)
	mana = maxi(mana, roundi(lerpf(float(_meditation_start_mana), float(max_mana), progress)))
	if state_frame >= _meditation_frames_total:
		mana = max_mana
		_change_state(State.FREE)

func cycle_spell() -> void:
	if favorite_spells.is_empty():
		return
	var i := favorite_spells.find(selected_spell)
	selected_spell = favorite_spells[(i + 1) % favorite_spells.size()]


# Compatibilidade com os testes de combate que exercitam a maquina por dentro.
func _cycle_spell() -> void:
	cycle_spell()


func select_spell(spell_id: String) -> bool:
	if not favorite_spells.has(spell_id):
		return false
	selected_spell = spell_id
	return true


func cast_selected_spell() -> bool:
	if state != State.FREE:
		return false
	_buffer("cast")
	return true


func set_waking_up(enabled: bool) -> void:
	if enabled and not _waking_up:
		_sitting_visual_started_at = _frame
	elif not enabled and _waking_up:
		_start_visual_transition("sitting_exit")
	_waking_up = enabled
	input_enabled = not enabled and not _resting
	velocity = Vector3.ZERO


func set_resting(enabled: bool) -> void:
	if enabled and not _resting:
		_sitting_visual_started_at = _frame
	elif not enabled and _resting:
		_start_visual_transition("sitting_exit")
	_resting = enabled
	input_enabled = not enabled and not _waking_up
	velocity = Vector3.ZERO


func apply_inventory_state(equipment: Dictionary, load_profile: Dictionary) -> void:
	main_weapon = equipment_weapon_id(equipment.get("main", ""))
	offhand_weapon = equipment_weapon_id(equipment.get("offhand", ""))
	is_two_handed = _loadout_uses_two_hands(main_weapon, offhand_weapon)
	favorite_spells.clear()
	for spell_value: Variant in equipment.get("spell_favorites", []):
		favorite_spells.append(String(spell_value))
	if not favorite_spells.has(selected_spell):
		selected_spell = favorite_spells[0] if not favorite_spells.is_empty() else ""
	_dodge_recovery_extra = int(load_profile.get("recovery_frames", 0))
	_load_can_dodge = bool(load_profile.get("can_dodge", true))
	_load_can_run = bool(load_profile.get("can_run", true))
	_load_can_sprint = bool(load_profile.get("can_sprint", true))
	_load_max_speed = float(load_profile["max_speed"])
	_load_fraction = float(load_profile.get("fraction", 0.0))
	stamina.set_regen_multiplier(float(load_profile["regen_multiplier"]))


## A fronteira persistente guarda IDs. Alguns percursos antigos entregaram a
## carta inteira; normaliza-a uma vez sem converter Dictionary/null em texto.
static func equipment_weapon_id(value: Variant) -> String:
	if value == null:
		return ""
	if value is Dictionary:
		var card := value as Dictionary
		for field: String in ["id", "weapon_id", "catalogue_id", "item_id", "key"]:
			var candidate := String(card.get(field, ""))
			if candidate.begins_with("arma:"):
				candidate = candidate.trim_prefix("arma:")
			if not candidate.is_empty():
				return candidate
		return ""
	var candidate := String(value)
	return candidate.trim_prefix("arma:") if candidate.begins_with("arma:") \
		else candidate


## O ataque primario usa o instrumento activo, como uma arma usa o seu golpe leve.
## A pancada continua acessivel pelo pesado/duas maos e torna-se fallback sem mana.
## O retorno e deliberadamente observavel: o teste e a UI nao precisam de conhecer
## buffers nem a maquina de estados para explicar o que aconteceu ao jogador.
func use_primary_attack() -> String:
	var broken := _broken_posture_target()
	if broken != null:
		_start_riposte(broken)
		return "riposte"

	var s := GameData.spell(selected_spell)
	var instrument := _casting_instrument_for(s)
	if s.is_empty() or instrument.is_empty():
		_start_attack("light")
		return "melee"

	var cost := int(s.get("mana_cost"))
	if mana < cost:
		casting_fallback.emit("mana_insuficiente")
		_start_attack("light", "pancada: mana insuficiente")
		return "melee_no_mana"

	_start_cast(s, instrument)
	return "cast"


## O instrumento secundario tem prioridade. Enquanto os kits reais ainda trazem
## apenas um cajado `can_cast`, o mesmo catalogo tambem o reconhece na mao principal.
func _secondary_instrument_for(spell: Dictionary) -> Dictionary:
	# O catalogo define o instrumento secundario como metade do par
	# cajado + instrumento. Se o jogador trocar o cajado por uma arma, o clique
	# volta imediatamente a usar essa arma; o talisma/sino sozinho nao pode
	# continuar a desviar o ataque para a magia que estava equipada antes.
	if offhand_weapon == "" or is_two_handed or spell.is_empty() \
			or not bool(GameData.weapon(main_weapon).get("can_cast", false)):
		return {}
	return _instrument_for_weapon(offhand_weapon, spell)


func _loadout_uses_two_hands(main_id: String, offhand_id: String) -> bool:
	# A decisao mais recente emparelha o cajado principal com um instrumento na
	# secundaria. O `hands` historico do cajado continua a valer quando ele esta
	# sozinho, mas nao pode esconder a segunda metade do par decidido.
	if bool(GameData.weapon(main_id).get("can_cast", false)) \
			and _is_magic_instrument(offhand_id):
		return false
	return int(GameData.weapon(main_id).get("hands", 1)) >= 2


func _is_magic_instrument(weapon_id: String) -> bool:
	if weapon_id.is_empty():
		return false
	var instruments: Dictionary = GameData.equipment.get("magic_instruments", {}) as Dictionary
	for instrument_id: String in instruments:
		var instrument := instruments.get(instrument_id, {}) as Dictionary
		if weapon_id == instrument_id \
				or weapon_id == String(instrument.get("weapon_id", instrument_id)):
			return true
	return false


func _casting_instrument_for(spell: Dictionary) -> Dictionary:
	var secondary := _secondary_instrument_for(spell)
	if not secondary.is_empty():
		return secondary
	if not bool(GameData.weapon(main_weapon).get("can_cast", false)):
		return {}
	return _instrument_for_weapon(main_weapon, spell)


func _instrument_for_weapon(weapon: String, spell: Dictionary) -> Dictionary:
	if weapon.is_empty() or spell.is_empty():
		return {}
	var instruments: Dictionary = GameData.equipment.get("magic_instruments", {}) as Dictionary
	var school := String(spell.get("school", ""))
	for instrument_id: String in instruments:
		var instrument: Dictionary = instruments.get(instrument_id, {}) as Dictionary
		var weapon_id := String(instrument.get("weapon_id", instrument_id))
		if weapon != weapon_id and weapon != instrument_id:
			continue
		if not (instrument.get("school_tags", []) as Array).has(school):
			continue
		var equipped := instrument.duplicate()
		equipped["_instrument_id"] = instrument_id
		return equipped
	return {}


func casting_instrument_id() -> String:
	return String(_cast_instrument.get("_instrument_id", ""))


## Prova opt-in no ficheiro que esta arvore pode editar. Exercita a mesma API que
## a entrada usa e imprime um marcador unico para o comando falhar se ele faltar.
func _run_casting_attack_self_test() -> void:
	var s := GameData.spell(selected_spell)
	var instruments: Dictionary = GameData.equipment.get("magic_instruments", {}) as Dictionary
	var test_instrument_id := ""
	var test_weapon_id := ""
	for instrument_id: String in instruments:
		var candidate: Dictionary = instruments.get(instrument_id, {}) as Dictionary
		if (candidate.get("school_tags", []) as Array).has(String(s.get("school", ""))):
			test_instrument_id = instrument_id
			test_weapon_id = String(candidate.get("weapon_id", instrument_id))
			break
	if s.is_empty() or test_instrument_id == "" or test_weapon_id == "":
		push_error("[casting-attack-test] catalogo sem feitico/instrumento compativel")
		return

	var original := {
		"state": state,
		"state_frame": state_frame,
		"mana": mana,
		"main_weapon": main_weapon,
		"offhand_weapon": offhand_weapon,
		"is_two_handed": is_two_handed,
		"stamina": stamina.current,
		"atk": _atk,
		"atk_kind": _atk_kind,
		"atk_weapon": _atk_weapon,
		"attack_feedback": _attack_feedback,
		"cast_spell": _cast_spell,
		"cast_instrument": _cast_instrument,
		"cast_frames_total": _cast_frames_total,
	}
	var staff: Dictionary = instruments.get("cajado", {}) as Dictionary
	main_weapon = String(staff.get("weapon_id", main_weapon))
	offhand_weapon = test_weapon_id
	is_two_handed = false
	state = State.FREE
	mana = int(s.get("mana_cost"))
	var cast_result := use_primary_attack()
	var cast_ok := cast_result == "cast" and state == State.CASTING and mana == 0 \
		and casting_instrument_id() == test_instrument_id

	state = State.FREE
	mana = 0
	stamina.current = stamina.maximum
	var fallback_result := use_primary_attack()
	var fallback_ok := fallback_result == "melee_no_mana" and state == State.ATTACK \
		and state_name() == "pancada: mana insuficiente"

	state = int(original.state)
	state_frame = int(original.state_frame)
	mana = int(original.mana)
	main_weapon = String(original.main_weapon)
	offhand_weapon = String(original.offhand_weapon)
	is_two_handed = bool(original.is_two_handed)
	stamina.current = float(original.stamina)
	_atk = original.atk as Dictionary
	_atk_kind = String(original.atk_kind)
	_atk_weapon = String(original.atk_weapon)
	_attack_feedback = String(original.attack_feedback)
	_cast_spell = original.cast_spell as Dictionary
	_cast_instrument = original.cast_instrument as Dictionary
	_cast_frames_total = int(original.cast_frames_total)

	if cast_ok and fallback_ok:
		print("[casting-attack-test] 2 passaram, 0 falharam")
	else:
		push_error("[casting-attack-test] esperado cast + fallback fisico legivel")


func _start_cast(spell: Dictionary = {}, instrument: Dictionary = {}) -> bool:
	var s: Dictionary = spell if not spell.is_empty() else GameData.spell(selected_spell)
	if s.is_empty():
		return false
	var active_instrument: Dictionary = instrument if not instrument.is_empty() \
		else _casting_instrument_for(s)
	# [CODEX] Compatibilidade transitória: prefere a secundária decidida pelo
	# Mateus, mas deixa o cajado `can_cast` dos kits actuais fechar o fio. Quando
	# o dono dos dados equipar o talismã, este fallback deixa de ser usado. A
	# alternativa é manter todos os kits de mago incapazes de conjurar.
	if active_instrument.is_empty():
		return false
	var bundle := _spell_vfx_bundle(String(s.get("id", selected_spell)))
	if bundle.is_empty():
		casting_fallback.emit("vfx_nao_residente")
		return false
	var cost := int(s.get("mana_cost"))
	if mana < cost:
		return false
	mana -= cost
	_cast_instrument = active_instrument
	_cast_spell = s.duplicate()
	_cast_spell["_spell_id"] = selected_spell
	_cast_spell["_instrument_id"] = casting_instrument_id()
	_cast_spell["_instrument_weapon_id"] = String(active_instrument.get("weapon_id", ""))
	_cast_spell["_instrument_spell_power"] = active_instrument.get("spell_power")
	_cast_frames_total = int(float(s.get("cast_time")) \
		* float(Engine.physics_ticks_per_second))
	_attack_feedback = ""
	_start_cast_flash(bundle, s)
	_change_state(State.CASTING)
	return true


func _tick_casting(delta: float) -> void:
	# Conjurar trava o movimento a 40% — e a Ruina trava-o por completo (WP4: "1,6 s parado").
	var mult := float((GameData.spells["_rules"] as Dictionary)[
		"move_multiplier_while_casting"])
	if bool(_cast_spell.get("movement_locked", false)):
		mult = 0.0
	_move(delta, _speed_for_mode() * mult)
	if is_instance_valid(lock_on.target):
		_face(_to_target())
	if is_instance_valid(_cast_flash) and _cast_flash.has_method("sync_tip"):
		_cast_flash.call("sync_tip", _spell_origin())

	if state_frame >= _cast_frames_total:
		_release_spell()
		_change_state(State.FREE)


func _release_spell() -> void:
	var spell_id := String(_cast_spell.get("_spell_id", selected_spell))
	var kind: String = _cast_spell.get("type", "projectile")
	var origin := _spell_origin()
	var dir := _facing()
	if is_instance_valid(lock_on.target):
		var target_radius: float = lock_on.target.get("body_radius") \
			if lock_on.target.get("body_radius") != null else 0.0
		dir = ((lock_on.target.global_position + Vector3.UP * target_radius) \
			- origin).normalized()

	var target_point := origin + dir * float(_cast_spell.get("max_range",
		_cast_spell.get("range_m", 0.0)))
	if is_instance_valid(lock_on.target):
		target_point = lock_on.target.global_position
	var delivery := SpellDeliveryFactoryScript.create(spell_id, GameData.spells, {
		"origin": origin,
		"direction": dir,
		"caster": self,
		"target": lock_on.target if is_instance_valid(lock_on.target) else null,
		"target_point": target_point,
		"target_group": "enemies",
		"vfx_bundle": _spell_vfx_bundle(spell_id),
	})
	if delivery == null:
		casting_fallback.emit("forma_de_magia_invalida")
		_cancel_cast_flash()
		return
	delivery.add_to_group("spell_deliveries")
	delivery.contacted.connect(_on_spell_delivery_contact)
	get_tree().current_scene.add_child(delivery)
	if kind == "barrier":
		_egide_shield = float(_cast_spell.get("absorb", 0.0))
		_egide_time = float(_cast_spell.get("duration", 0.0))
	if is_instance_valid(_cast_flash) and _cast_flash.has_method("commit"):
		_cast_flash.call("commit", origin)
	_cast_flash = null


func _on_spell_delivery_contact(target: Node3D, payload: Dictionary) -> void:
	if not bool(payload.get("damage_enabled", false)):
		return
	Spell.apply_contact(payload.get("spell", {}) as Dictionary, self, attrs, target)


func _spell_vfx_bundle(spell_id: String) -> Dictionary:
	if _spell_vfx_residency == null:
		_spell_vfx_residency = SpellVfxResidencyScript.new()
		_spell_vfx_residency.call("configure", GameData.spells)
	var equipped: Array = []
	for favorite_id: String in favorite_spells:
		equipped.append(favorite_id)
	if equipped.is_empty() and not spell_id.is_empty():
		equipped.append(spell_id)
	var resident_ids := _spell_vfx_residency.call("resident_spell_ids") as Array
	if resident_ids != equipped:
		if not bool(_spell_vfx_residency.call("equip", equipped)):
			return {}
	return _spell_vfx_residency.call("bundle_for", spell_id) as Dictionary


func _start_cast_flash(bundle: Dictionary, spell: Dictionary) -> void:
	_cancel_cast_flash()
	_ensure_casting_weapon_visual()
	var contact_contracts: Dictionary = GameData.spells.get("_contact_contracts", {}) as Dictionary
	var contact: Dictionary = contact_contracts.get(
		String(spell.get("contact_type", "")), {}) as Dictionary
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		return
	_cast_flash = SpellCastVfxScript.new()
	host.add_child(_cast_flash)
	_cast_flash.call("configure", bundle, float(spell.get("cast_time", 0.0)),
		int(contact.get("active_frames", 0)), _spell_origin())


func _cancel_cast_flash() -> void:
	if is_instance_valid(_cast_flash):
		if _cast_flash.has_method("cancel"):
			_cast_flash.call("cancel")
		else:
			_cast_flash.queue_free()
	_cast_flash = null


func _ensure_casting_weapon_visual() -> void:
	if is_instance_valid(_casting_weapon_visual):
		return
	if not is_instance_valid(_visual):
		return
	_casting_weapon_visual = _find_casting_weapon_visual(self)
	if is_instance_valid(_casting_weapon_visual):
		return
	var weapon_visual := CastingWeaponAttachScript.new() as Node3D
	add_child(weapon_visual)
	if not bool(weapon_visual.call("setup", self, _visual)):
		weapon_visual.queue_free()
		return
	_casting_weapon_visual = weapon_visual


func _find_casting_weapon_visual(root: Node) -> Node3D:
	for child: Node in root.get_children():
		if child != self and child.has_method("main_weapon_tip_position"):
			return child as Node3D
		var nested := _find_casting_weapon_visual(child)
		if nested != null:
			return nested
	return null


func _spell_origin() -> Vector3:
	if is_instance_valid(_casting_weapon_visual) \
			and _casting_weapon_visual.has_method("main_weapon_tip_position"):
		return _casting_weapon_visual.call("main_weapon_tip_position") as Vector3
	return global_position + Vector3.UP * float(
		GameData.section("player").get("capsule_height", 0.0))


# --- Levar dano ---------------------------------------------------------------

func take_damage(info: DamageInfo) -> void:
	if state == State.DEAD:
		return

	# 1. Invencibilidade (esquiva, riposte) — o golpe simplesmente nao existe.
	if has_iframes():
		return

	# 2. Parry: janela aberta E o golpe e aparavel -> anula tudo e parte a postura.
	if parry_window_open() and info.parryable and _is_in_front(info):
		if info.attacker != null and info.attacker.has_method("on_parried"):
			info.attacker.call("on_parried")
		# O momento-assinatura do jogo: 10 frames parados, o mais longo de todos.
		var stop := int(GameData.section("hit_stop")["parry_success"])
		Sfx.play("parry", null, 2.0, 0.02)
		_freeze(stop)
		if info.attacker != null and info.attacker.get("hitstop_frames") != null:
			info.attacker.set("hitstop_frames", stop)
		_change_state(State.FREE)
		_buffer("light")   # deixa o riposte sair logo a seguir
		return

	var amount := info.amount

	# 3. Bloqueio.
	if state == State.BLOCK and _is_in_front(info) and not info.is_aoe:
		var b := GameData.section("block")
		var source := _block_source()
		var absorb := float(b["shield_magic_absorb"] if info.is_magic \
			else b["shield_physical_absorb"])
		var cost_mult := 1.0
		if source == "onehand":
			absorb = float(b["onehand_absorb"])
			cost_mult = float(b["onehand_cost_multiplier"])

		var weight_key := "blow_weight_heavy" if info.weight == "heavy" else "blow_weight_light"
		if source == "shield" and not info.is_magic:
			absorb *= 1.0 - clampf(info.shield_pierce_fraction, 0.0, 1.0)
		var cost: float = float(b["stamina_per_blow"]) * float(b[weight_key]) \
			* cost_mult * maxf(info.guard_stamina_multiplier, 1.0)
		stamina.spend(cost)
		amount *= (1.0 - absorb)
		Sfx.play("hit_block")
		_freeze(int(GameData.section("hit_stop")["blocked"]))

		if stamina.current <= 0.0:
			_apply_health_loss(amount)
			_change_state(State.GUARD_BREAK)   # castigo de bloquear tudo
			return
		_apply_health_loss(amount)
		return

	# 4. Egide absorve antes da vida.
	if _egide_shield > 0.0:
		var soaked := minf(_egide_shield, amount)
		_egide_shield -= soaked
		amount -= soaked

	_apply_health_loss(amount)
	if health <= 0.0:
		return

	# 5. Conjurar: levar dano interrompe e a mana ja foi gasta. Meditar tambem
	# interrompe, mas conserva a mana que entrou ate este frame (spec/54 + 66).
	if state == State.CASTING and not has_hyper_armor():
		_cast_spell = {}
		_cancel_cast_flash()
		_change_state(State.FREE)
	elif state == State.MEDITATING:
		_change_state(State.FREE)

	# 6. Hiper-armadura: leva o dano, nao e interrompido.
	if has_hyper_armor():
		return

	Sfx.play("hit_flesh", null, -1.0, 0.1)
	_freeze(int(GameData.section("hit_stop")["player_hit"]))
	_hitstun_frames = int(info.hitstun_seconds(GameData.section("hitstun")) \
		* _reference_fps())
	_change_state(State.HITSTUN)


func _apply_health_loss(amount: float) -> void:
	if amount <= 0.0:
		return
	health = maxf(0.0, health - GameData.apply_defense(amount, defense))
	if health <= 0.0:
		_die()


func _apply_raw_health_loss(amount: float) -> void:
	if amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		_die()


func _die(stain_position: Variant = null) -> void:
	if state == State.DEAD:
		return
	death_stain_position = stain_position as Vector3 \
		if stain_position is Vector3 else global_position
	health = 0.0
	_change_state(State.DEAD)
	died.emit()


func _is_in_front(info: DamageInfo) -> bool:
	var to := info.source_position - global_position
	to.y = 0.0
	if to.length_squared() < 0.001:
		return true
	return _facing().angle_to(to.normalized()) < deg_to_rad(float(
		GameData.section("block")["front_half_angle_degrees"]))


func is_alive() -> bool:
	return state != State.DEAD


func respawn_at(p: Vector3) -> void:
	global_position = p
	velocity = Vector3.ZERO
	health = max_health
	stamina.refill()
	mana = max_mana
	meditation_uses = meditation_uses_max
	_egide_shield = 0.0
	_combo_index = 0
	_buffered = ""
	reset_fall_tracking(global_position.y)
	_last_supported_position = global_position
	_has_supported_position = true
	_change_state(State.FREE)


# --- Equipamento (Lei 3) ------------------------------------------------------

func _cycle_loadout(direction: int) -> void:
	var order: Array = (GameData.weapons.get("test_loadouts", {}) as Dictionary).get("order", [])
	if order.is_empty():
		return
	_loadout_index = wrapi(_loadout_index + direction, 0, order.size())
	var l: Dictionary = order[_loadout_index]
	main_weapon = equipment_weapon_id(l.get("main", "longsword"))
	offhand_weapon = equipment_weapon_id(l.get("offhand", ""))
	is_two_handed = _loadout_uses_two_hands(main_weapon, offhand_weapon)
	_combo_index = 0


func loadout_label() -> String:
	var main_name: String = GameData.weapon(main_weapon).get("display_name", main_weapon)
	if not GameData.meets_requirements(main_weapon, attrs):
		main_name += " (abaixo do requisito, dano x0,6)"
	if offhand_weapon != "" and not is_two_handed:
		return "%s + %s" % [main_name, GameData.weapon(offhand_weapon).get("display_name", offhand_weapon)]
	return "%s (duas maos)" % main_name if is_two_handed else main_name


# --- Leitura visual -----------------------------------------------------------

func _refresh_colour() -> void:
	if _visual == null:
		return
	var colour := Color.WHITE
	if state == State.DEAD:
		colour = Color(String(_palette.get("player_dead", "#3a3a3a")))
	elif has_iframes():
		colour = Color(String(_palette.get("player_iframes", "#7fe3ff")))
	elif has_hyper_armor():
		colour = Color(String(_palette.get("player_hyper_armor", "#c88bd6")))
	elif parry_window_open():
		colour = Color(String(_palette.get("player_parry_window", "#ffe680")))
	elif state == State.BLOCK:
		colour = Color(String(_palette.get("player_blocking", "#4a7ab5")))
	_visual.set_tint(colour)


func _refresh_animation() -> void:
	if _visual == null:
		return
	_update_visual_transition()
	if _waking_up or _resting:
		var sitting_enter_frames := _visual.state_animation_frames(
			"player", "sitting_enter")
		var sitting_elapsed := maxi(0, _frame - _sitting_visual_started_at)
		if sitting_elapsed < sitting_enter_frames:
			_play_visual_state("sitting_enter", "", sitting_enter_frames)
		else:
			_play_visual_state("sitting_idle")
		return
	if state == State.FREE and Input.is_action_just_pressed("interact") \
			and _ground_pickup_in_range():
		_start_visual_transition("pickup")
	if _play_visual_transition():
		return
	match state:
		State.DEAD:
			_play_visual_state("death")
		State.DODGE:
			_visual.play_animation("Roll")
		State.ATTACK:
			# AttackAnimationController e o escritor unico desta pose e procura o
			# clip pelo frame autoritativo. A chamada generica aqui apagava o arco.
			if _attack_animation_controller() == null:
				_visual.play_animation("Sword_Attack")
		State.RIPOSTE:
			_visual.play_animation("Sword_Attack")
			var dodge_frames := int(GameData.section("dodge").get(
				"duration_frames", 0)) + _dodge_recovery_extra
			_play_visual_state("dodge", "", dodge_frames)
		State.ATTACK:
			_play_visual_state("attack", _attack_animation_context(),
				_attack_animation_frames())
		State.RIPOSTE:
			var riposte_frames := int(float(GameData.section("parry").get(
				"riposte_duration", 0.0)) * float(Engine.physics_ticks_per_second))
			_play_visual_state("riposte", _weapon_animation_context(main_weapon),
				riposte_frames)
		State.CASTING:
			_play_casting_animation()
		State.HITSTUN, State.GUARD_BREAK:
			var locked_frames := _hitstun_frames if state == State.HITSTUN else int(
				float(GameData.section("block").get("guard_break_duration", 0.0))
				* float(Engine.physics_ticks_per_second))
			_play_visual_state("hit_chest", "", locked_frames)
		State.BLOCK, State.PARRY:
			_play_visual_state("block", _weapon_animation_context(main_weapon))
		State.MEDITATING:
			_play_visual_state("meditating")
		State.USING_ITEM:
			var item_frames := int(float(GameData.section("flask").get(
				"use_seconds", 0.0)) * float(Engine.physics_ticks_per_second))
			_play_visual_state("using_item", "", item_frames)
		State.ABILITY:
			_play_visual_state("ability")
		State.GRIP_SWITCH:
			_play_visual_state("grip_switch", "",
				int(GameData.section("grip").get("switch_frames", 0)))
		_:
			var planar_speed := Vector2(velocity.x, velocity.z).length()
			if planar_speed > 0.1:
				_play_visual_state("sprint" if _sprinting else "jog")
			else:
				_play_visual_state("idle", _weapon_animation_context(main_weapon))


func _play_visual_state(state_key: String, context := "", target_frames := 0) -> void:
	_visual.play_state_animation("player", state_key, context, target_frames)


func _weapon_animation_context(weapon_id: String) -> String:
	if weapon_id.is_empty():
		return "unarmed"
	var family := String(GameData.weapon(weapon_id).get("familia", ""))
	return family if not family.is_empty() else "armed"


func _attack_animation_context() -> String:
	if _atk_weapon.is_empty():
		return "unarmed_cross" if _combo_index % 2 == 0 else "unarmed_jab"
	return _weapon_animation_context(_atk_weapon)


func _attack_animation_frames() -> int:
	return _atk_startup + _charge_frames + _atk_active + _atk_recovery


func _ground_pickup_in_range() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for candidate: Node in scene.find_children("*", "SecretsGroundItem", true, false):
		if candidate.has_method("prompt_state") \
				and not (candidate.call("prompt_state", global_position) as Dictionary).is_empty():
			return true
	return false


func _play_casting_animation() -> void:
	var enter_frames := _visual.state_animation_frames("player", "casting_enter")
	var shoot_frames := _visual.state_animation_frames("player", "casting_shoot")
	if state_frame <= enter_frames:
		_play_visual_state("casting_enter", "", enter_frames)
	elif state_frame > maxi(enter_frames, _cast_frames_total - shoot_frames):
		_play_visual_state("casting_shoot", "", shoot_frames)
	else:
		_play_visual_state("casting_idle")


func _update_visual_transition() -> void:
	if state == _visual_previous_state:
		return
	if _visual_previous_state == State.CASTING and state == State.FREE:
		_start_visual_transition("casting_exit")
	elif state != State.FREE:
		_visual_transition_state = ""
	_visual_previous_state = state


func _start_visual_transition(state_key: String) -> void:
	_visual_transition_state = state_key
	_visual_transition_started_at = _frame


func _play_visual_transition() -> bool:
	if _visual_transition_state.is_empty() or state != State.FREE:
		return false
	var frames := _visual.state_animation_frames("player", _visual_transition_state)
	if frames <= 0 or _frame - _visual_transition_started_at >= frames:
		_visual_transition_state = ""
		return false
	_play_visual_state(_visual_transition_state, "", frames)
	return true


func _attack_animation_controller() -> Node:
	for child: Node in get_children():
		if child.has_method("play_attack") \
				and child.has_method("declared_family_animations"):
			return child
	return null


func state_name() -> String:
	match state:
		State.FREE: return "livre"
		State.ATTACK:
			return _attack_feedback if _attack_feedback != "" else "ataque"
		State.DODGE: return "esquiva"
		State.BLOCK: return "bloqueio"
		State.GRIP_SWITCH: return "troca de empunhadura"
		State.PARRY: return "parry"
		State.CASTING: return "conjuracao"
		State.HITSTUN: return "hit-stun"
		State.GUARD_BREAK: return "guarda quebrada"
		State.RIPOSTE: return "riposte"
		State.DEAD: return "morto"
		State.USING_ITEM: return "a beber"
		State.ABILITY: return "habilidade"
		State.MEDITATING: return "a meditar"
	return "?"


# --- Habilidade especial (WP3) [tecla V = PROTO] -------------------------------
# spec/12-classes.md: verbos novos, nao numeros. Cooldown fixo, nada escala.
# Implementadas: Impeto (warrior), Furia (berserker), Provocacao (tank).
# Eco, Passo Sombra e Julgamento: registadas nos dados, entram por iteracao.

func _request_raise_dead() -> void:
	var spell_id := String(_ability.get("raise_spell_id", ""))
	if not spell_id.is_empty():
		raise_requested.emit(spell_id)

func _start_ability() -> void:
	if _ability.is_empty() or _ability_cd > 0.0:
		return
	match String(_ability.get("id", "")):
		"impeto":
			if not stamina.can_act():
				return
			stamina.spend(float(_ability["stamina_cost"]))
			_ability_cd = float(_ability["cooldown_s"])
			if is_instance_valid(lock_on.target):
				_face(_to_target())
			_change_state(State.ABILITY)
		"furia":
			_ability_cd = float(_ability["cooldown_s"])
			_fury_time = float(_ability["duration_s"])
			Sfx.play("fury", null, 1.0)
		"provocacao":
			_ability_cd = float(_ability["cooldown_s"])
			_taunt_all()
		_:
			pass  # por implementar — fica sem efeito em vez de fingir


## Impeto: avanco em linha que termina num golpe leve com MV proprio (1,2).
func _tick_ability(_delta: float) -> void:
	var dash_seconds := float(_ability["dash_seconds"])
	var dash_frames := int(dash_seconds * _reference_fps())
	var speed := float(_ability["dash_m"]) / dash_seconds
	var dir := _facing()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if state_frame >= dash_frames:
		velocity.x = 0.0
		velocity.z = 0.0
		_change_state(State.FREE)
		_start_attack("light")
		if state == State.ATTACK:
			_atk_mv = float(_ability["strike_mv"])


## Provocacao: inimigos num raio ficam com atencao no Tanque (a ferramenta de
## co-op "segura o brutamontes"; a solo, acorda os que patrulham longe).
func _taunt_all() -> void:
	var radius := float(_ability["radius_m"])
	var secs := float(_ability["duration_s"])
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Node3D
		if e != null and e.global_position.distance_to(global_position) <= radius and e.has_method("taunt"):
			e.call("taunt", self, secs)


func ability_label() -> String:
	if _ability.is_empty():
		return "-"
	var n := String(_ability.get("display_name", "?"))
	if String(_ability.get("id", "")) == "furia" and _fury_time > 0.0:
		return "%s %.0fs!" % [n, ceilf(_fury_time)]
	return "%s ok" % n if _ability_cd <= 0.0 else "%s %ds" % [n, ceili(_ability_cd)]


# --- Frasco (cura) ------------------------------------------------------------
# A pergunta 7 decidiu o frasco recarregavel no descanso. O baseline [FABLE] da
# spec/14 demora 1,2 s a 50% de velocidade e interrompe-se com dano — curar a
# meio de um duelo e uma aposta, como no genero.
# O gole gasta-se ao COMECAR: interrompido = perdido (a regra da magia, igual).

func _start_flask() -> void:
	if flask_uses <= 0 or health >= max_health:
		return
	flask_uses -= 1
	_change_state(State.USING_ITEM)


func _tick_flask(delta: float) -> void:
	var fl := GameData.section("flask")
	_move(delta, float(GameData.section("movement")["walk_speed"]) \
		* float(fl["move_factor"]))
	if state_frame >= int(float(fl["use_seconds"]) * _reference_fps()):
		health = minf(max_health, health + max_health * float(fl["heal_fraction"]))
		Sfx.play("flask")
		_change_state(State.FREE)


func flask_refill() -> void:
	flask_uses = flask_max
