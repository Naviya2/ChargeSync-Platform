import { readFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { runStationWorkflowE2E } from './stations/station-workflow.spec.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const runtimePath = path.join(here, 'runtime.local.json');
const runtime = JSON.parse(await readFile(runtimePath, 'utf8'));

const artifacts = path.join(here, 'artifacts', `stations-${Date.now()}`);
await mkdir(artifacts, { recursive: true });

try {
  await runStationWorkflowE2E({ runtime, artifacts });
  console.log(`PASS. Evidence: ${artifacts}`);
} catch (error) {
  console.error(`FAIL: ${error.message}`);
  process.exitCode = 1;
}
