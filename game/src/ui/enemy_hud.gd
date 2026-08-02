class_name EnemyHud
extends CanvasLayer
## Leitura de ameaca comum sem transformar todos os inimigos em placas flutuantes.
##
## Mostra o alvo engatado; sem engate, conserva por instantes quem foi atingido
## ou quem esta a atacar o jogador. O mesmo apresentador da direcao e quantidade
## ao dano recebido, indispensavel em primeira pessoa.

const BAR_WIDTH := 500.0

var _enemies: Dictionary = {}
var _phases: Dictionary = {}
var _player: Node3D
var _current_enemy: Node3D
var _recent_enemy: Node3D
var _recent_time := 0.0
var _lost_fraction := 1.0

var _root: Control
var _target_group: Control
var _target_name: Label
var _health_background: ColorRect
var _health_lost: ColorRect
var _health_fill: ColorRect
var _phase_label: Label
var _enemy_damage: Label
var _enemy_damage_time := 0.0
var _damage_flash: ColorRect
var _player_damage: Label
var _player_damage_time := 0.0
var _context_hud: Node


func _ready() -> void:
	layer = 56
	_build_interface()


func register_enemy(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var key := enemy.get_instance_id()
	if _enemies.has(key):
		return
	_enemies[key] = enemy
	_phases[key] = {"phase": 0, "progress": 0.0, "parryable": false}
	if enemy.has_signal("health_changed"):
		enemy.connect("health_changed", _on_enemy_health_changed.bind(enemy))
	if enemy.has_signal("attack_phase_changed"):
		enemy.connect("attack_phase_changed", _on_attack_phase_changed.bind(enemy))
	if enemy.has_signal("state_changed"):
		enemy.connect("state_changed", _on_enemy_state_changed.bind(enemy))
	if enemy.has_signal("hit_landed"):
		enemy.connect("hit_landed", _on_hit_landed.bind(enemy))
	enemy.tree_exited.connect(_on_enemy_exited.bind(key))


func _build_interface() -> void:
	_root = Control.new()
	_root.name = "EnemyHudSurface"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_damage_flash = ColorRect.new()
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_damage_flash.color = Color(0.78, 0.025, 0.01, 0.0)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_damage_flash)

	_target_group = Control.new()
	_target_group.anchor_left = 0.5
	_target_group.anchor_right = 0.5
	_target_group.offset_left = -270.0
	_target_group.offset_right = 270.0
	_target_group.offset_top = 38.0
	_target_group.offset_bottom = 126.0
	_target_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_target_group)

	var panel := ColorRect.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(540.0, 88.0)
	panel.color = Color(0.018, 0.025, 0.027, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_group.add_child(panel)

	_target_name = _label(Vector2(20, 7), Vector2(500, 25), 18)
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_group.add_child(_target_name)

	_health_background = _rect(Color(0.06, 0.025, 0.025, 0.96), Vector2(20, 37),
		Vector2(BAR_WIDTH, 17))
	_target_group.add_child(_health_background)
	_health_lost = _rect(Color(0.86, 0.67, 0.31, 0.9), Vector2(20, 37),
		Vector2(BAR_WIDTH, 17))
	_target_group.add_child(_health_lost)
	_health_fill = _rect(Color(0.73, 0.15, 0.12), Vector2(20, 37),
		Vector2(BAR_WIDTH, 17))
	_target_group.add_child(_health_fill)

	_phase_label = _label(Vector2(20, 59), Vector2(500, 22), 15)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_group.add_child(_phase_label)

	_enemy_damage = _label(Vector2(386, 28), Vector2(130, 34), 24)
	_enemy_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_damage.add_theme_color_override("font_color", Color("ffd27d"))
	_target_group.add_child(_enemy_damage)

	_player_damage = _label(Vector2.ZERO, Vector2(640, 72), 30)
	_player_damage.anchor_left = 0.5
	_player_damage.anchor_right = 0.5
	_player_damage.anchor_top = 0.5
	_player_damage.anchor_bottom = 0.5
	_player_damage.offset_left = -320.0
	_player_damage.offset_right = 320.0
	_player_damage.offset_top = -150.0
	_player_damage.offset_bottom = -78.0
	_player_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_damage.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_damage.add_theme_color_override("font_color", Color("ffb09a"))
	_root.add_child(_player_damage)
	_target_group.visible = false


func _rect(colour: Color, position: Vector2, size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = colour
	rect.position = position
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _label(position: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f2eee2"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _process(delta: float) -> void:
	_find_local_player()
	_recent_time = maxf(_recent_time - delta, 0.0)
	_enemy_damage_time = maxf(_enemy_damage_time - delta, 0.0)
	_player_damage_time = maxf(_player_damage_time - delta, 0.0)
	if _enemy_damage_time <= 0.0:
		_enemy_damage.text = ""
	if _player_damage_time <= 0.0:
		_player_damage.text = ""
	var flash_alpha := clampf(_player_damage_time / 0.34, 0.0, 1.0) * 0.19
	_damage_flash.color.a = flash_alpha

	var combat_active := _combat_is_active()
	if combat_active:
		_silence_context_tutorial()
	var next_enemy := _select_enemy()
	if next_enemy != _current_enemy:
		_current_enemy = next_enemy
		_lost_fraction = _health_fraction(_current_enemy)
	_update_target(delta)


func _find_local_player() -> void:
	if is_instance_valid(_player):
		return
	for node: Node in get_tree().get_nodes_in_group("player"):
		var candidate := node as Node3D
		if candidate != null and candidate.get("camera") != null:
			_player = candidate
			return


func _select_enemy() -> Node3D:
	if not is_instance_valid(_player):
		return null
	var lock_on := _player.get("lock_on") as Node
	if lock_on != null and lock_on.has_method("display_target"):
		var locked := lock_on.call("display_target") as Node3D
		if is_instance_valid(locked) and _enemies.has(locked.get_instance_id()):
			return locked
	if _recent_time > 0.0 and is_instance_valid(_recent_enemy):
		return _recent_enemy
	var nearest: Node3D
	var nearest_distance := INF
	for value: Variant in _enemies.values():
		var enemy := value as Node3D
		if not _enemy_is_alive(enemy) or enemy.get("target") != _player:
			continue
		var state := String(enemy.call("state_name")) if enemy.has_method("state_name") else ""
		if state not in ["persegue", "preparacao", "golpe", "recuperacao"]:
			continue
		var distance := enemy.global_position.distance_to(_player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest


func _update_target(delta: float) -> void:
	var show := is_instance_valid(_current_enemy)
	_target_group.visible = show
	if not show:
		return
	var fraction := _health_fraction(_current_enemy)
	_lost_fraction = move_toward(_lost_fraction, fraction, delta * 0.32)
	_health_fill.size.x = BAR_WIDTH * fraction
	_health_lost.size.x = BAR_WIDTH * maxf(_lost_fraction, fraction)
	var current := float(_current_enemy.get("health"))
	var maximum := maxf(float(_current_enemy.get("max_health")), 1.0)
	var display_name: String = String(_current_enemy.call("display_name")) \
		if _current_enemy.has_method("display_name") else _current_enemy.name
	_target_name.text = "%s   %d / %d PV" % [display_name.to_upper(), ceili(current), ceili(maximum)]
	_update_phase_label(_current_enemy)


func _update_phase_label(enemy: Node3D) -> void:
	if not _enemy_is_alive(enemy):
		_phase_label.text = "DERROTADO"
		_phase_label.add_theme_color_override("font_color", Color("aeb4af"))
		return
	var presentation: Dictionary = _phases.get(enemy.get_instance_id(), {}) as Dictionary
	var phase := int(presentation.get("phase", 0))
	var parryable := bool(presentation.get("parryable", false))
	match phase:
		1:
			_phase_label.text = "PREPARA  |  %s" % ("APARAVEL" if parryable else "ESQUIVA")
			_phase_label.add_theme_color_override("font_color", Color("f1c85b"))
		2:
			_phase_label.text = "GOLPE"
			_phase_label.add_theme_color_override("font_color", Color("ff6b52"))
		3:
			_phase_label.text = "RECUPERA  |  CASTIGA"
			_phase_label.add_theme_color_override("font_color", Color("8fd3be"))
		_:
			_phase_label.text = "EM GUARDA"
			_phase_label.add_theme_color_override("font_color", Color("c4c5be"))


func _on_enemy_health_changed(current: float, maximum: float, delta: float,
		_source: Node3D, enemy: Node) -> void:
	if delta >= 0.0 or not is_instance_valid(enemy):
		return
	_recent_enemy = enemy as Node3D
	_recent_time = 3.0
	_lost_fraction = maxf(_lost_fraction, current / maxf(maximum, 1.0))
	_enemy_damage.text = "-%d" % ceili(absf(delta))
	_enemy_damage_time = 0.85


func _on_attack_phase_changed(phase: int, progress: float, parryable: bool,
		_attack_id: String, enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	_phases[enemy.get_instance_id()] = {
		"phase": phase, "progress": progress, "parryable": parryable,
	}


func _on_enemy_state_changed(_current: int, _previous: int, enemy: Node) -> void:
	if is_instance_valid(enemy) and not _enemy_is_alive(enemy):
		_recent_enemy = enemy as Node3D
		_recent_time = 1.4


func _on_hit_landed(victim: Node3D, damage: float, origin: Vector3,
		enemy: Node) -> void:
	if not is_instance_valid(_player) or victim != _player or damage <= 0.0:
		return
	var arrow := _direction_arrow(origin)
	var attacker_name: String = String(enemy.call("display_name")) \
		if enemy.has_method("display_name") else "INIMIGO"
	_player_damage.text = "%s  -%d PV  |  %s" % [arrow, ceili(damage), attacker_name.to_upper()]
	_player_damage_time = 0.34
	_recent_enemy = enemy as Node3D
	_recent_time = 2.0


func _direction_arrow(origin: Vector3) -> String:
	var direction := (origin - _player.global_position).normalized()
	var local_right := _player.global_transform.basis.x.normalized()
	var local_forward := -_player.global_transform.basis.z.normalized()
	var side := local_right.dot(direction)
	var front := local_forward.dot(direction)
	if absf(side) > 0.45:
		return "DIREITA" if side > 0.0 else "ESQUERDA"
	return "FRENTE" if front >= 0.0 else "ATRAS"


func _combat_is_active() -> bool:
	if not is_instance_valid(_player):
		return false
	for value: Variant in _enemies.values():
		var enemy := value as Node3D
		if not _enemy_is_alive(enemy) or enemy.get("target") != _player:
			continue
		var state := String(enemy.call("state_name")) if enemy.has_method("state_name") else ""
		if state in ["persegue", "preparacao", "golpe", "recuperacao"]:
			return true
	return false


func _silence_context_tutorial() -> void:
	if not is_instance_valid(_context_hud):
		for node: Node in get_tree().root.find_children("*", "CanvasLayer", true, false):
			if node.has_method("has_context_tip") and node.has_method("context_tip"):
				_context_hud = node
				break
	if not is_instance_valid(_context_hud) or not bool(_context_hud.call("has_context_tip")):
		return
	_context_hud.set("_lesson_time", 0.0)
	var lesson := _context_hud.get("_lesson") as Label
	if lesson != null:
		lesson.text = ""
		lesson.visible = false


func _health_fraction(enemy: Node3D) -> float:
	if not is_instance_valid(enemy):
		return 0.0
	return clampf(float(enemy.get("health")) / maxf(float(enemy.get("max_health")), 1.0),
		0.0, 1.0)


func _enemy_is_alive(enemy: Node3D) -> bool:
	return is_instance_valid(enemy) and (not enemy.has_method("is_alive") \
		or bool(enemy.call("is_alive")))


func _on_enemy_exited(key: int) -> void:
	_enemies.erase(key)
	_phases.erase(key)
