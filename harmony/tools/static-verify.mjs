// NetBird HarmonyOS — zero-dependency static verification harness.
// Validates project structure, JSON5 configs, resource/route references,
// ArkTS decorator rules, delimiter balance and forbidden constructs.
// Run: node tools/static-verify.mjs   (from the harmony/ directory)
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const ETS = path.join(ROOT, 'entry/src/main/ets');
const RES_BASE = path.join(ROOT, 'entry/src/main/resources/base/element');
const RES_DARK = path.join(ROOT, 'entry/src/main/resources/dark/element');

let pass = 0;
const failures = [];
const warnings = [];

function ok(msg) { pass++; console.log(`  \x1b[32m✓\x1b[0m ${msg}`); }
function fail(msg) { failures.push(msg); console.log(`  \x1b[31m✗\x1b[0m ${msg}`); }
function warn(msg) { warnings.push(msg); console.log(`  \x1b[33m!\x1b[0m ${msg}`); }
function section(t) { console.log(`\n\x1b[36m${t}\x1b[0m`); }

// ---- minimal JSON5 tolerant parser (strip comments + trailing commas) ----
function readJson5(file) {
  let s = fs.readFileSync(file, 'utf8');
  // remove block + line comments not inside strings (files here have none in strings)
  s = s.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1');
  s = s.replace(/,(\s*[}\]])/g, '$1'); // trailing commas
  return JSON.parse(s);
}

// ---- strip comments/strings to a "code skeleton" for balance & token scans ----
function skeleton(src) {
  let out = '';
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    const d = src[i + 1];
    if (c === '/' && d === '/') { while (i < n && src[i] !== '\n') i++; continue; }
    if (c === '/' && d === '*') { i += 2; while (i < n && !(src[i] === '*' && src[i + 1] === '/')) i++; i += 2; continue; }
    if (c === '"' || c === "'" || c === '`') {
      const q = c; i++;
      while (i < n) {
        if (src[i] === '\\') { i += 2; continue; }
        if (src[i] === q) { i++; break; }
        i++;
      }
      out += '""'; // placeholder literal
      continue;
    }
    out += c; i++;
  }
  return out;
}

function walk(dir, ext, acc = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, ext, acc);
    else if (e.name.endsWith(ext)) acc.push(p);
  }
  return acc;
}

// ============================ 1. config files ============================
section('[1/8] Config files (JSON5) parse & required fields');
const cfgFiles = [
  'AppScope/app.json5', 'build-profile.json5', 'oh-package.json5',
  'hvigorfile.ts', 'hvigor/hvigor-config.json5',
  'entry/oh-package.json5', 'entry/build-profile.json5', 'entry/hvigorfile.ts',
  'entry/src/main/module.json5',
];
const cfg = {};
for (const rel of cfgFiles) {
  const p = path.join(ROOT, rel);
  if (!fs.existsSync(p)) { fail(`missing config: ${rel}`); continue; }
  if (rel.endsWith('.json5')) {
    try { cfg[rel] = readJson5(p); ok(`${rel} parses`); }
    catch (e) { fail(`${rel} invalid JSON5: ${e.message}`); }
  } else ok(`${rel} present`);
}

const app = cfg['AppScope/app.json5']?.app;
const mod = cfg['entry/src/main/module.json5']?.module;
if (app) {
  if (/^[a-zA-Z][a-zA-Z0-9_.]+$/.test(app.bundleName)) ok(`bundleName "${app.bundleName}" valid`);
  else fail(`bundleName invalid: ${app.bundleName}`);
  if (typeof app.versionCode === 'number' && app.versionName) ok('versionCode/versionName present');
  else fail('missing versionCode/versionName');
}
if (mod) {
  if (mod.type === 'entry') ok('module.type = entry');
  else fail('module.type should be entry');
  if (mod.pages === '$profile:main_pages') ok('module.pages -> $profile:main_pages');
  else fail('module.pages must reference $profile:main_pages');
  const ability = (mod.abilities || []).find(a => a.name === mod.mainElement);
  if (ability) ok(`mainElement "${mod.mainElement}" declared in abilities`);
  else fail(`mainElement "${mod.mainElement}" not found in abilities`);
  if (ability) {
    const entry = path.join(ROOT, 'entry/src/main', ability.srcEntry.replace('./', ''));
    if (fs.existsSync(entry)) ok(`ability srcEntry resolves: ${ability.srcEntry}`);
    else fail(`ability srcEntry missing: ${ability.srcEntry}`);
  }
}

// ============================ 2. resources ============================
section('[2/8] Resource tables load & dark parity');
let strings = new Set(), colors = new Set(), floats = new Set(), darkColors = new Set();
try {
  strings = new Set(readJson5(path.join(RES_BASE, 'string.json')).string.map(s => s.name));
  colors = new Set(readJson5(path.join(RES_BASE, 'color.json')).color.map(c => c.name));
  floats = new Set(readJson5(path.join(RES_BASE, 'float.json')).float.map(f => f.name));
  strings = new Set([...strings, ...readJson5(path.join(ROOT, 'AppScope/resources/base/element/string.json')).string.map(s => s.name)]);
  ok(`base: ${strings.size} strings, ${colors.size} colors, ${floats.size} floats`);
} catch (e) { fail(`resource load: ${e.message}`); }
try {
  darkColors = new Set(readJson5(path.join(RES_DARK, 'color.json')).color.map(c => c.name));
  const missingDark = [...colors].filter(c => !darkColors.has(c));
  if (missingDark.length === 0) ok(`dark theme overrides all ${colors.size} colors`);
  else fail(`dark/element/color.json missing overrides: ${missingDark.join(', ')}`);
} catch (e) { fail(`dark color load: ${e.message}`); }

// ============================ 3. pages & routing ============================
section('[3/8] Pages, @Entry registration & Navigation route table');
const etsFiles = walk(ETS, '.ets');
const src = new Map(etsFiles.map(f => [f, fs.readFileSync(f, 'utf8')]));
const pagesJson = readJson5(path.join(ROOT, 'entry/src/main/resources/base/profile/main_pages.json'));
const declaredPages = pagesJson.src || [];

const entryFiles = etsFiles.filter(f => /(^|\n)\s*@Entry\b/.test(src.get(f)));
if (entryFiles.length === declaredPages.length) ok(`@Entry count (${entryFiles.length}) == main_pages.json (${declaredPages.length})`);
else fail(`@Entry count ${entryFiles.length} != main_pages ${declaredPages.length}`);
for (const pg of declaredPages) {
  const f = path.join(ETS, pg + '.ets');
  if (fs.existsSync(f) && /@Entry\b/.test(src.get(f))) ok(`page "${pg}" is an @Entry file`);
  else fail(`page "${pg}" missing or not @Entry`);
}

// Navigation route map names must have matching NavDestination components
const indexSrc = src.get(path.join(ETS, 'pages/Index.ets')) || '';
const routesConst = src.get(path.join(ETS, 'common/NavRouter.ets')) || '';
const routeNames = [...routesConst.matchAll(/static readonly \w+: string = '([^']+)'/g)].map(m => m[1]);
const pagemapNames = [...indexSrc.matchAll(/name === Routes\.(\w+)/g)].map(m => m[1]);
const routeKeys = [...routesConst.matchAll(/static readonly (\w+): string/g)].map(m => m[1]);
for (let i = 0; i < routeKeys.length; i++) {
  const key = routeKeys[i];
  if (key === 'FIRST_INSTALL') continue; // overlay, not pushed on the stack
  if (pagemapNames.includes(key)) ok(`route "${routeNames[i]}" handled in PageMap`);
  else fail(`route "${routeNames[i]}" (${key}) not handled in Index PageMap`);
}

// ============================ 4. components have build() ============================
section('[4/8] Every @Component/@Entry struct declares build()');
for (const f of etsFiles) {
  const s = src.get(f);
  const structs = [...s.matchAll(/@Component\b[\s\S]*?struct\s+(\w+)/g)].map(m => m[1])
    .concat([...s.matchAll(/@Entry\b[\s\S]*?struct\s+(\w+)/g)].map(m => m[1]));
  const uniq = [...new Set(structs)];
  for (const name of uniq) {
    if (/\bbuild\s*\(\s*\)\s*\{/.test(s)) ok(`${path.relative(ROOT, f)} :: ${name} has build()`);
    else fail(`${path.relative(ROOT, f)} :: ${name} missing build()`);
  }
}

// ============================ 5. imports & exports ============================
section('[5/8] Relative imports resolve & named exports exist');
const exportsByFile = new Map();
for (const f of etsFiles) {
  const s = src.get(f);
  const names = new Set();
  for (const m of s.matchAll(/export\s+(?:class|struct|enum|interface|function|const|let)\s+(\w+)/g)) names.add(m[1]);
  for (const m of s.matchAll(/export\s+default\s+class\s+(\w+)/g)) names.add(m[1]);
  exportsByFile.set(f, names);
}
let importEdges = 0;
for (const f of etsFiles) {
  const s = src.get(f);
  for (const m of s.matchAll(/import\s*\{([^}]+)\}\s*from\s*'(\.[^']+)'/g)) {
    const target = path.normalize(path.join(path.dirname(f), m[2])) + '.ets';
    if (!fs.existsSync(target)) { fail(`${path.relative(ROOT, f)} -> missing module ${m[2]}`); continue; }
    const ex = exportsByFile.get(target) || new Set();
    for (let nm of m[1].split(',')) {
      nm = nm.trim().split(/\s+as\s+/)[0].trim();
      if (!nm) continue;
      importEdges++;
      if (!ex.has(nm)) fail(`${path.relative(ROOT, f)} imports "${nm}" not exported by ${path.relative(ROOT, target)}`);
    }
  }
  for (const m of s.matchAll(/import\s+(\w+)\s+from\s*'(\.[^']+)'/g)) {
    const target = path.normalize(path.join(path.dirname(f), m[2])) + '.ets';
    if (!fs.existsSync(target)) fail(`${path.relative(ROOT, f)} -> missing default module ${m[2]}`);
  }
}
ok(`${importEdges} named import edges checked`);

// ============================ 6. resource & symbol refs ============================
section('[6/8] $r() resource refs exist & sys.symbol allowlist');
const SYMBOL_ALLOW = new Set(['house','house_fill','person','person_fill','gearshape','gearshape_fill',
  'externaldrive','list_bullet','magnifyingglass','chevron_right','chevron_left','chevron_up','chevron_down',
  'checkmark','clock','trash','arrow_up','plus','xmark','arrow_clockwise','square_and_pencil']);
const refStr = new Set(), refCol = new Set(), refFlo = new Set(), refSym = new Set();
for (const f of etsFiles) {
  const s = src.get(f);
  for (const m of s.matchAll(/\$r\('app\.(string|color|float)\.(\w+)'\)/g)) {
    if (m[1] === 'string') refStr.add(m[2]); else if (m[1] === 'color') refCol.add(m[2]); else refFlo.add(m[2]);
  }
  for (const m of s.matchAll(/\$r\('sys\.symbol\.(\w+)'\)/g)) refSym.add(m[1]);
}
for (const n of refStr) if (!strings.has(n)) fail(`missing string resource: ${n}`);
for (const n of refCol) if (!colors.has(n)) fail(`missing color resource: ${n}`);
for (const n of refFlo) if (!floats.has(n)) fail(`missing float resource: ${n}`);
ok(`${refStr.size} string / ${refCol.size} color refs all exist`);
const badSym = [...refSym].filter(s => !SYMBOL_ALLOW.has(s));
if (badSym.length === 0) ok(`${refSym.size} sys.symbol icons all in verified allowlist`);
else warn(`sys.symbol not in verified allowlist (confirm in DevEco): ${badSym.join(', ')}`);

// ============================ 7. ArkTS decorator & syntax rules ============================
section('[7/8] ArkTS decorator rules & forbidden constructs');
let anyHits = 0, decoChecked = 0;
for (const f of etsFiles) {
  const s = src.get(f);
  const rel = path.relative(ROOT, f);
  if (/:\s*any\b|as\s+any\b|<any>/.test(s)) { fail(`${rel}: uses forbidden "any"`); anyHits++; }
  // state decorators must have a type annotation; @State/@Prop/@StorageLink/@StorageProp need an initializer
  for (const m of s.matchAll(/@(State|Prop|Link|StorageLink|StorageProp|Provide|Consume)\s*(\([^)]*\))?\s+(\w+)\s*(:\s*[^=;\n]+)?(=\s*[^;\n]+)?;/g)) {
    decoChecked++;
    const [, deco, , name, typeAnn, init] = m;
    if (!typeAnn) fail(`${rel}: @${deco} ${name} missing type annotation`);
    const needsInit = ['State', 'Prop', 'StorageLink', 'StorageProp', 'Provide'].includes(deco);
    if (needsInit && !init) fail(`${rel}: @${deco} ${name} missing initializer`);
  }
  // @ObjectLink must not have a local initializer and its type should be @Observed somewhere
  // resolve import aliases (e.g. `Resource as NetResource`) to the real class name/file
  const aliasMap = new Map();
  for (const m of s.matchAll(/import\s*\{([^}]+)\}\s*from\s*'(\.[^']+)'/g)) {
    const target = path.normalize(path.join(path.dirname(f), m[2])) + '.ets';
    for (let part of m[1].split(',')) {
      part = part.trim();
      if (!part) continue;
      const asM = part.match(/^(\w+)\s+as\s+(\w+)$/);
      if (asM) aliasMap.set(asM[2], { orig: asM[1], target });
      else aliasMap.set(part, { orig: part, target });
    }
  }
  for (const m of s.matchAll(/@ObjectLink\s+(\w+)\s*:\s*(\w+)/g)) {
    decoChecked++;
    let typeName = m[2];
    let searchFiles = etsFiles;
    if (aliasMap.has(typeName)) {
      const a = aliasMap.get(typeName);
      typeName = a.orig;
      searchFiles = [a.target];
    }
    const observed = searchFiles.some(g => src.has(g) && src.get(g).replace(/\s+/g, ' ').includes('@Observed export class ' + typeName));
    if (!observed) fail(`${rel}: @ObjectLink ${m[1]}:${typeName} — ${typeName} is not an @Observed class`);
  }
}
ok(`${decoChecked} state/object decorators validated; ${anyHits} "any" violations`);

// delimiter balance on code skeleton
let balFail = 0;
for (const f of etsFiles) {
  const sk = skeleton(src.get(f));
  const pairs = { '(': ')', '{': '}', '[': ']' };
  const stack = [];
  let bad = false;
  for (const ch of sk) {
    if ('({['.includes(ch)) stack.push(ch);
    else if (')}]'.includes(ch)) {
      const top = stack.pop();
      if (pairs[top] !== ch) { bad = true; break; }
    }
  }
  if (bad || stack.length !== 0) { fail(`${path.relative(ROOT, f)}: unbalanced delimiters`); balFail++; }
}
if (balFail === 0) ok(`all ${etsFiles.length} .ets files have balanced (), {}, []`);

// ============================ 8. engine seam sanity ============================
section('[8/8] Engine abstraction seam wiring');
const mgr = src.get(path.join(ETS, 'engine/EngineManager.ets')) || '';
const mock = src.get(path.join(ETS, 'engine/MockVpnEngine.ets')) || '';
const iface = src.get(path.join(ETS, 'engine/VpnEngine.ets')) || '';
const ifaceMethods = [...iface.matchAll(/^\s{2}(\w+)\s*\(/gm)].map(m => m[1]);
const mockMethods = new Set([...mock.matchAll(/^\s{2}(\w+)\s*\(/gm)].map(m => m[1]));
const missingImpl = ifaceMethods.filter(mth => !mockMethods.has(mth));
if (missingImpl.length === 0) ok(`MockVpnEngine implements all ${ifaceMethods.length} VpnEngine methods`);
else fail(`MockVpnEngine missing VpnEngine methods: ${missingImpl.join(', ')}`);
if (/implements EngineObserver/.test(mgr)) ok('EngineManager implements EngineObserver (bridge)');
else fail('EngineManager must implement EngineObserver');
if (/new MockVpnEngine\(\)/.test(mgr)) ok('EngineManager injects MockVpnEngine (documented swap point)');
else warn('EngineManager engine injection point changed');

// ============================ 9. string key coverage ============================
section('[9/9] String resource coverage (advisory)');
const jsonFiles = [...walk(path.join(ROOT, 'entry/src/main/resources'))]
  .filter(f => f.endsWith('string.json'));
const defined = new Set();
for (const jf of jsonFiles) {
  try { for (const m of src.get(jf) ? src.get(jf).matchAll(/"name":\s*"([a-z0-9_]+)"/g) : []) defined.add(m[1]); } catch {}
}
const referenced = new Set();
for (const [f, content] of src) {
  for (const m of content.matchAll(/app\.string\.([a-z0-9_]+)/g)) referenced.add(m[1]);
}
const unused = [...defined].filter(k => !referenced.has(k));
if (unused.length === 0) ok('all string keys are referenced');
else warn(`unused string keys (${unused.length}, cleanup candidates, not a failure): ${unused.slice(0, 12).join(', ')}${unused.length > 12 ? ', ...' : ''}`);

// ---- summary ----
console.log(`\n${'='.repeat(56)}`);
console.log(`\x1b[32mPASS: ${pass}\x1b[0m   \x1b[31mFAIL: ${failures.length}\x1b[0m   \x1b[33mWARN: ${warnings.length}\x1b[0m`);
if (failures.length) { console.log('\nFailures:'); failures.forEach(f => console.log('  - ' + f)); }
if (warnings.length) { console.log('\nWarnings:'); warnings.forEach(w => console.log('  - ' + w)); }
console.log('='.repeat(56));
process.exit(failures.length ? 1 : 0);
