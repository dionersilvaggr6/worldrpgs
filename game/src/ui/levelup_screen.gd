class_name LevelUpScreen
extends Control
## Ecrã de subir de nível. A fogueira só precisa de criar este Control e chamar
## open_for_current(); toda a escolha, pré-visualização e persistência vive aqui.

signal level_confirmed(receipt: Dictionary)
signal closed

const LevelModel = preload("res://src/ui/levelup_model.gd")

var _selected_attribute := ""
var _view_model: Dictionary = {}
var _attribute_buttons := {}
var _last_message := ""

var _level_value: Label
var _souls_value: Label
var _cost_value: Label
var _attribute_column: VBoxContainer
var _preview_title: Label
var _preview_text: RichTextLabel
var _status: Label
var _confirm: Button
var _back: Button
var _confirm_audio: AudioStreamPlayer


func _ready() -> void:
	_build_ui()
	visible = false
	set_process_unhandled_input(false)


func open_for_current() -> void:
	_last_message = ""
	var state := _game_data().call("save_state_snapshot") as Dictionary
	_view_model = LevelModel.build(state, _selected_attribute)
	_selected_attribute = String(_view_model.get("selected_attribute", ""))
	visible = true
	set_process_unhandled_input(true)
	_refresh(state)
	_focus_selected()


func close_screen() -> void:
	visible = false
	set_process_unhandled_input(false)
	closed.emit()


func view_model() -> Dictionary:
	return _view_model.duplicate(true)


func attribute_button_count() -> int:
	return _attribute_buttons.size()


func select_attribute(attribute_id: String) -> bool:
	if not _attribute_buttons.has(attribute_id):
		return false
	_selected_attribute = attribute_id
	_refresh(_game_data().call("save_state_snapshot") as Dictionary)
	return true


func confirm_selected() -> Dictionary:
	var before := _game_data().call("save_state_snapshot") as Dictionary
	var result := LevelModel.purchase(before, _selected_attribute)
	if not bool(result.get("ok", false)):
		_last_message = _message_for_failure(result)
		_refresh(before)
		return result
	var working: Dictionary = result.get("state", {}) as Dictionary
	_game_data().call("replace_save_state", working)
	if not bool(_save_system().call("save_current")):
		_game_data().call("replace_save_state", before)
		result = {
			"ok": false,
			"status": "save_failed",
			"state": before.duplicate(true),
		}
		_last_message = _ui_string("save_failed")
		_refresh(before)
		return result
	_last_message = _ui_string("confirmed") % [
		_attribute_name(String(result.get("attribute_id", ""))),
		_format_integer(int(result.get("attribute_after", 0))),
		_format_integer(int(result.get("cost", 0))),
		_currency_label(int(result.get("cost", 0))),
	]
	_confirm_audio.play()
	level_confirmed.emit(result.duplicate(true))
	_refresh(working)
	return result


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = _build_theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color("071014f2")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 72)
	outer.add_theme_constant_override("margin_top", 54)
	outer.add_theme_constant_override("margin_right", 72)
	outer.add_theme_constant_override("margin_bottom", 54)
	add_child(outer)
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(frame)
	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 34)
	frame_margin.add_theme_constant_override("margin_top", 28)
	frame_margin.add_theme_constant_override("margin_right", 34)
	frame_margin.add_theme_constant_override("margin_bottom", 28)
	frame.add_child(frame_margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	frame_margin.add_child(page)

	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 24)
	page.add_child(heading)
	var heading_text := VBoxContainer.new()
	heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(heading_text)
	var title := Label.new()
	title.text = _ui_string("title")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("e8d39a"))
	heading_text.add_child(title)
	var subtitle := Label.new()
	subtitle.text = _ui_string("subtitle")
	subtitle.add_theme_color_override("font_color", Color("aeb9b8"))
	heading_text.add_child(subtitle)
	var totals := GridContainer.new()
	totals.columns = 3
	totals.add_theme_constant_override("h_separation", 26)
	heading.add_child(totals)
	_level_value = _stat_block(totals, _ui_string("level"))
	_souls_value = _stat_block(totals, _ui_string("souls"))
	_cost_value = _stat_block(totals, _ui_string("next_cost"))

	page.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 28)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 470
	left.add_theme_constant_override("separation", 10)
	body.add_child(left)
	var attributes_heading := Label.new()
	attributes_heading.text = _ui_string("attributes")
	attributes_heading.add_theme_font_size_override("font_size", 22)
	attributes_heading.add_theme_color_override("font_color", Color("e8d39a"))
	left.add_child(attributes_heading)
	_attribute_column = VBoxContainer.new()
	_attribute_column.add_theme_constant_override("separation", 6)
	_attribute_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_attribute_column)
	_build_attribute_buttons()

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(preview_panel)
	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 26)
	preview_margin.add_theme_constant_override("margin_top", 22)
	preview_margin.add_theme_constant_override("margin_right", 26)
	preview_margin.add_theme_constant_override("margin_bottom", 22)
	preview_panel.add_child(preview_margin)
	var preview_column := VBoxContainer.new()
	preview_column.add_theme_constant_override("separation", 12)
	preview_margin.add_child(preview_column)
	_preview_title = Label.new()
	_preview_title.text = _ui_string("preview")
	_preview_title.add_theme_font_size_override("font_size", 22)
	_preview_title.add_theme_color_override("font_color", Color("e8d39a"))
	preview_column.add_child(_preview_title)
	_preview_text = RichTextLabel.new()
	_preview_text.bbcode_enabled = true
	_preview_text.fit_content = false
	_preview_text.scroll_active = true
	_preview_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_text.custom_minimum_size.y = 360
	preview_column.add_child(_preview_text)
	var hint := Label.new()
	hint.text = _ui_string("preview_hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("8ea09f"))
	preview_column.add_child(hint)

	var curve_context := Label.new()
	curve_context.text = _ui_string("curve_context")
	curve_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	curve_context.add_theme_color_override("font_color", Color("8ea09f"))
	page.add_child(curve_context)
	_status = Label.new()
	_status.custom_minimum_size.y = 28
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", Color("efc06c"))
	page.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	page.add_child(actions)
	var controls_hint := Label.new()
	controls_hint.text = _ui_string("controls")
	controls_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_hint.add_theme_color_override("font_color", Color("8ea09f"))
	actions.add_child(controls_hint)
	_back = Button.new()
	_back.text = _ui_string("back")
	_back.custom_minimum_size = Vector2(180, 54)
	_back.pressed.connect(close_screen)
	actions.add_child(_back)
	_confirm = Button.new()
	_confirm.custom_minimum_size = Vector2(280, 54)
	_confirm.pressed.connect(confirm_selected)
	actions.add_child(_confirm)

	_confirm_audio = AudioStreamPlayer.new()
	if AudioServer.get_bus_index("UI") >= 0:
		_confirm_audio.bus = "UI"
	_confirm_audio.stream = _make_confirm_stream()
	add_child(_confirm_audio)
	_wire_focus()


func _build_attribute_buttons() -> void:
	var ui: Dictionary = _attributes().get("level_up_ui", {}) as Dictionary
	for row_value: Variant in ui.get("attribute_rows", []):
		var row := row_value as Dictionary
		var attribute_id := String(row.get("id", ""))
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 54
		button.pressed.connect(_on_attribute_pressed.bind(attribute_id))
		_attribute_column.add_child(button)
		_attribute_buttons[attribute_id] = button


func _refresh(state: Dictionary) -> void:
	_view_model = LevelModel.build(state, _selected_attribute)
	if not bool(_view_model.get("ok", false)):
		_status.text = "Estado de personagem indisponível."
		_confirm.disabled = true
		return
	_selected_attribute = String(_view_model.get("selected_attribute", ""))
	_level_value.text = "%s → %s" % [
		_format_integer(int(_view_model.get("current_level", 0))),
		_format_integer(int(_view_model.get("next_level", 0))),
	]
	_souls_value.text = _format_integer(int(_view_model.get("souls_held", 0)))
	_cost_value.text = "—" if bool(_view_model.get("at_level_cap", false)) else \
		_format_integer(int(_view_model.get("cost", 0)))
	for row: Dictionary in _view_model.get("attribute_rows", []):
		var attribute_id := String(row.get("id", ""))
		var button := _attribute_buttons.get(attribute_id) as Button
		if button == null:
			continue
		button.disabled = bool(row.get("capped", false)) or bool(
			_view_model.get("at_level_cap", false))
		button.text = _attribute_button_text(row)
	_preview_text.text = _preview_bbcode(_view_model.get("preview", {}) as Dictionary)
	_confirm.disabled = not bool(_view_model.get("can_confirm", false))
	_confirm.text = "%s · %s %s" % [
		_ui_string("confirm"),
		_format_integer(int(_view_model.get("cost", 0))),
		_currency_label(int(_view_model.get("cost", 0))),
	]
	_status.text = _last_message if _last_message != "" else _default_status()


func _attribute_button_text(row: Dictionary) -> String:
	var selected := String(row.get("id", "")) == _selected_attribute
	var prefix := "◆ " if selected else "  "
	var before := float(row.get("primary_before", 0.0))
	var after := float(row.get("primary_after", before))
	var delta := after - before
	var metric := String(row.get("primary_metric", ""))
	var metric_label := _metric_label(metric)
	var delta_text := "+%s" % _format_number(delta) if delta >= 0.0 else _format_number(delta)
	return "%s%s  %s → %s    %s %s" % [
		prefix,
		String(row.get("display_name", "")),
		_format_integer(int(row.get("value", 0))),
		_format_integer(int(row.get("proposed_value", 0))),
		metric_label,
		delta_text,
	]


func _preview_bbcode(preview: Dictionary) -> String:
	if not bool(preview.get("ok", false)):
		return _ui_string("select_prompt")
	var before: Dictionary = preview.get("before", {}) as Dictionary
	var after: Dictionary = preview.get("after", {}) as Dictionary
	var lines: Array[String] = []
	lines.append("[font_size=25][b]%s  %s → %s[/b][/font_size]" % [
		_attribute_name(String(preview.get("attribute_id", ""))),
		_format_integer(int(preview.get("current_value", 0))),
		_format_integer(int(preview.get("proposed_value", 0))),
	])
	lines.append("")
	if bool(before.get("damage_available", false)):
		lines.append(_transition_line("%s · %s" % [
			_metric_label("damage"), String(before.get("weapon_name", ""))],
			float(before.get("damage", 0.0)), float(after.get("damage", 0.0))))
	else:
		lines.append("[b]%s[/b]  — sem arma principal" % _metric_label("damage"))
	lines.append(_transition_line(_metric_label("health"),
		float(before.get("health", 0.0)), float(after.get("health", 0.0))))
	lines.append(_transition_line(_metric_label("defense"),
		float(before.get("defense", 0.0)), float(after.get("defense", 0.0))))
	lines.append(_transition_line(_metric_label("stamina"),
		float(before.get("stamina", 0.0)), float(after.get("stamina", 0.0))))
	lines.append(_transition_line(_metric_label("dodges"),
		float(before.get("dodges", 0)), float(after.get("dodges", 0)), true))
	lines.append(_transition_line(_metric_label("mana"),
		float(before.get("mana", 0)), float(after.get("mana", 0)), true))
	lines.append(_transition_line(_metric_label("load_capacity"),
		float(before.get("load_capacity", 0.0)), float(after.get("load_capacity", 0.0))))
	lines.append(_transition_line(_metric_label("load_fraction"),
		float(before.get("load_fraction", 0.0)) * 100.0,
		float(after.get("load_fraction", 0.0)) * 100.0, false, "%"))
	lines.append("")
	lines.append("[color=#8ea09f]%s[/color]" % _curve_summary(
		String(preview.get("attribute_id", "")), int(preview.get("current_value", 0))))
	lines.append("[color=#8ea09f]%s[/color]" % _ui_string("curve_hint"))
	return "\n".join(lines)


func _transition_line(label: String, before: float, after: float,
		integer := false, suffix := "") -> String:
	var delta := after - before
	var before_text := _format_integer(roundi(before)) if integer else _format_number(before)
	var after_text := _format_integer(roundi(after)) if integer else _format_number(after)
	var delta_text := _format_integer(roundi(delta)) if integer else _format_number(delta)
	if delta >= 0.0:
		delta_text = "+%s" % delta_text
	return "[b]%s[/b]  %s%s → %s%s  [color=#efc06c](%s%s)[/color]" % [
		label, before_text, suffix, after_text, suffix, delta_text, suffix]


func _curve_summary(attribute_id: String, current_value: int) -> String:
	var selected_row := {}
	for row: Dictionary in _view_model.get("attribute_rows", []):
		if String(row.get("id", "")) == attribute_id:
			selected_row = row
			break
	var markers: Array = selected_row.get("curve_markers", []) as Array
	var marker_texts: Array[String] = []
	var next_marker := 0
	for marker_value: Variant in markers:
		var marker := int(marker_value)
		marker_texts.append(_format_integer(marker))
		if next_marker == 0 and marker > current_value:
			next_marker = marker
	var next_text := "máximo" if next_marker == 0 else _format_integer(next_marker)
	return "Marcos da curva: %s · próximo: %s" % [" · ".join(marker_texts), next_text]


func _default_status() -> String:
	if bool(_view_model.get("at_level_cap", false)):
		return _ui_string("level_cap")
	if bool(_view_model.get("selected_capped", false)):
		return _ui_string("attribute_cap") % _format_integer(
			int(_attributes().get("max_per_attribute", 0)))
	if not bool(_view_model.get("can_afford", false)):
		return _ui_string("not_enough") % _format_integer(
			int(_view_model.get("shortfall", 0)))
	return ""


func _message_for_failure(result: Dictionary) -> String:
	match String(result.get("status", "")):
		"level_cap":
			return _ui_string("level_cap")
		"attribute_cap":
			return _ui_string("attribute_cap") % _format_integer(
				int(_attributes().get("max_per_attribute", 0)))
		"insufficient_currency":
			return _ui_string("not_enough") % _format_integer(
				int(result.get("shortfall", 0)))
		_:
			return _ui_string("select_prompt")


func _on_attribute_pressed(attribute_id: String) -> void:
	_selected_attribute = attribute_id
	_last_message = ""
	_refresh(_game_data().call("save_state_snapshot") as Dictionary)


func _focus_selected() -> void:
	var button := _attribute_buttons.get(_selected_attribute) as Button
	if button != null and not button.disabled:
		button.grab_focus()
	else:
		_back.grab_focus()


func _wire_focus() -> void:
	var focusables: Array[Control] = []
	for row_value: Variant in ((_attributes().get("level_up_ui", {}) as Dictionary).get(
			"attribute_rows", []) as Array):
		var button := _attribute_buttons.get(String((row_value as Dictionary).get("id", ""))) as Button
		if button != null:
			focusables.append(button)
	focusables.append(_back)
	focusables.append(_confirm)
	for index: int in focusables.size():
		var previous := focusables[(index - 1 + focusables.size()) % focusables.size()]
		var next := focusables[(index + 1) % focusables.size()]
		focusables[index].focus_neighbor_top = focusables[index].get_path_to(previous)
		focusables[index].focus_neighbor_bottom = focusables[index].get_path_to(next)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_screen()
		get_viewport().set_input_as_handled()


func _stat_block(parent: GridContainer, label_text: String) -> Label:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 155
	parent.add_child(column)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("8ea09f"))
	column.add_child(label)
	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 25)
	column.add_child(value)
	return value


func _build_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 20
	result.set_constant("outline_size", "Label", 1)
	result.set_color("font_outline_color", "Label", Color("071014"))
	result.set_stylebox("panel", "PanelContainer", _style_box(Color("111c20"),
		Color("6e6044"), 1, 8, 18))
	result.set_stylebox("normal", "Button", _style_box(Color("172328"),
		Color("304148"), 1, 5, 12))
	result.set_stylebox("hover", "Button", _style_box(Color("213238"),
		Color("a98d50"), 1, 5, 12))
	result.set_stylebox("pressed", "Button", _style_box(Color("0d171b"),
		Color("efc06c"), 2, 5, 12))
	result.set_stylebox("focus", "Button", _style_box(Color("213238"),
		Color("efc06c"), 3, 5, 12))
	result.set_stylebox("disabled", "Button", _style_box(Color("10181b"),
		Color("263338"), 1, 5, 12))
	result.set_color("font_color", "Button", Color("dce4e1"))
	result.set_color("font_hover_color", "Button", Color("fff0c5"))
	result.set_color("font_focus_color", "Button", Color("fff0c5"))
	result.set_color("font_disabled_color", "Button", Color("657271"))
	return result


func _style_box(fill: Color, border: Color, border_width: int,
		radius: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	return box


func _make_confirm_stream() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.18
	var sample_count := roundi(mix_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(mix_rate)
		var envelope := exp(-time * 18.0)
		var sample := (sin(TAU * 660.0 * time) * 0.38
			+ sin(TAU * 990.0 * time) * 0.20) * envelope
		bytes.encode_s16(index * 2, roundi(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _attribute_name(attribute_id: String) -> String:
	var ui: Dictionary = _attributes().get("level_up_ui", {}) as Dictionary
	for row_value: Variant in ui.get("attribute_rows", []):
		var row := row_value as Dictionary
		if String(row.get("id", "")) == attribute_id:
			return String(row.get("display_name", attribute_id))
	return attribute_id


func _metric_label(metric_id: String) -> String:
	var ui: Dictionary = _attributes().get("level_up_ui", {}) as Dictionary
	return String((ui.get("metric_labels", {}) as Dictionary).get(metric_id, metric_id))


func _ui_string(id: String) -> String:
	var ui: Dictionary = _attributes().get("level_up_ui", {}) as Dictionary
	return String((ui.get("strings", {}) as Dictionary).get(id, id))


func _currency_label(amount: int) -> String:
	if amount == 1:
		return _ui_string("currency_singular")
	return String(_view_model.get("currency_id", ""))


static func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return _format_integer(roundi(value))
	return ("%.2f" % value).trim_suffix("0").replace(".", ",")


static func _format_integer(value: int) -> String:
	var negative := value < 0
	var digits := str(absi(value))
	var groups: Array[String] = []
	while digits.length() > 3:
		groups.push_front(digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.push_front(digits)
	return ("-" if negative else "") + " ".join(groups)


func _game_data() -> Node:
	return get_node("/root/GameData")


func _save_system() -> Node:
	return get_node("/root/SaveSystem")


func _attributes() -> Dictionary:
	return _game_data().get("attributes") as Dictionary
