#!/usr/bin/env node
/**
 * Verifica as referências entre os 17 catálogos de game/data.
 *
 * Não há allowlist de dívida: qualquer prefixo ou slot novo tem de resolver
 * num catálogo real antes de entrar em main.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dataDir = path.join(root, "game", "data");
const files = fs.readdirSync(dataDir).filter((name) => name.endsWith(".json")).sort();
const data = Object.fromEntries(files.map((name) => [
  name.replace(/\.json$/, ""),
  JSON.parse(fs.readFileSync(path.join(dataDir, name), "utf8")),
]));

const errors = [];
let checked = 0;
const fail = (message) => errors.push(message);
const check = (condition, message) => {
  checked += 1;
  if (!condition) fail(message);
};
const publicEntries = (object) => Object.entries(object ?? {}).filter(([id]) => !id.startsWith("_"));
const sameSet = (actual, expected) => actual.size === expected.size
  && [...actual].every((value) => expected.has(value));
const ref = (collection, id, label) => check(
  typeof id === "string" && Object.hasOwn(collection ?? {}, id),
  `${label}: referência inexistente '${id}'`,
);
const slug = (value) => value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
  .replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");

// 01-08: 17 -> 18 (settings.json) -> 19 (status_effects.json) -> 20
// (audio_catalog.json) -> 21 (animations.json, do mapa estado->animacao).
// Este numero e proposital: obriga a que um JSON novo em game/data seja um acto
// deliberado, nao um ficheiro que alguem largou la sem ninguem reparar.
check(files.length === 21, `game/data devia conter 21 JSON; contém ${files.length}`);

const abilities = data.abilities;
const attributes = data.attributes;
const armor = data.armor;
const biomes = data.biomes;
const controls = data.controls;
const economy = data.economy;
const enemies = data.enemies;
const equipment = data.equipment;
const graphics = data.graphics;
const named = data.named_encounters.encounters;
const races = data.races;
const spells = data.spells;
const weapons = data.weapons;
const world = data.world;

const classIds = publicEntries(attributes.classes).map(([id]) => id);
const biomeIds = publicEntries(biomes).map(([id]) => id);
const raceIds = publicEntries(races).map(([id]) => id);
const enemyIds = publicEntries(enemies).map(([id]) => id);
const spellIds = publicEntries(spells).filter(([id, value]) => value && value.display_name).map(([id]) => id);

for (const classId of classIds) {
  ref(abilities, classId, `attributes.classes.${classId} -> abilities`);
  ref(weapons.loadouts, classId, `attributes.classes.${classId} -> weapons.loadouts`);
  ref(economy.class_bias.profiles, classId, `attributes.classes.${classId} -> economy.class_bias.profiles`);
  for (const attributeId of attributes.attribute_ids) {
    check(Object.hasOwn(attributes.classes[classId], attributeId),
      `attributes.classes.${classId}: falta atributo '${attributeId}'`);
  }
}
for (const [classId, ability] of publicEntries(abilities)) {
  check(classIds.includes(classId), `abilities.${classId}: classe inexistente`);
  check(typeof ability.id === "string" && ability.id.length > 0, `abilities.${classId}: id vazio`);
}
for (const actionId of controls.gamepad_required) {
  ref(controls.actions, actionId, "controls.gamepad_required");
}

for (const [biomeId, biome] of publicEntries(biomes)) {
  check(world.zones[biomeId]?.biome_id === biomeId, `biomes.${biomeId} -> world.zones`);
  const residents = [biome.racas?.dominante, ...(biome.racas?.secundarias ?? [])];
  for (const raceId of residents) ref(races, raceId, `biomes.${biomeId}.racas`);
}
for (const [raceId, race] of publicEntries(races)) {
  for (const biomeId of Object.keys(race.biomas ?? {})) ref(biomes, biomeId, `races.${raceId}.biomas`);
}

const resolveCard = (card, label) => {
  check(typeof card === "string" && card.includes(":"), `${label}: payload inválido '${card}'`);
  if (typeof card !== "string" || !card.includes(":")) return;
  const [kind, rawId] = card.split(":", 2);
  const id = kind === "consumivel" ? (economy.aliases[rawId] ?? rawId) : rawId;
  const catalogues = {
    arma: equipment.weapons,
    armadura: equipment.armor,
    anel: equipment.rings,
    material: economy.materials,
    consumivel: economy.consumables,
  };
  if (kind === "almas_bonus") {
    check(Number.isInteger(Number(id)) && Number(id) > 0, `${label}: almas_bonus inválido '${id}'`);
  } else if (kind === "bias") {
    check(id === "classe", `${label}: bias desconhecido '${id}'`);
  } else if (catalogues[kind]) {
    ref(catalogues[kind], id, label);
  } else {
    fail(`${label}: prefixo desconhecido '${kind}'`);
  }
};

for (const [enemyId, enemy] of publicEntries(enemies)) {
  ref(races, enemy.race_id, `enemies.${enemyId}.race_id`);
  for (const biomeId of enemy.biome_ids ?? []) ref(biomes, biomeId, `enemies.${enemyId}.biome_ids`);
  const attackIds = new Set((enemy.attacks ?? []).map((attack) => attack.id));
  for (const attack of enemy.attacks ?? []) {
    ref(enemies._attack_templates, attack.template, `enemies.${enemyId}.${attack.id}.template`);
    const followup = attack.false_recovery?.optional_followup;
    if (followup) check(attackIds.has(followup), `enemies.${enemyId}.${attack.id}: follow-up '${followup}' inexistente`);
  }
  for (const pattern of enemy.patterns ?? []) {
    for (const attackId of pattern) check(attackIds.has(attackId),
      `enemies.${enemyId}.patterns: ataque '${attackId}' inexistente`);
  }
  for (const card of enemy.loot_cards ?? []) resolveCard(card, `enemies.${enemyId}.loot_cards`);
}
for (const [biomeId, budget] of Object.entries(enemies._zone_budgets)) {
  ref(biomes, biomeId, "enemies._zone_budgets");
  for (const enemyId of Object.keys(budget.population)) ref(enemies, enemyId, `zone budget ${biomeId}`);
}

for (const [encounterId, encounter] of Object.entries(named)) {
  ref(enemies, encounter.base_enemy_id, `named_encounters.${encounterId}.base_enemy_id`);
  ref(biomes, encounter.zone_id, `named_encounters.${encounterId}.zone_id`);
  check(enemies[encounter.base_enemy_id]?.biome_ids?.includes(encounter.zone_id),
    `named_encounters.${encounterId}: base não pertence à zona '${encounter.zone_id}'`);
  resolveCard(encounter.guaranteed_loot, `named_encounters.${encounterId}.guaranteed_loot`);
}

for (const [materialId, material] of Object.entries(economy.materials)) {
  ref(biomes, material.zone_id, `economy.materials.${materialId}.zone_id`);
}
for (const [alias, target] of Object.entries(economy.aliases)) {
  ref(economy.consumables, target, `economy.aliases.${alias}`);
}
for (const [biomeId, profiles] of Object.entries(economy.class_bias.by_zone)) {
  ref(biomes, biomeId, "economy.class_bias.by_zone");
  for (const [profile, card] of Object.entries(profiles)) resolveCard(card, `economy.class_bias.${biomeId}.${profile}`);
}

for (const [classId, loadout] of publicEntries(weapons.loadouts)) {
  check(classIds.includes(classId), `weapons.loadouts.${classId}: classe inexistente`);
  ref(weapons, loadout.main, `weapons.loadouts.${classId}.main`);
  // 02-08: a mão secundária deixou de ser só arma ou escudo. [DECIDIDO] (Mateus,
  // 01-08) o instrumento mágico vive lá — "o cajado numa e o talismã na outra".
  // Continua a ter de existir num catálogo real; só passou a haver dois.
  if (loadout.offhand !== null) {
    const naArma = Object.hasOwn(weapons, loadout.offhand);
    const noInstrumento = Object.hasOwn(equipment.magic_instruments ?? {}, loadout.offhand);
    check(naArma || noInstrumento,
      `weapons.loadouts.${classId}.offhand: '${loadout.offhand}' não existe nem em weapons nem em equipment.magic_instruments`);
  }
  for (const pieceId of loadout.pecas ?? []) ref(armor.pieces, pieceId, `weapons.loadouts.${classId}.pecas`);
}
for (const loadout of weapons.test_loadouts.order ?? []) {
  ref(weapons, loadout.main, "weapons.test_loadouts.main");
  if (loadout.offhand !== null) ref(weapons, loadout.offhand, "weapons.test_loadouts.offhand");
}
for (const [weaponId, weapon] of Object.entries(equipment.weapons)) {
  if (weapon.familia) {
    ref(equipment.family_movesets, weapon.familia, `equipment.weapons.${weaponId}.familia`);
    ref(weapons.familias, weapon.familia, `equipment.weapons.${weaponId}.familia -> weapons`);
  } else {
    ref(weapons.familias_escudo, weapon.familia_escudo, `equipment.weapons.${weaponId}.familia_escudo`);
  }
  ref(biomes, weapon.origem, `equipment.weapons.${weaponId}.origem`);
  const generatedFamily = Object.keys(equipment.family_movesets).find((family) => weaponId.startsWith(`${family}_`));
  const embeddedBiome = generatedFamily && biomeIds.find((biomeId) => weaponId.startsWith(`${generatedFamily}_${biomeId}_`));
  if (embeddedBiome) {
    check(weapon.origem === embeddedBiome, `equipment.weapons.${weaponId}: ID diz '${embeddedBiome}', ficha diz '${weapon.origem}'`);
    const suffix = weaponId.slice(`${generatedFamily}_${embeddedBiome}_`.length);
    check(slug(weapon.nome) === suffix, `equipment.weapons.${weaponId}: nome '${weapon.nome}' não corresponde ao ID`);
  }
}
for (const [armorId, piece] of Object.entries(equipment.armor)) {
  check(armor.slots.includes(piece.slot), `equipment.armor.${armorId}: slot '${piece.slot}' inexistente`);
  check(piece.effect_type === "none", `equipment.armor.${armorId}: efeito sem cliente`);
}
for (const [instrumentId, instrument] of Object.entries(equipment.magic_instruments ?? {})) {
  ref(equipment.weapons, instrument.weapon_id, `equipment.magic_instruments.${instrumentId}.weapon_id`);
  for (const schoolId of instrument.school_tags ?? []) {
    ref(spells._schools, schoolId, `equipment.magic_instruments.${instrumentId}.school_tags`);
  }
  check(Object.keys(instrument.cast_speed_multiplier_by_form ?? {}).length === spells._delivery_forms.length,
    `equipment.magic_instruments.${instrumentId}: multiplicadores não cobrem as formas`);
}
for (const [ringId, ring] of Object.entries(equipment.rings)) {
  ref(equipment._ring_effect_clients, ring.effect_type, `equipment.rings.${ringId}.effect_type`);
  check(equipment._ring_effect_clients[ring.effect_type]?.client_id === ring.client_id,
    `equipment.rings.${ringId}: cliente não coincide com effect_type`);
  ref(equipment._ring_affinity_tags, ring.afinidade, `equipment.rings.${ringId}.afinidade`);
}

const deliveryForms = new Set(spells._delivery_forms);
const escapeVectors = new Set(spells._escape_vectors);
check(sameSet(new Set(spells.order), new Set(spellIds)), "spells.order não coincide com as 53 fichas");
for (const spellId of spells.order) {
  const spell = spells[spellId];
  ref(spells._schools, spell.school, `spells.${spellId}.school`);
  check(deliveryForms.has(spell.delivery_form), `spells.${spellId}: forma '${spell.delivery_form}' inexistente`);
  check(escapeVectors.has(spell.escape_vector) || spell.escape_vector === "nao_aplicavel",
    `spells.${spellId}: vector '${spell.escape_vector}' inexistente`);
}
for (const [schoolId, school] of Object.entries(spells._schools)) {
  for (const instrumentId of school.instrumentos ?? []) {
    ref(equipment.magic_instruments, instrumentId, `spells._schools.${schoolId}.instrumentos`);
  }
}
for (const spellId of spells._rules.default_favorites) ref(spells, spellId, "spells.default_favorites");

const connectionIds = new Set();
const edgeKeys = new Set();
for (const connection of world.connections) {
  check(!connectionIds.has(connection.id), `world.connections: ID repetido '${connection.id}'`);
  connectionIds.add(connection.id);
  ref(world.zones, connection.from, `world.${connection.id}.from`);
  ref(world.zones, connection.to, `world.${connection.id}.to`);
  check(sameSet(new Set(connection.loads), new Set([connection.from, connection.to])),
    `world.${connection.id}.loads não coincide com os extremos`);
  edgeKeys.add([connection.from, connection.to].sort().join("|"));
}
for (const [zoneId, zone] of Object.entries(world.zones)) {
  check(zone.biome_id === zoneId, `world.zones.${zoneId}.biome_id não coincide com a chave`);
  for (const neighbour of zone.connections) {
    ref(world.zones, neighbour, `world.zones.${zoneId}.connections`);
    check(world.zones[neighbour]?.connections?.includes(zoneId), `world: ligação ${zoneId}<->${neighbour} não é simétrica`);
    check(edgeKeys.has([zoneId, neighbour].sort().join("|")), `world: ligação ${zoneId}<->${neighbour} falta em connections`);
  }
  const guardian = zone.dungeon?.guardian_slot;
  ref(world.encounter_slots, guardian, `world.zones.${zoneId}.dungeon.guardian_slot`);
  ref(world.encounter_slots, zone.subboss_slot, `world.zones.${zoneId}.subboss_slot`);
}
for (const [slotId, slot] of Object.entries(world.encounter_slots ?? {})) {
  ref(world.zones, slot.zone_id, `world.encounter_slots.${slotId}.zone_id`);
  check(["guardian", "subboss"].includes(slot.kind), `world.encounter_slots.${slotId}: kind inválido`);
  check(["implemented", "blocked_owner_q52"].includes(slot.content_state),
    `world.encounter_slots.${slotId}: estado inválido`);
  if (slot.content_state === "implemented") {
    ref(enemies, slot.enemy_id, `world.encounter_slots.${slotId}.enemy_id`);
  } else {
    check(slot.enemy_id === null && slot.owner_gate === 52,
      `world.encounter_slots.${slotId}: bloqueio não aponta à pergunta 52`);
  }
}
for (const [doorId, door] of Object.entries(world.history_doors)) {
  ref(world.zones, door.biome_id, `world.history_doors.${doorId}.biome_id`);
}
ref(graphics.presets, graphics.default, "graphics.default");

if (errors.length > 0) {
  console.error(`\n${errors.length} ERRO(S) DE REFERÊNCIA:`);
  for (const error of errors) console.error(`  - ${error}`);
  process.exitCode = 1;
} else {
  console.log(`${files.length} JSON · ${checked} referências/contratos verificados · 0 erros`);
}
