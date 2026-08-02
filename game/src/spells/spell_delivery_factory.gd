class_name SpellDeliveryFactory
extends RefCounted
## Fronteira pequena: catálogo + contexto entram; uma entrega executável sai.

const DeliveryScript = preload("res://src/spells/spell_delivery.gd")


static func create(spell_id: String, catalog: Dictionary,
		context: Dictionary) -> SpellDelivery:
	var spell: Dictionary = catalog.get(spell_id, {}) as Dictionary
	if spell.is_empty():
		return null
	var form := String(spell.get("delivery_form", ""))
	if not (catalog.get("_delivery_forms", []) as Array).has(form):
		return null
	var contracts: Dictionary = catalog.get("_delivery_contracts", {}) as Dictionary
	var contract: Dictionary = (contracts.get(form, {}) as Dictionary).duplicate(true)
	if contract.is_empty():
		return null
	var contact_type := String(spell.get("contact_type", ""))
	var contact_contracts: Dictionary = catalog.get("_contact_contracts", {}) as Dictionary
	contract.merge((contact_contracts.get(contact_type, {}) as Dictionary), false)
	_apply_spell_overrides(contract, spell)
	contract["delivery_form"] = form
	contract["contact_type"] = contact_type
	var delivery := DeliveryScript.new()
	delivery.configure(spell_id, spell, contract, context)
	return delivery


static func contract_for(spell_id: String, catalog: Dictionary) -> Dictionary:
	var delivery := create(spell_id, catalog, {"manual": true})
	if delivery == null:
		return {}
	var contract: Dictionary = delivery.delivery_contract()
	delivery.free()
	return contract


static func _apply_spell_overrides(contract: Dictionary, spell: Dictionary) -> void:
	# Formas estacionárias conservam o zero canónico da forma; o campo legado
	# speed_mps de algumas fichas descrevia alcance/entrega antes do contrato 74.
	if spell.has("speed_mps") and float(contract.get("speed_m_s", 0.0)) > 0.0:
		contract["speed_m_s"] = float(spell.get("speed_mps"))
	if spell.has("range_m"):
		contract["max_range_m"] = float(spell.get("range_m"))
	if spell.has("max_range"):
		contract["max_range_m"] = float(spell.get("max_range"))
	if spell.has("radius"):
		contract["area_radius_m"] = float(spell.get("radius"))
	if spell.has("duration"):
		contract["lifetime_s"] = float(spell.get("duration"))
	var effect: Dictionary = spell.get("effect", {}) as Dictionary
	if effect.has("duration_s"):
		contract["effect_duration_s"] = float(effect.get("duration_s"))
