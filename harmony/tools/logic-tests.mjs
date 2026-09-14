// Transpiles the ArkTS logic/engine modules into Node-runnable .mts and executes
// the behaviour test suite with Node's built-in type-stripping + test runner.
// This is a real execution of the ported business logic (no HarmonyOS SDK needed).
//
// Run: node tools/logic-tests.mjs   (from the harmony/ directory)
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const ROOT = process.cwd();
const ETS = path.join(ROOT, 'entry/src/main/ets');
const BUILD = path.join(ROOT, 'tools/.build');

// Modules under test (relative to the ets root).
const INCLUDE = [
  'model/Status.ets', 'model/ConnectionState.ets', 'model/Peer.ets', 'model/Resource.ets',
  'model/Profile.ets', 'model/SshSession.ets', 'model/Settings.ets',
  'common/Constants.ets', 'common/Formatters.ets',
  'engine/EngineEvents.ets', 'engine/VpnEngine.ets', 'engine/MockVpnEngine.ets', 'engine/EngineManager.ets',
];

function stripComments(s) {
  return s.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1');
}

// A file is "type-only" when it exports nothing that exists at runtime.
function isTypeOnly(src) {
  const s = stripComments(src);
  const hasRuntime = /export\s+(default\s+)?(class|enum|const|let|function)\b/.test(s);
  const hasIface = /export\s+interface\b|(^|\n)\s*interface\b/.test(s);
  return hasIface && !hasRuntime;
}

function transform(src, relPath, typeOnlyTargets) {
  let s = src;
  // 1. drop ArkUI/ArkTS decorators that live on their own line (@Observed on models)
  s = s.split('\n')
    .filter((line) => !/^\s*@(Observed|Component|Entry|State|Prop|Link|ObjectLink|Provide|Consume|StorageLink|StorageProp|Builder|Extend|Styles)\b/.test(line))
    .join('\n');
  // 2. drop `implements X, Y` clauses (the interfaces are erased anyway)
  s = s.replace(/\s+implements\s+[A-Za-z0-9_.]+(\s*,\s*[A-Za-z0-9_.]+)*/g, '');
  // 3. rewrite / drop relative imports
  const dir = path.posix.dirname(relPath.replace(/\\/g, '/'));
  s = s.replace(/import\s+(\{[^}]*\}|\w+)\s+from\s*'(\.[^']+)';?/g, (full, names, spec) => {
    const target = path.posix.normalize(path.posix.join(dir, spec)) + '.ets';
    if (typeOnlyTargets.has(target)) return ''; // interface-only module: nothing to import at runtime
    return `import ${names} from '${spec}.mts';`;
  });
  return s;
}

// ---- prepare build dir ----
fs.rmSync(BUILD, { recursive: true, force: true });
fs.mkdirSync(BUILD, { recursive: true });

const typeOnlyTargets = new Set();
for (const rel of INCLUDE) {
  const src = fs.readFileSync(path.join(ETS, rel), 'utf8');
  if (isTypeOnly(src)) typeOnlyTargets.add(rel);
}

let emitted = 0;
for (const rel of INCLUDE) {
  if (typeOnlyTargets.has(rel)) continue;
  const src = fs.readFileSync(path.join(ETS, rel), 'utf8');
  const out = transform(src, rel, typeOnlyTargets);
  const dest = path.join(BUILD, rel.replace(/\.ets$/, '.mts'));
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, out);
  emitted++;
}

// copy the shim + test templates verbatim (they already use .mts specifiers)
fs.copyFileSync(path.join(ROOT, 'tools/shim.template.mts'), path.join(BUILD, 'shim.mts'));
fs.copyFileSync(path.join(ROOT, 'tools/logic.test.template.mts'), path.join(BUILD, 'logic.test.mts'));

console.log(`Transpiled ${emitted} ArkTS modules -> tools/.build (type-only skipped: ${[...typeOnlyTargets].join(', ') || 'none'})`);
console.log(`Running: node --test --experimental-transform-types --test-force-exit\n`);

const res = spawnSync(process.execPath,
  ['--test', '--experimental-transform-types', '--test-force-exit', '--no-warnings',
    path.join(BUILD, 'logic.test.mts')],
  { stdio: 'inherit', cwd: ROOT });

process.exit(res.status ?? 1);
