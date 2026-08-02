class_name QuickSlots
extends CanvasLayer
## Caixa compacta de acesso rapido: as quatro categorias ficam legiveis ao mesmo
## tempo e nunca pausam o jogo. As accoes sao IDs de controls.json; a UI pede os
## labels actuais ao SettingsSystem, portanto remapear nao deixa texto obsoleto.

const REFRESH_SECONDS := 0.10
const EquipmentScreenScript = preload("res://src/ui/equipment_screen.gd")
const EMPTY_ITEM_FEEDBACK := "Ranhura de item vazia."
const UNAVAILABLE_ITEM_FEEDBACK := "Este consumível ainda não tem efeito ligado."


class QuickSlotsSurface extends Control:
	var slots: Array[Dictionary] = []
	var feedback := ""


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


	func _draw() -> void:
		if slots.is_empty():
			return
		var origin := Vector2(24.0, maxf(130.0, size.y - 590.0))
		var cell_size := Vector2(78.0, 78.0)
		var positions := {
			"spell": origin + Vector2(82.0, 0.0),
			"left_hand": origin + Vector2(0.0, 82.0),
			"right_hand": origin + Vector2(164.0, 82.0),
			"item": origin + Vector2(82.0, 164.0),
		}
		var panel_height := 304.0 if feedback != "" else 276.0
		draw_rect(Rect2(origin - Vector2(8.0, 26.0), Vector2(258.0, panel_height)),
			Color(0.012, 0.019, 0.022, 0.72))
		_draw_text(origin + Vector2(0.0, -8.0), "ACESSO RAPIDO", 13,
			Color("d4b36f"), 242.0, HORIZONTAL_ALIGNMENT_CENTER)
		for slot: Dictionary in slots:
			var slot_name := String(slot.get("slot", ""))
			if not positions.has(slot_name):
				continue
			_draw_slot(Rect2(positions[slot_name] as Vector2, cell_size), slot)
		if feedback != "":
			_draw_text(origin + Vector2(0.0, 270.0), feedback, 11,
				Color("e6c77a"), 242.0, HORIZONTAL_ALIGNMENT_CENTER)


	func _draw_slot(rect: Rect2, slot: Dictionary) -> void:
		var slot_name := String(slot.get("slot", ""))
		var kind := String(slot.get("kind", ""))
		var tint := _kind_colour(kind)
		draw_rect(rect, Color(0.035, 0.045, 0.047, 0.94))
		draw_rect(rect, tint.darkened(0.12), false, 2.0)
		var icon_rect := Rect2(rect.position + Vector2(14.0, 15.0), Vector2(50.0, 43.0))
		if kind == "arma" and _draw_weapon_icon(icon_rect, slot, tint):
			pass
		elif String(slot.get("key", "")) == "consumivel:frasco_bruma":
			_draw_flask(icon_rect, tint)
		elif kind == "magia":
			_draw_spell(icon_rect, String(slot.get("name", "?")), tint)
		else:
			_draw_state(icon_rect, tint)
		var category: String = String({
			"spell": "FEITICO", "left_hand": "MAO E",
			"right_hand": "MAO D", "item": "ITEM",
		}.get(slot_name, slot_name))
		_draw_text(rect.position + Vector2(3.0, 11.0), String(category), 10,
			Color("aab2b4"), rect.size.x - 6.0, HORIZONTAL_ALIGNMENT_CENTER)
		if bool(slot.get("show_count", false)):
			_draw_text(rect.position + Vector2(3.0, rect.size.y - 8.0),
				str(int(slot.get("count", 0))), 16, Color("f0e4c8"),
				rect.size.x - 8.0, HORIZONTAL_ALIGNMENT_RIGHT)
		var hint := _binding_hint(slot)
		var hint_size := _fitted_font_size(hint, rect.size.x - 4.0, 10)
		_draw_text(rect.position + Vector2(2.0, rect.size.y + 15.0), hint, hint_size,
			Color("d4b36f"), rect.size.x - 4.0, HORIZONTAL_ALIGNMENT_CENTER)


	func _draw_weapon_icon(rect: Rect2, slot: Dictionary, tint: Color) -> bool:
		var data: Dictionary = slot.get("data", {}) as Dictionary
		if String(data.get("familia_escudo", "")) != "":
			_draw_shield(rect, tint)
			return true
		var family_id := String(data.get("familia", ""))
		if family_id == "" and String(data.get("instrument_type", "")) != "":
			family_id = "cajado"
		if family_id == "":
			return false
		_draw_family_weapon(rect, family_id, tint)
		return true


	func _draw_family_weapon(rect: Rect2, family_id: String, tint: Color) -> void:
		var centre := rect.get_center()
		match family_id:
			"arco":
				draw_arc(centre + Vector2(-3.0, 0.0), 18.0, -1.15, 1.15,
					16, tint, 3.0)
				draw_line(centre + Vector2(4.0, -16.0),
					centre + Vector2(4.0, 16.0), tint.lightened(0.2), 2.0)
			"besta":
				draw_line(centre + Vector2(-19.0, -9.0),
					centre + Vector2(19.0, -9.0), tint, 4.0)
				draw_line(centre + Vector2(0.0, -16.0),
					centre + Vector2(0.0, 19.0), tint.lightened(0.2), 4.0)
				_draw_arrow_head(centre + Vector2(0.0, -17.0), tint)
			"cajado":
				draw_line(centre + Vector2(-11.0, 19.0),
					centre + Vector2(9.0, -15.0), tint, 5.0)
				draw_circle(centre + Vector2(11.0, -18.0), 7.0,
					tint.lightened(0.2))
			"haste":
				draw_line(centre + Vector2(-14.0, 19.0),
					centre + Vector2(12.0, -15.0), tint, 4.0)
				_draw_arrow_head(centre + Vector2(14.0, -18.0), tint)
			"pesada_corte":
				draw_line(centre + Vector2(-13.0, 18.0),
					centre + Vector2(8.0, -10.0), tint.darkened(0.28), 6.0)
				draw_colored_polygon(PackedVector2Array([
					centre + Vector2(2.0, -17.0), centre + Vector2(19.0, -8.0),
					centre + Vector2(10.0, 5.0), centre + Vector2(-1.0, -4.0),
				]), tint)
			_:
				var blade_width := 4.0 if family_id == "adaga" else 6.0
				var blade_start := centre + Vector2(-7.0, 8.0) \
					if family_id == "adaga" else centre + Vector2(-12.0, 13.0)
				draw_line(blade_start, centre + Vector2(14.0, -16.0),
					tint.lightened(0.24), blade_width)
				draw_line(centre + Vector2(-13.0, 4.0),
					centre + Vector2(0.0, 17.0), tint, 4.0)
				draw_circle(centre + Vector2(-11.0, 16.0), 3.0, tint.darkened(0.2))


	func _draw_arrow_head(tip: Vector2, tint: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			tip + Vector2(0.0, -5.0), tip + Vector2(6.0, 7.0),
			tip + Vector2(-6.0, 7.0),
		]), tint)


	func _draw_shield(rect: Rect2, tint: Color) -> void:
		var centre := rect.get_center()
		var points := PackedVector2Array([
			centre + Vector2(-18.0, -17.0), centre + Vector2(18.0, -17.0),
			centre + Vector2(15.0, 9.0), centre + Vector2(0.0, 21.0),
			centre + Vector2(-15.0, 9.0),
		])
		draw_colored_polygon(points, tint.darkened(0.5))
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, tint, 2.0)
		draw_line(centre + Vector2(0.0, -15.0), centre + Vector2(0.0, 15.0),
			tint.lightened(0.22), 2.0)


	func _draw_flask(rect: Rect2, tint: Color) -> void:
		var neck := Rect2(rect.position + Vector2(19.0, 2.0), Vector2(12.0, 13.0))
		var body := Rect2(rect.position + Vector2(11.0, 14.0), Vector2(28.0, 27.0))
		draw_rect(neck, tint.darkened(0.35))
		draw_rect(body, tint.darkened(0.58))
		draw_rect(body, tint, false, 2.0)
		draw_circle(body.position + Vector2(14.0, 21.0), 8.0, Color("76c6cf"))


	func _draw_spell(rect: Rect2, display_name: String, tint: Color) -> void:
		var centre := rect.get_center()
		draw_circle(centre, 18.0, tint.darkened(0.58))
		draw_circle(centre, 18.0, tint, false, 2.0)
		_draw_text(rect.position + Vector2(0.0, 31.0), display_name.left(1).to_upper(),
			22, Color("f2ead7"), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


	func _draw_state(rect: Rect2, tint: Color) -> void:
		draw_line(rect.position + Vector2(10.0, 32.0),
			rect.position + Vector2(40.0, 10.0), tint, 4.0)
		draw_line(rect.position + Vector2(10.0, 10.0),
			rect.position + Vector2(40.0, 32.0), tint, 4.0)


	func _binding_hint(slot: Dictionary) -> String:
		if String(slot.get("slot", "")) == "item":
			var select_action := String(slot.get("select_action", ""))
			var use_action := String(slot.get("use_action", ""))
			var select_label := SettingsSystem.binding_label(select_action).to_upper() \
				if select_action != "" else "—"
			var use_label := SettingsSystem.binding_label(use_action).to_upper() \
				if use_action != "" else "—"
			return "%s → %s" % [select_label, use_label]
		var action := String(slot.get("cycle_action", ""))
		if action != "":
			return SettingsSystem.binding_label(action).to_upper()
		return "SEM DIRECCAO"


	func _kind_colour(kind: String) -> Color:
		match kind:
			"arma": return Color("c7aa72")
			"magia": return Color("78b9df")
			"consumivel": return Color("78bea5")
		return Color("879194")


	func _fitted_font_size(value: String, width: float, preferred: int) -> int:
		var measured := ThemeDB.fallback_font.get_string_size(value,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, preferred).x
		if measured <= width:
			return preferred
		return maxi(6, floori(float(preferred) * width / maxf(measured, 1.0)))


	func _draw_text(at: Vector2, value: String, font_size: int, colour: Color,
			width: float, alignment: HorizontalAlignment) -> void:
		draw_string(ThemeDB.fallback_font, at, value, alignment, width,
			font_size, colour)


var _inventory: Node
var _surface: QuickSlotsSurface
var _player: Node
var _refresh_elapsed := REFRESH_SECONDS
var _selected_item_index := 0
var _restore_input_after_frame := false
var _input_was_enabled := false
var _backpack_button: Button
var _editor_menu: Node
var _editor_screen: CanvasLayer
var _pending_hand_slots: Array[String] = []
var _after_input_scheduled := false
var _last_item_feedback := ""


func setup(inventory: Node) -> void:
	_inventory = inventory
	layer = 52
	# Precisa de observar a escolha do atalho antes de Player ler use_item.
	process_physics_priority = -100
	_surface = QuickSlotsSurface.new()
	add_child(_surface)
	if not _inventory.is_connected("inventory_changed", _on_inventory_changed):
		_inventory.connect("inventory_changed", _on_inventory_changed)
	call_deferred("_install_gameplay_proof")


func _physics_process(_delta: float) -> void:
	_resolve_player()
	visible = is_instance_valid(_player) and bool(_player.get("input_enabled")) \
		and not get_tree().paused
	if not visible:
		return
	_before_player_input()
	for slot_name: String in ["right_hand", "left_hand"]:
		var action := String(_inventory.call("quick_slot_action", slot_name))
		if action != "" and Input.is_action_just_pressed(action):
			_pending_hand_slots.append(slot_name)
	if _restore_input_after_frame or not _pending_hand_slots.is_empty():
		_schedule_after_player_input()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_elapsed += delta
	if _refresh_elapsed >= REFRESH_SECONDS:
		_refresh()


func _resolve_player() -> void:
	if is_instance_valid(_player):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var candidate := scene.find_child("Player", true, false)
	if candidate != null and candidate.has_method("apply_inventory_state"):
		_player = candidate
		_refresh_elapsed = REFRESH_SECONDS


func _sync_player_from_inventory() -> void:
	if not is_instance_valid(_player):
		return
	var state := GameData.save_state_snapshot()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment := (inventory.get("equipment", {}) as Dictionary).duplicate(true)
	for hand: String in ["main", "offhand"]:
		if equipment.get(hand) == null:
			equipment[hand] = ""
	_player.call("apply_inventory_state", equipment,
		EquipmentScreenScript.load_profile_for_state(state))


func _refresh() -> void:
	_refresh_elapsed = 0.0
	if not is_instance_valid(_surface) or not is_instance_valid(_player):
		return
	var state := GameData.save_state_snapshot()
	var readable_state := EquipmentScreenScript.state_for_inventory_read(state)
	_surface.slots = _inventory.call(
		"quick_slot_snapshot", readable_state, _player) as Array[Dictionary]
	for index: int in _surface.slots.size():
		_surface.slots[index] = _with_instrument_presentation(_surface.slots[index])
	var item_descriptor := _selected_item_descriptor(state)
	for index: int in _surface.slots.size():
		if String(_surface.slots[index].get("slot", "")) == "item":
			_surface.slots[index] = item_descriptor
			break
	_surface.queue_redraw()


func _with_instrument_presentation(slot: Dictionary) -> Dictionary:
	if String(slot.get("kind", "")) != "arma" \
			or not (slot.get("data", {}) as Dictionary).is_empty():
		return slot
	var weapon_id := String(slot.get("key", "")).trim_prefix("arma:")
	var instruments := GameData.equipment.get("magic_instruments", {}) as Dictionary
	var instrument := instruments.get(weapon_id, {}) as Dictionary
	if instrument.is_empty():
		return slot
	var presented := slot.duplicate(true)
	presented["data"] = instrument.duplicate(true)
	presented["name"] = String(instrument.get("display_name", weapon_id))
	return presented


func _on_inventory_changed() -> void:
	_resolve_player()
	_sync_player_from_inventory()
	_refresh_elapsed = REFRESH_SECONDS


func _before_player_input() -> void:
	_resolve_player()
	if not is_instance_valid(_player) or get_tree().paused \
			or not bool(_player.get("input_enabled")):
		return
	var hotbar_actions := EquipmentScreenScript.quick_slot_actions()
	for index: int in hotbar_actions.size():
		if Input.is_action_just_pressed(hotbar_actions[index]):
			_selected_item_index = index
			_clear_item_feedback()
			_refresh()
	var use_action := _configured_action("use_item")
	if use_action == "" or not Input.is_action_just_pressed(use_action):
		return
	var item_key := selected_item_key()
	if item_key == QuickSlotsModel.FLASK_ITEM_KEY:
		_clear_item_feedback()
		return
	# Player ainda trata use_item como frasco. Suprimimos esse fallback quando
	# a ranhura activa esta vazia ou aponta para outro consumivel: usar X nunca
	# pode gastar Y. Os restantes efeitos ficam explicitamente na LACUNAS.md.
	_input_was_enabled = bool(_player.get("input_enabled"))
	_player.set("input_enabled", false)
	_restore_input_after_frame = true
	_show_item_feedback(EMPTY_ITEM_FEEDBACK if item_key == "" \
		else UNAVAILABLE_ITEM_FEEDBACK)
	_refresh()


func _restore_player_input() -> void:
	if not _restore_input_after_frame or not is_instance_valid(_player):
		return
	_player.set("input_enabled", _input_was_enabled)
	_restore_input_after_frame = false


func _schedule_after_player_input() -> void:
	if _after_input_scheduled:
		return
	_after_input_scheduled = true
	call_deferred("_after_player_input")


func _after_player_input() -> void:
	_after_input_scheduled = false
	_restore_player_input()
	for slot_name: String in _pending_hand_slots:
		var result: Dictionary = _inventory.call(
			"cycle_quick_slot", slot_name, 1) as Dictionary
		if bool(result.get("ok", false)):
			_sync_player_from_inventory()
	_pending_hand_slots.clear()
	_refresh()


func selected_item_key() -> String:
	var state := GameData.save_state_snapshot()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var quick_slots: Array = inventory.get("quick_slots", []) as Array
	return String(quick_slots[_selected_item_index]) \
		if _selected_item_index >= 0 and _selected_item_index < quick_slots.size() else ""


func visible_item_snapshot() -> Dictionary:
	if not is_instance_valid(_surface):
		return {}
	for slot: Dictionary in _surface.slots:
		if String(slot.get("slot", "")) == "item":
			return slot.duplicate(true)
	return {}


func visible_item_feedback() -> String:
	return _surface.feedback if is_instance_valid(_surface) else ""


func _selected_item_descriptor(state: Dictionary) -> Dictionary:
	var item_key := selected_item_key()
	var readable_state := EquipmentScreenScript.state_for_inventory_read(state)
	var entry: Dictionary = _inventory.call(
		"describe_item", item_key, 1, readable_state) as Dictionary
	if entry.is_empty():
		entry = {"key": item_key, "id": item_key.get_slice(":", 1),
			"kind": "estado" if item_key == "" else item_key.get_slice(":", 0),
			"name": "Ranhura vazia" if item_key == "" else item_key,
			"count": 0, "data": {}}
	entry["slot"] = "item"
	entry["select_action"] = _selected_hotbar_action()
	entry["use_action"] = _configured_action("use_item")
	entry["show_count"] = String(entry.get("kind", "")) == "consumivel"
	if item_key == QuickSlotsModel.FLASK_ITEM_KEY and is_instance_valid(_player):
		entry["count"] = int(_player.get("flask_uses"))
	return entry


func _selected_hotbar_action() -> String:
	var actions := EquipmentScreenScript.quick_slot_actions()
	return actions[_selected_item_index] \
		if _selected_item_index >= 0 and _selected_item_index < actions.size() else ""


func _configured_action(action: String) -> String:
	var actions: Dictionary = GameData.controls.get("actions", {}) as Dictionary
	return action if actions.has(action) and InputMap.has_action(action) else ""


func _show_item_feedback(message: String) -> void:
	_last_item_feedback = message
	if is_instance_valid(_surface):
		_surface.feedback = message
		_surface.queue_redraw()
	var gameplay := _player.get_parent() if is_instance_valid(_player) else null
	var hud: Node = gameplay.get("hud") as Node if gameplay != null else null
	if is_instance_valid(hud) and hud.has_method("toast"):
		hud.call("toast", message)


func _clear_item_feedback() -> void:
	_last_item_feedback = ""
	if is_instance_valid(_surface) and _surface.feedback != "":
		_surface.feedback = ""
		_surface.queue_redraw()


func _input(event: InputEvent) -> void:
	var inventory_action := _configured_action("inventory_menu")
	if inventory_action != "" and event.is_action_pressed(inventory_action):
		# A mochila e criada por GameShell a partir do mesmo evento. O deferred
		# corre depois, sem pesquisa permanente pela arvore do mundo.
		call_deferred("_install_backpack_entry")


func _install_backpack_entry() -> void:
	if is_instance_valid(_backpack_button) or is_instance_valid(_editor_screen):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	for candidate: Node in scene.find_children("*", "CanvasLayer", true, false):
		var script := candidate.get_script() as Script
		if script != null and script.resource_path == "res://src/ui/inventory_menu.gd":
			_backpack_button = EquipmentScreenScript.install_backpack_button(
				candidate, _open_editor_from_backpack.bind(candidate))
			return


func _open_editor_from_backpack(menu: Node) -> void:
	if not is_instance_valid(menu) or is_instance_valid(_editor_screen):
		return
	_editor_menu = menu
	menu.visible = false
	menu.process_mode = Node.PROCESS_MODE_DISABLED
	_editor_screen = EquipmentScreenScript.new()
	_editor_screen.name = "EquipmentScreen"
	menu.get_parent().add_child(_editor_screen)
	_editor_screen.closed.connect(_close_editor_to_backpack)
	_editor_screen.call("open", menu.get("_theme") as Theme,
		menu.get("_gameplay") as Node, "quick:0")


func _close_editor_to_backpack() -> void:
	if is_instance_valid(_editor_screen):
		_editor_screen.queue_free()
	_editor_screen = null
	if is_instance_valid(_editor_menu):
		_editor_menu.visible = true
		_editor_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_editor_menu = null


func _install_gameplay_proof() -> void:
	var scene := get_tree().current_scene
	var scene_script := scene.get_script() as Script if scene != null else null
	if scene_script == null \
			or scene_script.resource_path != "res://src/tests/repro_inicio.gd" \
			or get_node_or_null("QuickSlotsGameplayProof") != null:
		return
	var proof_script := load("res://src/ui/quick_slots_gameplay_proof.gd") as Script
	if proof_script == null:
		push_error("Prova integrada do acesso rapido em falta.")
		get_tree().quit(1)
		return
	var proof := proof_script.new() as Node
	proof.name = "QuickSlotsGameplayProof"
	add_child(proof)
	proof.call("setup", self)
