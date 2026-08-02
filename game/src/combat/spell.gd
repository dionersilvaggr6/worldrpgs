class_name Spell
extends RefCounted
## Fronteira de dano da magia. Movimento, tempo, hitbox e desenho pertencem a
## SpellDelivery; este ficheiro apenas traduz um contacto confirmado em dano.


static func _damage_for(data: Dictionary, attrs: Dictionary,
		target_defense: float) -> float:
	var attr := GameData.casting_attribute_for(
		String(data.get("school", "feiticaria")), attrs)
	var scale := GameData.attribute_scale(
		attr, String(data.get("scale_weight", "forte")))
	var raw := float(data.get("mv", 0.0)) \
		* float(data.get("base_damage", 0.0)) * scale
	return GameData.apply_defense(raw, target_defense)


## A entrega decide QUANDO e ONDE houve contacto; este facade conserva a
## formula de dano usada no jogo e nao conhece listas de feiticos.
static func apply_contact(data: Dictionary, caster: Node3D, attrs: Dictionary,
		target: Node3D) -> float:
	if target == null or not is_instance_valid(target) \
			or not target.has_method("take_damage"):
		return 0.0
	var target_def: float = target.get("defense") \
		if target.get("defense") != null else 0.0
	var amount := _damage_for(data, attrs, target_def)
	if amount <= 0.0:
		return 0.0
	var info := DamageInfo.make(amount, caster,
		String(data.get("weight", "light")))
	info.is_magic = true
	info.is_aoe = String(data.get("type", "")) == "aoe"
	info.posture_damage = GameData.posture_damage_from_mv(
		float(data.get("mv", 0.0)))
	target.call("take_damage", info)
	return amount
