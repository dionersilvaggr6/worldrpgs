class_name GameShell
extends Node
## Casca navegavel do jogo: menu principal, criacao e transicao para o mundo.
## A cena 3D so nasce depois de um save valido, por isso arrancar nunca larga o
## jogador no greybox e os menus nao pagam o custo do mundo em segundo plano.

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/gameplay.tscn")
## ⚠️ NAO voltar a escrever as origens a mao aqui.
## 02-08: o Mago do Mal foi decidido, entrou em attributes.json, e NAO APARECIA
## no ecra de criacao — porque esta lista era uma constante de seis, escrita a
## mao. O jogador via seis origens e os dados tinham sete. E exactamente o que a
## regra de ouro do game/CLAUDE.md existe para impedir: os catalogos mandam, o
## codigo le. Agora le.
static var CLASS_IDS: Array[String]:
	get:
		var ids: Array[String] = []
		for id: String in (GameData.attributes.get("classes", {}) as Dictionary):
			if not id.begins_with("_"):
				ids.append(id)
		return ids

static func _catalogue_strings(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if not values is Array:
		return result
	for value: Variant in values as Array:
		result.append(String(value))
	return result

const STEP_TITLES: Array[String] = ["1  Classe", "2  Aspecto", "3  Nome", "4  Rever"]
const SKIN_TINTS := {
	"skin_01": Color("9a6048"),
	"skin_02": Color("c88768"),
	"skin_03": Color("e1ad86"),
	"skin_04": Color("f0c9aa"),
}
const ACTION_LABELS := {
	"move_forward": "Mover para a frente", "move_back": "Mover para trás",
	"move_left": "Mover para a esquerda", "move_right": "Mover para a direita",
	"look_left": "Câmara à esquerda", "look_right": "Câmara à direita",
	"look_up": "Câmara para cima", "look_down": "Câmara para baixo",
	"attack": "Ataque leve", "heavy_mod": "Ataque pesado (manter)",
	"block": "Bloquear (manter)", "parry": "Aparar (tocar)",
	"dodge_sprint": "Esquivar (tocar) / correr (manter)", "lock_on": "Fixar alvo",
	"next_spell": "Magia seguinte / roda", "cast": "Conjurar", "meditate": "Meditar",
	"use_item": "Usar item", "ability": "Habilidade de origem",
	"raise_dead": "Levantar corpo",
	"toggle_grip": "Uma / duas mãos", "interact": "Interagir / descansar",
	"hotbar_1": "Atalho 1", "hotbar_2": "Atalho 2", "hotbar_3": "Atalho 3",
	"hotbar_4": "Atalho 4", "hotbar_5": "Atalho 5",
	"loadout_next": "Equipamento seguinte", "loadout_prev": "Equipamento anterior",
	"toggle_perf": "Mostrar FPS", "toggle_help": "Instruções", "toggle_mouse": "Libertar rato",
	"reset_arena": "Reiniciar arena", "debug_class_next": "Classe de teste seguinte",
	"pause_menu": "Pausa",
	"inventory_menu": "Mochila / inventário",
	"open_map": "Mapa da zona",
}
const INSTRUCTION_GROUPS := [
	{"title": "MOVIMENTO E CÂMARA", "actions": [
		"move_forward", "move_back", "move_left", "move_right",
		"look_left", "look_right", "look_up", "look_down"]},
	{"title": "COMBATE", "actions": [
		"attack", "heavy_mod", "block", "parry", "dodge_sprint",
		"lock_on", "toggle_grip", "ability"]},
	{"title": "MAGIA E ITENS", "actions": [
		"next_spell", "cast", "raise_dead", "meditate", "use_item", "hotbar_1",
		"hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5"]},
	{"title": "MUNDO E SISTEMA", "actions": [
		"interact", "loadout_next", "loadout_prev", "toggle_perf",
		"toggle_help", "toggle_mouse", "reset_arena", "debug_class_next",
		"pause_menu", "inventory_menu", "open_map"]},
]
static var LEARNING_TIP_IDS: Array[String]:
	get:
		return _catalogue_strings((GameData.ui_strings.get("intro", {}) as Dictionary).get(
			"tip_ids", []))

var _layer: CanvasLayer
var _screen: Control
var _gameplay: Node
var _theme: Theme
var _draft: Dictionary = {}
var _creation_step := 0
var _options_box: VBoxContainer
var _detail: RichTextLabel
var _footer_previous: Button
var _footer_next: Button
var _footer_create: Button
var _preview_viewport: SubViewport
var _preview_pivot: Node3D
var _preview_visual: CharacterVisual
var _preview_dragging := false
var _capture_screen := ""
var _capture_frames := 0
var _pause_layer: CanvasLayer
var _pause_open := false
var _settings_layer: CanvasLayer
var _settings_root: Control
var _settings_origin := "main"
var _settings_tab := "graphics"
var _settings_fps_label: Label
var _settings_content: Control
var _binding_action := ""
var _binding_add_secondary := false
var _binding_prompt: Control
var _pending_binding_event: InputEvent
var _pending_binding_action := ""
var _pending_binding_add := false
var _selected_control_action := ""
var _instructions_layer: CanvasLayer
var _instructions_open := false
var _instructions_paused_here := false
var _inventory_menu: InventoryMenu
var _spell_wheel: SpellWheel
var _spell_hold_seconds := 0.0
var _spell_hold_pending := false
const SPELL_WHEEL_HOLD_SECONDS := 0.28


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = _make_theme()
	_capture_screen = _argument_value("--capture-ui=")
	if _capture_screen != "":
		Bench.set_overlay_visible(false)
	var measured_screen := Bench.scene_arg if Bench.is_benchmarking() else ""
	if measured_screen == "ui-instructions" or _capture_screen == "instructions":
		show_main_menu()
		_show_instructions()
	elif measured_screen.begins_with("ui-settings") or _capture_screen.begins_with("settings"):
		show_main_menu()
		_settings_tab = _settings_variant(measured_screen if measured_screen != "" else _capture_screen)
		_show_settings("main")
	elif measured_screen == "ui-main" or _capture_screen == "main":
		show_main_menu()
	elif measured_screen == "ui-creation" or _capture_screen == "creation":
		show_character_creation()
	elif measured_screen == "ui-opening" or _capture_screen == "opening":
		show_opening()
	elif measured_screen == "ui-awakening" or _capture_screen == "awakening":
		_start_gameplay()
		call_deferred("_show_capture_awakening")
	elif measured_screen == "ui-tip" or _capture_screen == "tip":
		_start_gameplay()
		call_deferred("_show_capture_tip")
	elif measured_screen == "ui-inventory" or _capture_screen == "inventory":
		_start_gameplay()
		call_deferred("_show_inventory")
	elif measured_screen == "ui-spell-wheel" or _capture_screen == "spell-wheel":
		_start_gameplay()
		call_deferred("_show_spell_wheel", true)
	elif measured_screen == "ui-pause" or _capture_screen == "pause":
		_start_gameplay()
		call_deferred("_show_pause_menu")
	elif Bench.is_benchmarking() or "--photos" in OS.get_cmdline_user_args():
		_start_gameplay()
	else:
		show_main_menu()
	set_process(true)


func _unhandled_input(_event: InputEvent) -> void:
	if is_instance_valid(_inventory_menu):
		return
	if is_instance_valid(_gameplay) and _gameplay.has_method("wake_sequence_active") \
			and bool(_gameplay.call("wake_sequence_active")):
		return
	if is_instance_valid(_gameplay) and InputMap.has_action("inventory_menu") \
			and Input.is_action_just_pressed("inventory_menu") and not _pause_open \
			and not _instructions_open and not is_instance_valid(_settings_layer):
		_show_inventory()
		get_viewport().set_input_as_handled()
		return
	if InputMap.has_action("toggle_help") and Input.is_action_just_pressed("toggle_help"):
		_toggle_instructions()
		get_viewport().set_input_as_handled()
		return
	if _instructions_open and InputMap.has_action("pause_menu") \
			and Input.is_action_just_pressed("pause_menu"):
		_close_instructions()
		get_viewport().set_input_as_handled()
		return
	if not is_instance_valid(_gameplay) or not InputMap.has_action("pause_menu"):
		return
	if Input.is_action_just_pressed("pause_menu"):
		if _pause_open:
			_resume_game()
		else:
			_show_pause_menu()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _binding_action == "" or not event.is_pressed():
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		_cancel_binding_capture()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton \
			or (event is InputEventJoypadMotion and absf(
				(event as InputEventJoypadMotion).axis_value) >= 0.5):
		_finish_binding_capture(event)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_tick_spell_wheel(delta)
	if _capture_screen == "":
		return
	_capture_frames += 1
	# Os controlos criam a lista remapeavel no primeiro frame. Esperar tres
	# segundos faz a captura mostrar o FPS sustentado, nao o custo unico de montagem.
	var target_frames := 180 if _capture_screen.begins_with("settings") \
		or _capture_screen in ["inventory", "spell-wheel", "opening", "awakening"] else 30
	if _capture_frames < target_frames:
		return
	var directory := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := "res://captures/%s.png" % _capture_screen
	# A criacao contem um SubViewport 3D; capturar explicitamente a janela raiz
	# evita que o ultimo viewport renderizado substitua a interface completa.
	var result := get_tree().root.get_texture().get_image().save_png(path)
	print("UI_CAPTURE %s %s" % [path, error_string(result)])
	get_tree().quit(0 if result == OK else 1)


func show_main_menu() -> void:
	_close_inventory()
	_close_spell_wheel(false)
	_close_instructions()
	_close_pause_layer()
	_clear_gameplay()
	_begin_screen()
	_add_background(Color("071014"), Color("26313a"))

	var mist := Label.new()
	mist.text = "BRUMAL"
	mist.position = Vector2(1080, 92)
	mist.add_theme_font_size_override("font_size", 148)
	mist.add_theme_color_override("font_color", Color(0.58, 0.65, 0.68, 0.08))
	_screen.add_child(mist)

	var title := Label.new()
	title.text = "WORLDRPGS"
	title.position = Vector2(150, 160)
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color("e5d3aa"))
	_screen.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A BRUMA CHEGOU.  ENTRA ONDE NINGUÉM ENTRA."
	subtitle.position = Vector2(156, 255)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("93a2a5"))
	_screen.add_child(subtitle)

	var rule := ColorRect.new()
	rule.color = Color("9a743d")
	rule.position = Vector2(156, 302)
	rule.size = Vector2(84, 2)
	_screen.add_child(rule)

	var menu := VBoxContainer.new()
	menu.position = Vector2(150, 380)
	menu.size = Vector2(430, 420)
	menu.add_theme_constant_override("separation", 12)
	_screen.add_child(menu)

	var continue_button := _menu_button("CONTINUAR", "Retomar no último ponto de descanso")
	continue_button.disabled = not _has_save()
	continue_button.pressed.connect(_continue_last_save)
	menu.add_child(continue_button)

	var new_button := _menu_button("NOVO JOGO", "Criar uma personagem")
	new_button.pressed.connect(show_character_creation)
	menu.add_child(new_button)

	var settings_button := _menu_button("CONFIGURAÇÕES", "Gráficos, controlos e áudio")
	settings_button.pressed.connect(_show_settings.bind("main"))
	menu.add_child(settings_button)

	var quit_button := _menu_button("SAIR", "Fechar o jogo")
	quit_button.pressed.connect(get_tree().quit)
	menu.add_child(quit_button)

	var version := Label.new()
	version.text = "PROTÓTIPO DA FATIA 1  ·  %s" % ProjectSettings.get_setting(
		"application/config/version", "0.1.0")
	version.position = Vector2(151, 970)
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", Color("6f7b7d"))
	_screen.add_child(version)
	new_button.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_opening() -> void:
	_close_instructions()
	_close_pause_layer()
	_clear_gameplay()
	_begin_screen()
	_add_background(Color("030709"), Color("152127"))
	var mist := Label.new()
	mist.text = "BRUMAL"
	mist.position = Vector2(1060, 96)
	mist.add_theme_font_size_override("font_size", 156)
	mist.add_theme_color_override("font_color", Color(0.58, 0.65, 0.68, 0.07))
	_screen.add_child(mist)
	var chapter := Label.new()
	chapter.text = "PRÓLOGO"
	chapter.position = Vector2(224, 166)
	chapter.add_theme_font_size_override("font_size", 17)
	chapter.add_theme_color_override("font_color", Color("d4b36f"))
	_screen.add_child(chapter)
	var title := Label.new()
	title.text = "A BRUMA CHEGOU"
	title.position = Vector2(218, 214)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("eadbb9"))
	_screen.add_child(title)
	var rule := ColorRect.new()
	rule.color = Color("9a743d")
	rule.position = Vector2(224, 300)
	rule.size = Vector2(112, 2)
	_screen.add_child(rule)
	var story := RichTextLabel.new()
	story.bbcode_enabled = true
	story.position = Vector2(224, 354)
	story.size = Vector2(1000, 410)
	story.add_theme_font_size_override("normal_font_size", 25)
	story.add_theme_font_size_override("bold_font_size", 25)
	story.add_theme_color_override("default_color", Color("aeb7b5"))
	story.text = String((GameData.ui_strings.get("opening", {}) as Dictionary)[
		"story_bbcode"])
	_screen.add_child(story)
	var enter := Button.new()
	enter.text = "ENTRAR EM BRUMAL"
	enter.position = Vector2(224, 820)
	enter.size = Vector2(420, 68)
	enter.pressed.connect(_enter_brumal)
	_screen.add_child(enter)
	var note := Label.new()
	note.text = "O resto é contado pelo caminho. Nenhuma leitura é obrigatória."
	note.position = Vector2(224, 920)
	note.add_theme_color_override("font_color", Color("687778"))
	_screen.add_child(note)
	enter.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _enter_brumal() -> void:
	_start_gameplay(true)


func show_character_creation() -> void:
	_clear_gameplay()
	if _draft.is_empty():
		_draft = {
			"class_id": "warrior",
			"name": "",
			"appearance": (GameData.appearance.get("default", {}) as Dictionary).duplicate(true),
			"slot": _first_free_slot(),
		}
	_creation_step = clampi(_creation_step, 0, 3)
	_begin_screen()
	_add_background(Color("091116"), Color("1a2429"))

	var heading := Label.new()
	heading.text = "NOVO PERSONAGEM"
	heading.position = Vector2(48, 24)
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("e5d3aa"))
	_screen.add_child(heading)

	var law := Label.new()
	law.text = "É SÓ O TEU COMEÇO.  PODES USAR QUALQUER ARMA, ARMADURA E MAGIA."
	law.position = Vector2(475, 32)
	law.add_theme_font_size_override("font_size", 18)
	law.add_theme_color_override("font_color", Color("d4b36f"))
	_screen.add_child(law)

	var access := Button.new()
	access.text = "ACESSIBILIDADE"
	access.position = Vector2(1660, 22)
	access.size = Vector2(220, 46)
	access.pressed.connect(_show_settings.bind("creation"))
	_screen.add_child(access)

	var left := _panel(Vector2(40, 92), Vector2(430, 870))
	var steps := VBoxContainer.new()
	steps.position = Vector2(22, 22)
	steps.size = Vector2(386, 210)
	steps.add_theme_constant_override("separation", 6)
	left.add_child(steps)
	for index: int in STEP_TITLES.size():
		var step_button := Button.new()
		step_button.text = STEP_TITLES[index]
		step_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		step_button.toggle_mode = true
		step_button.button_pressed = index == _creation_step
		step_button.pressed.connect(_set_creation_step.bind(index))
		steps.add_child(step_button)

	var separator := HSeparator.new()
	separator.position = Vector2(22, 240)
	separator.size = Vector2(386, 2)
	left.add_child(separator)
	_options_box = VBoxContainer.new()
	_options_box.position = Vector2(22, 262)
	_options_box.size = Vector2(386, 560)
	_options_box.add_theme_constant_override("separation", 8)
	left.add_child(_options_box)

	_build_preview(Vector2(490, 92), Vector2(760, 870))

	var right := _panel(Vector2(1270, 92), Vector2(610, 870))
	var detail_heading := Label.new()
	detail_heading.text = "O QUE ESTA ESCOLHA MUDA"
	detail_heading.position = Vector2(28, 26)
	detail_heading.add_theme_font_size_override("font_size", 18)
	detail_heading.add_theme_color_override("font_color", Color("d4b36f"))
	right.add_child(detail_heading)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.position = Vector2(28, 72)
	_detail.size = Vector2(554, 680)
	_detail.add_theme_font_size_override("normal_font_size", 20)
	_detail.add_theme_font_size_override("bold_font_size", 22)
	_detail.add_theme_color_override("default_color", Color("d7dddd"))
	right.add_child(_detail)

	var footer := HBoxContainer.new()
	footer.position = Vector2(28, 786)
	footer.size = Vector2(554, 60)
	footer.add_theme_constant_override("separation", 10)
	right.add_child(footer)
	var back := Button.new()
	back.text = "VOLTAR AO MENU"
	back.custom_minimum_size = Vector2(166, 54)
	back.pressed.connect(show_main_menu)
	footer.add_child(back)
	_footer_previous = Button.new()
	_footer_previous.text = "ANTERIOR"
	_footer_previous.custom_minimum_size = Vector2(112, 54)
	_footer_previous.pressed.connect(_previous_creation_step)
	footer.add_child(_footer_previous)
	_footer_next = Button.new()
	_footer_next.text = "SEGUINTE"
	_footer_next.custom_minimum_size = Vector2(112, 54)
	_footer_next.pressed.connect(_next_creation_step)
	footer.add_child(_footer_next)
	_footer_create = Button.new()
	_footer_create.text = "CRIAR"
	_footer_create.custom_minimum_size = Vector2(112, 54)
	_footer_create.pressed.connect(_create_character)
	footer.add_child(_footer_create)
	_refresh_creation_step()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _refresh_creation_step() -> void:
	if not is_instance_valid(_options_box):
		return
	for child: Node in _options_box.get_children():
		child.queue_free()
	match _creation_step:
		0: _build_class_options()
		1: _build_appearance_options()
		2: _build_name_options()
		3: _build_review()
	_footer_previous.disabled = _creation_step == 0
	_footer_next.visible = _creation_step < 3
	_footer_create.visible = _creation_step == 3
	if is_instance_valid(_preview_visual):
		_update_preview()


func _build_class_options() -> void:
	var selected := String(_draft.get("class_id", "warrior"))
	for class_id: String in CLASS_IDS:
		var button := Button.new()
		button.text = String(GameData.class_attributes(class_id).get("display_name", class_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = class_id == selected
		button.custom_minimum_size.y = 48
		button.pressed.connect(_select_class.bind(class_id))
		_options_box.add_child(button)
	_update_class_detail()


func _build_appearance_options() -> void:
	var axes := [
		["body_id", "CORPO"], ["skin_tone_id", "TOM DE PELE"],
		["hair_id", "CABELO"], ["hair_color_id", "COR DO CABELO"],
		["brows_id", "SOBRANCELHAS"], ["accent_id", "ACENTO DO KIT"],
		["voice_id", "VOZ"],
	]
	for axis: Array in axes:
		var key := String(axis[0])
		var label := Label.new()
		label.text = String(axis[1])
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color("99a8a9"))
		_options_box.add_child(label)
		var option := OptionButton.new()
		option.custom_minimum_size.y = 42
		var values: Array = (GameData.appearance.get("options", {}) as Dictionary).get(key, [])
		var labels: Dictionary = GameData.appearance.get("labels", {}) as Dictionary
		var current := String((_draft.get("appearance", {}) as Dictionary).get(key, ""))
		for value: Variant in values:
			option.add_item(String(labels.get(value, value)))
			option.set_item_metadata(option.item_count - 1, value)
			if String(value) == current:
				option.select(option.item_count - 1)
		option.item_selected.connect(_appearance_selected.bind(key, values))
		_options_box.add_child(option)
	_detail.text = "[b]Aspecto sem vantagem mecânica[/b]\n\nOs dois corpos usam o mesmo esqueleto, cápsula, alcance, câmara e frames. Corpo e voz são independentes.\n\nA amostra de voz é provisória; a escolha fica gravada sem inventar áudio."


func _build_name_options() -> void:
	var label := Label.new()
	label.text = "NOME DA PERSONAGEM"
	label.add_theme_color_override("font_color", Color("99a8a9"))
	_options_box.add_child(label)
	var input := LineEdit.new()
	input.name = "CharacterName"
	input.placeholder_text = "1–24 caracteres"
	input.text = String(_draft.get("name", ""))
	input.max_length = 64
	input.custom_minimum_size.y = 54
	input.text_changed.connect(_name_changed)
	_options_box.add_child(input)
	var status := Label.new()
	status.name = "NameStatus"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 80
	_options_box.add_child(status)
	_update_name_status(status)
	_detail.text = "[b]O nome é só texto mostrado.[/b]\n\nNunca é usado como nome de ficheiro, ID de rede ou chave de catálogo. Nomes repetidos são permitidos.\n\nAceita letras Unicode, espaço simples, apóstrofo e hífen."
	input.grab_focus()


func _build_review() -> void:
	var summary := Label.new()
	summary.text = "PRONTO PARA ENTRAR EM BRUMAL"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_color_override("font_color", Color("d4b36f"))
	_options_box.add_child(summary)
	var validation := validate_character_name(String(_draft.get("name", "")))
	_footer_create.disabled = not bool(validation.get("valid", false)) or int(_draft.get("slot", -1)) < 0
	var class_id := String(_draft.get("class_id", "warrior"))
	var attrs := GameData.class_attributes(class_id)
	var loadout: Dictionary = (GameData.weapons.get("loadouts", {}) as Dictionary).get(class_id, {})
	var appearance: Dictionary = _draft.get("appearance", {}) as Dictionary
	var labels: Dictionary = GameData.appearance.get("labels", {}) as Dictionary
	_detail.text = "[b]%s[/b]\n%s\n\n[b]Origem[/b]\n%s — é só o começo.\n\n[b]Atributos[/b]\n%s\n\n[b]Equipamento inicial[/b]\n%s\n\n[b]Aspecto[/b]\n%s · %s\n\n[b]Slot[/b]\n%d" % [
		String(_draft.get("name", "—")),
		String(validation.get("error", "Nome válido.")),
		String(attrs.get("display_name", class_id)), _attribute_line(attrs),
		_loadout_line(loadout),
		String(labels.get(appearance.get("body_id", ""), appearance.get("body_id", ""))),
		String(labels.get(appearance.get("voice_id", ""), appearance.get("voice_id", ""))),
		int(_draft.get("slot", -1)) + 1,
	]


func _update_class_detail() -> void:
	var class_id := String(_draft.get("class_id", "warrior"))
	var attrs := GameData.class_attributes(class_id)
	var loadout: Dictionary = (GameData.weapons.get("loadouts", {}) as Dictionary).get(class_id, {})
	var ability := GameData.ability(class_id)
	var roles := GameData.ui_strings.get("class_roles", {}) as Dictionary
	var role := roles[class_id] as Array
	_detail.text = "[b]%s[/b]\n%s\n\n[b]Começa com[/b]\n%s\n\n[b]É forte quando[/b]\n%s\n\n[b]Sofre quando[/b]\n%s\n\n[b]Verbo de assinatura[/b]\n%s\n\n[b]Atributos[/b]\n%s\n\n[color=#d4b36f]Podes mudar de arma e subir qualquer atributo.[/color]" % [
		String(attrs.get("display_name", class_id)), String(role[0]),
		_loadout_line(loadout), String(role[1]), String(role[2]),
		String(ability.get("display_name", "—")), _attribute_line(attrs),
	]


func _attribute_line(attrs: Dictionary) -> String:
	var parts: Array[String] = []
	for key: String in ["vida", "stamina", "constituicao", "inteligencia", "fe", "forca", "destreza", "carga"]:
		var short := String({"constituicao": "con", "inteligencia": "int", "destreza": "des"}.get(key, key))
		parts.append("%s %d" % [short, int(attrs.get(key, 8))])
	return " · ".join(parts)


func _loadout_line(loadout: Dictionary) -> String:
	var items: Array[String] = []
	for key: String in ["main", "offhand"]:
		var item: Variant = loadout.get(key)
		if item != null and String(item) != "":
			items.append(String(GameData.weapon(String(item)).get("display_name", item)))
	for piece: Variant in loadout.get("pecas", []):
		items.append(String(piece).replace("_", " ").capitalize())
	return ", ".join(items)


func _select_class(class_id: String) -> void:
	_draft["class_id"] = class_id
	_refresh_creation_step()


func _appearance_selected(index: int, key: String, values: Array) -> void:
	if index < 0 or index >= values.size():
		return
	var appearance: Dictionary = _draft.get("appearance", {}) as Dictionary
	appearance[key] = values[index]
	_draft["appearance"] = appearance
	_update_preview()


func _name_changed(value: String) -> void:
	_draft["name"] = value
	var status := _options_box.get_node_or_null("NameStatus") as Label
	if status != null:
		_update_name_status(status)


func _update_name_status(status: Label) -> void:
	var validation := validate_character_name(String(_draft.get("name", "")))
	status.text = "%d/24\n%s" % [int(validation.get("count", 0)), String(validation.get("error", "Nome válido."))]
	status.add_theme_color_override("font_color", Color("9fc59f") if validation.get("valid") else Color("db8d7c"))


func _set_creation_step(index: int) -> void:
	_creation_step = clampi(index, 0, 3)
	show_character_creation()


func _previous_creation_step() -> void:
	_set_creation_step(_creation_step - 1)


func _next_creation_step() -> void:
	if _creation_step == 2 and not validate_character_name(String(_draft.get("name", ""))).get("valid"):
		return
	_set_creation_step(_creation_step + 1)


func _create_character() -> void:
	var validation := validate_character_name(String(_draft.get("name", "")))
	if not bool(validation.get("valid", false)):
		_creation_step = 2
		show_character_creation()
		return
	var slot := int(_draft.get("slot", -1))
	if slot < 0 or FileAccess.file_exists(SaveSystem.slot_path(slot)):
		_show_modal("SEM SLOT LIVRE", "Os três slots estão ocupados. Este fluxo nunca substitui um save.")
		return
	var identity := {
		"name": String(validation.get("name", "")),
		"appearance": (_draft.get("appearance", {}) as Dictionary).duplicate(true),
	}
	var profile_id := "local-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	if not SaveSystem.new_game(profile_id, String(_draft.get("class_id", "warrior")), slot, identity):
		_show_modal("NÃO FOI POSSÍVEL GRAVAR", SaveSystem.last_error)
		return
	show_opening()


func _continue_last_save() -> void:
	var slot := SaveSystem.latest_slot()
	if slot < 0:
		_show_modal("SEM SAVE", "Não existe uma gravação íntegra para continuar.")
		return
	var loaded := SaveSystem.load_slot(slot)
	if loaded.is_empty():
		_show_modal("NÃO FOI POSSÍVEL CARREGAR", SaveSystem.last_error)
		return
	_start_gameplay()


func _start_gameplay(wake_on_start := false) -> void:
	_close_inventory()
	_close_spell_wheel(false)
	_close_instructions()
	_close_pause_layer()
	_clear_screen()
	if is_instance_valid(_gameplay):
		_gameplay.queue_free()
	_gameplay = GAMEPLAY_SCENE.instantiate()
	add_child(_gameplay)
	if wake_on_start:
		_gameplay.call_deferred("begin_wake_sequence")


func _show_capture_tip() -> void:
	if not is_instance_valid(_gameplay):
		return
	var capture_hud := _gameplay.get("hud") as Hud
	if capture_hud != null:
		capture_hud.context_tip(tutorial_tip_text("dodge"), 30.0)


func _show_capture_awakening() -> void:
	if is_instance_valid(_gameplay) and _gameplay.has_method("begin_wake_sequence"):
		_gameplay.call("begin_wake_sequence", true)


func return_to_main_menu() -> void:
	show_main_menu()


func _show_pause_menu() -> void:
	if _pause_open or not is_instance_valid(_gameplay) or is_instance_valid(_spell_wheel):
		return
	_pause_open = true
	var coop := _is_coop_session()
	get_tree().paused = pause_world_for_mode(coop)
	_set_gameplay_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 400
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.01, 0.012, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_layer.add_child(shade)
	var panel := Panel.new()
	panel.theme = _theme
	panel.position = Vector2(610, 160)
	panel.size = Vector2(700, 760)
	_pause_layer.add_child(panel)
	var eyebrow := Label.new()
	eyebrow.text = "CO-OP · O MUNDO CONTINUA" if coop else "SOLO · MUNDO EM PAUSA"
	eyebrow.position = Vector2(58, 50)
	eyebrow.add_theme_font_size_override("font_size", 17)
	eyebrow.add_theme_color_override("font_color", Color("d4b36f"))
	panel.add_child(eyebrow)
	var title := Label.new()
	title.text = "PAUSA"
	title.position = Vector2(52, 92)
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("eadbb9"))
	panel.add_child(title)
	var explanation := Label.new()
	explanation.text = ("O anfitrião não pode congelar o parceiro. Procura abrigo antes de abrir este menu."
		if coop else "O mundo está parado. Ao jogar a dois, este mesmo menu não interrompe o combate.")
	explanation.position = Vector2(58, 172)
	explanation.size = Vector2(584, 86)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 18)
	explanation.add_theme_color_override("font_color", Color("96a3a4"))
	panel.add_child(explanation)
	var menu := VBoxContainer.new()
	menu.position = Vector2(56, 298)
	menu.size = Vector2(588, 330)
	menu.add_theme_constant_override("separation", 12)
	panel.add_child(menu)
	var resume := _menu_button("RETOMAR", "Voltar ao jogo")
	resume.custom_minimum_size.x = 588
	resume.pressed.connect(_resume_game)
	menu.add_child(resume)
	var settings := _menu_button("CONFIGURAÇÕES", "Gráficos, controlos e áudio")
	settings.custom_minimum_size.x = 588
	settings.pressed.connect(_show_settings.bind("pause"))
	menu.add_child(settings)
	var instructions := _menu_button("COMANDOS", "Ver todas as tuas teclas num só ecrã")
	instructions.custom_minimum_size.x = 588
	instructions.pressed.connect(_show_instructions)
	menu.add_child(instructions)
	var leave := _menu_button("SAIR PARA O MENU", "Guarda os eventos confirmados e abandona o mundo")
	leave.custom_minimum_size.x = 588
	leave.pressed.connect(_leave_gameplay_to_menu)
	menu.add_child(leave)
	var hint := Label.new()
	hint.text = "%s  RETOMAR" % _binding_label_for_ui("pause_menu")
	hint.position = Vector2(58, 688)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("697879"))
	panel.add_child(hint)
	resume.grab_focus()


func _resume_game() -> void:
	_close_pause_layer()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _leave_gameplay_to_menu() -> void:
	if not GameData.save_state.is_empty():
		SaveSystem.save_current()
	show_main_menu()


func _close_pause_layer() -> void:
	get_tree().paused = false
	_pause_open = false
	if is_instance_valid(_pause_layer):
		_fechar_no(_pause_layer)
	_pause_layer = null
	_set_gameplay_input(true)


func _is_coop_session() -> bool:
	return multiplayer.has_multiplayer_peer() \
		and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


static func pause_world_for_mode(is_coop: bool) -> bool:
	return not is_coop


func _binding_label_for_ui(action_name: String) -> String:
	return SettingsSystem.binding_label(action_name).to_upper()


static func instruction_actions() -> Array[String]:
	var actions: Array[String] = []
	for group: Dictionary in INSTRUCTION_GROUPS:
		for action_name: String in group.get("actions", []):
			actions.append(action_name)
	return actions


static func tutorial_tip_text(tip_id: String) -> String:
	match tip_id:
		"movement":
			return "%s / %s / %s / %s — mover  ·  rato — câmara" % [
				SettingsSystem.binding_label("move_forward"),
				SettingsSystem.binding_label("move_back"),
				SettingsSystem.binding_label("move_left"),
				SettingsSystem.binding_label("move_right")]
		"attack":
			return "%s — ataque leve" % SettingsSystem.binding_label("attack")
		"dodge":
			return "%s — esquiva; uma estocada falhada deixa as costas abertas" % \
				SettingsSystem.binding_label("dodge_sprint")
		"parry":
			return "%s — aparar; toca durante a preparação do golpe" % \
				SettingsSystem.binding_label("parry")
		"flask":
			return "%s — Frasco de Bruma" % SettingsSystem.binding_label("use_item")
	return ""


func _toggle_instructions() -> void:
	if _instructions_open:
		_close_instructions()
	else:
		_show_instructions()


func _show_instructions() -> void:
	if _instructions_open:
		return
	_instructions_open = true
	_instructions_paused_here = false
	if is_instance_valid(_gameplay) and not _pause_open:
		_instructions_paused_here = pause_world_for_mode(_is_coop_session())
		if _instructions_paused_here:
			get_tree().paused = true
		_set_gameplay_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_instructions_layer = CanvasLayer.new()
	_instructions_layer.layer = 550
	_instructions_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_instructions_layer)
	var root := Control.new()
	root.theme = _theme
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_instructions_layer.add_child(root)
	var background := ColorRect.new()
	background.color = Color("071014")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(background)
	var title := Label.new()
	title.text = "COMANDOS"
	title.position = Vector2(48, 28)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("eadbb9"))
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Este ecrã lê as tuas ligações actuais. Tocar e manter são acções diferentes."
	subtitle.position = Vector2(48, 76)
	subtitle.add_theme_color_override("font_color", Color("96a3a4"))
	root.add_child(subtitle)
	var world_rule := Label.new()
	world_rule.text = ("CO-OP · O MUNDO CONTINUA" if is_instance_valid(_gameplay) \
		and _is_coop_session() else "SOLO · O MUNDO ESTÁ EM PAUSA" if \
		_instructions_paused_here else "REFERÊNCIA · TODAS AS ACÇÕES NUM ECRÃ")
	world_rule.position = Vector2(1240, 44)
	world_rule.size = Vector2(420, 36)
	world_rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	world_rule.add_theme_color_override("font_color", Color("d4b36f"))
	root.add_child(world_rule)
	var close := Button.new()
	close.text = "VOLTAR"
	close.position = Vector2(1680, 30)
	close.size = Vector2(190, 54)
	close.pressed.connect(_close_instructions)
	root.add_child(close)
	for group_index: int in INSTRUCTION_GROUPS.size():
		var group: Dictionary = INSTRUCTION_GROUPS[group_index]
		var panel := Panel.new()
		panel.position = Vector2(48 + group_index * 462, 126)
		panel.size = Vector2(438, 828)
		root.add_child(panel)
		var heading := Label.new()
		heading.text = String(group.get("title", ""))
		heading.position = Vector2(24, 22)
		heading.add_theme_font_size_override("font_size", 19)
		heading.add_theme_color_override("font_color", Color("d4b36f"))
		panel.add_child(heading)
		var row_y := 70.0
		for action_name: String in group.get("actions", []):
			var action_label := Label.new()
			action_label.text = String(ACTION_LABELS.get(action_name, action_name))
			action_label.position = Vector2(24, row_y)
			action_label.size = Vector2(390, 24)
			action_label.add_theme_font_size_override("font_size", 16)
			panel.add_child(action_label)
			var binding := Label.new()
			binding.text = SettingsSystem.binding_label(action_name)
			binding.position = Vector2(24, row_y + 25)
			binding.size = Vector2(390, 24)
			binding.clip_text = true
			binding.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			binding.add_theme_font_size_override("font_size", 14)
			binding.add_theme_color_override("font_color", Color("d4b36f"))
			panel.add_child(binding)
			row_y += 78.0
	var footer := Label.new()
	footer.text = "%s — fechar  ·  As dicas contextuais aparecem uma vez e nunca durante combate." % \
		_binding_label_for_ui("toggle_help")
	footer.position = Vector2(48, 990)
	footer.size = Vector2(1820, 42)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color("7f8e90"))
	root.add_child(footer)
	close.grab_focus()


func _close_instructions() -> void:
	if not _instructions_open:
		return
	if _instructions_paused_here:
		get_tree().paused = false
	_instructions_paused_here = false
	_instructions_open = false
	if is_instance_valid(_instructions_layer):
		_fechar_no(_instructions_layer)
	_instructions_layer = null
	if is_instance_valid(_gameplay) and not _pause_open and not is_instance_valid(_settings_layer):
		_set_gameplay_input(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _set_gameplay_input(enabled: bool) -> void:
	if is_instance_valid(_gameplay) and _gameplay.has_method("set_local_input_enabled"):
		_gameplay.call("set_local_input_enabled", enabled)


func _show_inventory() -> void:
	if is_instance_valid(_inventory_menu) or not is_instance_valid(_gameplay):
		return
	# Nem solo nem co-op pausam aqui: gerir a mochila e uma escolha vulneravel.
	_set_gameplay_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_inventory_menu = InventoryMenu.new()
	add_child(_inventory_menu)
	_inventory_menu.closed.connect(_close_inventory)
	_inventory_menu.open(_theme, _gameplay)


func _close_inventory() -> void:
	if is_instance_valid(_inventory_menu):
		_fechar_no(_inventory_menu)
	_inventory_menu = null
	if is_instance_valid(_gameplay) and not _pause_open and not _instructions_open \
			and not is_instance_valid(_settings_layer):
		_set_gameplay_input(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _tick_spell_wheel(delta: float) -> void:
	if not is_instance_valid(_gameplay) or _pause_open or _instructions_open \
			or is_instance_valid(_settings_layer) or is_instance_valid(_inventory_menu) \
			or (_gameplay.has_method("wake_sequence_active") \
			and bool(_gameplay.call("wake_sequence_active"))):
		_spell_hold_pending = false
		_spell_hold_seconds = 0.0
		return
	if Input.is_action_just_pressed("next_spell"):
		_spell_hold_pending = true
		_spell_hold_seconds = 0.0
	if _spell_hold_pending and Input.is_action_pressed("next_spell"):
		_spell_hold_seconds += delta
		if _spell_hold_seconds >= SPELL_WHEEL_HOLD_SECONDS and not is_instance_valid(_spell_wheel):
			_show_spell_wheel(false)
	if _spell_hold_pending and Input.is_action_just_released("next_spell"):
		if is_instance_valid(_spell_wheel):
			_close_spell_wheel(true)
		elif _gameplay.has_method("cycle_spell"):
			_gameplay.call("cycle_spell")
		_spell_hold_pending = false
		_spell_hold_seconds = 0.0


func _show_spell_wheel(capture_mode := false) -> void:
	if is_instance_valid(_spell_wheel) or not is_instance_valid(_gameplay):
		return
	var favorites: Array[String] = []
	for spell_value: Variant in _gameplay.call("spell_favorites"):
		favorites.append(String(spell_value))
	_set_gameplay_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_spell_wheel = SpellWheel.new()
	add_child(_spell_wheel)
	_spell_wheel.open(_theme, favorites, String(_gameplay.call("selected_spell_id")), capture_mode)


func _close_spell_wheel(cast_selection: bool) -> void:
	if not is_instance_valid(_spell_wheel):
		return
	var selected := _spell_wheel.selected_spell_id
	_fechar_no(_spell_wheel)
	_spell_wheel = null
	if is_instance_valid(_gameplay):
		_set_gameplay_input(true)
		if cast_selection and selected != "" and _gameplay.has_method("select_and_cast_spell"):
			_gameplay.call("select_and_cast_spell", selected)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_settings(origin: String) -> void:
	if is_instance_valid(_settings_layer):
		return
	_settings_origin = origin
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 500
	_settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings_layer)
	_settings_root = Control.new()
	_settings_root.theme = _theme
	_settings_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_layer.add_child(_settings_root)
	var background := ColorRect.new()
	background.color = Color("091217")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_root.add_child(background)
	var title := Label.new()
	title.text = "CONFIGURAÇÕES"
	title.position = Vector2(48, 28)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("eadbb9"))
	_settings_root.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(48, 92)
	tabs.size = Vector2(1030, 58)
	tabs.add_theme_constant_override("separation", 8)
	_settings_root.add_child(tabs)
	for tab_data: Array in [["graphics", "GRÁFICOS"], ["controls", "CONTROLOS"], ["audio", "ÁUDIO"]]:
		var tab := Button.new()
		tab.text = String(tab_data[1])
		tab.custom_minimum_size = Vector2(230, 52)
		tab.toggle_mode = true
		tab.button_pressed = _settings_tab == String(tab_data[0])
		tab.pressed.connect(_set_settings_tab.bind(String(tab_data[0])))
		tabs.add_child(tab)
	var close := Button.new()
	close.text = "VOLTAR"
	close.position = Vector2(1660, 30)
	close.size = Vector2(210, 54)
	close.pressed.connect(_close_settings)
	_settings_root.add_child(close)
	_settings_content = Panel.new()
	_settings_content.position = Vector2(48, 170)
	_settings_content.size = Vector2(1260, 850)
	_settings_root.add_child(_settings_content)
	var monitor := Panel.new()
	monitor.position = Vector2(1330, 170)
	monitor.size = Vector2(540, 850)
	_settings_root.add_child(monitor)
	_build_settings_monitor(monitor)
	_build_settings_tab()
	var timer := Timer.new()
	timer.wait_time = 0.35
	timer.autostart = true
	timer.process_callback = Timer.TIMER_PROCESS_IDLE
	timer.timeout.connect(_update_settings_fps)
	_settings_root.add_child(timer)
	_update_settings_fps()


func _build_settings_monitor(panel: Panel) -> void:
	var label := Label.new()
	label.text = "LEI 4 · EFEITO AO VIVO"
	label.position = Vector2(34, 34)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("d4b36f"))
	panel.add_child(label)
	_settings_fps_label = Label.new()
	_settings_fps_label.position = Vector2(30, 88)
	_settings_fps_label.size = Vector2(480, 108)
	_settings_fps_label.add_theme_font_size_override("font_size", 36)
	_settings_fps_label.add_theme_color_override("font_color", Color("9fc59f"))
	panel.add_child(_settings_fps_label)
	var explanation := RichTextLabel.new()
	explanation.bbcode_enabled = true
	explanation.position = Vector2(34, 226)
	explanation.size = Vector2(472, 550)
	explanation.add_theme_font_size_override("normal_font_size", 19)
	explanation.add_theme_font_size_override("bold_font_size", 21)
	panel.add_child(explanation)
	var preset := _graphics_preset()
	explanation.text = "[b]Preset activo: %s[/b]\n\nEscala 3D: %d%%\nDistância de visão: %d m\nÁrvores no próximo carregamento: %d\nSombras: %s\n\n[color=#d4b36f]BAIXO[/color] reduz a resolução 3D para 85%%, encurta a vista e corta sombras. A interface mantém a resolução nativa para continuar legível.\n\nAs alterações visuais aplicam-se já; densidade do cenário aplica-se ao próximo carregamento." % [
		SettingsSystem.graphics_preset_name().to_upper(),
		int(float(preset.get("render_scale", 1.0)) * 100.0),
		int(preset.get("view_distance", 70)), int(preset.get("tree_count", 100)),
		"sim" if bool(preset.get("shadows", false)) else "não",
	]


func _build_settings_tab() -> void:
	match _settings_tab:
		"controls": _build_controls_settings()
		"audio": _build_audio_settings()
		_: _build_graphics_settings()


func _settings_heading(title: String, description: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.position = Vector2(34, 28)
	box.size = Vector2(1192, 780)
	box.add_theme_constant_override("separation", 12)
	_settings_content.add_child(box)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("eadbb9"))
	box.add_child(heading)
	var detail := Label.new()
	detail.text = description
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(1160, 52)
	detail.add_theme_color_override("font_color", Color("96a3a4"))
	box.add_child(detail)
	return box


func _build_graphics_settings() -> void:
	var box := _settings_heading("GRÁFICOS",
		"Escolhe desempenho com um botão. A alteração é visível sem reiniciar o jogo.")
	var current := SettingsSystem.graphics_preset_name()
	var presets: Dictionary = _graphics_catalogue().get("presets", {}) as Dictionary
	for preset_name: String in ["alto", "medio", "baixo"]:
		var preset: Dictionary = presets.get(preset_name, {}) as Dictionary
		var button := Button.new()
		button.text = "%s%s\n%d%% resolução 3D · vista %d m · %s" % [
			"◆  " if current == preset_name else "", preset_name.to_upper(),
			int(float(preset.get("render_scale", 1.0)) * 100.0),
			int(preset.get("view_distance", 70)),
			"sombras" if bool(preset.get("shadows", false)) else "sem sombras",
		]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(1120, 80)
		button.pressed.connect(_select_graphics_preset.bind(preset_name))
		box.add_child(button)
	var graphics: Dictionary = SettingsSystem.data.get("graphics", {}) as Dictionary
	var fullscreen := CheckButton.new()
	fullscreen.text = "Ecrã inteiro"
	fullscreen.button_pressed = bool(graphics.get("fullscreen", true))
	fullscreen.toggled.connect(SettingsSystem.set_fullscreen)
	box.add_child(fullscreen)
	var show_fps := CheckButton.new()
	show_fps.text = "Mostrar FPS durante o jogo"
	show_fps.button_pressed = bool(graphics.get("show_fps", true))
	show_fps.toggled.connect(SettingsSystem.set_show_fps)
	box.add_child(show_fps)
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 18)
	box.add_child(fps_row)
	var fps_label := Label.new()
	fps_label.text = "Limite de FPS"
	fps_label.custom_minimum_size = Vector2(260, 48)
	fps_row.add_child(fps_label)
	var fps_option := OptionButton.new()
	for limit: int in [30, 60, 120, 0]:
		fps_option.add_item("Sem limite" if limit == 0 else str(limit), limit)
		if int(graphics.get("fps_limit", 60)) == limit:
			fps_option.select(fps_option.item_count - 1)
	fps_option.item_selected.connect(_fps_limit_selected.bind(fps_option))
	fps_row.add_child(fps_option)


func _build_controls_settings() -> void:
	var box := _settings_heading("CONTROLOS",
		"Tudo é remapeável. Alterar conserva a ligação de comando; Adicionar permite uma segunda tecla.")
	var preferences := HBoxContainer.new()
	preferences.custom_minimum_size = Vector2(1120, 58)
	preferences.add_theme_constant_override("separation", 12)
	box.add_child(preferences)
	var controls: Dictionary = SettingsSystem.data.get("controls", {}) as Dictionary
	var sensitivity_label := Label.new()
	sensitivity_label.text = "Sensibilidade"
	sensitivity_label.custom_minimum_size.x = 126
	preferences.add_child(sensitivity_label)
	var sensitivity_slider := HSlider.new()
	sensitivity_slider.min_value = 25
	sensitivity_slider.max_value = 200
	sensitivity_slider.step = 5
	sensitivity_slider.value = float(controls.get("mouse_sensitivity", 1.0)) * 100.0
	sensitivity_slider.custom_minimum_size.x = 190
	preferences.add_child(sensitivity_slider)
	var sensitivity_value := Label.new()
	sensitivity_value.text = "%d%%" % int(sensitivity_slider.value)
	sensitivity_value.custom_minimum_size.x = 58
	preferences.add_child(sensitivity_value)
	sensitivity_slider.value_changed.connect(_sensitivity_changed.bind(sensitivity_value))
	var invert := CheckButton.new()
	invert.text = "Inverter Y"
	invert.button_pressed = bool(controls.get("invert_y", false))
	invert.custom_minimum_size.x = 150
	invert.toggled.connect(SettingsSystem.set_invert_y)
	preferences.add_child(invert)
	var fov_label := Label.new()
	fov_label.text = "Campo de visão"
	fov_label.custom_minimum_size.x = 142
	preferences.add_child(fov_label)
	var fov_slider := HSlider.new()
	fov_slider.min_value = 45
	fov_slider.max_value = 75
	fov_slider.step = 1
	fov_slider.value = float(controls.get("fov", 55.0))
	fov_slider.custom_minimum_size.x = 180
	preferences.add_child(fov_slider)
	var fov_value := Label.new()
	fov_value.text = "%d°" % int(fov_slider.value)
	fov_value.custom_minimum_size.x = 55
	preferences.add_child(fov_value)
	fov_slider.value_changed.connect(_fov_changed.bind(fov_value))
	var context_tips := CheckButton.new()
	context_tips.text = "Mostrar uma vez as dicas contextuais dos primeiros minutos"
	context_tips.button_pressed = SettingsSystem.context_tips_enabled()
	context_tips.custom_minimum_size = Vector2(1120, 42)
	context_tips.toggled.connect(SettingsSystem.set_context_tips_enabled)
	box.add_child(context_tips)
	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size = Vector2(1120, 48)
	toolbar.add_theme_constant_override("separation", 8)
	box.add_child(toolbar)
	var reset := Button.new()
	reset.text = "REPOR VALORES DE FÁBRICA"
	reset.custom_minimum_size = Vector2(330, 48)
	reset.pressed.connect(_reset_controls)
	toolbar.add_child(reset)
	var change := Button.new()
	change.text = "ALTERAR SELECCIONADO"
	change.custom_minimum_size = Vector2(270, 48)
	change.pressed.connect(_start_selected_binding.bind(false))
	toolbar.add_child(change)
	var add := Button.new()
	add.text = "+ SEGUNDA LIGAÇÃO"
	add.custom_minimum_size = Vector2(250, 48)
	add.pressed.connect(_start_selected_binding.bind(true))
	toolbar.add_child(add)
	var list := Tree.new()
	list.custom_minimum_size = Vector2(1170, 440)
	list.columns = 2
	list.column_titles_visible = true
	list.set_column_title(0, "ACÇÃO")
	list.set_column_title(1, "LIGAÇÕES ACTUAIS — selecciona uma linha para alterar")
	list.set_column_custom_minimum_width(0, 390)
	list.select_mode = Tree.SELECT_ROW
	list.hide_root = true
	box.add_child(list)
	var root := list.create_item()
	var action_names: Array = (GameData.controls.get("actions", {}) as Dictionary).keys()
	action_names.sort_custom(func(a: Variant, b: Variant) -> bool:
		return String(ACTION_LABELS.get(a, a)) < String(ACTION_LABELS.get(b, b)))
	for action_value: Variant in action_names:
		var action_name := String(action_value)
		var item := list.create_item(root)
		item.set_text(0, String(ACTION_LABELS.get(action_name,
			action_name.replace("_", " ").capitalize())))
		item.set_text(1, SettingsSystem.binding_label(action_name, true))
		item.set_metadata(0, action_name)
	_selected_control_action = String(action_names[0]) if not action_names.is_empty() else ""
	if root.get_first_child() != null:
		root.get_first_child().select(0)
	list.item_selected.connect(_control_action_selected.bind(list))


func _build_audio_settings() -> void:
	var box := _settings_heading("ÁUDIO",
		"Cada canal pode ir a zero. O equivalente visual de combate continua activo.")
	var labels := {"Master": "Geral", "Musica": "Música", "Efeitos": "Efeitos",
		"Ambiente": "Ambiente", "Vozes": "Vozes"}
	var audio: Dictionary = SettingsSystem.data.get("audio", {}) as Dictionary
	for bus_name: String in SettingsSystem.AUDIO_BUSES:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(1120, 88)
		row.add_theme_constant_override("separation", 20)
		box.add_child(row)
		var name_label := Label.new()
		name_label.text = String(labels.get(bus_name, bus_name)).to_upper()
		name_label.custom_minimum_size = Vector2(260, 60)
		row.add_child(name_label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = float(audio.get(bus_name, 1.0)) * 100.0
		slider.custom_minimum_size = Vector2(680, 60)
		row.add_child(slider)
		var value_label := Label.new()
		value_label.text = "%d%%" % int(slider.value)
		value_label.custom_minimum_size = Vector2(100, 60)
		row.add_child(value_label)
		slider.value_changed.connect(_audio_value_changed.bind(bus_name, value_label))


func _set_settings_tab(tab_name: String) -> void:
	_settings_tab = tab_name
	_rebuild_settings()


func _rebuild_settings() -> void:
	var origin := _settings_origin
	if is_instance_valid(_settings_layer):
		_fechar_no(_settings_layer)
	_settings_layer = null
	_settings_root = null
	_show_settings(origin)


func _close_settings() -> void:
	_cancel_binding_capture()
	if is_instance_valid(_settings_layer):
		_fechar_no(_settings_layer)
	_settings_layer = null
	_settings_root = null
	_settings_fps_label = null


func _select_graphics_preset(preset_name: String) -> void:
	SettingsSystem.set_graphics_preset(preset_name)
	_rebuild_settings()


func _fps_limit_selected(index: int, option: OptionButton) -> void:
	SettingsSystem.set_fps_limit(option.get_item_id(index))


func _audio_value_changed(value: float, bus_name: String, value_label: Label) -> void:
	value_label.text = "%d%%" % int(value)
	SettingsSystem.set_audio(bus_name, value / 100.0)


func _sensitivity_changed(value: float, value_label: Label) -> void:
	value_label.text = "%d%%" % int(value)
	SettingsSystem.set_mouse_sensitivity(value / 100.0)


func _fov_changed(value: float, value_label: Label) -> void:
	value_label.text = "%d°" % int(value)
	SettingsSystem.set_fov(value)


func _control_action_selected(list: Tree) -> void:
	var selected := list.get_selected()
	if selected != null:
		_selected_control_action = String(selected.get_metadata(0))


func _start_selected_binding(add_secondary: bool) -> void:
	if _selected_control_action != "":
		_start_binding_capture(_selected_control_action, add_secondary)


func _update_settings_fps() -> void:
	if not is_instance_valid(_settings_fps_label):
		return
	var fps := Engine.get_frames_per_second()
	_settings_fps_label.text = "%d FPS\n%.2f ms" % [fps, 1000.0 / maxf(float(fps), 1.0)]
	_settings_fps_label.add_theme_color_override("font_color",
		Color("9fc59f") if fps >= 60 else Color("db8d7c"))


func _start_binding_capture(action_name: String, add_secondary: bool) -> void:
	_binding_action = action_name
	_binding_add_secondary = add_secondary
	_binding_prompt = ColorRect.new()
	(_binding_prompt as ColorRect).color = Color(0.0, 0.0, 0.0, 0.9)
	_binding_prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_root.add_child(_binding_prompt)
	var label := Label.new()
	label.text = "PRIME A NOVA TECLA OU BOTÃO\n%s\n\nESCAPE cancela" % String(
		ACTION_LABELS.get(action_name, action_name))
	label.position = Vector2(560, 390)
	label.size = Vector2(800, 300)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("eadbb9"))
	_binding_prompt.add_child(label)


func _cancel_binding_capture() -> void:
	_binding_action = ""
	_binding_add_secondary = false
	if is_instance_valid(_binding_prompt):
		_fechar_no(_binding_prompt)
	_binding_prompt = null


func _finish_binding_capture(event: InputEvent) -> void:
	var action_name := _binding_action
	var add_secondary := _binding_add_secondary
	var conflict := SettingsSystem.find_conflict(event, action_name)
	_cancel_binding_capture()
	if conflict == "":
		SettingsSystem.remap_action(action_name, event, add_secondary)
		_rebuild_settings()
		return
	_pending_binding_event = event.duplicate()
	_pending_binding_action = action_name
	_pending_binding_add = add_secondary
	var confirmation := ConfirmationDialog.new()
	confirmation.title = "CONFLITO DE CONTROLO"
	confirmation.dialog_text = "%s já usa %s. Retirar de %s e atribuir a %s?" % [
		event.as_text().replace(" (Physical)", ""),
		String(ACTION_LABELS.get(conflict, conflict)),
		String(ACTION_LABELS.get(conflict, conflict)),
		String(ACTION_LABELS.get(action_name, action_name)),
	]
	confirmation.min_size = Vector2i(720, 260)
	confirmation.confirmed.connect(_confirm_pending_binding)
	_settings_root.add_child(confirmation)
	confirmation.popup_centered()


func _confirm_pending_binding() -> void:
	if _pending_binding_event == null or _pending_binding_action == "":
		return
	SettingsSystem.remap_action(_pending_binding_action, _pending_binding_event,
		_pending_binding_add, true)
	_pending_binding_event = null
	_pending_binding_action = ""
	_pending_binding_add = false
	_rebuild_settings()


func _reset_controls() -> void:
	SettingsSystem.reset_controls()
	_rebuild_settings()


func _graphics_catalogue() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/graphics.json"))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _graphics_preset() -> Dictionary:
	return ((_graphics_catalogue().get("presets", {}) as Dictionary).get(
		SettingsSystem.graphics_preset_name(), {}) as Dictionary)


func _settings_variant(value: String) -> String:
	if value.contains("controls"):
		return "controls"
	if value.contains("audio"):
		return "audio"
	return "graphics"


func _settings_placeholder() -> void:
	_show_settings("main")


func _show_modal(title: String, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.min_size = Vector2i(560, 220)
	var parent: Node = _screen if is_instance_valid(_screen) else _pause_layer
	if parent == null:
		return
	parent.add_child(dialog)
	dialog.popup_centered()


func _build_preview(pos: Vector2, dimensions: Vector2) -> void:
	var frame := _panel(pos, dimensions)
	var caption := Label.new()
	caption.text = "ARRASTA PARA RODAR  ·  RODA DO RATO PARA APROXIMAR"
	caption.position = Vector2(22, 22)
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override("font_color", Color("7f8e90"))
	frame.add_child(caption)
	var container := SubViewportContainer.new()
	container.position = Vector2(18, 58)
	container.size = dimensions - Vector2(36, 84)
	container.stretch = true
	container.gui_input.connect(_preview_input)
	frame.add_child(container)
	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(724, 786)
	_preview_viewport.transparent_bg = true
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(_preview_viewport)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("10191d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8b9ba0")
	env.ambient_light_energy = 1.2
	environment.environment = env
	_preview_viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_color = Color("f0d8ae")
	light.light_energy = 2.0
	light.shadow_enabled = false
	_preview_viewport.add_child(light)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-2.5, 2.2, -1.5)
	rim.light_color = Color("7196a5")
	rim.omni_range = 6.0
	rim.light_energy = 4.0
	_preview_viewport.add_child(rim)
	_preview_pivot = Node3D.new()
	_preview_viewport.add_child(_preview_pivot)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.0, -4.4)
	camera.fov = 33.0
	_preview_viewport.add_child(camera)
	camera.look_at(Vector3(0, 0.9, 0))
	_update_preview()


func _update_preview() -> void:
	if not is_instance_valid(_preview_pivot):
		return
	if is_instance_valid(_preview_visual):
		_fechar_no(_preview_visual)
	var appearance: Dictionary = _draft.get("appearance", {}) as Dictionary
	# ⚠️ 02-08: isto criava um CharacterVisual — o corpo base, que nao sabe
	# vestir. Resultado: o ecra de criacao mostrava caixas onde o jogo ja
	# mostrava roupa modular, e o Mateus via "o quadrado feio" exactamente aqui.
	# ⭐ Quem sabe vestir e o ArmorVisual, e e ele que o mundo usa. O ecra de
	# escolha tem de mostrar O MESMO boneco que se vai jogar, senao a escolha e
	# feita as cegas.
	var armadura := ArmorVisual.new()
	_preview_visual = armadura
	_preview_pivot.add_child(_preview_visual)
	var tint: Color = SKIN_TINTS.get(String(appearance.get("skin_tone_id", "skin_02")), Color.WHITE)
	# O tint da pre-visualizacao distingue os quatro tons sem duplicar texturas;
	# a fisica e o material do mundo continuam independentes desta escolha.
	var origem := String(_draft.get("class_id", "warrior"))
	_preview_visual.setup(2.2, tint, false,
		String(appearance.get("body_id", "body_male")), origem)
	# Veste o kit inicial da origem escolhida — as mesmas pecas com que se vai
	# comecar a jogar, lidas do catalogo e nunca escritas a mao aqui.
	var kit: Dictionary = (GameData.weapons.get("loadouts", {}) as Dictionary).get(
		origem, {}) as Dictionary
	var pecas: Array = kit.get("pecas", []) as Array
	if not pecas.is_empty():
		armadura.apply_equipment(pecas)
	_preview_visual.position = Vector3(0, -0.15, 0)


func _preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_preview_dragging = mouse_button.pressed
		elif mouse_button.pressed and mouse_button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var camera := _preview_viewport.get_camera_3d()
			if camera != null:
				camera.position.z = clampf(camera.position.z + (-0.25 if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP else 0.25), 2.8, 5.2)
	elif event is InputEventMouseMotion and _preview_dragging:
		_preview_pivot.rotation.y += (event as InputEventMouseMotion).relative.x * 0.01


func _begin_screen() -> void:
	_clear_screen()
	_layer = CanvasLayer.new()
	_layer.layer = 200
	add_child(_layer)
	_screen = Control.new()
	_screen.name = "Screen"
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.theme = _theme
	_layer.add_child(_screen)


## ⚠️ Fecha um no de interface EM SEGURANCA. Nunca usar free() directamente aqui.
##
## Porque isto existe (01-08-2026): o jogo fechava ao escolher a classe e carregar
## em iniciar. Estas funcoes de fecho sao chamadas de dentro do handler de um
## botao — ou seja, o sinal `pressed` desse botao AINDA ESTA A SER EMITIDO. O
## free() destroi o botao a meio da propria emissao: use-after-free. As vezes
## sobrevive, as vezes fecha a janela sem dizer nada, e por isso o auto-teste
## nunca apanhou. O proprio Godot diz o remedio no erro:
##   "use queue_free() ... to avoid this error and potential crashes"
##
## Tira do ecra JA (para nao ficar nada visivel a mais um frame) e deixa morrer
## no fim do frame, quando ja ninguem esta a emitir nada.
func _fechar_no(no: Node) -> void:
	if not is_instance_valid(no):
		return
	var pai: Node = no.get_parent()
	if pai != null:
		pai.remove_child(no)
	no.queue_free()

func _clear_screen() -> void:
	if is_instance_valid(_layer):
		_fechar_no(_layer)
	_layer = null
	_screen = null
	_preview_viewport = null
	_preview_pivot = null
	_preview_visual = null


func _clear_gameplay() -> void:
	if is_instance_valid(_gameplay):
		_fechar_no(_gameplay)
	_gameplay = null


func _add_background(top: Color, bottom: Color) -> void:
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([top, bottom])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	texture.gradient = gradient
	texture.fill_from = Vector2(0.2, 0.0)
	texture.fill_to = Vector2(0.8, 1.0)
	var background := TextureRect.new()
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(background)
	_screen.move_child(background, 0)


func _panel(pos: Vector2, dimensions: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = dimensions
	_screen.add_child(panel)
	return panel


func _menu_button(label: String, description: String) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [label, description]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(430, 76)
	return button


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.set_default_font_size(18)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.055, 0.94)
	panel_style.border_color = Color(0.34, 0.39, 0.39, 0.8)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(3)
	theme.set_stylebox("panel", "Panel", panel_style)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = {
			"normal": Color(0.07, 0.10, 0.11, 0.92),
			"hover": Color(0.15, 0.18, 0.18, 0.98),
			"pressed": Color(0.28, 0.22, 0.13, 0.98),
			"focus": Color(0.12, 0.15, 0.16, 0.98),
			"disabled": Color(0.035, 0.05, 0.055, 0.7),
		}[state]
		style.border_color = Color("9a743d") if state in ["hover", "pressed", "focus"] else Color("3f4849")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(2)
		style.content_margin_left = 18
		style.content_margin_right = 14
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		theme.set_stylebox(state, "Button", style)
	theme.set_color("font_color", "Button", Color("d9dfdd"))
	theme.set_color("font_hover_color", "Button", Color("f2dfb5"))
	theme.set_color("font_pressed_color", "Button", Color("f5d28a"))
	theme.set_color("font_disabled_color", "Button", Color("596366"))
	theme.set_font_size("font_size", "Button", 18)
	return theme


func _has_save() -> bool:
	for slot: int in range(3):
		if SaveSystem.has_save(slot):
			return true
	return false


func _first_free_slot() -> int:
	for slot: int in range(3):
		if not FileAccess.file_exists(SaveSystem.slot_path(slot)):
			return slot
	return -1


func _argument_value(prefix: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


static func validate_character_name(raw_name: String) -> Dictionary:
	var name := raw_name.strip_edges()
	var graphemes := 0
	var previous_space := false
	if name == "":
		return {"valid": false, "name": name, "count": 0, "error": "Escreve um nome."}
	for index: int in name.length():
		var code := name.unicode_at(index)
		var combining := (code >= 0x0300 and code <= 0x036f) or (code >= 0x1ab0 and code <= 0x1aff)
		if not combining:
			graphemes += 1
		var is_space := code == 0x20
		if is_space and previous_space:
			return {"valid": false, "name": name, "count": graphemes, "error": "Usa apenas um espaço entre palavras."}
		previous_space = is_space
		var ascii_letter := (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		var unicode_letter_or_mark := code >= 0x00c0 and not (code >= 0x2000 and code <= 0x206f)
		var punctuation_allowed := code in [0x20, 0x27, 0x2019, 0x2d]
		if code < 0x20 or code in [0x2f, 0x5c, 0x3a, 0x3c, 0x3e, 0x5b, 0x5d, 0x7b, 0x7d] \
				or not (ascii_letter or unicode_letter_or_mark or punctuation_allowed or combining):
			return {"valid": false, "name": name, "count": graphemes, "error": "Usa letras, espaço simples, apóstrofo ou hífen."}
	if graphemes > 24:
		return {"valid": false, "name": name, "count": graphemes, "error": "O nome pode ter no máximo 24 caracteres."}
	return {"valid": true, "name": name, "count": graphemes, "error": ""}
