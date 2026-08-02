#!/usr/bin/env node
/**
 * Encontra ÓRFÃOS: código que existe no repositório e que o jogo nunca chama.
 *
 * Porque isto existe (02-08-2026): cinco vezes seguidas um agente construiu um
 * sistema completo, com testes e benchmark, e ninguém o instanciou. O
 * `dark_mage.gd` esteve escrito e desligado. O `necromancy_runtime.gd` tinha 355
 * linhas e zero referências. O `WorldPickupManager` montava três baús que nunca
 * apareciam. O `Bonfire` sentava um jogador que o `main.gd` nunca criava.
 *
 * ⭐ Os testes não apanham isto — eles exercitam a classe directamente, e a
 * classe funciona. O que falha é o FIO até ao jogo.
 *
 * Regra: um `class_name` só conta como ligado se algo fora do seu próprio
 * ficheiro, dos seus testes e dos seus benchmarks o mencionar.
 *
 * Uso:  node tools/orfaos.mjs          — lista os órfãos
 *       node tools/orfaos.mjs --gate   — sai com erro se houver órfãos novos
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const src = path.join(raiz, "game", "src");

/** Ficheiros que não contam como "alguém chamou": são o próprio e a sua prova. */
const ehProvaDe = (ficheiro, base) => {
  const nome = path.basename(ficheiro, ".gd");
  return nome === base
    || nome.startsWith(`${base}_test`) || nome.startsWith(`${base}_self_test`)
    || nome.startsWith(`${base}_selftest`) || nome.startsWith(`${base}_benchmark`)
    || nome.startsWith(`${base}_probe`) || nome.startsWith(`${base}_repro`)
    || nome.startsWith(`${base}_perf`);
};

const percorrer = (dir, acc = []) => {
  for (const entrada of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, entrada.name);
    if (entrada.isDirectory()) percorrer(p, acc);
    else if (entrada.name.endsWith(".gd")) acc.push(p);
  }
  return acc;
};

const ficheiros = percorrer(src);
const conteudo = new Map(ficheiros.map((f) => [f, fs.readFileSync(f, "utf8")]));

// project.godot e as cenas também contam como quem chama.
const extras = [path.join(raiz, "game", "project.godot")];
const cenas = path.join(raiz, "game", "scenes");
if (fs.existsSync(cenas)) {
  for (const n of fs.readdirSync(cenas)) if (n.endsWith(".tscn")) extras.push(path.join(cenas, n));
}
for (const f of ficheiros) {
  const t = f.replace(/\.gd$/, ".tscn");
  if (fs.existsSync(t)) extras.push(t);
}
for (const e of extras) if (fs.existsSync(e)) conteudo.set(e, fs.readFileSync(e, "utf8"));

const classes = [];
for (const [f, texto] of conteudo) {
  if (!f.endsWith(".gd")) continue;
  const m = texto.match(/^class_name\s+([A-Za-z0-9_]+)/m);
  if (m) classes.push({ nome: m[1], ficheiro: f, base: path.basename(f, ".gd") });
}

const orfaos = [];
for (const { nome, ficheiro, base } of classes) {
  const relativo = path.relative(raiz, ficheiro).replaceAll("\\", "/");
  let chamadores = 0;
  for (const [outro, texto] of conteudo) {
    if (outro === ficheiro) continue;
    if (ehProvaDe(outro, base)) continue;
    // Menção ao class_name, ou carregamento do próprio ficheiro.
    if (new RegExp(`\\b${nome}\\b`).test(texto) || texto.includes(`${base}.gd`)) chamadores += 1;
  }
  if (chamadores === 0) orfaos.push({ nome, relativo, linhas: conteudo.get(ficheiro).split("\n").length });
}

orfaos.sort((a, b) => b.linhas - a.linhas);

if (orfaos.length === 0) {
  console.log("✅ Sem órfãos: todo o class_name é chamado por alguém fora da sua própria prova.");
  process.exit(0);
}

console.log(`\n⚠️  ${orfaos.length} ÓRFÃO(S) — existem no repositório e o jogo nunca os chama:\n`);
for (const o of orfaos) {
  console.log(`  ${String(o.linhas).padStart(5)} linhas   ${o.nome.padEnd(28)} ${o.relativo}`);
}
const total = orfaos.reduce((s, o) => s + o.linhas, 0);
console.log(`\n  ${total} linhas de código que ninguém executa a jogar.`);
console.log(`\n  ⭐ Isto não é um teste a falhar — os testes destas classes passam.`);
console.log(`     O que falta é o fio: alguém tem de as instanciar em main.gd,`);
console.log(`     nos autoloads do project.godot, ou numa cena.\n`);

if (process.argv.includes("--gate")) process.exit(1);
