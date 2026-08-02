class_name ArmorVisual
extends CharacterVisual
## Armadura modular para o corpo Quaternius.
##
## Ranger e Campones vem do pack Modular Character Outfits - Fantasy e usam o
## mesmo Skin UAL de 65 ossos. Os quatro componentes de cobertura substituem o
## corpo; o corpo base conserva apenas a cabeca. Slots sem modelo gratuito
## continuam com geometria suave gerada em codigo.

const SLOT_ORDER := [
	"cabeca", "rosto", "ombros", "peito", "maos", "cintura", "pernas", "pes", "capa",
]
const BODY_REPLACEMENT_SLOTS := ["peito", "maos", "pernas", "pes"]
const MODEL_SLOTS := ["cabeca", "ombros", "peito", "maos", "pernas", "pes"]
const ORIGIN_OUTFIT_FAMILY := {
	"warrior": "ranger", "tank": "ranger", "berserker": "ranger",
	"evil_mage": "ranger", "sorcerer": "peasant", "assassin": "peasant",
	"paladin": "peasant",
}
const OUTFIT_MODEL_PATHS := {
	"body_male": {
		"ranger": {
			"peito": "res://assets/models/outfits/Male_Ranger_Body.gltf",
			"maos": "res://assets/models/outfits/Male_Ranger_Arms.gltf",
			"pernas": "res://assets/models/outfits/Male_Ranger_Legs.gltf",
			"pes": "res://assets/models/outfits/Male_Ranger_Feet_Boots.gltf",
			"ombros": "res://assets/models/outfits/Male_Ranger_Acc_Pauldron.gltf",
			"cabeca": "res://assets/models/outfits/Male_Ranger_Head_Hood.gltf",
		},
		"peasant": {
			"peito": "res://assets/models/outfits/Male_Peasant_Body.gltf",
			"maos": "res://assets/models/outfits/Male_Peasant_Arms.gltf",
			"pernas": "res://assets/models/outfits/Male_Peasant_Legs.gltf",
			"pes": "res://assets/models/outfits/Male_Peasant_Feet.gltf",
		},
	},
	"body_female": {
		"ranger": {
			"peito": "res://assets/models/outfits/Female_Ranger_Body.gltf",
			"maos": "res://assets/models/outfits/Female_Ranger_Arms.gltf",
			"pernas": "res://assets/models/outfits/Female_Ranger_Legs.gltf",
			"pes": "res://assets/models/outfits/Female_Ranger_Feet.gltf",
			"ombros": "res://assets/models/outfits/Female_Ranger_Acc_Pauldrons.gltf",
			"cabeca": "res://assets/models/outfits/Female_Ranger_Head_Hood.gltf",
		},
		"peasant": {
			"peito": "res://assets/models/outfits/Female_Peasant_Body.gltf",
			"maos": "res://assets/models/outfits/Female_Peasant_Arms.gltf",
			"pernas": "res://assets/models/outfits/Female_Peasant_Legs.gltf",
			"pes": "res://assets/models/outfits/Female_Peasant_Feet.gltf",
		},
	},
}

static var _material_cache := {}

var _armor_attachments: Array[BoneAttachment3D] = []
var _outfit_meshes: Array[MeshInstance3D] = []
var _armor_piece_ids: Array[String] = []
var _signatures := {}
var _armor_casts_shadow := true
var _armor_body_id := "body_male"


func setup(target_height: float, tint := Color.WHITE, casts_shadow := true,
		body_id := "body_male", class_id := "") -> void:
	_armor_casts_shadow = casts_shadow
	_armor_body_id = body_id if body_id in OUTFIT_MODEL_PATHS else "body_male"
	super.setup(target_height, tint, casts_shadow, body_id, class_id)
	_remove_origin_placeholders()


func apply_equipment(piece_ids: Array) -> void:
	_clear_armor()
	var selected_by_slot := {}
	for piece_value: Variant in piece_ids:
		var piece_id := String(piece_value)
		var data := _piece_data(piece_id)
		var slot := String(data.get("slot", ""))
		if not data.is_empty() and slot in SLOT_ORDER:
			selected_by_slot[slot] = piece_id
	if selected_by_slot.is_empty():
		return

	# Body, Arms, Legs e Feet sao um fato completo. Mesmo que armor.json ainda
	# nao equipe maos/pernas na Fatia 1, estes componentes cobrem o corpo nu e
	# tornam-se o underlayer visual; o item do slot, quando existe, escolhe a
	# familia e o material desse componente.
	var base_family := _base_outfit_family(selected_by_slot)
	var body_model_ok := true
	var model_result_by_slot := {}
	for slot: String in BODY_REPLACEMENT_SLOTS:
		var piece_id := String(selected_by_slot.get(slot, ""))
		var data := _piece_data(piece_id) if not piece_id.is_empty() else {}
		var family := _family_for_piece(data, base_family)
		var built := _build_model_slot(slot, family, piece_id, data)
		model_result_by_slot[slot] = built
		body_model_ok = body_model_ok and built
	set_body_replaced_by_outfit(body_model_ok)
	if not body_model_ok:
		push_warning("[armor-visual] fato modular incompleto; corpo restaurado para evitar buracos")

	for slot: String in SLOT_ORDER:
		var piece_id := String(selected_by_slot.get(slot, ""))
		if piece_id.is_empty():
			continue
		var data := _piece_data(piece_id)
		if slot in BODY_REPLACEMENT_SLOTS:
			if not bool(model_result_by_slot.get(slot, false)):
				_build_piece(piece_id, data)
		elif slot in MODEL_SLOTS:
			var family := "ranger" if slot in ["cabeca", "ombros"] \
				else _family_for_piece(data, base_family)
			if not _build_model_slot(slot, family, piece_id, data):
				_build_piece(piece_id, data)
		else:
			_build_piece(piece_id, data)
		_armor_piece_ids.append(piece_id)


func equipped_piece_ids() -> Array[String]:
	return _armor_piece_ids.duplicate()


func visual_signature(slot: String) -> String:
	return String(_signatures.get(slot, ""))


func visualized_slots() -> Array:
	return _signatures.keys()


func draw_surface_count() -> int:
	var total := 0
	for mesh_node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.visible and mesh_instance.mesh != null:
			total += mesh_instance.mesh.get_surface_count()
	return total


func armor_mesh_count() -> int:
	var total := 0
	for mesh_node: Node in find_children("*", "MeshInstance3D", true, false):
		if mesh_node.is_in_group("armor_visual_piece"):
			total += 1
	return total


func _remove_origin_placeholders() -> void:
	# CharacterVisual deixa uma fronteira de extensão, mas os placeholders da
	# origem incluem BoxMesh. Removemo-los só nesta subclasse; o corpo, Skin e
	# AnimationPlayer Quaternius ficam intactos.
	var attachments: Array[BoneAttachment3D] = []
	for mesh_node: Node in find_children("*", "MeshInstance3D", true, false):
		if not mesh_node.is_in_group("character_origin_outfit"):
			continue
		_meshes.erase(mesh_node as MeshInstance3D)
		var attachment := mesh_node.get_parent() as BoneAttachment3D
		if attachment != null and attachment not in attachments:
			attachments.append(attachment)
	for attachment: BoneAttachment3D in attachments:
		if is_instance_valid(attachment):
			attachment.free()
	clear_generated_origin_outfit()


func _clear_armor() -> void:
	set_body_replaced_by_outfit(false)
	for mesh_instance: MeshInstance3D in _outfit_meshes:
		_meshes.erase(mesh_instance)
		if is_instance_valid(mesh_instance):
			mesh_instance.free()
	_outfit_meshes.clear()
	for attachment: BoneAttachment3D in _armor_attachments:
		if not is_instance_valid(attachment):
			continue
		for descendant: Node in attachment.find_children("*", "MeshInstance3D", true, false):
			_meshes.erase(descendant as MeshInstance3D)
		attachment.free()
	_armor_attachments.clear()
	_armor_piece_ids.clear()
	_signatures.clear()


func _base_outfit_family(selected_by_slot: Dictionary) -> String:
	var fallback := String(ORIGIN_OUTFIT_FAMILY.get(_origin_id, "peasant"))
	for slot: String in BODY_REPLACEMENT_SLOTS:
		var piece_id := String(selected_by_slot.get(slot, ""))
		if not piece_id.is_empty():
			return _family_for_piece(_piece_data(piece_id), fallback)
	return fallback


static func _family_for_piece(data: Dictionary, fallback: String) -> String:
	var material_text := String(data.get("material", "")).to_lower()
	if "pano" in material_text or "la" in material_text or "lã" in material_text:
		return "peasant"
	if "couro" in material_text or "ferro" in material_text or "pelo" in material_text:
		return "ranger"
	return fallback


func _build_model_slot(slot: String, family: String, piece_id: String,
		data: Dictionary) -> bool:
	# Campones nao traz capuz nem ombreiras na versao gratuita. Estes dois slots
	# usam o equivalente Ranger; nao se procura nem se finge o conteudo pago.
	if slot in ["cabeca", "ombros"]:
		family = "ranger"
	var by_body := OUTFIT_MODEL_PATHS.get(_armor_body_id, {}) as Dictionary
	var by_family := by_body.get(family, {}) as Dictionary
	var model_path := String(by_family.get(slot, ""))
	if model_path.is_empty():
		return false
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("[armor-visual] modelo ausente: %s" % model_path)
		return false
	var donor_root := packed.instantiate()
	var donor_skeleton := _find_skeleton(donor_root)
	if donor_skeleton == null or not _skeletons_match(donor_skeleton, _skeleton):
		donor_root.free()
		push_warning("[armor-visual] rig nao coincide: %s" % model_path)
		return false
	var donor_nodes := donor_root.find_children("*", "MeshInstance3D", true, false)
	if donor_nodes.is_empty():
		donor_root.free()
		push_warning("[armor-visual] modelo sem malha: %s" % model_path)
		return false
	var material := _material_for(piece_id, data) if not data.is_empty() \
		else _source_material("dark_cloth" if family == "peasant" else "leather")
	var material_strength := 0.58 if not data.is_empty() else 0.36
	var moved := 0
	for donor_node: Node in donor_nodes:
		var donor_mesh := donor_node as MeshInstance3D
		donor_mesh.owner = null
		donor_mesh.reparent(_skeleton, false)
		donor_mesh.name = "Outfit_%s" % donor_mesh.name
		donor_mesh.skeleton = NodePath("..")
		donor_mesh.mesh = reduced_skinned_mesh(donor_mesh.mesh,
			"%s#%s" % [model_path, donor_mesh.name])
		donor_mesh.add_to_group("armor_visual_piece")
		donor_mesh.set_meta("armor_slot", slot)
		donor_mesh.set_meta("outfit_source", model_path)
		donor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON \
			if _armor_casts_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_outfit_meshes.append(donor_mesh)
		_register_mesh(donor_mesh, _armor_casts_shadow,
			CLASS_TINTS.get(_origin_id, Color.WHITE))
		apply_equipment_material(donor_mesh, material.albedo_color,
			material_strength, material.roughness, material.metallic)
		moved += 1
	donor_root.free()
	if not piece_id.is_empty():
		_signatures[slot] = "%s:quaternius_%s_%s" % [piece_id, family, slot]
	return moved > 0


static func _skeletons_match(donor: Skeleton3D, target: Skeleton3D) -> bool:
	if donor.get_bone_count() != target.get_bone_count():
		return false
	for bone_index: int in donor.get_bone_count():
		if donor.get_bone_name(bone_index) != target.get_bone_name(bone_index):
			return false
	return true


func _build_piece(piece_id: String, data: Dictionary) -> void:
	var slot := String(data.get("slot", ""))
	var material := _material_for(piece_id, data)
	match slot:
		"cabeca":
			_build_helmet(piece_id, material)
		"rosto":
			_build_face_wrap(piece_id, material)
		"ombros":
			_build_shoulders(piece_id, material)
		"peito":
			_build_cuirass(piece_id, material, "ferro" in String(data.get("material", "")).to_lower())
		"maos":
			_build_gauntlets(piece_id, material)
		"cintura":
			_build_belt(piece_id, material)
		"pernas":
			_build_greaves(piece_id, material)
		"pes":
			_build_boots(piece_id, material)
		"capa":
			_build_cape(piece_id, material)


func _build_cuirass(piece_id: String, material: Material, heavy: bool) -> void:
	var root := Node3D.new()
	root.name = "Armor_%s" % piece_id
	# O rig Quaternius apresenta o peito para -Z; a casca e os pormenores sao
	# construidos em +Z para manter a matematica legivel e rodam juntos aqui.
	# Sem esta orientacao, a camara via as costas lisas e a correia atravessava-a.
	root.rotation.y = PI
	# Uma unica superficie conserva a silhueta curva, as placas sobrepostas, o
	# volume principal. Um segundo material agrupa rebordo/rebites; continuam a
	# ser duas chamadas no total, em vez de uma chamada por pormenor.
	root.add_child(_mesh_instance("FittedCuirass", _cuirass_mesh(material, heavy)))
	# No ferro, a segunda superficie e couro escuro (correia e fixacoes), como no
	# conceito aprovado. No couro, os mesmos pormenores leem-se como ferragens.
	var trim := _accent_material("dark_leather" if heavy else "polished_iron")
	root.add_child(_mesh_instance("LayeredCuirassDetails",
		_cuirass_detail_mesh(trim, heavy)))
	_attach(root, "spine_02", Vector3(0.0, 1.25, 0.01))
	_signatures["peito"] = "%s:fitted_layered_%s" % [piece_id, "plate" if heavy else "leather"]


func _build_helmet(piece_id: String, material: Material) -> void:
	var root := Node3D.new()
	root.name = "Armor_%s" % piece_id
	var dome := _sphere("HammeredDome", Vector3(0.185, 0.17, 0.205), material)
	dome.position.y = 0.105
	root.add_child(dome)
	var skirt := _cylinder("HelmetSkirt", 0.185, 0.205, 0.235, material)
	skirt.position.y = -0.035
	root.add_child(skirt)
	var dark := _accent_material("iron_visor")
	var visor := _cylinder("TVisorBand", 0.19, 0.192, 0.045, dark)
	visor.scale.z = 1.06
	visor.position = Vector3(0.0, 0.005, -0.01)
	root.add_child(visor)
	var nasal := _capsule("TVisorNasal", 0.018, 0.13, dark)
	nasal.position = Vector3(0.0, -0.045, 0.205)
	root.add_child(nasal)
	_attach(root, "Head", Vector3(0.0, 1.68, 0.0))
	_signatures["cabeca"] = "%s:hammered_t_visor" % piece_id


func _build_face_wrap(piece_id: String, material: Material) -> void:
	var root := Node3D.new()
	root.name = "Armor_%s" % piece_id
	var wrap := _cylinder("CurvedFaceWrap", 0.153, 0.145, 0.13, material)
	wrap.scale.z = 0.86
	root.add_child(wrap)
	_attach(root, "Head", Vector3(0.0, 1.625, 0.01))
	_signatures["rosto"] = "%s:cloth_face_wrap" % piece_id


func _build_shoulders(piece_id: String, material: Material) -> void:
	var sides := [["upperarm_l", -0.08], ["upperarm_r", 0.08]]
	for side: Array in sides:
		var root := Node3D.new()
		root.name = "Armor_%s_%s" % [piece_id, String(side[0])]
		var pauldron := _sphere("LayeredPauldron", Vector3(0.18, 0.105, 0.205), material)
		pauldron.rotation.z = float(side[1])
		root.add_child(pauldron)
		var fur := _cylinder("FurEdge", 0.18, 0.19, 0.045, _accent_material("fur"))
		fur.rotation.z = PI * 0.5
		fur.scale.y = 0.72
		fur.position.y = -0.07
		root.add_child(fur)
		_attach_local(root, String(side[0]), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.035, 0.0)))
	_signatures["ombros"] = "%s:paired_domelike_pauldrons" % piece_id


func _build_gauntlets(piece_id: String, material: Material) -> void:
	for bone_name: String in ["forearm_l", "forearm_r"]:
		var root := Node3D.new()
		root.name = "Armor_%s_%s" % [piece_id, bone_name]
		root.add_child(_cylinder("TaperedVambrace", 0.075, 0.105, 0.30, material))
		_attach_local(root, bone_name, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.14, 0.0)))
	_signatures["maos"] = "%s:paired_tapered_vambraces" % piece_id


func _build_belt(piece_id: String, material: Material) -> void:
	var root := Node3D.new()
	root.name = "Armor_%s" % piece_id
	var belt := _cylinder("CurvedBelt", 0.255, 0.255, 0.085, material)
	belt.scale.z = 0.68
	root.add_child(belt)
	for x: float in [-0.18, -0.06, 0.07, 0.19]:
		var pouch := _sphere("RoundedPouch", Vector3(0.075, 0.09, 0.045), material)
		pouch.position = Vector3(x, -0.065, 0.155)
		root.add_child(pouch)
	_attach(root, "pelvis", Vector3(0.0, 0.98, 0.0))
	_signatures["cintura"] = "%s:curved_belt_four_pouches" % piece_id


func _build_greaves(piece_id: String, material: Material) -> void:
	for bone_name: String in ["calf_l", "calf_r"]:
		var root := Node3D.new()
		root.name = "Armor_%s_%s" % [piece_id, bone_name]
		root.add_child(_cylinder("TaperedGreave", 0.078, 0.11, 0.37, material))
		_attach_local(root, bone_name, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.22, 0.0)))
	_signatures["pernas"] = "%s:paired_tapered_greaves" % piece_id


func _build_boots(piece_id: String, material: Material) -> void:
	for side: Array in [["calf_l", "foot_l"], ["calf_r", "foot_r"]]:
		var calf_root := Node3D.new()
		calf_root.name = "Armor_%s_%s" % [piece_id, String(side[0])]
		calf_root.add_child(_cylinder("CurvedBootLeg", 0.082, 0.105, 0.31, material))
		_attach_local(calf_root, String(side[0]),
			Transform3D(Basis.IDENTITY, Vector3(0.0, 0.33, 0.0)))
		var foot_root := Node3D.new()
		foot_root.name = "Armor_%s_%s" % [piece_id, String(side[1])]
		var toe := _sphere("RoundedBootToe", Vector3(0.075, 0.13, 0.055), material)
		foot_root.add_child(toe)
		_attach_local(foot_root, String(side[1]),
			Transform3D(Basis.IDENTITY, Vector3(0.0, 0.075, 0.0)))
	_signatures["pes"] = "%s:paired_tapered_boots" % piece_id


func _build_cape(piece_id: String, material: Material) -> void:
	var root := Node3D.new()
	root.name = "Armor_%s" % piece_id
	root.add_child(_mesh_instance("CurvedDrape", _armor_cape_mesh(material)))
	_attach(root, "spine_03", Vector3(0.0, 1.32, -0.17))
	_signatures["capa"] = "%s:curved_drape" % piece_id


func _attach(piece: Node3D, bone_name: String, model_position: Vector3) -> void:
	_attach_transform(piece, bone_name, Transform3D(Basis.IDENTITY, model_position))


func _attach_local(piece: Node3D, bone_name: String, local_transform: Transform3D) -> void:
	var bone_index := _skeleton.find_bone(StringName(bone_name))
	if bone_index < 0:
		piece.free()
		push_warning("[armor-visual] osso ausente: %s" % bone_name)
		return
	var skeleton_to_body := Transform3D.IDENTITY
	var cursor := _skeleton as Node3D
	while cursor != _body:
		skeleton_to_body = cursor.transform * skeleton_to_body
		cursor = cursor.get_parent() as Node3D
		if cursor == null:
			piece.free()
			push_warning("[armor-visual] esqueleto fora do corpo")
			return
	var model_transform := skeleton_to_body * _skeleton.get_bone_global_pose(bone_index) * local_transform
	_attach_transform(piece, bone_name, model_transform)


func _attach_transform(piece: Node3D, bone_name: String, model_transform: Transform3D) -> void:
	var attachment := attach_equipment_to_bone(piece, StringName(bone_name),
		model_transform, false, _armor_casts_shadow)
	if attachment == null:
		piece.free()
		push_warning("[armor-visual] osso ausente: %s" % bone_name)
		return
	_armor_attachments.append(attachment)


static func _mesh_instance(node_name: String, mesh: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.add_to_group("armor_visual_piece")
	return instance


static func _cylinder(node_name: String, top_radius: float, bottom_radius: float,
		height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 2
	mesh.material = material
	return _mesh_instance(node_name, mesh)


static func _sphere(node_name: String, dimensions: Vector3,
		material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = material
	var instance := _mesh_instance(node_name, mesh)
	instance.scale = dimensions * 2.0
	return instance


static func _capsule(node_name: String, radius: float, height: float,
		material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	mesh.material = material
	return _mesh_instance(node_name, mesh)


static func _cuirass_mesh(material: Material, heavy: bool) -> ArrayMesh:
	# Casca de torso feita por aneis de onze pontos. O centro avanca, os flancos
	# recuam, a cintura afunila e o decote desce no meio: nao existe uma unica
	# face rectangular nesta peca.
	var width_scale := 1.03 if heavy else 1.0
	var depth_scale := 1.03 if heavy else 1.0
	var rows := [
		{"y": -0.245, "width": 0.160 * width_scale, "depth": 0.105 * depth_scale},
		{"y": -0.14, "width": 0.188 * width_scale, "depth": 0.124 * depth_scale},
		{"y": 0.0, "width": 0.208 * width_scale, "depth": 0.140 * depth_scale},
		{"y": 0.125, "width": 0.216 * width_scale, "depth": 0.148 * depth_scale},
		{"y": 0.225, "width": 0.158 * width_scale, "depth": 0.116 * depth_scale},
	]
	var columns := 10
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row_index: int in rows.size() - 1:
		for column: int in columns:
			var u0 := lerpf(-1.0, 1.0, float(column) / float(columns))
			var u1 := lerpf(-1.0, 1.0, float(column + 1) / float(columns))
			var front_a := _cuirass_point(rows[row_index], u0, true, row_index)
			var front_b := _cuirass_point(rows[row_index], u1, true, row_index)
			var front_c := _cuirass_point(rows[row_index + 1], u0, true, row_index + 1)
			var front_d := _cuirass_point(rows[row_index + 1], u1, true, row_index + 1)
			_add_triangle(surface, front_a, front_b, front_c)
			_add_triangle(surface, front_c, front_b, front_d)
			var back_a := _cuirass_point(rows[row_index], u0, false, row_index)
			var back_b := _cuirass_point(rows[row_index], u1, false, row_index)
			var back_c := _cuirass_point(rows[row_index + 1], u0, false, row_index + 1)
			var back_d := _cuirass_point(rows[row_index + 1], u1, false, row_index + 1)
			_add_triangle(surface, back_a, back_c, back_b)
			_add_triangle(surface, back_c, back_d, back_b)
	# Fecha os flancos seguindo a curva do corpo, sem parede vertical de caixa.
	for row_index: int in rows.size() - 1:
		for side: float in [-1.0, 1.0]:
			var front_lower := _cuirass_point(rows[row_index], side, true, row_index)
			var back_lower := _cuirass_point(rows[row_index], side, false, row_index)
			var front_upper := _cuirass_point(rows[row_index + 1], side, true, row_index + 1)
			var back_upper := _cuirass_point(rows[row_index + 1], side, false, row_index + 1)
			if side < 0.0:
				_add_triangle(surface, back_lower, front_lower, back_upper)
				_add_triangle(surface, back_upper, front_lower, front_upper)
			else:
				_add_triangle(surface, front_lower, back_lower, front_upper)
				_add_triangle(surface, front_upper, back_lower, back_upper)
	return _fechar_suave(surface, material)


static func _cuirass_detail_mesh(material: Material, heavy: bool) -> ArrayMesh:
	var width_scale := 1.03 if heavy else 1.0
	var depth_scale := 1.03 if heavy else 1.0
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Uma bainha estreita acompanha a cintura; a faixa larga que fazia o torso
	# parecer uma pilha de caixotes foi removida. A diagonal quebra a leitura de
	# avental e segue a correia do alvo visual do guerreiro.
	_add_cuirass_band(surface, -0.252, -0.222, 0.161 * width_scale,
		0.127 * depth_scale)
	_add_diagonal_cuirass_strap(surface, width_scale, depth_scale, heavy)
	for rivet_x: float in [-0.142, 0.142]:
		_add_low_poly_rivet(surface, Vector3(rivet_x * width_scale, 0.132,
			0.169 * depth_scale), 0.011)
		_add_low_poly_rivet(surface, Vector3(rivet_x * 0.82 * width_scale, -0.17,
			0.151 * depth_scale), 0.010)
	return _fechar_suave(surface, material)


static func _cuirass_point(row: Dictionary, u: float, front: bool,
		row_index: int) -> Vector3:
	var width := float(row["width"])
	var depth := float(row["depth"])
	var arch := (1.0 - u * u) * (0.026 if front else 0.012)
	var z := depth + arch if front else -depth - arch * 0.5
	var y := float(row["y"])
	# Decote em U e bainha central curta: a silhueta segue o torso e as pernas.
	if row_index == 4:
		y -= (1.0 - absf(u)) * 0.065
	elif row_index == 0:
		y += (1.0 - absf(u)) * 0.025
	return Vector3(u * width, y, z)


static func _add_diagonal_cuirass_strap(surface: SurfaceTool, width_scale: float,
		depth_scale: float, heavy: bool) -> void:
	var start := Vector2(-0.145 * width_scale, 0.185)
	var finish := Vector2(0.125 * width_scale, -0.145)
	var direction := (finish - start).normalized()
	var side := Vector2(-direction.y, direction.x) * (0.016 if heavy else 0.009)
	var z_start := 0.166 * depth_scale
	var z_finish := 0.151 * depth_scale
	var a := Vector3(start.x + side.x, start.y + side.y, z_start)
	var b := Vector3(start.x - side.x, start.y - side.y, z_start)
	var c := Vector3(finish.x + side.x, finish.y + side.y, z_finish)
	var d := Vector3(finish.x - side.x, finish.y - side.y, z_finish)
	_add_triangle(surface, a, b, c)
	_add_triangle(surface, c, b, d)


static func _add_cuirass_band(surface: SurfaceTool, lower_y: float, upper_y: float,
		half_width: float, depth: float) -> void:
	var segments := 6
	for segment: int in segments:
		var u0 := lerpf(-1.0, 1.0, float(segment) / float(segments))
		var u1 := lerpf(-1.0, 1.0, float(segment + 1) / float(segments))
		var z0 := depth + (1.0 - u0 * u0) * 0.025
		var z1 := depth + (1.0 - u1 * u1) * 0.025
		var a := Vector3(u0 * half_width, lower_y, z0)
		var b := Vector3(u1 * half_width, lower_y, z1)
		var c := Vector3(u0 * half_width * 0.96, upper_y, z0 + 0.006)
		var d := Vector3(u1 * half_width * 0.96, upper_y, z1 + 0.006)
		_add_triangle(surface, a, b, c)
		_add_triangle(surface, c, b, d)


static func _add_low_poly_rivet(surface: SurfaceTool, centre: Vector3,
		radius: float) -> void:
	var peak := centre + Vector3(0.0, 0.0, radius)
	var ring := [
		centre + Vector3(-radius, 0.0, 0.0),
		centre + Vector3(0.0, radius, 0.0),
		centre + Vector3(radius, 0.0, 0.0),
		centre + Vector3(0.0, -radius, 0.0),
	]
	for index: int in ring.size():
		_add_triangle(surface, ring[index], ring[(index + 1) % ring.size()], peak)


static func _elliptical_shell(rings: Array, segments: int, material: Material) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index: int in rings.size() - 1:
		var lower: Dictionary = rings[ring_index]
		var upper: Dictionary = rings[ring_index + 1]
		for step: int in segments:
			var angle_a := TAU * float(step) / float(segments)
			var angle_b := TAU * float(step + 1) / float(segments)
			var a := _ellipse_point(lower, angle_a)
			var b := _ellipse_point(lower, angle_b)
			var c := _ellipse_point(upper, angle_a)
			var d := _ellipse_point(upper, angle_b)
			# A frente do boneco é -Z. Esta ordem mantém as normais para fora;
			# normais invertidas tornavam ferro e couro em silhuetas quase pretas.
			_add_triangle(surface, a, c, b)
			_add_triangle(surface, c, d, b)
	return _fechar_suave(surface, material)


static func _elliptical_arc(rings: Array, segments: int, material: Material) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# No espaço do modelo Quaternius, +Z é a frente apresentada ao jogador.
	var start := deg_to_rad(25.0)
	var finish := deg_to_rad(155.0)
	for ring_index: int in rings.size() - 1:
		var lower: Dictionary = rings[ring_index]
		var upper: Dictionary = rings[ring_index + 1]
		for step: int in segments:
			var angle_a := lerpf(start, finish, float(step) / float(segments))
			var angle_b := lerpf(start, finish, float(step + 1) / float(segments))
			var a := _ellipse_point(lower, angle_a)
			var b := _ellipse_point(lower, angle_b)
			var c := _ellipse_point(upper, angle_a)
			var d := _ellipse_point(upper, angle_b)
			_add_triangle(surface, a, c, b)
			_add_triangle(surface, c, d, b)
	return _fechar_suave(surface, material)


static func _ellipse_point(ring: Dictionary, angle: float) -> Vector3:
	return Vector3(cos(angle) * float(ring["x"]), float(ring["y"]),
		sin(angle) * float(ring["z"]))


static func _armor_cape_mesh(material: Material) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 8
	var rows := 6
	for row: int in rows:
		var y0 := -0.92 * float(row) / float(rows)
		var y1 := -0.92 * float(row + 1) / float(rows)
		var width0 := lerpf(0.31, 0.43, float(row) / float(rows))
		var width1 := lerpf(0.31, 0.43, float(row + 1) / float(rows))
		for column: int in columns:
			var u0 := lerpf(-1.0, 1.0, float(column) / float(columns))
			var u1 := lerpf(-1.0, 1.0, float(column + 1) / float(columns))
			var a := Vector3(u0 * width0, y0, 0.025 + 0.035 * u0 * u0)
			var b := Vector3(u1 * width0, y0, 0.025 + 0.035 * u1 * u1)
			var c := Vector3(u0 * width1, y1, 0.035 + 0.05 * u0 * u0)
			var d := Vector3(u1 * width1, y1, 0.035 + 0.05 * u1 * u1)
			_add_triangle(surface, a, b, c)
			_add_triangle(surface, c, b, d)
	return _fechar_suave(surface, material)


## ⚠️ NAO voltar a pôr uma normal por triângulo aqui.
##
## 02-08: o Mateus dizia "esse quadrado feio" e "ainda ta como uma caixa estilo
## minecraft". A GEOMETRIA nunca foi uma caixa — é uma casca de 5 anéis × 10
## colunas, com cintura afunilada e decote descido. O que estava errado era a
## LUZ: este método dava a mesma normal aos três vértices de cada triângulo, ou
## seja **flat shading**. Numa casca curva feita de 50 quadrados, cada face
## acende-se sozinha e o resultado lê-se como cartão facetado.
##
## Agora os vértices entram sem normal; o `index()` solda os que partilham
## posição e o `generate_normals()` calcula a média entre faces vizinhas. A
## mesma malha, a mesma contagem de triângulos, e passa a curvar-se à luz.
static func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for vertex: Vector3 in [a, b, c]:
		surface.add_vertex(vertex)


## Fecha uma superfície com normais suaves. Chamar antes de `commit()`.
static func _fechar_suave(surface: SurfaceTool, material: Material) -> ArrayMesh:
	surface.index()
	surface.generate_normals()
	# As cascas geradas nao tem UV nem normal map; tangentes seriam trabalho
	# inutil e o Godot rejeita gera-las sem UV. As normais continuam suaves.
	surface.set_material(material)
	return surface.commit()


static func _piece_data(piece_id: String) -> Dictionary:
	var data := GameData.equipment_armor(piece_id)
	if data.is_empty():
		data = (GameData.armor.get("pieces", {}) as Dictionary).get(piece_id, {}) as Dictionary
	return data


static func _material_for(piece_id: String, data: Dictionary) -> StandardMaterial3D:
	var material_text := String(data.get("material", "")).to_lower()
	var profile := "leather"
	if "ferro" in material_text:
		profile = "polished_iron" if "polido" in material_text else "rough_iron"
	elif "pano" in material_text:
		profile = "dark_cloth"
	elif "la" in material_text or "lã" in material_text:
		profile = "light_cloth" if "clara" in piece_id else "waxed_wool"
	elif "pelo" in material_text:
		profile = "fur_leather"
	return _source_material(profile)


static func _accent_material(profile: String) -> StandardMaterial3D:
	return _source_material(profile)


static func _source_material(profile: String) -> StandardMaterial3D:
	if _material_cache.has(profile):
		return _material_cache[profile] as StandardMaterial3D
	var colors := {
		"leather": Color("69452f"), "fur_leather": Color("6e5a43"),
		"dark_leather": Color("281a13"),
		"rough_iron": Color("8a8e8e"), "polished_iron": Color("bec3c2"),
		"dark_cloth": Color("24282a"), "waxed_wool": Color("30383b"),
		"light_cloth": Color("aaa48f"), "iron_visor": Color("16191a"),
		"fur": Color("625b50"),
	}
	var material := StandardMaterial3D.new()
	material.albedo_color = colors.get(profile, Color("4a3022")) as Color
	material.roughness = 0.42 if profile == "polished_iron" else 0.72 \
		if profile == "rough_iron" else 0.9
	# Sem um cubemap de reflexão, metal a 0.9 lia-se como carvão no renderer
	# Mobile. Estes valores conservam o brilho sem apagar a geometria.
	material.metallic = 0.10 if profile == "polished_iron" else 0.06 \
		if profile == "rough_iron" else 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[profile] = material
	return material
