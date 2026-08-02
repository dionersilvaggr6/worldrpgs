class_name CharacterVisual
extends Node3D
## Corpo humano Quaternius vestido sobre a capsula de fisica.
##
## Os dois corpos base partilham o esqueleto UAL de 65 ossos. A origem nunca
## troca o rig. Quando existe um fato modular, porem, a geometria do fato
## substitui o corpo e o modelo base conserva apenas cabeca, olhos e
## sobrancelhas. E o contrato do pack Quaternius e evita clipping e trabalho de
## vertices invisiveis. O KayKit continua no repositorio para cenario, mas nao
## e um corpo de jogador.

const PLAYER_BODY_PACK := "quaternius"
const BODY_PATHS := {
	"body_male": "res://assets/models/characters/quaternius/Superhero_Male_FullBody.gltf",
	"body_female": "res://assets/models/characters/quaternius/Superhero_Female_FullBody.gltf",
}
const BODY_SOURCE_HEIGHTS := {
	"body_male": 1.819586,
	"body_female": 1.775051,
}

const CLASS_TINTS := {
	"warrior": Color("d9b46f"),
	"sorcerer": Color("829de0"),
	"tank": Color("aeb8c5"),
	"assassin": Color("71907c"),
	"berserker": Color("c87562"),
	"paladin": Color("e2c66f"),
	"evil_mage": Color("8f789e"),
}

# [CODEX] Silhuetas de baixo custo para as pecas iniciais que ainda nao tem
# modelo UAL compativel. Razao: um corpo adulto vestido com geometria simples
# cumpre a decisao e preserva as animacoes. Alternativa descartada: usar os
# aventureiros KayKit como fatos completos; voltava a trocar corpo, proporcao e
# esqueleto. As assinaturas descrevem geometria, nao cor, e sao unicas.
const ORIGIN_OUTFITS := {
	"warrior": {
		"signature": "cuirass_tapered|pauldron_left|boots_paired",
		"pieces": [
			{"name": "Cuirass", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.50, 0.46, 0.38), "depth": 0.38,
				"position": Vector3(0.0, 1.24, 0.02),
				"material": "leather"},
			{"name": "PauldronLeft", "shape": "sphere", "bone": "upperarm_l",
				"scale": Vector3(0.30, 0.16, 0.35), "position": Vector3(-0.28, 1.43, 0.0),
				"material": "iron"},
			{"name": "BootLeft", "shape": "box", "bone": "calf_l",
				"size": Vector3(0.17, 0.38, 0.24), "position": Vector3(-0.13, 0.31, 0.015),
				"material": "leather"},
			{"name": "BootRight", "shape": "box", "bone": "calf_r",
				"size": Vector3(0.17, 0.38, 0.24), "position": Vector3(0.13, 0.31, 0.015),
				"material": "leather"},
		],
	},
	"sorcerer": {
		"signature": "robe_fitted|cape_long_flared|belt_narrow",
		"pieces": [
			{"name": "RobeTorso", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.44, 0.54, 0.36), "depth": 0.34,
				"position": Vector3(0.0, 1.20, 0.02), "material": "cloth"},
			{"name": "LongCape", "shape": "cape", "bone": "spine_03",
				"size": Vector3(0.36, 0.98, 0.66), "depth": 0.045,
				"position": Vector3(0.0, 1.06, -0.17), "material": "cloth"},
			{"name": "Belt", "shape": "box", "bone": "pelvis",
				"size": Vector3(0.46, 0.10, 0.29), "position": Vector3(0.0, 0.99, 0.0),
				"material": "leather"},
		],
	},
	"tank": {
		"signature": "helm_closed|cuirass_wide_tapered|pauldrons_symmetric",
		"pieces": [
			{"name": "ClosedHelm", "shape": "frustum", "bone": "Head",
				"size": Vector3(0.18, 0.28, 0.21), "position": Vector3(0.0, 1.67, 0.0),
				"material": "iron"},
			{"name": "WideCuirass", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.60, 0.52, 0.46), "depth": 0.40,
				"position": Vector3(0.0, 1.24, 0.02),
				"material": "iron"},
			{"name": "PauldronLeft", "shape": "sphere", "bone": "upperarm_l",
				"scale": Vector3(0.32, 0.18, 0.38), "position": Vector3(-0.30, 1.43, 0.0),
				"material": "iron"},
			{"name": "PauldronRight", "shape": "sphere", "bone": "upperarm_r",
				"scale": Vector3(0.32, 0.18, 0.38), "position": Vector3(0.30, 1.43, 0.0),
				"material": "iron"},
		],
	},
	"assassin": {
		"signature": "hood_close|mask_band|tunic_fitted|boots_paired",
		"pieces": [
			{"name": "CloseHood", "shape": "hood", "bone": "Head",
				"size": Vector3(0.38, 0.30, 0.34), "position": Vector3(0.0, 1.68, 0.0),
				"material": "cloth"},
			{"name": "MaskBand", "shape": "box", "bone": "Head",
				"size": Vector3(0.25, 0.10, 0.08), "position": Vector3(0.0, 1.63, 0.11),
				"material": "cloth"},
			{"name": "FittedTunic", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.42, 0.44, 0.32), "depth": 0.32,
				"position": Vector3(0.0, 1.18, 0.02), "material": "cloth"},
			{"name": "BootLeft", "shape": "box", "bone": "calf_l",
				"size": Vector3(0.18, 0.32, 0.23), "position": Vector3(-0.13, 0.28, 0.015),
				"material": "cloth"},
			{"name": "BootRight", "shape": "box", "bone": "calf_r",
				"size": Vector3(0.18, 0.32, 0.23), "position": Vector3(0.13, 0.28, 0.015),
				"material": "cloth"},
		],
	},
	"berserker": {
		"signature": "vest_short|pauldron_left_large|pauldron_right_small",
		"pieces": [
			{"name": "LeatherVest", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.47, 0.40, 0.35), "depth": 0.36,
				"position": Vector3(0.0, 1.25, 0.02), "material": "leather"},
			{"name": "PauldronLeftHuge", "shape": "sphere", "bone": "upperarm_l",
				"scale": Vector3(0.36, 0.20, 0.40), "position": Vector3(-0.30, 1.43, 0.0),
				"material": "leather"},
			{"name": "PauldronRightSmall", "shape": "sphere", "bone": "upperarm_r",
				"scale": Vector3(0.22, 0.12, 0.26), "position": Vector3(0.28, 1.43, 0.0),
				"material": "leather"},
		],
	},
	"paladin": {
		"signature": "cuirass_polished_tapered|cape_long_straight",
		"pieces": [
			{"name": "PolishedCuirass", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.52, 0.48, 0.39), "depth": 0.38,
				"position": Vector3(0.0, 1.24, 0.02),
				"material": "polished"},
			{"name": "StraightCape", "shape": "cape", "bone": "spine_03",
				"size": Vector3(0.58, 1.04, 0.48), "depth": 0.06,
				"position": Vector3(0.0, 1.04, -0.18), "material": "light_cloth"},
		],
	},
	"evil_mage": {
		"signature": "hood_high|robe_torso|cape_long_inverted_taper",
		"pieces": [
			{"name": "HighHood", "shape": "hood", "bone": "Head",
				"size": Vector3(0.42, 0.38, 0.38), "position": Vector3(0.0, 1.69, 0.0),
				"material": "dark_cloth"},
			{"name": "DarkRobeTorso", "shape": "tunic", "bone": "spine_02",
				"size": Vector3(0.46, 0.54, 0.35), "depth": 0.36,
				"position": Vector3(0.0, 1.20, 0.02), "material": "dark_cloth"},
			{"name": "InvertedCape", "shape": "cape", "bone": "spine_03",
				"size": Vector3(0.68, 1.05, 0.40), "depth": 0.06,
				"position": Vector3(0.0, 1.04, -0.18), "material": "dark_cloth"},
		],
	},
}

const OUTFIT_MATERIALS := {
	"leather": {"colour": Color("49342a"), "roughness": 0.92, "metallic": 0.0},
	"cloth": {"colour": Color("292c34"), "roughness": 1.0, "metallic": 0.0},
	"light_cloth": {"colour": Color("a79f8c"), "roughness": 0.95, "metallic": 0.0},
	"dark_cloth": {"colour": Color("171820"), "roughness": 1.0, "metallic": 0.0},
	"iron": {"colour": Color("606873"), "roughness": 0.68, "metallic": 0.55},
	"polished": {"colour": Color("aeb5bd"), "roughness": 0.38, "metallic": 0.72},
}

const QUATERNIUS_ANIMATION_PATH := "res://assets/models/animations/quaternius/UAL1_Standard.glb"
const ANIMATION_CATALOGUE_PATH := "res://data/animations.json"
const HEAD_BONES := [&"Head", &"neck_01"]
const HEAD_WEIGHT_THRESHOLD := 0.5
const AGGRESSIVE_LOD_TRIANGLE_THRESHOLD := 6000

# Um unico ShaderMaterial por material-fonte; actor_tint e class_tint sao
# uniforms de instancia. Assim seis cores nao criam seis materiais por actor.
const CHARACTER_SHADER_SOURCE := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 material_albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_albedo_texture = false;
uniform float material_roughness = 1.0;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_roughness_texture = false;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_normal_texture = false;
uniform float normal_scale = 1.0;
uniform float material_metallic = 0.0;
instance uniform vec4 actor_tint : source_color = vec4(1.0);
instance uniform vec4 class_tint : source_color = vec4(1.0);
instance uniform vec4 equipment_tint : source_color = vec4(1.0);
instance uniform float equipment_tint_strength = 0.0;
instance uniform float equipment_material_strength = 0.0;
instance uniform float equipment_roughness = 1.0;
instance uniform float equipment_metallic = 0.0;

void fragment() {
	vec3 base_colour = material_albedo.rgb;
	if (use_albedo_texture) {
		base_colour *= texture(albedo_texture, UV).rgb;
	}
	base_colour *= actor_tint.rgb * mix(vec3(1.0), class_tint.rgb, 0.35);
	// A tinta de equipamento existe para dar COR a geometria gerada sem textura.
	// Aplicada com forca total sobre um modelo que JA TRAZ textura, multiplica
	// escuro por escuro e o boneco fica preto — foi o que o Mateus viu em
	// 02-08 ("o personagem ta preto total"), com o inimigo iluminado ao lado.
	// Onde ha textura, a tinta passa a ser um toque, nao uma segunda camada.
	float equip = equipment_tint_strength * (use_albedo_texture ? 0.22 : 1.0);
	base_colour *= mix(vec3(1.0), equipment_tint.rgb, equip);
	// A luz clara do pack entra no mundo frio e humido por material, nunca por
	// uma segunda textura. Assim a mesma regra cobre modelos e pecas geradas.
	// ⚠️ O escurecimento global tambem se acumulava: sobre textura fica mais
	// leve, senao dessatura duas vezes o que ja vinha dessaturado.
	float luminance = dot(base_colour, vec3(0.2126, 0.7152, 0.0722));
	float dessatura = use_albedo_texture ? 0.18 : 0.32;
	// ⭐ 02-08, medido: T_Ranger_BaseColor tem luminancia media 63/255 e a do
	// Peasant 57 — sao texturas JA escuras de origem. Multiplica-las ainda por
	// um escurecimento global dava o "personagem preto total" que o Mateus viu,
	// com o inimigo iluminado ao lado. Onde ha textura, LEVANTA-SE em vez de se
	// escurecer, e o mundo frio continua a vir do nevoeiro e da gradacao.
	// ⚠️ Sem isto nao ha material nem luz que salve: a cor de partida ja e preta.
	vec3 saida = mix(base_colour, vec3(luminance), dessatura);
	if (use_albedo_texture) {
		saida = pow(saida, vec3(0.62)) * 1.18;
	} else {
		saida *= 0.78;
	}
	ALBEDO = saida;
	ROUGHNESS = mix(material_roughness, equipment_roughness, equipment_material_strength);
	METALLIC = mix(material_metallic, equipment_metallic, equipment_material_strength);
	if (use_roughness_texture) {
		ROUGHNESS *= texture(roughness_texture, UV).r;
	}
	if (use_normal_texture) {
		NORMAL_MAP = texture(normal_texture, UV).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
	// ⭐ 02-08 — LUZ DE RECORTE. O Mateus: "o personagem ta preto total". Nao era
	// so o material: em Brumal a luz vem de cima e de tras, e o jogador fica em
	// contraluz enquanto o inimigo a sua frente apanha a luz toda. Sem isto a
	// silhueta desaparece exactamente quando e mais precisa — a olhar para a
	// frente, que e o que se faz o jogo inteiro.
	// E o que os souls-like fazem: a personagem le-se SEMPRE, mesmo contra a luz.
	// ⚠️ Custa uma multiplicacao por pixel e nada de memoria. Lei 4 intacta.
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.6);
	RIM = 0.55;
	RIM_TINT = 0.35;
	EMISSION = ALBEDO * rim * 0.30;
}
"""

static var _quaternius_library: AnimationLibrary
static var _quaternius_library_configured := false
static var _animation_catalogue: Dictionary = {}
static var _animation_catalogue_loaded := false
static var _shared_shader: Shader
static var _shared_double_sided_shader: Shader
static var _shared_materials: Dictionary = {}
static var _outfit_source_materials: Dictionary = {}
static var _reduced_mesh_cache: Dictionary = {}
static var _head_mesh_cache: Dictionary = {}

var _animation_player: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _body: Node3D
var _skeleton: Skeleton3D
var _generated_attachments: Array[BoneAttachment3D] = []
var _original_body_meshes: Dictionary = {}
var _body_source_path := ""
var _origin_id := ""
var _current_animation := ""
var _current_state_request := ""
var _current_state_speed := 1.0
var _current_tint := Color(-1.0, -1.0, -1.0, -1.0)
var _body_is_head_only := false


func setup(target_height: float, tint := Color.WHITE, casts_shadow := true,
		body_id := "body_male", class_id := "") -> void:
	name = "CharacterVisual"
	# Player ja conhece a origem antes de construir o visual. A procura pelos
	# ascendentes tambem alcanca o rascunho do criador de personagem, sem obrigar
	# os ficheiros que pertencem a outros agentes a mudar de chamada.
	if class_id.is_empty():
		class_id = _parent_class_id()
	_origin_id = class_id
	_body_source_path = body_path_for(body_id)
	var source_height := float(BODY_SOURCE_HEIGHTS.get(body_id, BODY_SOURCE_HEIGHTS["body_male"]))
	var body_scene := load(_body_source_path) as PackedScene
	if body_scene == null:
		push_error("[CharacterVisual] Modelo desconhecido: %s / %s" % [body_id, class_id])
		return
	_body = body_scene.instantiate() as Node3D
	if _body == null:
		push_error("[CharacterVisual] Corpo Quaternius sem raiz Node3D: %s" % _body_source_path)
		return
	_body.name = "Body"
	# O Quaternius chega a olhar para +Z; o combate usa -Z como frente.
	_body.rotation.y = PI
	_body.set_meta("character_body_pack", PLAYER_BODY_PACK)
	_body.set_meta("character_body_source", _body_source_path)
	add_child(_body)
	scale = Vector3.ONE * (target_height / source_height)
	_skeleton = _find_skeleton(_body)
	if _skeleton == null:
		push_error("[CharacterVisual] Corpo Quaternius sem Skeleton3D: %s" % _body_source_path)
		return
	_remember_original_body_meshes()
	_build_animation_player()
	# A biblioteca UAL tem uma pose inicial diferente do rest pose importado.
	# Aplicamo-la antes de calcular encaixes, para a roupa nao ganhar um braco de
	# alavanca invisivel quando a primeira animacao entra.
	var initial_profile := animation_state_profile("player", "idle", "unarmed")
	var initial_clip := String(initial_profile.get("clip", ""))
	if _animation_player != null and _animation_player.has_animation(initial_clip):
		_animation_player.play(initial_clip, 0.0)
		_animation_player.advance(0.0)
		_current_animation = initial_clip
	_build_origin_outfit(class_id)
	var class_tint: Color = CLASS_TINTS.get(class_id, Color.WHITE)
	_collect_meshes(_body, casts_shadow, class_tint)
	set_tint(tint)
	play_state_animation("player", "idle", "unarmed")
	set_meta("character_body_pack", PLAYER_BODY_PACK)
	set_meta("character_body_source", _body_source_path)
	set_meta("origin_id", _origin_id)
	set_meta("silhouette_signature", silhouette_signature_for(_origin_id))


static func body_path_for(body_id: String) -> String:
	return String(BODY_PATHS.get(body_id, BODY_PATHS["body_male"]))


static func body_id_uses_quaternius(body_id: String) -> bool:
	return body_path_for(body_id).begins_with(
		"res://assets/models/characters/quaternius/")


static func silhouette_signature_for(class_id: String) -> String:
	var profile: Dictionary = ORIGIN_OUTFITS.get(class_id, {}) as Dictionary
	return String(profile.get("signature", ""))


static func outfit_contract_errors(origin_ids: Array) -> PackedStringArray:
	## Contrato que o repro-inicio pode chamar sem conhecer a implementacao.
	var errors := PackedStringArray()
	var signatures := {}
	for body_id: String in BODY_PATHS:
		if not body_id_uses_quaternius(body_id):
			errors.append("corpo %s nao usa Quaternius" % body_id)
	for origin_value: Variant in origin_ids:
		var origin := String(origin_value)
		var signature := silhouette_signature_for(origin)
		if signature.is_empty():
			errors.append("origem %s sem silhueta" % origin)
		elif signatures.has(signature):
			errors.append("origens %s e %s repetem silhueta" % [signatures[signature], origin])
		else:
			signatures[signature] = origin
	return errors


func uses_quaternius_body() -> bool:
	return _body != null and String(_body.get_meta(
		"character_body_pack", "")) == PLAYER_BODY_PACK \
		and BODY_PATHS.values().has(_body_source_path)


func get_body_source_path() -> String:
	return _body_source_path


func get_origin_id() -> String:
	return _origin_id


func get_character_body() -> Node3D:
	return _body


func get_equipment_skeleton() -> Skeleton3D:
	return _skeleton


func set_body_replaced_by_outfit(replaced: bool) -> void:
	## O readme Quaternius manda usar so a cabeca com roupa modular. Restaurar e
	## deterministico para o caso de o jogador desequipar tudo no mesmo actor.
	if _body == null or _skeleton == null or _body_is_head_only == replaced:
		return
	for mesh_node: Node in _body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		var original := _original_body_meshes.get(mesh_instance) as Mesh
		if original == null:
			continue
		if not replaced:
			mesh_instance.mesh = original
			continue
		var cache_key := "%s#%s" % [_body_source_path, mesh_instance.name]
		if _is_main_body_mesh(mesh_instance):
			mesh_instance.mesh = _head_only_mesh(original, _skeleton, cache_key)
		else:
			mesh_instance.mesh = _reduced_skinned_mesh(original, _skeleton, cache_key)
	_body_is_head_only = replaced
	set_meta("body_geometry", "head_only" if replaced else "full_body")


func body_is_replaced_by_outfit() -> bool:
	return _body_is_head_only


func reduced_skinned_mesh(source: Mesh, cache_key: String) -> Mesh:
	## Fronteira usada por ArmorVisual para as pecas importadas. Materializa um
	## LOD como malha principal; pecas densas usam o segundo nivel para que botas
	## e mangas nunca custem mais do que o corpo que vieram substituir.
	return _reduced_skinned_mesh(source, _skeleton, cache_key)


func visible_triangle_count() -> int:
	var total := 0
	for mesh_node: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if not mesh_instance.visible or mesh_instance.mesh == null:
			continue
		for surface: int in mesh_instance.mesh.get_surface_count():
			var indices: PackedInt32Array = mesh_instance.mesh.surface_get_arrays(
				surface)[Mesh.ARRAY_INDEX]
			total += indices.size() / 3
	return total


func set_tint(tint: Color) -> void:
	# Uniform de instancia: muda estado/cor sem duplicar nem reescrever materiais.
	if tint.is_equal_approx(_current_tint):
		return
	_current_tint = tint
	for mesh_instance: MeshInstance3D in _meshes:
		mesh_instance.set_instance_shader_parameter("actor_tint", tint)


func _remember_original_body_meshes() -> void:
	_original_body_meshes.clear()
	for mesh_node: Node in _body.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.mesh != null:
			_original_body_meshes[mesh_instance] = mesh_instance.mesh


static func _is_main_body_mesh(mesh_instance: MeshInstance3D) -> bool:
	var lowered := mesh_instance.name.to_lower()
	return "superhero" in lowered or "superhero" in String(
		mesh_instance.mesh.resource_name).to_lower()


static func _head_only_mesh(source: Mesh, skeleton: Skeleton3D,
		cache_key: String) -> Mesh:
	if _head_mesh_cache.has(cache_key):
		return _head_mesh_cache[cache_key] as Mesh
	var head_bone_indices: Array[int] = []
	for bone_name: StringName in HEAD_BONES:
		var bone_index := skeleton.find_bone(bone_name)
		if bone_index >= 0:
			head_bone_indices.append(bone_index)
	if head_bone_indices.is_empty():
		push_warning("[CharacterVisual] corpo sem ossos de cabeca; conserva corpo completo")
		return source
	var cropped := ArrayMesh.new()
	for surface: int in source.get_surface_count():
		var arrays := _portable_surface_arrays(source.surface_get_arrays(surface))
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if vertices.is_empty() or indices.is_empty() or bones.is_empty() or weights.is_empty():
			continue
		var influences := int(bones.size() / vertices.size())
		var head_indices := PackedInt32Array()
		for offset: int in range(0, indices.size(), 3):
			var keep_face := true
			for corner: int in 3:
				var vertex_index := indices[offset + corner]
				var head_weight := 0.0
				for influence: int in influences:
					var influence_offset := vertex_index * influences + influence
					if bones[influence_offset] in head_bone_indices:
						head_weight += weights[influence_offset]
				if head_weight < HEAD_WEIGHT_THRESHOLD:
					keep_face = false
					break
			if keep_face:
				for corner: int in 3:
					head_indices.append(indices[offset + corner])
		if head_indices.is_empty():
			continue
		arrays[Mesh.ARRAY_INDEX] = head_indices
		cropped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		cropped.surface_set_material(cropped.get_surface_count() - 1,
			source.surface_get_material(surface))
	if cropped.get_surface_count() == 0:
		push_warning("[CharacterVisual] recorte de cabeca vazio; conserva corpo completo")
		return source
	var reduced := _reduced_skinned_mesh(cropped, skeleton, "%s#head" % cache_key)
	_head_mesh_cache[cache_key] = reduced
	return reduced


static func _reduced_skinned_mesh(source: Mesh, skeleton: Skeleton3D,
		cache_key: String) -> Mesh:
	if source == null or skeleton == null:
		return source
	if _reduced_mesh_cache.has(cache_key):
		return _reduced_mesh_cache[cache_key] as Mesh
	var importer := ImporterMesh.new()
	for surface: int in source.get_surface_count():
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,
			_portable_surface_arrays(source.surface_get_arrays(surface)), [], {},
			source.surface_get_material(surface), "surface_%d" % surface)
	var bone_transforms: Array[Transform3D] = []
	for bone_index: int in skeleton.get_bone_count():
		bone_transforms.append(skeleton.get_bone_global_rest(bone_index))
	importer.generate_lods(deg_to_rad(60.0), deg_to_rad(25.0), bone_transforms)
	var source_triangle_count := 0
	for surface: int in source.get_surface_count():
		var source_indices: PackedInt32Array = source.surface_get_arrays(
			surface)[Mesh.ARRAY_INDEX]
		source_triangle_count += source_indices.size() / 3
	var preferred_lod := 1 if source_triangle_count > AGGRESSIVE_LOD_TRIANGLE_THRESHOLD else 0
	var reduced := ArrayMesh.new()
	for surface: int in source.get_surface_count():
		var arrays := _portable_surface_arrays(source.surface_get_arrays(surface))
		var lod_count := importer.get_surface_lod_count(surface)
		if lod_count > 0:
			arrays[Mesh.ARRAY_INDEX] = importer.get_surface_lod_indices(
				surface, mini(preferred_lod, lod_count - 1))
		reduced.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		reduced.surface_set_material(surface, source.surface_get_material(surface))
	_reduced_mesh_cache[cache_key] = reduced
	return reduced


static func _portable_surface_arrays(source_arrays: Array) -> Array:
	## Os GLTF do corpo trazem canais custom comprimidos que so o mesh importado
	## original sabe descrever. Nao contêm posicao, UV, normal, tangent, Skin nem
	## material; remove-los permite materializar o LOD sem alterar o aspecto.
	var arrays := source_arrays.duplicate()
	for custom_channel: int in range(Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM3 + 1):
		arrays[custom_channel] = null
	return arrays


func apply_equipment_material(mesh_instance: MeshInstance3D,
		tint: Color, tint_strength: float, roughness: float, metallic: float) -> void:
	## Parametros de instancia: duas armaduras que partilham textura continuam a
	## partilhar o Material, mas leem couro/ferro/pano sem editar o PNG 1024x1024.
	mesh_instance.set_instance_shader_parameter("equipment_tint", tint)
	mesh_instance.set_instance_shader_parameter("equipment_tint_strength", tint_strength)
	mesh_instance.set_instance_shader_parameter("equipment_material_strength", tint_strength)
	mesh_instance.set_instance_shader_parameter("equipment_roughness", roughness)
	mesh_instance.set_instance_shader_parameter("equipment_metallic", metallic)


func play_animation(animation_name: String, speed := 1.0) -> void:
	_current_state_request = ""
	_play_clip(animation_name, speed)


func play_state_animation(actor_kind: String, state_key: String,
		context := "", target_frames := 0) -> String:
	## Fronteira semântica: Player e Enemy dizem o estado e os frames; o nome do
	## clip e a sua duração-fonte pertencem exclusivamente a animations.json.
	var profile := animation_state_profile(actor_kind, state_key, context)
	var animation_name := String(profile.get("clip", ""))
	if animation_name.is_empty():
		return ""
	var speed := animation_playback_speed(profile, target_frames)
	var request := "%s|%s|%s|%d" % [actor_kind, state_key, context, target_frames]
	var looped := bool(profile.get("loop", false))
	if _current_state_request == request and _current_animation == animation_name \
			and _animation_player != null \
			and _animation_player.assigned_animation == animation_name:
		_animation_player.speed_scale = speed
		_current_state_speed = speed
		if _animation_player.is_playing() or not looped:
			return animation_name
	_current_state_request = request
	_play_clip(animation_name, speed)
	return animation_name


func state_animation_frames(actor_kind: String, state_key: String,
		context := "") -> int:
	return int(animation_state_profile(actor_kind, state_key, context).get(
		"phase_frames", 0))


func current_animation_name() -> String:
	if _animation_player == null:
		return ""
	return String(_animation_player.assigned_animation)


func _play_clip(animation_name: String, speed: float) -> void:
	if _animation_player == null:
		return
	if not _animation_player.has_animation(animation_name):
		animation_name = "Idle"
	if _current_animation == animation_name \
			and _animation_player.assigned_animation == animation_name \
			and _animation_player.is_playing():
		animation_name = String(_catalogue().get("fallback_clip", ""))
	if animation_name.is_empty() or not _animation_player.has_animation(animation_name):
		return
	speed = maxf(speed, 0.001)
	if _current_animation == animation_name and _animation_player.is_playing() \
			and _animation_player.assigned_animation == animation_name:
		_animation_player.speed_scale = speed
		_current_state_speed = speed
		return
	_current_animation = animation_name
	_current_state_speed = speed
	_animation_player.speed_scale = speed
	_animation_player.play(animation_name, 0.12)


static func animation_state_profile(actor_kind: String, state_key: String,
		context := "") -> Dictionary:
	var catalogue := _catalogue()
	var actor: Dictionary = catalogue.get(actor_kind, {}) as Dictionary
	var states: Dictionary = actor.get("states", {}) as Dictionary
	var state_value: Variant = states.get(state_key, {})
	if not state_value is Dictionary:
		return _profile_for_clip(String(state_value))
	var state_profile := state_value as Dictionary
	var selected: Variant = state_profile
	var contexts: Dictionary = state_profile.get("contexts", {}) as Dictionary
	if not contexts.is_empty():
		selected = contexts.get(context)
		if selected == null and context.begins_with("unarmed"):
			selected = contexts.get("unarmed")
		if selected == null and not context.begins_with("unarmed"):
			selected = contexts.get("armed")
		if selected == null:
			selected = contexts.get("default")
	var profile := _normalise_profile(selected)
	for inherited_key: String in ["phase_frames", "loop", "source_frames"]:
		if state_profile.has(inherited_key) and not profile.has(inherited_key):
			profile[inherited_key] = state_profile[inherited_key]
	return _complete_profile(profile)


static func animation_playback_speed(profile: Dictionary, target_frames: int) -> float:
	if target_frames <= 0:
		return float(profile.get("speed", 1.0))
	var source_frames := float(profile.get("source_frames", 0.0))
	if source_frames <= 0.0:
		return 1.0
	return source_frames / float(target_frames)


static func animation_catalogue_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var catalogue := _catalogue()
	var clips: Dictionary = catalogue.get("clips", {}) as Dictionary
	if clips.size() != 43:
		errors.append("o catálogo UAL declara %d clips, esperados 43" % clips.size())
	for actor_kind: String in ["player", "enemy"]:
		var states: Dictionary = (catalogue.get(actor_kind, {}) as Dictionary).get(
			"states", {}) as Dictionary
		if states.is_empty():
			errors.append("%s não declara estados" % actor_kind)
		for state_key: String in states:
			_collect_profile_errors(actor_kind, state_key, states[state_key], clips, errors)
	return errors


static func _collect_profile_errors(actor_kind: String, state_key: String,
		value: Variant, clips: Dictionary, errors: PackedStringArray) -> void:
	if value is String:
		if not clips.has(String(value)):
			errors.append("%s/%s aponta clip ausente %s" % [actor_kind, state_key, value])
		return
	if not value is Dictionary:
		errors.append("%s/%s não é um perfil" % [actor_kind, state_key])
		return
	var profile := value as Dictionary
	if profile.has("clip") and not clips.has(String(profile.get("clip", ""))):
		errors.append("%s/%s aponta clip ausente %s" % [
			actor_kind, state_key, profile.get("clip", "")])
	for context: String in (profile.get("contexts", {}) as Dictionary):
		_collect_profile_errors(actor_kind, "%s[%s]" % [state_key, context],
			(profile.get("contexts", {}) as Dictionary)[context], clips, errors)


static func _normalise_profile(value: Variant) -> Dictionary:
	if value is String:
		return {"clip": String(value)}
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _profile_for_clip(animation_name: String) -> Dictionary:
	return _complete_profile({"clip": animation_name})


static func _complete_profile(profile: Dictionary) -> Dictionary:
	var animation_name := String(profile.get("clip", ""))
	var clip_profile: Dictionary = (_catalogue().get("clips", {}) as Dictionary).get(
		animation_name, {}) as Dictionary
	for key: String in clip_profile:
		if not profile.has(key):
			profile[key] = clip_profile[key]
	return profile


static func _catalogue() -> Dictionary:
	if _animation_catalogue_loaded:
		return _animation_catalogue
	_animation_catalogue_loaded = true
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(ANIMATION_CATALOGUE_PATH))
	if parsed is Dictionary:
		_animation_catalogue = parsed as Dictionary
		for error: String in animation_catalogue_errors():
			push_error("[CharacterVisual] %s" % error)
	else:
		push_error("[CharacterVisual] catálogo inválido: %s" % ANIMATION_CATALOGUE_PATH)
	return _animation_catalogue


func _parent_class_id() -> String:
	var ancestor := get_parent()
	while ancestor != null:
		for property: Dictionary in ancestor.get_property_list():
			var property_name := String(property.get("name", ""))
			if property_name == "class_id":
				return String(ancestor.get("class_id"))
			if property_name == "_draft":
				var draft: Dictionary = ancestor.get("_draft") as Dictionary
				if draft.has("class_id"):
					return String(draft["class_id"])
		ancestor = ancestor.get_parent()
	return ""


func _collect_meshes(node: Node, casts_shadow: bool, class_tint: Color) -> void:
	if node is MeshInstance3D:
		_register_mesh(node as MeshInstance3D, casts_shadow, class_tint)
	for descendant: Node in node.find_children("*", "MeshInstance3D", true, false):
		_register_mesh(descendant as MeshInstance3D, casts_shadow, class_tint)


func _register_mesh(mesh_instance: MeshInstance3D, casts_shadow: bool,
		class_tint: Color) -> void:
	if mesh_instance == null or mesh_instance.mesh == null or mesh_instance in _meshes:
		return
	_meshes.append(mesh_instance)
	mesh_instance.set_instance_shader_parameter("class_tint", class_tint)
	if _current_tint.a >= 0.0:
		mesh_instance.set_instance_shader_parameter("actor_tint", _current_tint)
	if not casts_shadow:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for surface: int in mesh_instance.mesh.get_surface_count():
		var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
		if source != null:
			mesh_instance.set_surface_override_material(surface, _shared_material_for(source))


func _build_origin_outfit(class_id: String) -> void:
	var profile: Dictionary = ORIGIN_OUTFITS.get(class_id, {}) as Dictionary
	for raw_piece: Variant in profile.get("pieces", []):
		var config := raw_piece as Dictionary
		var piece := _create_outfit_piece(config)
		if piece == null:
			continue
		var model_transform := _piece_model_transform(config)
		var attachment := attach_equipment_to_bone(
			piece, StringName(config.get("bone", "")), model_transform, true)
		if attachment == null:
			piece.free()
			push_warning("[CharacterVisual] Peca %s da origem %s sem osso %s" % [
				config.get("name", "?"), class_id, config.get("bone", "?")])


func attach_equipment_to_bone(piece: Node3D, bone_name: StringName,
		model_space_transform: Transform3D, generated := false,
		casts_shadow := true) -> BoneAttachment3D:
	## Fronteira para o agente de armaduras: uma peca externa conserva o corpo,
	## o rig e a animacao e declara apenas osso + transform no espaco do modelo.
	if piece == null or _body == null or _skeleton == null:
		return null
	var bone_index := _skeleton.find_bone(bone_name)
	if bone_index < 0:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = "%sAttachment" % piece.name
	attachment.bone_name = bone_name
	attachment.set_meta("character_equipment_attachment", true)
	attachment.set_meta("generated_origin_outfit", generated)
	_skeleton.add_child(attachment)
	attachment.add_child(piece)

	# Converte uma pose facil de rever (coordenadas do modelo em repouso) para a
	# pose local do osso. A peca passa depois a seguir esse osso em cada clip UAL.
	var skeleton_to_body := _transform_from_ancestor(_body, _skeleton)
	var desired_skeleton_space := skeleton_to_body.affine_inverse() * model_space_transform
	var bone_pose := _skeleton.get_bone_global_pose(bone_index)
	piece.transform = bone_pose.affine_inverse() * desired_skeleton_space
	if generated:
		_generated_attachments.append(attachment)
	# Durante setup() a recolha conjunta acontece depois. Pecas equipadas mais
	# tarde entram aqui sem obrigar o consumidor a conhecer o shader interno.
	if not _meshes.is_empty():
		_collect_meshes(piece, casts_shadow, CLASS_TINTS.get(_origin_id, Color.WHITE))
	return attachment


static func _transform_from_ancestor(ancestor: Node3D, descendant: Node3D) -> Transform3D:
	## Equivalente local de global_transform, tambem funciona nos testes que
	## constroem um Player fora da SceneTree.
	var result := Transform3D.IDENTITY
	var cursor := descendant
	while cursor != ancestor:
		result = cursor.transform * result
		cursor = cursor.get_parent() as Node3D
		if cursor == null:
			return Transform3D.IDENTITY
	return result


func clear_generated_origin_outfit() -> void:
	## Permite ao sistema de armaduras substituir o placeholder por uma peca
	## real sem remover nem reinstanciar o corpo Quaternius.
	for attachment: BoneAttachment3D in _generated_attachments:
		if is_instance_valid(attachment):
			for descendant: Node in attachment.find_children(
					"*", "MeshInstance3D", true, false):
				_meshes.erase(descendant as MeshInstance3D)
			attachment.queue_free()
	_generated_attachments.clear()


func _create_outfit_piece(config: Dictionary) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = String(config.get("name", "OutfitPiece"))
	piece.add_to_group("character_origin_outfit")
	var shape := String(config.get("shape", "box"))
	match shape:
		"box":
			var box := BoxMesh.new()
			box.size = config.get("size", Vector3(0.2, 0.2, 0.2)) as Vector3
			box.material = _outfit_source_material(String(config.get("material", "cloth")))
			piece.mesh = box
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 12
			sphere.rings = 6
			sphere.material = _outfit_source_material(String(config.get("material", "cloth")))
			piece.mesh = sphere
		"frustum":
			var dimensions: Vector3 = config.get("size", Vector3(0.2, 0.3, 0.3)) as Vector3
			var frustum := CylinderMesh.new()
			frustum.top_radius = dimensions.x
			frustum.height = dimensions.y
			frustum.bottom_radius = dimensions.z
			frustum.radial_segments = 10
			frustum.rings = 1
			frustum.material = _outfit_source_material(String(config.get("material", "cloth")))
			piece.mesh = frustum
		"hood":
			piece.mesh = _hood_mesh(
				config.get("size", Vector3(0.4, 0.3, 0.35)) as Vector3,
				_outfit_source_material(String(config.get("material", "cloth"))))
		"cape":
			var cape_size: Vector3 = config.get("size", Vector3(0.4, 0.8, 0.6)) as Vector3
			piece.mesh = _cape_mesh(cape_size.x, cape_size.z, cape_size.y,
				float(config.get("depth", 0.05)),
				_outfit_source_material(String(config.get("material", "cloth"))))
		"tunic":
			var tunic_size: Vector3 = config.get("size", Vector3(0.45, 0.45, 0.35)) as Vector3
			piece.mesh = _torso_mesh(tunic_size.x, tunic_size.z, tunic_size.y,
				float(config.get("depth", 0.32)),
				_outfit_source_material(String(config.get("material", "cloth"))))
		_:
			push_warning("[CharacterVisual] Forma de roupa desconhecida: %s" % shape)
			piece.free()
			return null
	return piece


func _piece_model_transform(config: Dictionary) -> Transform3D:
	var rotation_degrees: Vector3 = config.get("rotation_degrees", Vector3.ZERO) as Vector3
	var rotation_radians := Vector3(
		deg_to_rad(rotation_degrees.x), deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z))
	var basis := Basis.from_euler(rotation_radians)
	if config.has("scale"):
		basis = basis.scaled(config["scale"] as Vector3)
	return Transform3D(basis, config.get("position", Vector3.ZERO) as Vector3)


static func _cape_mesh(top_width: float, bottom_width: float, height: float,
		depth: float, material: Material) -> ArrayMesh:
	var half_top := top_width * 0.5
	var half_bottom := bottom_width * 0.5
	var half_height := height * 0.5
	var half_depth := depth * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_top, half_height, half_depth),
		Vector3(half_top, half_height, half_depth),
		Vector3(-half_bottom, -half_height, half_depth),
		Vector3(half_bottom, -half_height, half_depth),
		Vector3(-half_top, half_height, -half_depth),
		Vector3(half_top, half_height, -half_depth),
		Vector3(-half_bottom, -half_height, -half_depth),
		Vector3(half_bottom, -half_height, -half_depth),
	])
	var triangles := PackedInt32Array([
		0, 2, 1, 1, 2, 3,
		5, 7, 4, 4, 7, 6,
		4, 6, 0, 0, 6, 2,
		1, 3, 5, 5, 3, 7,
		4, 0, 5, 5, 0, 1,
		2, 6, 3, 3, 6, 7,
	])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0, triangles.size(), 3):
		var a := vertices[triangles[index]]
		var b := vertices[triangles[index + 1]]
		var c := vertices[triangles[index + 2]]
		_add_triangle(surface, a, b, c)
	return _finish_smooth_surface(surface, material)


static func _torso_mesh(top_width: float, bottom_width: float, height: float,
		depth: float, material: Material) -> ArrayMesh:
	# Peitoral/tunica de dez vertices: afunila na cintura e ganha uma nervura
	# central. Continua barato, mas deixa de parecer uma caixa pousada no corpo.
	var half_top := top_width * 0.5
	var half_bottom := bottom_width * 0.5
	var half_height := height * 0.5
	var front := depth * 0.5
	var back := -depth * 0.5
	var ridge := depth * 0.11
	var v := PackedVector3Array([
		Vector3(-half_top, half_height, front),
		Vector3(0.0, half_height, front + ridge),
		Vector3(half_top, half_height, front),
		Vector3(-half_bottom, -half_height, front * 0.82),
		Vector3(0.0, -half_height, front * 0.82 + ridge * 0.45),
		Vector3(half_bottom, -half_height, front * 0.82),
		Vector3(-half_top, half_height, back),
		Vector3(half_top, half_height, back),
		Vector3(-half_bottom, -half_height, back * 0.82),
		Vector3(half_bottom, -half_height, back * 0.82),
	])
	var triangles := PackedInt32Array([
		0, 3, 1, 1, 3, 4, 1, 4, 2, 2, 4, 5,
		7, 9, 6, 6, 9, 8,
		6, 8, 0, 0, 8, 3,
		2, 5, 7, 7, 5, 9,
		6, 0, 1, 6, 1, 7, 7, 1, 2,
		3, 8, 4, 4, 8, 9, 4, 9, 5,
	])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0, triangles.size(), 3):
		_add_triangle(surface, v[triangles[index]], v[triangles[index + 1]],
			v[triangles[index + 2]])
	return _finish_smooth_surface(surface, material)


static func _hood_mesh(size: Vector3, material: Material) -> ArrayMesh:
	# Casca angular aberta a frente: le-se como capuz sem tapar a cara com uma
	# esfera nem repetir o chapeu de bruxa do KayKit.
	var rings := [
		{"y": -size.y * 0.50, "x": size.x * 0.48, "z": size.z * 0.46},
		{"y": size.y * 0.05, "x": size.x * 0.52, "z": size.z * 0.52},
		{"y": size.y * 0.50, "x": size.x * 0.30, "z": size.z * 0.34},
	]
	var arc_steps := 8
	var start_angle := deg_to_rad(48.0)
	var end_angle := deg_to_rad(312.0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in rings.size() - 1:
		var lower: Dictionary = rings[ring_index]
		var upper: Dictionary = rings[ring_index + 1]
		for step in arc_steps:
			var t0 := float(step) / float(arc_steps)
			var t1 := float(step + 1) / float(arc_steps)
			var angle0 := lerpf(start_angle, end_angle, t0)
			var angle1 := lerpf(start_angle, end_angle, t1)
			var a := Vector3(sin(angle0) * float(lower["x"]), float(lower["y"]),
				cos(angle0) * float(lower["z"]))
			var b := Vector3(sin(angle1) * float(lower["x"]), float(lower["y"]),
				cos(angle1) * float(lower["z"]))
			var c := Vector3(sin(angle0) * float(upper["x"]), float(upper["y"]),
				cos(angle0) * float(upper["z"]))
			var d := Vector3(sin(angle1) * float(upper["x"]), float(upper["y"]),
				cos(angle1) * float(upper["z"]))
			_add_triangle(surface, a, b, c)
			_add_triangle(surface, c, b, d)
	return _finish_smooth_surface(surface, material)


static func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for vertex: Vector3 in [a, b, c]:
		surface.add_vertex(vertex)


static func _finish_smooth_surface(surface: SurfaceTool, material: Material) -> ArrayMesh:
	## Nunca regressar a uma normal por triangulo: foi essa luz facetada que fazia
	## as pecas geradas lerem-se como caixas, mesmo quando a silhueta era curva.
	surface.index()
	surface.generate_normals()
	surface.set_material(material)
	return surface.commit()


static func _outfit_source_material(material_id: String) -> StandardMaterial3D:
	if _outfit_source_materials.has(material_id):
		return _outfit_source_materials[material_id] as StandardMaterial3D
	var config: Dictionary = OUTFIT_MATERIALS.get(
		material_id, OUTFIT_MATERIALS["cloth"]) as Dictionary
	var material := StandardMaterial3D.new()
	material.albedo_color = config.get("colour", Color.WHITE) as Color
	material.roughness = float(config.get("roughness", 1.0))
	material.metallic = float(config.get("metallic", 0.0))
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_outfit_source_materials[material_id] = material
	return material


static func _shared_material_for(source: StandardMaterial3D) -> ShaderMaterial:
	var key := source.get_instance_id()
	if _shared_materials.has(key):
		return _shared_materials[key] as ShaderMaterial
	if _shared_shader == null:
		_shared_shader = Shader.new()
		_shared_shader.code = CHARACTER_SHADER_SOURCE
	var material := ShaderMaterial.new()
	if source.cull_mode == BaseMaterial3D.CULL_DISABLED:
		if _shared_double_sided_shader == null:
			_shared_double_sided_shader = Shader.new()
			_shared_double_sided_shader.code = CHARACTER_SHADER_SOURCE.replace(
				"render_mode diffuse_burley, specular_schlick_ggx;",
				"render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;")
		material.shader = _shared_double_sided_shader
	else:
		material.shader = _shared_shader
	material.set_shader_parameter("material_albedo", source.albedo_color)
	material.set_shader_parameter("material_roughness", source.roughness)
	material.set_shader_parameter("material_metallic", source.metallic)
	if source.albedo_texture != null:
		material.set_shader_parameter("albedo_texture", source.albedo_texture)
		material.set_shader_parameter("use_albedo_texture", true)
	if source.roughness_texture != null:
		material.set_shader_parameter("roughness_texture", source.roughness_texture)
		material.set_shader_parameter("use_roughness_texture", true)
	if source.normal_enabled and source.normal_texture != null:
		material.set_shader_parameter("normal_texture", source.normal_texture)
		material.set_shader_parameter("use_normal_texture", true)
		material.set_shader_parameter("normal_scale", source.normal_scale)
	_shared_materials[key] = material
	return material


func _build_animation_player() -> void:
	var library := _quaternius_animation_library()
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	_animation_player.root_node = NodePath("../Body")
	add_child(_animation_player)
	if library != null:
		_animation_player.add_animation_library("", library)


static func _quaternius_animation_library() -> AnimationLibrary:
	if _quaternius_library != null:
		return _quaternius_library
	var source_scene := load(QUATERNIUS_ANIMATION_PATH) as PackedScene
	if source_scene == null:
		return null
	var source_root := source_scene.instantiate()
	var source_player := _find_animation_player(source_root)
	if source_player != null and source_player.has_animation_library(""):
		_quaternius_library = source_player.get_animation_library("")
	source_root.free()
	if _quaternius_library == null or _quaternius_library_configured:
		return _quaternius_library
	var clips: Dictionary = (_catalogue().get("clips", {}) as Dictionary)
	for animation_name: String in clips:
		var clip_profile: Dictionary = clips.get(animation_name, {}) as Dictionary
		if not _quaternius_library.has_animation(animation_name):
			push_error("[CharacterVisual] clip catalogado ausente na UAL: %s" \
				% animation_name)
			continue
		if bool(clip_profile.get("loop", false)) \
				and _quaternius_library.has_animation(animation_name):
			_quaternius_library.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_quaternius_library_configured = true
	return _quaternius_library

static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


static func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child: Node in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
