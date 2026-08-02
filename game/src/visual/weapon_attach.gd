class_name WeaponAttach
extends Node3D
## Equipamento visivel preso ao esqueleto real do personagem.
##
## O actor continua a ser a autoridade sobre o loadout. Este componente apenas
## traduz os IDs/familias declarados nos JSON para props CC0 ja importados e
## troca a instancia no proprio frame em que o loadout muda.

const MODEL_ROOT := "res://assets/models/weapons/"
const CENTIMETRES_PER_METRE := 100.0

# [CODEX] O nome do ficheiro e o ID da familia do catalogo. Razao: uma familia
# nova passa a ser descoberta pelo dado, sem acrescentar outra lista manual a
# GDScript. Alternativa descartada: dicionarios EXACT_MODELS/FAMILY_MODELS; foi
# precisamente uma lista dessas que deixou conteudo existente invisivel.

static var _visual_materials := {}

const RIGHT_HAND_CANDIDATES := [
	"handslot.r", "HandSlot.R", "hand.R", "Hand.R", "hand_r", "RightHand",
	"mixamorig:RightHand",
]
const LEFT_HAND_CANDIDATES := [
	"handslot.l", "HandSlot.L", "hand.L", "Hand.L", "hand_l", "LeftHand",
	"mixamorig:LeftHand",
]

var _actor: Node
var _skeleton: Skeleton3D
var _main_attachment: BoneAttachment3D
var _offhand_attachment: BoneAttachment3D
var _main_model: Node3D
var _offhand_model: Node3D
var _main_tip: Marker3D
var _main_weapon_id := ""
var _offhand_weapon_id := ""
var _two_handed := false


func setup(actor: Node, character_visual: Node3D) -> bool:
	name = "WeaponAttach"
	_actor = actor
	_skeleton = character_visual.call("get_equipment_skeleton") as Skeleton3D \
		if character_visual.has_method("get_equipment_skeleton") else _find_skeleton(character_visual)
	if _skeleton == null:
		push_error("[weapon-attach] o corpo nao tem Skeleton3D")
		return false

	_main_attachment = _make_attachment("MainHandWeapon", true)
	_offhand_attachment = _make_attachment("OffhandWeapon", false)
	if _main_attachment == null or _offhand_attachment == null:
		_cleanup_attachments()
		return false

	# O prop de classe antigo nao representa o loadout. Esconde-lo impede um
	# escudo fantasma quando o jogador muda de equipamento.
	var decorative_prop := character_visual.find_child("ClassProp", true, false) as Node3D
	if decorative_prop != null:
		decorative_prop.visible = false
	sync_from_actor()
	return true


func _process(_delta: float) -> void:
	if is_instance_valid(_actor):
		sync_from_actor()


func sync_from_actor() -> void:
	if not is_instance_valid(_actor):
		return
	sync_loadout(
		String(_read_property(_actor, "main_weapon", "")),
		String(_read_property(_actor, "offhand_weapon", "")),
		bool(_read_property(_actor, "is_two_handed", false)))


func sync_loadout(main_weapon: String, offhand_weapon: String, two_handed: bool) -> void:
	if main_weapon != _main_weapon_id:
		_main_weapon_id = main_weapon
		_main_model = _replace_model(_main_attachment, _main_model, main_weapon, true)
		_main_tip = _make_tip_marker(_main_model)
	if offhand_weapon != _offhand_weapon_id:
		_offhand_weapon_id = offhand_weapon
		_offhand_model = _replace_model(_offhand_attachment, _offhand_model, offhand_weapon, false)
	_two_handed = two_handed
	if is_instance_valid(_offhand_model):
		_offhand_model.visible = not two_handed


func model_source_for(weapon_id: String) -> String:
	var data := _weapon_data(weapon_id)
	# Estes instrumentos recusam honestamente o prop generico da familia; sino e
	# talisma acabavam ambos como uma vara quando essa decisao se perdia.
	if _visual_kind(data) in ["bell", "talisman"]:
		return ""
	var family := _visual_family_for(weapon_id)
	if family.is_empty():
		return ""
	for extension: String in ["glb", "gltf", "tscn"]:
		var candidate := "%s%s.%s" % [MODEL_ROOT, family, extension]
		if ResourceLoader.exists(candidate):
			return candidate
	return ""


func model_kind_for(weapon_id: String) -> String:
	return "asset" if not model_source_for(weapon_id).is_empty() else "procedural"


func has_visible_weapon(weapon_id: String, main_hand := true) -> bool:
	if main_hand:
		return weapon_id == _main_weapon_id \
			and is_instance_valid(_main_model) and _main_model.visible
	return weapon_id == _offhand_weapon_id \
		and is_instance_valid(_offhand_model) and _offhand_model.visible


func attachment_bones() -> Dictionary:
	return {
		"main": _main_attachment.bone_name if is_instance_valid(_main_attachment) else "",
		"offhand": _offhand_attachment.bone_name if is_instance_valid(_offhand_attachment) else "",
	}


func visible_mesh_count() -> int:
	var count := 0
	for model: Node3D in [_main_model, _offhand_model]:
		if not is_instance_valid(model) or not model.visible:
			continue
		count += model.find_children("*", "MeshInstance3D", true, false).size()
	return count


func main_model_instance_id() -> int:
	return _main_model.get_instance_id() if is_instance_valid(_main_model) else 0


func main_weapon_tip_position() -> Vector3:
	if is_instance_valid(_main_tip):
		return _main_tip.global_position
	if is_instance_valid(_main_attachment):
		return _main_attachment.global_position
	return global_position


func _make_attachment(node_name: String, right_hand: bool) -> BoneAttachment3D:
	var bone_name := _find_hand_bone(_skeleton, right_hand)
	if bone_name.is_empty():
		push_error("[weapon-attach] rig sem mao %s: %s" % [
			"direita" if right_hand else "esquerda", _skeleton.name])
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = node_name
	attachment.bone_name = bone_name
	_skeleton.add_child(attachment)
	return attachment


func _replace_model(attachment: BoneAttachment3D, previous: Node3D,
		weapon_id: String, is_main: bool) -> Node3D:
	if is_instance_valid(previous):
		# A troca visual acontece ja; o no antigo e libertado no fim do frame para
		# o servidor de render terminar qualquer leitura em curso.
		previous.visible = false
		previous.queue_free()
	if attachment == null or weapon_id.is_empty():
		return null
	var weapon_data := _weapon_data(weapon_id)
	var scene_path := model_source_for(weapon_id)
	var model: Node3D
	if scene_path.is_empty():
		model = _build_procedural_weapon(weapon_data)
	else:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			push_error("[weapon-attach] modelo nao importavel: %s" % scene_path)
			return null
		model = packed.instantiate() as Node3D
		_tune_imported_materials(model)
	if model == null:
		push_error("[weapon-attach] sem geometria credivel: %s" % weapon_id)
		return null
	model.name = ("Main_%s" if is_main else "Offhand_%s") % weapon_id
	attachment.add_child(model)
	if not bool(model.get_meta("visual_size_ready", false)):
		model.scale = _catalogue_scale_for(model, weapon_data)
	_apply_grip_transform(model, weapon_data)
	model.set_meta("weapon_family", _visual_family_for(weapon_id))
	model.set_meta("weapon_visual_source", scene_path if not scene_path.is_empty() else "procedural")
	_disable_prop_shadows(model)
	return model


func _weapon_data(weapon_id: String) -> Dictionary:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		return {}
	var weapon: Dictionary = game_data.call("weapon", weapon_id) as Dictionary \
		if game_data.has_method("weapon") else {}
	var catalogue: Dictionary = game_data.call("equipment_weapon", weapon_id) as Dictionary \
		if game_data.has_method("equipment_weapon") else {}
	var instrument := {}
	var equipment_data := game_data.get("equipment") as Dictionary
	for instrument_id: String in (equipment_data.get(
			"magic_instruments", {}) as Dictionary):
		var candidate := (equipment_data.get(
			"magic_instruments", {}) as Dictionary).get(instrument_id, {}) as Dictionary
		if instrument_id == weapon_id \
				or String(candidate.get("weapon_id", "")) == weapon_id:
			instrument = candidate
			break
	# O runtime curto traz frames/slot; os catalogos largos trazem materia e
	# descricao. Completar chaves ausentes conserva uma autoridade por eixo.
	weapon = weapon.duplicate(true)
	for source: Dictionary in [instrument, catalogue]:
		for key: Variant in source:
			if not weapon.has(key):
				weapon[key] = source[key]
	return weapon


func _visual_family_for(weapon_id: String) -> String:
	var data := _weapon_data(weapon_id)
	var family := String(data.get("familia", ""))
	if family.is_empty():
		family = String(data.get("familia_escudo", ""))
	return family


static func _visual_kind(data: Dictionary) -> String:
	var presentation := data.get("presentation", {}) as Dictionary
	var result := String(presentation.get("visual_kind", ""))
	if result.is_empty():
		result = String(data.get("instrument_type", ""))
	if result == "sino":
		result = "bell"
	elif result == "talisma":
		result = "talisman"
	return result


static func _apply_grip_transform(model: Node3D, data: Dictionary) -> void:
	var presentation := data.get("presentation", {}) as Dictionary
	var grip := presentation.get("grip_transform", {}) as Dictionary
	if grip.is_empty():
		return
	model.position = _vector3_from_data(grip.get("position", []), Vector3.ZERO)
	model.rotation_degrees = _vector3_from_data(
		grip.get("rotation_degrees", []), Vector3.ZERO)
	model.scale *= _vector3_from_data(grip.get("scale", []), Vector3.ONE)
	model.set_meta("weapon_grip_transform", grip.duplicate(true))


static func _vector3_from_data(value: Variant, fallback: Vector3) -> Vector3:
	if value is Vector3:
		return value as Vector3
	if value is Array and (value as Array).size() >= 3:
		var values := value as Array
		return Vector3(float(values[0]), float(values[1]), float(values[2]))
	return fallback


static func _catalogue_scale_for(model: Node3D, data: Dictionary) -> Vector3:
	var target_length := _target_visual_length_m(data)
	if target_length <= 0.0:
		return Vector3.ONE
	var source_bounds := _model_bounds(model)
	var source_length := maxf(source_bounds.size.x,
		maxf(source_bounds.size.y, source_bounds.size.z))
	if source_length <= 0.0:
		return Vector3.ONE
	var uniform := target_length / source_length
	var result := Vector3.ONE * uniform
	var description := String(data.get("descricao_visual", data.get("visual_description", "")))
	if description.is_empty():
		description = String((data.get("visual", {}) as Dictionary).get(
			"visual_description", ""))
	var normal := description.to_lower()
	# O modelo KayKit da espada tem proporcao de cutelo de fantasia. O catalogo
	# diz explicitamente "lamina" e "guarda curta"; comprimir apenas os eixos
	# transversais conserva o modelo 3D e devolve-lhe a silhueta longa e estreita.
	if String(data.get("familia", "")) == "espada_recta" \
			and source_bounds.size.y == source_length \
			and ("lamina" in normal or "lâmina" in normal):
		result.x *= 0.38
		result.z *= 0.62
	return result


static func _target_visual_length_m(data: Dictionary) -> float:
	var description := String(data.get("descricao_visual", data.get("visual_description", "")))
	if description.is_empty():
		description = String((data.get("visual", {}) as Dictionary).get(
			"visual_description", ""))
	var expression := RegEx.new()
	if expression.compile("(\\d+(?:[.,]\\d+)?)\\s*cm") != OK:
		return 0.0
	var largest_cm := 0.0
	for result: RegExMatch in expression.search_all(description.to_lower()):
		largest_cm = maxf(largest_cm,
			result.get_string(1).replace(",", ".").to_float())
	return largest_cm / CENTIMETRES_PER_METRE


static func _model_bounds(model: Node3D) -> AABB:
	var found := false
	var bounds := AABB()
	for descendant: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var to_model := model.global_transform.affine_inverse() * mesh_instance.global_transform
		for corner: Vector3 in _aabb_corners(mesh_instance.mesh.get_aabb()):
			var point := to_model * corner
			if not found:
				bounds = AABB(point, Vector3.ZERO)
				found = true
			else:
				bounds = bounds.expand(point)
	return bounds


static func _build_procedural_weapon(data: Dictionary) -> Node3D:
	var description := String(data.get("descricao_visual", data.get("visual_description", "")))
	if description.is_empty():
		description = String((data.get("visual", {}) as Dictionary).get(
			"visual_description", ""))
	var normal := description.to_lower()
	var target_length := _target_visual_length_m(data)
	match _visual_kind(data):
		"bell":
			return _build_bell()
		"talisman":
			return _build_talisman()
	if "curva" in normal and ("lamina" in normal or "lâmina" in normal):
		return _build_curved_blade(maxf(target_length, 0.75))
	if "cajado" in normal:
		return _build_staff(maxf(target_length, 1.5))
	if "haste" in normal or "lanca" in normal or "lança" in normal:
		return _build_polearm(maxf(target_length, 1.5))
	return _build_polearm(maxf(target_length, 1.2))


static func _build_bell() -> Node3D:
	var root := Node3D.new()
	root.set_meta("visual_size_ready", true)
	var leather := _visual_material("leather", Color("2d211b"), 0.94, 0.0)
	var bronze := _visual_material("dull_bronze", Color("8b7042"), 0.72, 0.28)
	var iron := _visual_material("worn_iron", Color("aeb4b4"), 0.62, 0.08)
	var handle := _cylinder_mesh_instance(
		"BellLeatherHandle", 0.018, 0.11, leather)
	handle.position.y = -0.025
	root.add_child(handle)
	var bell_mesh := CylinderMesh.new()
	bell_mesh.top_radius = 0.028
	bell_mesh.bottom_radius = 0.070
	bell_mesh.height = 0.105
	bell_mesh.radial_segments = 12
	bell_mesh.rings = 2
	bell_mesh.material = bronze
	var bell := MeshInstance3D.new()
	bell.name = "CrackedBronzeBell"
	bell.mesh = bell_mesh
	bell.position.y = -0.125
	root.add_child(bell)
	var clapper := _cylinder_mesh_instance("IronClapper", 0.012, 0.075, iron)
	clapper.position.y = -0.180
	root.add_child(clapper)
	return root


static func _build_talisman() -> Node3D:
	var root := Node3D.new()
	root.set_meta("visual_size_ready", true)
	var leather := _visual_material("leather", Color("2d211b"), 0.94, 0.0)
	var iron := _visual_material("dead_iron", Color("54575a"), 0.88, 0.20)
	var cord := _cylinder_mesh_instance("BlackLeatherCord", 0.010, 0.13, leather)
	cord.position.y = -0.035
	root.add_child(cord)
	var plaque_mesh := CylinderMesh.new()
	plaque_mesh.top_radius = 0.082
	plaque_mesh.bottom_radius = 0.072
	plaque_mesh.height = 0.018
	plaque_mesh.radial_segments = 7
	plaque_mesh.rings = 1
	plaque_mesh.material = iron
	var plaque := MeshInstance3D.new()
	plaque.name = "PalmSizedIronTalisman"
	plaque.mesh = plaque_mesh
	plaque.rotation.x = PI * 0.5
	plaque.position.y = -0.145
	root.add_child(plaque)
	var rune := _box_mesh_instance(
		"DeepRune", Vector3(0.018, 0.075, 0.008), leather)
	rune.rotation.z = PI * 0.22
	rune.position = Vector3(0.0, -0.145, 0.014)
	root.add_child(rune)
	return root


static func _build_curved_blade(total_length: float) -> Node3D:
	var root := Node3D.new()
	root.set_meta("visual_size_ready", true)
	# O plano largo da lamina fica perpendicular ao eixo lateral da mao UAL;
	# sem esta rotacao, a captura via apenas a espessura apesar do volume existir.
	root.rotation.y = PI * 0.25
	var leather := _visual_material("leather", Color("2d211b"), 0.94, 0.0)
	var iron := _visual_material("worn_iron", Color("aeb4b4"), 0.62, 0.08)
	var grip := _cylinder_mesh_instance("WrappedGrip", 0.026, 0.23, leather)
	grip.position.y = 0.02
	root.add_child(grip)
	var guard := _cylinder_mesh_instance("OvalGuard", 0.075, 0.018, iron)
	guard.scale.z = 0.62
	guard.position.y = 0.15
	root.add_child(guard)
	var blade := MeshInstance3D.new()
	blade.name = "SolidCurvedBlade"
	blade.mesh = _solid_curved_blade_mesh(maxf(0.45, total_length - 0.18), iron)
	blade.position.y = 0.15
	root.add_child(blade)
	return root


static func _build_polearm(total_length: float) -> Node3D:
	var root := Node3D.new()
	root.set_meta("visual_size_ready", true)
	var wood := _visual_material("dark_wood", Color("2e2117"), 0.96, 0.0)
	var iron := _visual_material("worn_iron", Color("aeb4b4"), 0.62, 0.08)
	var tip_length := minf(total_length * 0.14, 0.24)
	var shaft_length := total_length - tip_length
	var shaft := _cylinder_mesh_instance("RoundShaft", 0.024, shaft_length, wood)
	shaft.position.y = shaft_length * 0.5 - total_length * 0.16
	root.add_child(shaft)
	var tip_mesh := CylinderMesh.new()
	tip_mesh.top_radius = 0.0
	tip_mesh.bottom_radius = 0.065
	tip_mesh.height = tip_length
	tip_mesh.radial_segments = 6
	tip_mesh.rings = 1
	tip_mesh.material = iron
	var tip := MeshInstance3D.new()
	tip.name = "ForgedTip"
	tip.mesh = tip_mesh
	tip.position.y = shaft.position.y + shaft_length * 0.5 + tip_length * 0.5
	root.add_child(tip)
	return root


static func _build_staff(total_length: float) -> Node3D:
	var root := Node3D.new()
	root.set_meta("visual_size_ready", true)
	var wood := _visual_material("dark_wood", Color("2e2117"), 0.96, 0.0)
	var iron := _visual_material("worn_iron", Color("aeb4b4"), 0.62, 0.08)
	var crystal := _visual_material("dull_blue_crystal", Color("446879"), 0.34, 0.08)
	var head_length := minf(total_length * 0.11, 0.19)
	var shaft_length := total_length - head_length
	var shaft := _cylinder_mesh_instance("ThinWoodenShaft", 0.019, shaft_length, wood)
	# No osso UAL, -Y local aponta para cima. O foco fica acima do ombro e a
	# extremidade simples desce ate perto do chao, como no conceito.
	shaft.position.y = -shaft_length * 0.5 + total_length * 0.18
	root.add_child(shaft)
	var collar := _cylinder_mesh_instance("IronCrystalCollar", 0.052, 0.075, iron)
	collar.position.y = shaft.position.y - shaft_length * 0.5 - 0.02
	root.add_child(collar)
	var crystal_mesh := SphereMesh.new()
	crystal_mesh.radius = 0.5
	crystal_mesh.height = 1.0
	crystal_mesh.radial_segments = 6
	crystal_mesh.rings = 3
	crystal_mesh.material = crystal
	var focus := MeshInstance3D.new()
	focus.name = "FacetedDullCrystal"
	focus.mesh = crystal_mesh
	focus.scale = Vector3(0.075, head_length, 0.075)
	focus.position.y = collar.position.y - head_length * 0.55
	root.add_child(focus)
	return root


static func _solid_curved_blade_mesh(length: float, material: Material) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 10
	var half_thickness := 0.008
	for segment: int in segments:
		var t0 := float(segment) / float(segments)
		var t1 := float(segment + 1) / float(segments)
		var c0 := Vector3(length * 0.13 * t0 * t0, length * t0, 0.0)
		var c1 := Vector3(length * 0.13 * t1 * t1, length * t1, 0.0)
		var half_width0 := lerpf(0.042, 0.006, t0)
		var half_width1 := lerpf(0.042, 0.006, t1)
		var a := c0 + Vector3(-half_width0, 0.0, half_thickness)
		var b := c0 + Vector3(half_width0, 0.0, half_thickness)
		var c := c1 + Vector3(-half_width1, 0.0, half_thickness)
		var d := c1 + Vector3(half_width1, 0.0, half_thickness)
		_add_triangle(surface, a, b, c)
		_add_triangle(surface, c, b, d)
		var back_a := Vector3(a.x, a.y, -half_thickness)
		var back_b := Vector3(b.x, b.y, -half_thickness)
		var back_c := Vector3(c.x, c.y, -half_thickness)
		var back_d := Vector3(d.x, d.y, -half_thickness)
		_add_triangle(surface, back_a, back_c, back_b)
		_add_triangle(surface, back_c, back_d, back_b)
		_add_triangle(surface, a, c, back_a)
		_add_triangle(surface, back_a, c, back_c)
		_add_triangle(surface, b, back_b, d)
		_add_triangle(surface, d, back_b, back_d)
	surface.set_material(material)
	return surface.commit()


static func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	for vertex: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.add_vertex(vertex)


static func _cylinder_mesh_instance(node_name: String, radius: float, height: float,
		material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	return instance


static func _box_mesh_instance(node_name: String, size: Vector3,
		material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	return instance


static func _visual_material(key: String, colour: Color, roughness: float,
		metallic: float) -> StandardMaterial3D:
	if _visual_materials.has(key):
		return _visual_materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	material.metallic = metallic
	_visual_materials[key] = material
	return material


func _make_tip_marker(model: Node3D) -> Marker3D:
	if not is_instance_valid(model):
		return null
	var marker := Marker3D.new()
	marker.name = "WeaponTip"
	model.add_child(marker)
	var farthest := Vector3.ZERO
	var farthest_squared := 0.0
	for descendant: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var box := mesh_instance.mesh.get_aabb()
		var to_model := model.global_transform.affine_inverse() * mesh_instance.global_transform
		for corner in _aabb_corners(box):
			var point := to_model * corner
			if point.length_squared() > farthest_squared:
				farthest = point
				farthest_squared = point.length_squared()
	marker.position = farthest
	return marker


static func _aabb_corners(box: AABB) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	for x in [box.position.x, box.end.x]:
		for y in [box.position.y, box.end.y]:
			for z in [box.position.z, box.end.z]:
				corners.append(Vector3(x, y, z))
	return corners


static func _disable_prop_shadows(model: Node3D) -> void:
	# Evita um passe de sombra adicional por arma na GPU alvo. A leitura da
	# silhueta conserva-se com o material original e a sombra do corpo.
	for descendant: Node in model.find_children("*", "MeshInstance3D", true, false):
		(descendant as MeshInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _tune_imported_materials(model: Node3D) -> void:
	# Os atlas KayKit sao vivos para leitura a distancia. Multiplica a textura,
	# sem a apagar, para a paleta fria/desgastada do conceito aprovado.
	for descendant: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface_index: int in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface_index) as StandardMaterial3D
			if source == null:
				# Alguns GLTF deixam a superficie sem material explicito. O renderer
				# Dummy consulta-a na libertacao; dar-lhe um material neutro evita um
				# RID nulo e conserva uma arma visivel se o atlas faltar.
				mesh_instance.set_surface_override_material(surface_index,
					_visual_material("imported_fallback", Color("788080"), 0.72, 0.04))
				continue
			var tuned := source.duplicate() as StandardMaterial3D
			tuned.albedo_color *= Color(0.68, 0.70, 0.70, 1.0)
			tuned.roughness = maxf(tuned.roughness, 0.68)
			tuned.metallic = minf(tuned.metallic, 0.18)
			mesh_instance.set_surface_override_material(surface_index, tuned)


static func _find_hand_bone(skeleton: Skeleton3D, right_hand: bool) -> String:
	var candidates := RIGHT_HAND_CANDIDATES if right_hand else LEFT_HAND_CANDIDATES
	for candidate: String in candidates:
		if skeleton.find_bone(candidate) >= 0:
			return candidate
	var wanted_side := "right" if right_hand else "left"
	var wanted_letter := "r" if right_hand else "l"
	for bone_index in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone_index)
		var normal := String(bone_name).to_lower().replace(".", "").replace("_", "").replace(":", "")
		if "handslot" in normal and (wanted_side in normal or normal.ends_with(wanted_letter)):
			return bone_name
	for bone_index in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone_index)
		var normal := String(bone_name).to_lower().replace(".", "").replace("_", "").replace(":", "")
		if "hand" in normal and (wanted_side in normal or normal.ends_with(wanted_letter)):
			return bone_name
	return ""


static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


static func _read_property(object: Object, property_name: StringName,
		fallback: Variant) -> Variant:
	for property: Dictionary in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return object.get(property_name)
	return fallback


func _cleanup_attachments() -> void:
	for attachment: BoneAttachment3D in [_main_attachment, _offhand_attachment]:
		if is_instance_valid(attachment):
			attachment.queue_free()
	_main_attachment = null
	_offhand_attachment = null


func _exit_tree() -> void:
	_cleanup_attachments()
