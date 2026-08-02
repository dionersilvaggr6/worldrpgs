#!/usr/bin/env node
/**
 * COBERTURA DA SPEC: que documentos descrevem sistemas que o jogo não tem.
 *
 * Porque isto existe (02-08-2026): o Mateus pediu *"garantir que a spec esteja
 * aplicada, que não tenha nada faltando"*. Tínhamos três guardas e nenhum
 * respondia a essa pergunta:
 *
 *   · `check-coerencia.mjs`      — a spec é coerente consigo própria?
 *   · `check-data-references.mjs`— os catálogos referem-se a coisas que existem?
 *   · `orfaos.mjs`               — o código escrito é chamado pelo jogo?
 *
 * ⭐ Faltava o inverso de todos: **a spec descreve coisas que o código nunca
 * implementou?** Um documento pode estar perfeito, coerente e citado, e não
 * existir uma linha de jogo por trás dele.
 *
 * Como mede: cada documento declara **âncoras** — nomes de catálogo, ficheiros de
 * dados, ids e sistemas. Se nenhuma âncora do documento aparece em `game/`, o
 * documento está **sem chão**.
 *
 * ⚠️ Isto não prova que um sistema está BEM feito — prova que existe alguma
 * coisa. É um detector de vazio, não de qualidade.
 *
 * Uso:  node tools/cobertura-spec.mjs
 *       node tools/cobertura-spec.mjs --gate   (sai com erro se houver vazios)
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const specDir = path.join(raiz, "spec");
const gameDir = path.join(raiz, "game");

/** Junta todo o código e dados do jogo num só texto, para procurar âncoras. */
const juntarJogo = () => {
  const partes = [];
  const percorrer = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      if (e.name === ".godot" || e.name === "captures" || e.name === "assets") continue;
      const p = path.join(dir, e.name);
      if (e.isDirectory()) percorrer(p);
      else if (/\.(gd|json|tscn|bat)$/.test(e.name)) partes.push(fs.readFileSync(p, "utf8"));
    }
  };
  percorrer(gameDir);
  return partes.join("\n");
};

const jogo = juntarJogo();

/**
 * Âncoras de um documento: as coisas concretas que ele nomeia e que teriam de
 * existir no jogo. Deliberadamente conservador — só conta o que é inequívoco.
 */
const ancoras = (texto) => {
  const encontradas = new Set();
  // `algo.json`, `algo_qualquer.gd`
  for (const m of texto.matchAll(/`([a-z_0-9]+\.(?:json|gd))`/g)) encontradas.add(m[1]);
  // ids em código: `orc_spearman`, `couro_peitoral`, `follow_caster`
  for (const m of texto.matchAll(/`([a-z][a-z_0-9]{4,40})`/g)) {
    const id = m[1];
    if (!id.includes(".") && id.includes("_")) encontradas.add(id);
  }
  // Nomes de classe GDScript: `ArmorVisual`, `NecromancyRuntime`
  for (const m of texto.matchAll(/`([A-Z][A-Za-z0-9]{3,40})`/g)) encontradas.add(m[1]);
  return [...encontradas];
};

const docs = fs.readdirSync(specDir).filter((n) => n.endsWith(".md")).sort();
const semChao = [];
const fracos = [];
const naoMedivel = [];
const solidos = [];

for (const nome of docs) {
  const texto = fs.readFileSync(path.join(specDir, nome), "utf8");
  const lista = ancoras(texto);
  if (lista.length === 0) {
    // ⚠️ Não é uma lacuna do jogo — é uma limitação desta ferramenta. Os
    // documentos mais antigos escrevem em prosa e não citam ids em crase, por
    // isso não há nada de concreto para procurar. Dizer que "falta" seria mentir.
    naoMedivel.push(nome);
    continue;
  }
  const presentes = lista.filter((a) => jogo.includes(a));
  const razao = presentes.length / lista.length;
  const registo = { nome, total: lista.length, presentes: presentes.length, razao,
    faltam: lista.filter((a) => !jogo.includes(a)).slice(0, 6) };
  if (presentes.length === 0) semChao.push(registo);
  else if (razao < 0.34) fracos.push(registo);
  else solidos.push(registo);
}

const pct = (r) => `${Math.round(r.razao * 100)}%`;

console.log(`\n📐 COBERTURA DA SPEC — ${docs.length} documentos\n`);

if (semChao.length) {
  console.log(`🔴 SEM CHÃO — descrevem sistemas que o jogo não tem (${semChao.length}):\n`);
  for (const r of semChao) {
    console.log(`   ${r.nome}`);
    console.log(`      0 de ${r.total} âncoras existem em game/ · ex: ${r.faltam.join(", ")}`);
  }
  console.log("");
}

if (fracos.length) {
  console.log(`🟠 POUCO CHÃO — menos de um terço implementado (${fracos.length}):\n`);
  for (const r of fracos) {
    console.log(`   ${r.nome}  ${pct(r)}  (${r.presentes}/${r.total}) · falta: ${r.faltam.join(", ")}`);
  }
  console.log("");
}

console.log(`🟢 COM CHÃO: ${solidos.length} documentos\n`);
const media = solidos.length
  ? Math.round(solidos.reduce((s, r) => s + r.razao, 0) / solidos.length * 100) : 0;
console.log(`   cobertura média desses: ${media}%`);
console.log(`\n⚠️  Isto detecta VAZIO, não qualidade: prova que existe alguma coisa,`);
console.log(`   nunca que está bem feita. Para isso há scenes/percurso.tscn.\n`);

if (process.argv.includes("--gate") && semChao.length) process.exit(1);
