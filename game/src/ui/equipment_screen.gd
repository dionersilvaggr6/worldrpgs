class_name EquipmentScreen
extends CanvasLayer
## Ecrã completo de equipamento: slot -> objectos compatíveis -> comparação.
##
## A selecção só altera uma cópia do save e actualiza o boneco 3D. A fronteira
## persistente é atravessada apenas em CONFIRMAR. O ecrã configura também os
## `inventory.quick_slots` consumidos pela caixa de acesso rápido.

signal closed
signal equipment_changed(result: Dictionary)
signal quick_slot_changed(slot_index: int, item_id: String)

const ArmorSystem = preload("res://src/equipment/armor_system.gd")
const ArmorVisualScript = preload("res://src/visual/armor_visual.gd")
const WeaponVisualScript = preload("res://src/visual/weapon_visual.gd")
const WeaponFamilyIcons = preload("res://assets/ui/weapon_family_icons.gd")
const EMPTY_CANDIDATE := "__empty__"
const BACKPACK_BUTTON_NAME := "EditQuickAccessButton"

class PreviewActor extends Node3D:
	var main_weapon := ""
	var offhand_weapon := ""
	var is_two_handed := false


var _theme: Theme
var _gameplay: Node
var _base_state := {}
var _class_id := ""
var _selected_slot := "main"
var _selected_candidate := ""
var _model := {}
var _persist_changes := false
var _built := false

var _root: Control
var _slot_list: ItemList
var _candidate_list: ItemList
var _details: RichTextLabel
var _load_banner: RichTextLabel
var _message: Label
var _confirm_button: Button
var _preview_viewport: SubViewport
var _preview_actor: PreviewActor
var _preview_armor: ArmorVisual
var _preview_weapons: WeaponVisual


static func quick_slot_actions() -> Array[String]:
	var actions: Array[String] = []
	var configured: Dictionary = GameData.controls.get("actions", {}) as Dictionary
	for action_value: Variant in configured.keys():
		var action := String(action_value)
		if action.begins_with("hotbar_"):
			actions.append(action)
	actions.sort_custom(func(a: String, b: String) -> bool:
		return a.trim_prefix("hotbar_").to_int() < b.trim_prefix("hotbar_").to_int())
	return actions


## O menu da mochila pertence a outro modulo. Este ponto de montagem permite
## acrescentar a entrada sem duplicar ou alterar o seu codigo.
static func install_backpack_button(menu: Node, callback: Callable) -> Button:
	if not is_instance_valid(menu):
		return null
	var existing := menu.find_child(BACKPACK_BUTTON_NAME, true, false) as Button
	if existing != null:
		return existing
	var root: Control
	for child: Node in menu.get_children():
		if child is Control:
			root = child as Control
			break
	if root == null:
		return null
	var button := Button.new()
	button.name = BACKPACK_BUTTON_NAME
	button.text = "EDITAR ACESSO RÁPIDO"
	button.position = Vector2(1330, 30)
	button.size = Vector2(310, 54)
	button.tooltip_text = "Escolher o consumível de cada atalho"
	button.pressed.connect(callback)
	root.add_child(button)
	return button


## Aplica a mesma copia confirmada ao actor real. A conversao de `null` para
## string vazia acontece apenas na fronteira antiga de Player; o save conserva
## o contrato canonico que admite uma mao sem arma.
static func apply_state_to_gameplay(gameplay: Node, state: Dictionary) -> bool:
	if not is_instance_valid(gameplay):
		return false
	var player: Node = gameplay.get("player") as Node
	if not is_instance_valid(player):
		player = gameplay.find_child("Player", true, false)
	if not is_instance_valid(player) or not player.has_method("apply_inventory_state"):
		return false
	var equipment := _equipment_from_state(state).duplicate(true)
	for hand: String in ["main", "offhand"]:
		if equipment.get(hand) == null:
			equipment[hand] = ""
	player.call("apply_inventory_state", equipment, load_profile_for_state(state))
	return true


static func slot_grammar(state: Dictionary) -> Array[Dictionary]:
	var slots: Array[Dictionary] = [
		{"id": "main", "group": "maos", "label": "MÃO PRINCIPAL", "kind": "arma"},
		{"id": "offhand", "group": "maos", "label": "MÃO SECUNDÁRIA", "kind": "arma"},
	]
	var labels: Dictionary = ((GameData.armor.get("ui", {}) as Dictionary).get(
		"slot_labels", {}) as Dictionary)
	for armor_slot_value: Variant in GameData.armor.get("slots", []):
		var armor_slot := String(armor_slot_value)
		slots.append({
			"id": "armor:%s" % armor_slot,
			"group": "armadura",
			"label": String(labels.get(armor_slot, armor_slot.to_upper())),
			"kind": "armadura",
			"armor_slot": armor_slot,
		})
	var equipment: Dictionary = GameData.equipment
	var ring_rules: Dictionary = equipment.get("_rules", {}) as Dictionary
	var ring_slots := int(ring_rules.get("ring_slots_start", 0))
	var inventory_equipment := _equipment_from_state(state)
	ring_slots = maxi(ring_slots, (inventory_equipment.get("rings", []) as Array).size())
	for index: int in ring_slots:
		slots.append({
			"id": "ring:%d" % index, "group": "aneis",
			"label": "ANEL %d" % (index + 1), "kind": "anel", "index": index,
		})
	var hotbar_actions := quick_slot_actions()
	for index: int in hotbar_actions.size():
		var action := hotbar_actions[index]
		slots.append({
			"id": "quick:%d" % index, "group": "atalhos",
			"label": "ATALHO %s · %s" % [action.trim_prefix("hotbar_"),
				SettingsSystem.binding_label(action).to_upper()],
			"kind": "consumivel", "index": index,
		})
	return slots


static func build_model(state: Dictionary, selected_slot := "main",
		candidate_key := "") -> Dictionary:
	# InventorySystem.normalise_state é útil mas mutável; a UI nunca o deixa
	# tocar no estado real enquanto o jogador está apenas a navegar.
	var working := state.duplicate(true)
	InventorySystem.normalise_state(working)
	var slots := slot_grammar(working)
	if not _has_slot(slots, selected_slot) and not slots.is_empty():
		selected_slot = String(slots[0].get("id", "main"))
	var candidates := candidates_for_slot(working, selected_slot)
	var before_load := load_profile_for_state(working)
	var preview := {}
	if candidate_key != "" and _candidate_is_listed(candidates, candidate_key):
		var preview_state := working.duplicate(true)
		var result := apply_candidate_to_state(preview_state, selected_slot, candidate_key)
		if bool(result.get("ok", false)):
			preview = {
				"candidate_key": candidate_key,
				"before_load": before_load,
				"after_load": load_profile_for_state(preview_state),
				"state": preview_state,
				"current_key": current_key_for_slot(working, selected_slot),
			}
	var quick_slot_ids: Array = (
		_inventory_from_state(working).get("quick_slots", []) as Array
	).duplicate()
	# [CODEX] Mantemos posições vazias porque cada índice corresponde a uma
	# ação hotbar estável. A alternativa compacta mudaria as teclas ao remover
	# um item e tornaria a configuração imprevisível.
	_ensure_positional_size(quick_slot_ids, quick_slot_actions().size())
	return {
		"slots": slots,
		"selected_slot": selected_slot,
		"candidates": candidates,
		"current_key": current_key_for_slot(working, selected_slot),
		"quick_slot_ids": quick_slot_ids,
		"before_load": before_load,
		"preview": preview,
		"state": working,
	}


static func candidates_for_slot(state: Dictionary, slot_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{
		"key": EMPTY_CANDIDATE, "id": "", "kind": "vazio", "name": "— VAZIO",
		"data": {}, "equipped": current_key_for_slot(state, slot_id) == "",
	}]
	for entry: Dictionary in InventorySystem.entries(state_for_inventory_read(state)):
		if slot_accepts_entry(slot_id, entry):
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if String(a.get("key", "")) == EMPTY_CANDIDATE:
			return true
		if String(b.get("key", "")) == EMPTY_CANDIDATE:
			return false
		return String(a.get("name", "")) < String(b.get("name", "")))
	return result


static func slot_accepts_entry(slot_id: String, entry: Dictionary) -> bool:
	var kind := String(entry.get("kind", ""))
	if slot_id in ["main", "offhand"]:
		return kind == "arma"
	if slot_id.begins_with("armor:"):
		return kind == "armadura" and String(
			(entry.get("data", {}) as Dictionary).get("slot", "")) == slot_id.trim_prefix("armor:")
	if slot_id.begins_with("ring:"):
		return kind == "anel"
	if slot_id.begins_with("quick:"):
		return kind == "consumivel"
	return false


static func current_key_for_slot(state: Dictionary, slot_id: String) -> String:
	var equipment := _equipment_from_state(state)
	if slot_id in ["main", "offhand"]:
		var weapon_id := _string_id(equipment.get(slot_id, ""))
		return "arma:%s" % weapon_id if weapon_id != "" else ""
	if slot_id.begins_with("armor:"):
		var wanted := slot_id.trim_prefix("armor:")
		for piece_value: Variant in equipment.get("armor", []):
			var piece_id := String(piece_value)
			if String(_armor_data(piece_id).get("slot", "")) == wanted:
				return "armadura:%s" % piece_id
		return ""
	if slot_id.begins_with("ring:"):
		var rings: Array = equipment.get("rings", []) as Array
		var index := slot_id.trim_prefix("ring:").to_int()
		return "anel:%s" % String(rings[index]) \
			if index >= 0 and index < rings.size() and String(rings[index]) != "" else ""
	if slot_id.begins_with("quick:"):
		var quick_slots: Array = _inventory_from_state(state).get("quick_slots", []) as Array
		var index := slot_id.trim_prefix("quick:").to_int()
		if index < 0 or index >= quick_slots.size():
			return ""
		var quick_key := String(quick_slots[index])
		if quick_key != "" and not quick_key.contains(":"):
			quick_key = "consumivel:%s" % quick_key
		return quick_key
	return ""


static func apply_candidate_to_state(state: Dictionary, slot_id: String,
		candidate_key: String) -> Dictionary:
	if state.is_empty() or not _has_slot(slot_grammar(state), slot_id):
		return {"ok": false, "message": "Ranhura desconhecida."}
	var inventory := _inventory_from_state(state).duplicate(true)
	var equipment := (inventory.get("equipment", {}) as Dictionary).duplicate(true)
	var empty := candidate_key == EMPTY_CANDIDATE
	var kind := ""
	var item_id := ""
	if not empty:
		var parts := candidate_key.split(":", false, 1)
		if parts.size() != 2:
			return {"ok": false, "message": "Objecto inválido."}
		kind = String(parts[0])
		item_id = String(parts[1])
		if int((inventory.get("items", {}) as Dictionary).get(candidate_key, 0)) <= 0:
			return {"ok": false, "message": "O objecto não está na mochila."}
		var described := InventorySystem.describe_item(candidate_key, 1,
			state_for_inventory_read(state))
		if described.is_empty() or not slot_accepts_entry(slot_id, described):
			return {"ok": false, "message": "O objecto não cabe nesta ranhura."}

	if slot_id in ["main", "offhand"]:
		equipment[slot_id] = null if empty else item_id
	elif slot_id.begins_with("armor:"):
		var armor: Array = (equipment.get("armor", []) as Array).duplicate()
		var wanted_slot := slot_id.trim_prefix("armor:")
		for index: int in range(armor.size() - 1, -1, -1):
			if String(_armor_data(String(armor[index])).get("slot", "")) == wanted_slot:
				armor.remove_at(index)
		if not empty:
			armor.append(item_id)
		equipment["armor"] = armor
	elif slot_id.begins_with("ring:"):
		var rings: Array = (equipment.get("rings", []) as Array).duplicate()
		var index := slot_id.trim_prefix("ring:").to_int()
		_ensure_positional_size(rings, slot_grammar(state).filter(
			func(slot: Dictionary) -> bool: return String(slot.get("group", "")) == "aneis").size())
		if not empty:
			for previous: int in rings.size():
				if String(rings[previous]) == item_id:
					rings[previous] = ""
		rings[index] = "" if empty else item_id
		equipment["rings"] = rings
	elif slot_id.begins_with("quick:"):
		var quick_slots: Array = (inventory.get("quick_slots", []) as Array).duplicate()
		var index := slot_id.trim_prefix("quick:").to_int()
		_ensure_positional_size(quick_slots, quick_slot_actions().size())
		if not empty:
			for previous: int in quick_slots.size():
				var previous_key := String(quick_slots[previous])
				if previous_key == candidate_key \
						or previous_key == candidate_key.trim_prefix("consumivel:"):
					quick_slots[previous] = ""
		quick_slots[index] = "" if empty else candidate_key
		inventory["quick_slots"] = quick_slots
	else:
		return {"ok": false, "message": "Ranhura desconhecida."}

	inventory["equipment"] = equipment
	var character: Dictionary = state.get("character", {}) as Dictionary
	character["inventory"] = inventory
	state["character"] = character
	return {"ok": true, "message": "Pré-visualização pronta.", "item_id": item_id,
		"kind": kind, "slot_id": slot_id}


static func load_profile_for_state(state: Dictionary) -> Dictionary:
	var equipment := _equipment_from_state(state)
	var weight := 0.0
	for hand: String in ["main", "offhand"]:
		var weapon_id := _string_id(equipment.get(hand, ""))
		if weapon_id != "":
			weight += float(_weapon_data(weapon_id).get("peso", 0.0))
	for armor_value: Variant in equipment.get("armor", []):
		weight += float(_armor_data(String(armor_value)).get("peso", 0.0))
	for ring_value: Variant in equipment.get("rings", []):
		weight += float(GameData.ring(String(ring_value)).get("peso", 0.0))
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var attributes: Dictionary = progression.get("attributes", {}) as Dictionary
	var capacity := GameData.load_capacity_for(int(attributes.get("carga", 0)))
	return ArmorSystem.load_profile_for_weight(weight, capacity)


static func state_for_inventory_read(state: Dictionary) -> Dictionary:
	var readable := state.duplicate(true)
	var inventory := _inventory_from_state(readable)
	var equipment := (inventory.get("equipment", {}) as Dictionary).duplicate(true)
	for hand: String in ["main", "offhand"]:
		if equipment.get(hand) == null:
			equipment[hand] = ""
	inventory["equipment"] = equipment
	var character: Dictionary = readable.get("character", {}) as Dictionary
	character["inventory"] = inventory
	readable["character"] = character
	return readable


func open(theme: Theme, gameplay: Node, initial_slot := "main") -> void:
	_theme = theme
	_gameplay = gameplay
	_persist_changes = true
	var state := GameData.save_state_snapshot()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var identity: Dictionary = character.get("identity", {}) as Dictionary
	_class_id = String(identity.get("class_id", character.get("class_id", "")))
	_open_state(state, initial_slot, "")


func open_for_state(state: Dictionary, class_id := "", initial_slot := "main",
		candidate_key := "") -> void:
	_theme = null
	_gameplay = null
	_persist_changes = false
	_class_id = class_id
	_open_state(state, initial_slot, candidate_key)


func close_screen() -> void:
	visible = false
	closed.emit()


func _open_state(state: Dictionary, initial_slot: String, candidate_key: String) -> void:
	_base_state = state.duplicate(true)
	_selected_slot = initial_slot
	_selected_candidate = candidate_key
	layer = 525
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _built:
		_build_ui()
	visible = true
	_rebuild_model()
	_slot_list.grab_focus()


func _build_ui() -> void:
	_built = true
	_root = Control.new()
	_root.name = "EquipmentScreenRoot"
	_root.theme = _theme
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color("11191eef")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]:
		outer.add_theme_constant_override("margin_%s" % side, 44)
	outer.add_theme_constant_override("margin_top", 28)
	outer.add_theme_constant_override("margin_bottom", 30)
	_root.add_child(outer)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	outer.add_child(page)
	page.add_child(_build_header())
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	page.add_child(columns)
	columns.add_child(_build_slot_panel())
	columns.add_child(_build_candidate_panel())
	columns.add_child(_build_preview_panel())
	page.add_child(_build_footer())
	_build_preview_world()


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 68
	var title := Label.new()
	title.text = "EQUIPAMENTO"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("eadbb9"))
	header.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "  RANHURA  →  OBJECTO  →  CONFIRMAR"
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("9ba8aa"))
	header.add_child(subtitle)
	_load_banner = RichTextLabel.new()
	_load_banner.bbcode_enabled = true
	_load_banner.fit_content = true
	_load_banner.custom_minimum_size = Vector2(520, 58)
	_load_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_load_banner)
	return header


func _build_slot_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 390
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = "RANHURAS"
	label.add_theme_color_override("font_color", Color("d4b36f"))
	box.add_child(label)
	_slot_list = ItemList.new()
	_slot_list.name = "EquipmentSlotList"
	_slot_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slot_list.select_mode = ItemList.SELECT_SINGLE
	_slot_list.item_selected.connect(_on_slot_selected)
	box.add_child(_slot_list)
	return panel


func _build_candidate_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 480
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = "MOCHILA · COMPATÍVEIS"
	label.add_theme_color_override("font_color", Color("d4b36f"))
	box.add_child(label)
	_candidate_list = ItemList.new()
	_candidate_list.name = "EquipmentCandidateList"
	_candidate_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_candidate_list.select_mode = ItemList.SELECT_SINGLE
	_candidate_list.fixed_icon_size = Vector2i(48, 48)
	_candidate_list.item_selected.connect(_on_candidate_selected)
	box.add_child(_candidate_list)
	_message = Label.new()
	_message.custom_minimum_size.y = 52
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color("9ba8aa"))
	box.add_child(_message)
	return panel


func _build_preview_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var label := Label.new()
	label.text = "NO CORPO · ANTES DE GUARDAR"
	label.add_theme_color_override("font_color", Color("d4b36f"))
	box.add_child(label)
	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(0, 480)
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.stretch = true
	box.add_child(viewport_container)
	_preview_viewport = SubViewport.new()
	_preview_viewport.name = "EquipmentPreviewViewport"
	_preview_viewport.size = Vector2i(640, 560)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.msaa_3d = Viewport.MSAA_2X
	_preview_viewport.own_world_3d = true
	viewport_container.add_child(_preview_viewport)
	_details = RichTextLabel.new()
	_details.bbcode_enabled = true
	_details.custom_minimum_size.y = 170
	_details.add_theme_font_size_override("normal_font_size", 17)
	box.add_child(_details)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	_confirm_button = Button.new()
	_confirm_button.name = "EquipmentConfirmButton"
	_confirm_button.text = "CONFIRMAR TROCA"
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_button.custom_minimum_size.y = 54
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_confirm_selection)
	actions.add_child(_confirm_button)
	var back := Button.new()
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(170, 54)
	back.pressed.connect(close_screen)
	actions.add_child(back)
	return panel


func _build_footer() -> Control:
	var footer := Label.new()
	footer.custom_minimum_size.y = 28
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.text = "O MUNDO CONTINUA  ·  A CARGA MOSTRADA JÁ INCLUI MÃOS E ARMADURA  ·  ESC VOLTA SEM ALTERAR"
	footer.add_theme_color_override("font_color", Color("748487"))
	return footer


func _build_preview_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182127")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("7d8d94")
	environment.ambient_light_energy = 0.72
	world.environment = environment
	_preview_viewport.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	key.light_color = Color("dce3df")
	key.light_energy = 1.35
	key.shadow_enabled = false
	_preview_viewport.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18.0, 152.0, 0.0)
	rim.light_color = Color("889dae")
	rim.light_energy = 0.65
	rim.shadow_enabled = false
	_preview_viewport.add_child(rim)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.25, -4.2)
	camera.fov = 34.0
	_preview_viewport.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0.0, 0.95, 0.0))
	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(4.0, 4.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("293338")
	floor_material.roughness = 1.0
	floor_mesh.material = floor_material
	floor.mesh = floor_mesh
	_preview_viewport.add_child(floor)
	_preview_actor = PreviewActor.new()
	_preview_actor.name = "EquipmentPreviewActor"
	_preview_viewport.add_child(_preview_actor)
	_preview_armor = ArmorVisualScript.new()
	_preview_actor.add_child(_preview_armor)
	_preview_armor.setup(1.8, Color.WHITE, false, "body_male", _class_id)
	_preview_armor.play_animation("Idle")
	_preview_weapons = WeaponVisualScript.new()
	_preview_actor.add_child(_preview_weapons)
	_preview_weapons.setup(_preview_actor, _preview_armor)


func _process(delta: float) -> void:
	if visible and is_instance_valid(_preview_actor):
		_preview_actor.rotation.y = wrapf(_preview_actor.rotation.y + delta * 0.32, -PI, PI)


func _rebuild_model() -> void:
	_model = build_model(_base_state, _selected_slot, _selected_candidate)
	_selected_slot = String(_model.get("selected_slot", "main"))
	_refresh_slot_list()
	_refresh_candidate_list()
	_refresh_comparison()


func _refresh_slot_list() -> void:
	_slot_list.clear()
	var last_group := ""
	for slot_value: Variant in _model.get("slots", []):
		var slot := slot_value as Dictionary
		var group := String(slot.get("group", ""))
		var prefix := ""
		if group != last_group:
			prefix = "%s · " % _group_label(group)
			last_group = group
		var slot_id := String(slot.get("id", ""))
		var current := current_key_for_slot(_model.get("state", {}) as Dictionary, slot_id)
		var current_name := _name_for_key(current, _model.get("state", {}) as Dictionary)
		_slot_list.add_item("%s%s\n    %s" % [prefix, String(slot.get("label", slot_id)), current_name])
		_slot_list.set_item_metadata(_slot_list.item_count - 1, slot_id)
		if slot_id == _selected_slot:
			_slot_list.select(_slot_list.item_count - 1)


func _refresh_candidate_list() -> void:
	_candidate_list.clear()
	var current_key := String(_model.get("current_key", ""))
	for entry_value: Variant in _model.get("candidates", []):
		var entry := entry_value as Dictionary
		var key := String(entry.get("key", ""))
		var marker := "◆ " if key == current_key or (key == EMPTY_CANDIDATE and current_key == "") else ""
		var count := int(entry.get("count", 0))
		var count_label := "  ×%d" % count if count > 1 else ""
		_candidate_list.add_item("%s%s%s" % [marker, String(entry.get("name", "—")), count_label],
			_icon_for_entry(entry))
		_candidate_list.set_item_metadata(_candidate_list.item_count - 1, key)
		if key == _selected_candidate:
			_candidate_list.select(_candidate_list.item_count - 1)


func _refresh_comparison() -> void:
	var preview: Dictionary = _model.get("preview", {}) as Dictionary
	var baseline: Dictionary = _model.get("before_load", {}) as Dictionary
	_confirm_button.disabled = preview.is_empty()
	if preview.is_empty():
		_load_banner.text = _load_text(baseline, baseline, false)
		_details.text = "[color=#839194]Escolhe um objecto compatível. O boneco e a carga mudam aqui sem alterar o save.[/color]"
		_update_preview(_model.get("state", {}) as Dictionary)
		return
	var before: Dictionary = preview.get("before_load", {}) as Dictionary
	var after: Dictionary = preview.get("after_load", {}) as Dictionary
	_load_banner.text = _load_text(before, after, true)
	var candidate_key := String(preview.get("candidate_key", ""))
	var entry := InventorySystem.describe_item(candidate_key, 1,
		state_for_inventory_read(preview.get("state", {}) as Dictionary)) \
		if candidate_key != EMPTY_CANDIDATE else {}
	var description := String((entry.get("data", {}) as Dictionary).get(
		"descricao_visual", (entry.get("data", {}) as Dictionary).get("visual", "Ranhura vazia.")))
	var effect := _effect_text(before, after)
	_details.text = "[b]%s[/b]\n[color=#89989b]%s[/color]\n\n%s\n\n[color=#d4b36f]ANTES DE CONFIRMAR[/color]\n%s" % [
		"— VAZIO" if candidate_key == EMPTY_CANDIDATE else String(entry.get("name", candidate_key)),
		_selected_slot.replace("_", " ").to_upper(), description, effect]
	_update_preview(preview.get("state", {}) as Dictionary)


func _update_preview(state: Dictionary) -> void:
	if not is_instance_valid(_preview_armor):
		return
	var equipment := _equipment_from_state(state)
	_preview_armor.apply_equipment(equipment.get("armor", []) as Array)
	_preview_actor.main_weapon = _string_id(equipment.get("main", ""))
	_preview_actor.offhand_weapon = _string_id(equipment.get("offhand", ""))
	_preview_weapons.sync_loadout(_preview_actor.main_weapon, _preview_actor.offhand_weapon, false)


func _on_slot_selected(index: int) -> void:
	_selected_slot = String(_slot_list.get_item_metadata(index))
	_selected_candidate = ""
	_model = build_model(_base_state, _selected_slot)
	_refresh_candidate_list()
	_refresh_comparison()


func _on_candidate_selected(index: int) -> void:
	_selected_candidate = String(_candidate_list.get_item_metadata(index))
	_model = build_model(_base_state, _selected_slot, _selected_candidate)
	_refresh_comparison()


func _confirm_selection() -> void:
	var preview: Dictionary = _model.get("preview", {}) as Dictionary
	if preview.is_empty():
		return
	var next_state := (preview.get("state", {}) as Dictionary).duplicate(true)
	var item_id := "" if _selected_candidate == EMPTY_CANDIDATE \
		else _selected_candidate.split(":", false, 1)[1]
	if _persist_changes:
		var previous := GameData.save_state_snapshot()
		GameData.replace_save_state(next_state)
		if not SaveSystem.save_current():
			GameData.replace_save_state(previous)
			_message.text = "Não foi possível guardar a troca. Nada mudou."
			return
		InventorySystem.emit_signal("inventory_changed")
		apply_state_to_gameplay(_gameplay, next_state)
	_base_state = next_state
	var result := {"ok": true, "slot_id": _selected_slot, "item_id": item_id,
		"load": load_profile_for_state(next_state)}
	_message.text = "Equipamento guardado." if _persist_changes else "Equipamento aplicado à prova."
	equipment_changed.emit(result)
	if _selected_slot.begins_with("quick:"):
		quick_slot_changed.emit(_selected_slot.trim_prefix("quick:").to_int(), item_id)
	_selected_candidate = ""
	_rebuild_model()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory_menu"):
		close_screen()
		get_viewport().set_input_as_handled()


static func _load_text(before: Dictionary, after: Dictionary, previewing: bool) -> String:
	var changed := not is_equal_approx(float(before.get("weight", 0.0)),
		float(after.get("weight", 0.0))) or String(before.get("class", "")) != String(after.get("class", ""))
	var colour := "#e6c77a" if changed else "#9ba8aa"
	var heading := "CARGA SE CONFIRMAR" if previewing else "CARGA EQUIPADA"
	return "[right][color=#89989b]%s[/color]\n[color=%s][font_size=25]%s  %.1f / %.1f  ·  %d%%[/font_size][/color]\n%s[/right]" % [
		heading, colour, String(after.get("class", "")).to_upper(), float(after.get("weight", 0.0)),
		float(after.get("capacity", 0.0)), roundi(float(after.get("fraction", 0.0)) * 100.0),
		"PRÉ-VISUALIZAÇÃO" if previewing else "ESTADO ACTUAL"]


static func _effect_text(before: Dictionary, after: Dictionary) -> String:
	var lines: Array[String] = ["Carga: %.1f → %.1f" % [
		float(before.get("weight", 0.0)), float(after.get("weight", 0.0))]]
	if String(before.get("class", "")) != String(after.get("class", "")):
		lines.append("Classe: %s → %s" % [String(before.get("class", "")).to_upper(),
			String(after.get("class", "")).to_upper()])
	if not is_equal_approx(float(before.get("dodge_distance", 0.0)),
		float(after.get("dodge_distance", 0.0))):
		lines.append("Distância de esquiva: %.2f m → %.2f m" % [
			float(before.get("dodge_distance", 0.0)), float(after.get("dodge_distance", 0.0))])
	if int(before.get("recovery_frames", 0)) != int(after.get("recovery_frames", 0)):
		lines.append("Recuperação: %d f → %d f" % [int(before.get("recovery_frames", 0)),
			int(after.get("recovery_frames", 0))])
	lines.append("I-frames: %d–%d → %d–%d" % [int(before.get("iframe_start_frame", -1)),
		int(before.get("iframe_end_frame", -1)), int(after.get("iframe_start_frame", -1)),
		int(after.get("iframe_end_frame", -1))])
	return "\n".join(lines)


static func _icon_for_entry(entry: Dictionary) -> Texture2D:
	var kind := String(entry.get("kind", ""))
	var item_id := String(entry.get("id", ""))
	if kind == "armadura":
		var path := "res://assets/ui/icons/armor/%s.png" % item_id.replace("_", "-")
		return load(path) as Texture2D if ResourceLoader.exists(path) else null
	if kind == "arma":
		var data: Dictionary = entry.get("data", {}) as Dictionary
		return WeaponFamilyIcons.texture_for(String(data.get("familia", "")))
	return null


static func _name_for_key(item_key: String, state: Dictionary) -> String:
	if item_key.is_empty():
		return "—"
	return String(InventorySystem.describe_item(item_key, 1,
		state_for_inventory_read(state)).get("name", item_key))


static func _group_label(group: String) -> String:
	return String({"maos": "MÃOS", "armadura": "ARMADURA", "aneis": "ANÉIS",
		"atalhos": "ACESSO RÁPIDO"}.get(group, group.to_upper()))


static func _candidate_is_listed(candidates: Array[Dictionary], candidate_key: String) -> bool:
	for candidate: Dictionary in candidates:
		if String(candidate.get("key", "")) == candidate_key:
			return true
	return false


static func _has_slot(slots: Array[Dictionary], slot_id: String) -> bool:
	for slot: Dictionary in slots:
		if String(slot.get("id", "")) == slot_id:
			return true
	return false


static func _ensure_positional_size(values: Array, wanted_size: int) -> void:
	while values.size() < wanted_size:
		values.append("")


static func _string_id(value: Variant) -> String:
	return "" if value == null else String(value)


static func _inventory_from_state(state: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	return character.get("inventory", {}) as Dictionary


static func _equipment_from_state(state: Dictionary) -> Dictionary:
	return _inventory_from_state(state).get("equipment", {}) as Dictionary


static func _armor_data(piece_id: String) -> Dictionary:
	var data := GameData.equipment_armor(piece_id)
	if data.is_empty():
		data = (GameData.armor.get("pieces", {}) as Dictionary).get(piece_id, {}) as Dictionary
	return data


static func _weapon_data(weapon_id: String) -> Dictionary:
	var data := GameData.equipment_weapon(weapon_id)
	if data.is_empty():
		data = GameData.weapon(weapon_id)
	return data
