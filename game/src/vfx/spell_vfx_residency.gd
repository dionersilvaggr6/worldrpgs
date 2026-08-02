class_name SpellVfxResidency
extends RefCounted
## Cache transaccional dos VFX de magia: so materializa os feiticos equipados.

var _catalog: Dictionary = {}
var _vfx: Dictionary = {}
var _resident_ids: Array = []
var _bundles: Dictionary = {}
var _meshes: Dictionary = {}
var _materials: Dictionary = {}
var _last_build_ms: float = 0.0


func configure(catalog: Dictionary) -> void:
	_catalog = catalog
	_vfx = catalog.get("_vfx", {}) as Dictionary
	release_all()


func equip(spell_ids: Array) -> bool:
	var residency: Dictionary = _vfx.get("residency", {}) as Dictionary
	var maximum := int(residency.get("max_spells", 0))
	if maximum <= 0 or spell_ids.size() > maximum:
		return false

	var next_ids: Array = []
	for raw_id: Variant in spell_ids:
		var spell_id := String(raw_id)
		if spell_id.begins_with("_") or not _catalog.has(spell_id) or next_ids.has(spell_id):
			return false
		next_ids.append(spell_id)

	var started_usec := Time.get_ticks_usec()
	var next_meshes: Dictionary = {}
	var next_materials: Dictionary = {}
	var next_bundles: Dictionary = {}
	var shapes: Dictionary = _vfx.get("form_shapes", {}) as Dictionary
	var audio_profiles: Dictionary = _vfx.get("audio_profiles", {}) as Dictionary
	for spell_id: String in next_ids:
		var spell: Dictionary = _catalog.get(spell_id, {}) as Dictionary
		var form := String(spell.get("delivery_form", ""))
		var shape := String(shapes.get(form, "orb"))
		var school := String(spell.get("school", "feiticaria"))
		if not next_meshes.has(shape):
			next_meshes[shape] = _build_mesh(shape)
		if not next_materials.has(school):
			next_materials[school] = _build_material(school)
		next_bundles[spell_id] = {
			"spell_id": spell_id,
			"form": form,
			"shape": shape,
			"school": school,
			"mesh": next_meshes[shape],
			"material": next_materials[school],
			"render": (_vfx.get("render", {}) as Dictionary).duplicate(true),
			"audio_profile": String(audio_profiles.get(school, "attack_moving")),
		}

	_resident_ids = next_ids
	_meshes = next_meshes
	_materials = next_materials
	_bundles = next_bundles
	_last_build_ms = float(Time.get_ticks_usec() - started_usec) / 1000.0
	return true


func has_spell(spell_id: String) -> bool:
	return _bundles.has(spell_id)


func resident_spell_ids() -> Array:
	return _resident_ids.duplicate()


func bundle_for(spell_id: String) -> Dictionary:
	return (_bundles.get(spell_id, {}) as Dictionary).duplicate()


func stats() -> Dictionary:
	return {
		"policy": String((_vfx.get("residency", {}) as Dictionary).get("policy", "")),
		"resident_spell_count": _resident_ids.size(),
		"mesh_count": _meshes.size(),
		"material_count": _materials.size(),
		"resource_count": _meshes.size() + _materials.size(),
		"last_build_ms": _last_build_ms,
	}


func release_all() -> void:
	_resident_ids.clear()
	_bundles.clear()
	_meshes.clear()
	_materials.clear()
	_last_build_ms = 0.0


func _build_mesh(shape: String) -> PrimitiveMesh:
	var render: Dictionary = _vfx.get("render", {}) as Dictionary
	var radial_segments := int(render.get("radial_segments", 0))
	var rings := int(render.get("rings", 0))
	var diameter := float(render.get("base_diameter_m", 0.0))
	match shape:
		"shard":
			var shard := CylinderMesh.new()
			shard.top_radius = 0.0
			shard.bottom_radius = float(render.get("shard_width_m", 0.0))
			shard.height = float(render.get("shard_length_m", 0.0))
			shard.radial_segments = radial_segments
			return shard
		"plate":
			var plate := CylinderMesh.new()
			plate.top_radius = diameter * 0.5
			plate.bottom_radius = diameter * 0.5
			plate.height = float(render.get("plate_height_m", 0.0))
			plate.radial_segments = radial_segments
			return plate
		"beam":
			var beam := BoxMesh.new()
			beam.size = Vector3(
				float(render.get("beam_width_m", 0.0)),
				float(render.get("beam_height_m", 0.0)),
				diameter)
			return beam
		"blade":
			var blade := BoxMesh.new()
			blade.size = Vector3(
				float(render.get("blade_width_m", 0.0)),
				float(render.get("blade_width_m", 0.0)),
				float(render.get("blade_length_m", 0.0)))
			return blade
		"ring":
			var ring := TorusMesh.new()
			ring.inner_radius = float(render.get("ring_inner_radius_m", 0.0))
			ring.outer_radius = float(render.get("ring_outer_radius_m", 0.0))
			ring.rings = rings
			ring.ring_segments = radial_segments
			return ring
		_:
			var orb := SphereMesh.new()
			orb.radius = diameter * 0.5
			orb.height = diameter
			orb.radial_segments = radial_segments
			orb.rings = rings
			return orb


func _build_material(school: String) -> StandardMaterial3D:
	var render: Dictionary = _vfx.get("render", {}) as Dictionary
	var colors: Dictionary = _vfx.get("school_colors", {}) as Dictionary
	var color := Color.from_string(String(colors.get(school, "#FFFFFF")), Color.WHITE)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = float(render.get("emission_energy", 0.0))
	return material
