// One-shot verification entry point: runs the static harness then the executable
// logic/engine suite, and aggregates the exit codes.
//   node tools/run-all-tests.mjs
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const ROOT = process.cwd();
const steps = [
  { name: 'Static verification', cmd: 'tools/static-verify.mjs' },
  { name: 'Logic & engine tests', cmd: 'tools/logic-tests.mjs' },
];

let failed = 0;
for (const step of steps) {
  console.log(`\n\x1b[1m===== ${step.name} =====\x1b[0m`);
  const res = spawnSync(process.execPath, [path.join(ROOT, step.cmd)], { stdio: 'inherit', cwd: ROOT });
  if (res.status !== 0) failed++;
}

console.log(`\n\x1b[1m===== Summary =====\x1b[0m`);
console.log(`Suites run: ${steps.length}   failed: ${failed}`);
console.log('\nNote: the on-device instrumented suites (entry/src/ohosTest — Engine.test + Ui.test)');
console.log('and the host unit suite (entry/src/test — Logic.test) require DevEco Studio / a');
console.log('HarmonyOS device or emulator and are run from the IDE, not here.');
process.exit(failed ? 1 : 0);
