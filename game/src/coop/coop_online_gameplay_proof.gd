extends Node
## Prova de co-op pelo percurso do jogador, em dois processos Godot reais.
##
## Sem argumentos, este processo abre anfitriao e convidado. Cada filho instancia
## `gameplay.tscn`, carrega em F3, activa Hospedar/Entrar, anda com o comando real
## e observa o corpo visivel do parceiro a mover-se no seu proprio mundo.
##
## Nao deixa saves: usa slots temporarios altos, limpa-os antes de sair e o pai
## recusa perfis desta prova nos slots reais ou ficheiros temporarios proprios.

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/gameplay.tscn")
const ROLE_HOST := "host"
const ROLE_GUEST := "guest"
const JOIN_TARGET_SECONDS := 120.0
const BODY_TIMEOUT_SECONDS := 20.0
const CHILD_TIMEOUT_SECONDS := 55.0
const MOVE_FRAMES := 36
const POSITION_EPSILON_METERS := 0.15
const PROOF_SLOT_BASE := 900000000

var _role := ""
var _run_id := ""
var _run_dir := ""
var _proof_port := 0
var _gameplay: Node
var _actor: Player


func _ready() -> void:
	_role = _argument_value("--coop-proof-role=")
	_run_id = _argument_value("--coop-proof-run=")
	if _role.is_empty():
		await _run_parent()
	else:
		_run_dir = "user://coop-online-proof-%s" % _run_id
		await _run_child()


func _run_parent() -> void:
	_run_id = "%d-%d" % [OS.get_process_id(), Time.get_ticks_msec()]
	_run_dir = "user://coop-online-proof-%s" % _run_id
	_proof_port = 30000 + (OS.get_process_id() % 20000)
	if not _prepare_run_dir():
		_fail_parent("nao foi possivel criar a pasta temporaria da prova")
		return

	var executable := OS.get_executable_path()
	var host_pid := _spawn_child(executable, ROLE_HOST)
	var guest_pid := _spawn_child(executable, ROLE_GUEST)
	if host_pid <= 0 or guest_pid <= 0:
		_stop_child(host_pid)
		_stop_child(guest_pid)
		_cleanup_run_dir()
		_fail_parent("nao foi possivel abrir os dois processos do jogo")
		return

	var deadline := _now() + CHILD_TIMEOUT_SECONDS
	while _now() < deadline and (not _has_marker("host-done") or not _has_marker("guest-done")):
		if not OS.is_process_running(host_pid) and not _has_marker("host-done"):
			break
		if not OS.is_process_running(guest_pid) and not _has_marker("guest-done"):
			break
		await get_tree().process_frame

	var host_result := _read_marker("host-done")
	var guest_result := _read_marker("guest-done")
	_stop_child(host_pid)
	_stop_child(guest_pid)
	_cleanup_proof_save(ROLE_HOST)
	_cleanup_proof_save(ROLE_GUEST)
	var saves_untouched := _proof_left_no_save()
	var passed := host_result.begins_with("PASS") and guest_result.begins_with("PASS") \
		and saves_untouched
	if passed:
		print("\n=== CO-OP ONLINE: JOGO REAL PASSOU ===")
		print(host_result)
		print(guest_result)
		print("saves: nenhum perfil/ficheiro da prova ficou nos slots")
	else:
		printerr("\n=== CO-OP ONLINE: PROVA FALHOU ===")
		printerr("anfitriao: %s" % (host_result if not host_result.is_empty() else "sem resultado"))
		printerr("convidado: %s" % (guest_result if not guest_result.is_empty() else "sem resultado"))
		if not saves_untouched:
			printerr("saves: a prova deixou um perfil ou ficheiro temporario")
		_print_child_log(ROLE_HOST)
		_print_child_log(ROLE_GUEST)
	_cleanup_run_dir()
	get_tree().quit(0 if passed else 1)


func _run_child() -> void:
	if not _role in [ROLE_HOST, ROLE_GUEST] or _run_id.is_empty():
		await _finish_child(false, "papel da prova invalido")
		return
	_proof_port = int(_argument_value("--coop-proof-port="))
	if _proof_port < 30000 or _proof_port > 49999:
		await _finish_child(false, "porta temporaria da prova invalida")
		return
	NetSession.connection_port = _proof_port
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(_run_dir))
	var profile_id := "prova-%s-%s" % [_run_id, _role]
	SaveSystem.active_slot = _proof_slot(_role)
	var class_ids := GameShell.CLASS_IDS
	if class_ids.is_empty():
		await _finish_child(false, "o catalogo nao publicou nenhuma origem jogavel")
		return
	var class_id: String = class_ids[0] if _role == ROLE_HOST else class_ids[-1]
	GameData.replace_save_state(SaveSystem.create_save(profile_id, class_id, {
		"name": "Anfitriao" if _role == ROLE_HOST else "Convidado",
		"appearance": {},
	}))
	_gameplay = GAMEPLAY_SCENE.instantiate()
	add_child(_gameplay)
	for _frame: int in 4:
		await get_tree().physics_frame
	_actor = _gameplay.get("player") as Player
	if _actor == null or not is_instance_valid(_gameplay.get("world")):
		await _finish_child(false, "a cena real nao criou jogador e mundo")
		return
	# A prova e de transporte/movimento. Os inimigos reais continuam em cena,
	# visiveis, mas nao atacam os corpos enquanto os dois processos sincronizam.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.set_physics_process(false)

	var started_at := _now()
	await _press_action("toggle_mouse")
	var menu := _gameplay.get("net_menu") as NetMenu
	if menu == null or not menu.visible or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		await _finish_child(false, "F3 nao abriu Jogar a dois com o rato livre")
		return

	if _role == ROLE_HOST:
		var host_button := menu.get("_host_button") as Button
		if host_button == null:
			await _finish_child(false, "o ecra nao mostrou o botao Hospedar")
			return
		host_button.grab_focus()
		await _press_action("ui_accept")
		if not NetSession.is_host():
			await _finish_child(false, _visible_status(menu, "Hospedar nao arrancou"))
			return
		_write_marker("host-ready", "À espera do parceiro")
	else:
		if not await _wait_for_marker("host-ready", BODY_TIMEOUT_SECONDS):
			await _finish_child(false, "o anfitriao nao ficou pronto a tempo")
			return
		var address := menu.get("_address") as LineEdit
		var join_button := menu.get("_join_button") as Button
		if address == null or join_button == null:
			await _finish_child(false, "o ecra nao mostrou endereco e Entrar")
			return
		join_button.grab_focus()
		await _press_action("ui_accept")
		var missing_address := _visible_status(menu, "")
		if not missing_address.contains("Falta o endereço"):
			await _finish_child(false,
				"Entrar sem endereço não explicou em português o que faltava")
			return
		address.grab_focus()
		await _type_text(address, "127.0.0.1")
		join_button.grab_focus()
		await _press_action("ui_accept")

	if not await _wait_until(func() -> bool: return NetSession.partner_id() != 0,
			BODY_TIMEOUT_SECONDS):
		await _finish_child(false, _visible_status(menu, "o parceiro nao entrou"))
		return
	var join_elapsed := _now() - started_at
	if join_elapsed >= JOIN_TARGET_SECONDS:
		await _finish_child(false, "entrar demorou %.1f s, acima dos dois minutos" % join_elapsed)
		return

	var remote := await _wait_for_remote_body()
	if remote == null:
		await _finish_child(false,
			"a sessao ligou, mas o corpo do parceiro nao apareceu no mundo")
		return
	var remote_visual: CharacterVisual
	for child: Node in remote.get_children():
		if child is CharacterVisual:
			remote_visual = child as CharacterVisual
			break
	if not remote.visible or not is_instance_valid(remote_visual) or not remote_visual.visible:
		var child_names: Array[String] = []
		for child: Node in remote.get_children():
			child_names.append(child.name)
		await _finish_child(false,
			"o corpo remoto existe, mas nao esta visivel (visible=%s, filhos=%s)" % [
				remote.visible, ",".join(child_names)])
		return
	var expected_remote_class: String = class_ids[-1] if _role == ROLE_HOST else class_ids[0]
	if str(remote.get("class_id")) != expected_remote_class:
		await _finish_child(false,
			"o corpo remoto apareceu com a origem errada (vi %s, esperava %s)" % [
				str(remote.get("class_id")), expected_remote_class])
		return

	_write_marker("%s-body-ready" % _role, "corpo visivel")
	var other_role := ROLE_GUEST if _role == ROLE_HOST else ROLE_HOST
	if not await _wait_for_marker("%s-body-ready" % other_role, BODY_TIMEOUT_SECONDS):
		await _finish_child(false, "o parceiro nao viu o segundo corpo")
		return
	var remote_start := remote.global_position
	_write_marker("%s-observing" % _role, "a observar movimento")
	if not await _wait_for_marker("%s-observing" % other_role, BODY_TIMEOUT_SECONDS):
		await _finish_child(false, "o parceiro nao ficou pronto para observar movimento")
		return

	if _role == ROLE_HOST:
		await _move_local_player()
		_write_marker("host-moved", "anfitriao andou")
		if not await _wait_for_marker("guest-moved", BODY_TIMEOUT_SECONDS):
			await _finish_child(false, "o convidado nao andou a tempo")
			return
	else:
		if not await _wait_for_marker("host-moved", BODY_TIMEOUT_SECONDS):
			await _finish_child(false, "o anfitriao nao andou a tempo")
			return
		if not await _wait_for_remote_motion(remote, remote_start):
			await _finish_child(false, "o convidado viu o parceiro, mas nao o viu andar")
			return
		await _move_local_player()
		_write_marker("guest-moved", "convidado andou")

	if not await _wait_for_remote_motion(remote, remote_start):
		await _finish_child(false, "%s viu o parceiro, mas nao o viu andar" % _role_label())
		return
	var measured_bps := NetSession.measured_bits_per_second()
	if measured_bps >= NetProtocol.BANDWIDTH_BUDGET_BPS:
		await _finish_child(false, "a sessão gastou %.0f bps, acima do tecto da spec" % measured_bps)
		return
	await _finish_child(true,
		"%s: dois corpos/origens visiveis, movimento remoto em %.2f s, %.0f bps" % [
			_role_label(), join_elapsed, measured_bps])


func _wait_for_remote_body() -> Node3D:
	var deadline := _now() + BODY_TIMEOUT_SECONDS
	while _now() < deadline:
		var bodies := get_tree().get_nodes_in_group("coop_remote_player")
		if not bodies.is_empty() and bodies[0] is Node3D and bodies[0].visible:
			return bodies[0] as Node3D
		await get_tree().process_frame
	return null


func _wait_for_remote_motion(remote: Node3D, start: Vector3) -> bool:
	return await _wait_until(func() -> bool:
		return is_instance_valid(remote) \
			and remote.global_position.distance_to(start) >= POSITION_EPSILON_METERS,
		BODY_TIMEOUT_SECONDS)


func _move_local_player() -> void:
	await _wait_until(func() -> bool: return is_instance_valid(_actor) and _actor.input_enabled,
		BODY_TIMEOUT_SECONDS)
	Input.action_press("move_forward")
	for _frame: int in MOVE_FRAMES:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	for _frame: int in 3:
		await get_tree().physics_frame


func _press_action(action_name: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await get_tree().process_frame
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await get_tree().process_frame


func _type_text(field: LineEdit, value: String) -> void:
	for character: String in value:
		var event := InputEventKey.new()
		event.pressed = true
		event.unicode = character.unicode_at(0)
		event.keycode = character.unicode_at(0)
		Input.parse_input_event(event)
		await get_tree().process_frame


func _wait_until(condition: Callable, timeout_seconds: float) -> bool:
	var deadline := _now() + timeout_seconds
	while _now() < deadline:
		if bool(condition.call()):
			return true
		await get_tree().process_frame
	return bool(condition.call())


func _wait_for_marker(marker_name: String, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool: return _has_marker(marker_name), timeout_seconds)


func _visible_status(menu: NetMenu, fallback: String) -> String:
	var status := menu.get("_status") as Label
	if status != null and not status.text.strip_edges().is_empty():
		return status.text
	return fallback


func _finish_child(passed: bool, message: String) -> void:
	Input.action_release("move_forward")
	if NetSession.is_online():
		NetSession.leave("A prova terminou.")
	GameData.replace_save_state({})
	if is_instance_valid(_gameplay):
		_gameplay.queue_free()
		await get_tree().process_frame
	_cleanup_proof_save(_role)
	_write_marker("%s-done" % _role, ("PASS: " if passed else "FAIL: ") + message)
	await get_tree().process_frame
	get_tree().quit(0 if passed else 1)


func _spawn_child(executable: String, child_role: String) -> int:
	var project_dir := ProjectSettings.globalize_path("res://")
	var log_path := ProjectSettings.globalize_path("%s/%s.log" % [_run_dir, child_role])
	var args := PackedStringArray([
		"--headless", "--audio-driver", "Dummy",
		"--path", project_dir,
		"--log-file", log_path,
		"res://src/coop/coop_online_gameplay_proof.tscn",
		"--", "--coop-proof-role=%s" % child_role,
		"--coop-proof-run=%s" % _run_id,
		"--coop-proof-port=%d" % _proof_port,
		"--scene=combat",
	])
	return OS.create_process(executable, args)


func _stop_child(pid: int) -> void:
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)


func _argument_value(prefix: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


func _role_label() -> String:
	return "anfitriao" if _role == ROLE_HOST else "convidado"


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _marker_path(marker_name: String) -> String:
	return "%s/%s.txt" % [_run_dir, marker_name]


func _has_marker(marker_name: String) -> bool:
	return FileAccess.file_exists(_marker_path(marker_name))


func _write_marker(marker_name: String, content: String) -> void:
	var file := FileAccess.open(_marker_path(marker_name), FileAccess.WRITE)
	if file != null:
		file.store_string(content)
		file.close()


func _read_marker(marker_name: String) -> String:
	var file := FileAccess.open(_marker_path(marker_name), FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content


func _prepare_run_dir() -> bool:
	var absolute := ProjectSettings.globalize_path(_run_dir)
	return DirAccess.make_dir_absolute(absolute) in [OK, ERR_ALREADY_EXISTS]


func _cleanup_run_dir() -> void:
	var known_files: Array[String] = [
		"host-ready", "host-body-ready", "guest-body-ready",
		"host-observing", "guest-observing", "host-moved", "guest-moved",
		"host-done", "guest-done",
	]
	for marker_name: String in known_files:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_marker_path(marker_name)))
	for child_role: String in [ROLE_HOST, ROLE_GUEST]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(
			"%s/%s.log" % [_run_dir, child_role]))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_run_dir))


func _proof_slot(child_role: String) -> int:
	var parent_pid := int(_run_id.get_slice("-", 0))
	var role_offset := 0 if child_role == ROLE_HOST else 1
	return PROOF_SLOT_BASE + (parent_pid % 100000) * 10 + role_offset


func _cleanup_proof_save(child_role: String) -> void:
	var base_path := SaveSystem.slot_path(_proof_slot(child_role))
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(base_path + suffix))


func _print_child_log(child_role: String) -> void:
	var path := "%s/%s.log" % [_run_dir, child_role]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	file.close()
	if not content.is_empty():
		printerr("--- log %s ---\n%s" % [child_role, content])


func _proof_left_no_save() -> bool:
	for child_role: String in [ROLE_HOST, ROLE_GUEST]:
		var proof_base := SaveSystem.slot_path(_proof_slot(child_role))
		for suffix: String in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(proof_base + suffix):
				return false
	# Outra arvore pode gravar os slots reais enquanto esta prova corre. A regra
	# verificavel aqui e de autoria: nenhum deles pode conter ESTE perfil.
	for slot: int in range(3):
		for suffix: String in ["", ".bak"]:
			var path := SaveSystem.slot_path(slot) + suffix
			if not FileAccess.file_exists(path):
				continue
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				continue
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary:
				var character := (parsed as Dictionary).get("character", {}) as Dictionary
				if String(character.get("profile_id", "")).begins_with("prova-%s" % _run_id):
					return false
	return true


func _fail_parent(message: String) -> void:
	printerr("CO-OP ONLINE FALHOU: %s" % message)
	get_tree().quit(1)
