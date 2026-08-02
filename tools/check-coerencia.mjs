#!/usr/bin/env node
/**
 * Guarda de coerência da spec.
 *
 * Uma spec escrita a várias mãos descose-se em silêncio: um link que deixa de
 * apontar para lado nenhum, um documento novo que ninguém pôs no índice, uma
 * tensão que se resolve num sítio e fica por resolver noutro, ou — o pior — um
 * [DECIDIDO] que muda sem ninguém ter decidido nada.
 *
 * Isto corre em cada PR e apanha essas quatro coisas.
 *
 * Uso:
 *   node tools/check-coerencia.mjs              verifica o estado actual
 *   node tools/check-coerencia.mjs --base main  verifica também o que mudou
 */

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, resolve, relative, sep } from 'node:path';
import { execFileSync } from 'node:child_process';

const ROOT = resolve(process.cwd());
const erros = [];
const avisos = [];

function erro(ficheiro, msg) { erros.push({ ficheiro, msg }); }
function aviso(ficheiro, msg) { avisos.push({ ficheiro, msg }); }

function listarMarkdown(dir, encontrados = []) {
  for (const entrada of readdirSync(dir)) {
    if (entrada === '.git' || entrada === 'node_modules') continue;
    const caminho = join(dir, entrada);
    if (statSync(caminho).isDirectory()) listarMarkdown(caminho, encontrados);
    else if (entrada.endsWith('.md')) encontrados.push(caminho);
  }
  return encontrados;
}

const ficheiros = listarMarkdown(ROOT);
const rel = (p) => relative(ROOT, p).split(sep).join('/');

// ------------------------------------------------------------ 0. conflitos ---
// Marcadores de merge esquecidos num ficheiro. Passou-me uma vez a resolver o
// PR #1, e o guarda deu verde — por isso passa a estar aqui.

for (const ficheiro of ficheiros) {
  const linhas = readFileSync(ficheiro, 'utf8').split(/\r?\n/);
  linhas.forEach((linha, i) => {
    if (/^(<{7}|={7}|>{7})(\s|$)/.test(linha)) {
      erro(rel(ficheiro), `marcador de conflito de merge por resolver, linha ${i + 1}`);
    }
  });
}

// ---------------------------------------------------------------- 1. links ---
// Um link partido numa spec é pior do que nenhum link: manda quem lê para o
// sítio errado e faz parecer que a resposta existe algures.

const LINK_RE = /\[[^\]]*\]\(([^)]+)\)/g;

for (const ficheiro of ficheiros) {
  const texto = readFileSync(ficheiro, 'utf8');
  for (const [, alvo] of texto.matchAll(LINK_RE)) {
    if (/^(https?:|mailto:|#)/.test(alvo)) continue;
    const semAncora = alvo.split('#')[0];
    if (!semAncora) continue;
    const destino = resolve(dirname(ficheiro), decodeURIComponent(semAncora));
    if (!existsSync(destino)) {
      erro(rel(ficheiro), `link partido: ${alvo}`);
    }
  }
}

// ---------------------------------------------------------------- 2. índice ---
// Um documento que existe mas não está no SPEC.md é um documento que ninguém lê.

const specDir = join(ROOT, 'spec');
if (existsSync(specDir)) {
  const indice = existsSync(join(ROOT, 'SPEC.md'))
    ? readFileSync(join(ROOT, 'SPEC.md'), 'utf8')
    : '';

  for (const nome of readdirSync(specDir).filter((f) => f.endsWith('.md'))) {
    if (!indice.includes(`spec/${nome}`)) {
      erro('SPEC.md', `falta no índice: spec/${nome}`);
    }
  }
}

// --------------------------------------------------------------- 3. tensões ---
// Uma tensão registada num documento mas ausente da lista de perguntas abertas
// desaparece de vista, e é exactamente o tipo de coisa que se descobre tarde.

const perguntasPath = join(ROOT, 'spec', '99-perguntas-abertas.md');
const perguntas = existsSync(perguntasPath) ? readFileSync(perguntasPath, 'utf8') : '';

for (const ficheiro of ficheiros) {
  const nome = rel(ficheiro);
  if (!nome.startsWith('spec/') || nome.endsWith('99-perguntas-abertas.md')) continue;

  const texto = readFileSync(ficheiro, 'utf8');
  const tensoes = (texto.match(/\[TENSÃO\]/g) || []).length;
  if (tensoes === 0) continue;

  const base = nome.replace('spec/', '');
  if (!perguntas.includes(base)) {
    aviso(nome, `tem ${tensoes} [TENSÃO] mas não é referido em 99-perguntas-abertas.md`);
  }
}

// -------------------------------------------------------------- 4. decidido ---
// O mais importante. [DECIDIDO] é o que o Mateus e o Rico fecharam numa
// conversa. Ninguém — nem o Fable, nem eu — o muda sem uma decisão nova.

const base = process.argv.includes('--base')
  ? process.argv[process.argv.indexOf('--base') + 1]
  : null;

let decididosAlterados = [];
let decididosNovos = [];

if (base) {
  let diff = '';
  try {
    diff = execFileSync('git', ['diff', `${base}...HEAD`, '--unified=0', '--', '*.md'], {
      encoding: 'utf8',
      maxBuffer: 20 * 1024 * 1024,
    });
  } catch {
    aviso('git', `não consegui comparar com ${base} — a verificação de [DECIDIDO] não correu`);
  }

  let ficheiroActual = null;
  for (const linha of diff.split('\n')) {
    const m = linha.match(/^\+\+\+ b\/(.+)$/);
    if (m) { ficheiroActual = m[1]; continue; }
    if (linha.startsWith('-') && !linha.startsWith('---') && linha.includes('[DECIDIDO]')) {
      decididosAlterados.push({ ficheiro: ficheiroActual, linha: linha.slice(1).trim(), tipo: 'removido' });
    }
    // Promover algo a [DECIDIDO] também merece um olhar. Um agente pode
    // carimbar a sua própria escolha como decisão dos donos sem má intenção
    // nenhuma, e a etiqueta perde o significado todo.
    if (linha.startsWith('+') && !linha.startsWith('+++') && linha.includes('[DECIDIDO]')) {
      decididosNovos.push({ ficheiro: ficheiroActual, linha: linha.slice(1).trim() });
    }
  }
}

// ----------------------------------------------------------------- relatório ---

let relatorioDados = '';
try {
  relatorioDados = execFileSync(process.execPath, [join(ROOT, 'tools', 'check-data-references.mjs')], {
    cwd: ROOT,
    encoding: 'utf8',
  }).trim();
} catch (error) {
  const detalhe = String(error?.stdout || error?.stderr || error?.message || error).trim();
  erro('game/data', `a verificação cruzada dos 21 JSON falhou${detalhe ? `:\n${detalhe}` : ''}`);
}

console.log('Guarda de coerência da spec\n');
console.log(`Ficheiros markdown analisados: ${ficheiros.length}`);
if (relatorioDados) console.log(`\n${relatorioDados}`);

if (decididosNovos.length) {
  console.log(`
🟠 ${decididosNovos.length} linha(s) promovida(s) a [DECIDIDO]:
`);
  for (const d of decididosNovos) {
    console.log(`   ${d.ficheiro}`);
    console.log(`   ${d.linha.slice(0, 160)}
`);
  }
  console.log('   [DECIDIDO] é o que o Mateus e o Rico fecharam — não o que quem');
  console.log('   escreveu o PR concluiu. Cada linha tem de dizer a sua fonte, e');
  console.log('   se só um dos dois decidiu, tem de ficar marcado que falta o outro.');
}

if (decididosAlterados.length) {
  console.log(`\n🔴 ${decididosAlterados.length} linha(s) [DECIDIDO] removida(s) ou reescrita(s):\n`);
  for (const d of decididosAlterados) {
    console.log(`   ${d.ficheiro}`);
    console.log(`   ${d.linha.slice(0, 160)}\n`);
  }
  console.log('   [DECIDIDO] é o que o Mateus e o Rico fecharam numa conversa gravada.');
  console.log('   Se isto é intencional, diz no PR qual foi a decisão nova que o substitui.');
}

if (avisos.length) {
  console.log(`\n🟡 ${avisos.length} aviso(s):\n`);
  for (const a of avisos) console.log(`   ${a.ficheiro} — ${a.msg}`);
}

if (erros.length) {
  console.log(`\n❌ ${erros.length} erro(s):\n`);
  for (const e of erros) console.log(`   ${e.ficheiro} — ${e.msg}`);
  console.log('');
  process.exit(1);
}

console.log(`\n✅ Sem erros.${avisos.length ? ' (ver avisos acima)' : ''}`);
