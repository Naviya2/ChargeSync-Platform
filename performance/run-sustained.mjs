import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import assert from 'node:assert/strict';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.dirname(here);
const settingsPath = path.join(repo, 'e2e', 'settings.local.json');
const runtimePath = path.join(repo, 'e2e', 'runtime.local.json');
const output = path.join(here, 'artifacts', `sustained-${new Date().toISOString().replace(/[:.]/g, '-')}`);
await mkdir(output, { recursive: true });

const result = {
  startedAt: new Date().toISOString(),
  status: 'running',
  environment: 'Local Release ASP.NET Core API on port 5036; isolated cloud Supabase E2E database',
  workload: 'Read-only GET requests; 30-second unscored warm-up, then 1, 5, and 10 constant virtual users for 60 seconds each; 0.5-second think time',
  targets: { apiP95Ms: 500, httpFailureRateBelow: 0.01, applicationCheckRateAbove: 0.99 },
  targetSource: 'ChargeSync group SRS for standard API p95; team criteria for failures and response checks',
  phases: [],
};

async function executable(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isFile() && entry.name === 'k6.exe') return file;
    if (entry.isDirectory()) {
      const found = await executable(file);
      if (found) return found;
    }
  }
}

async function command(file, args, extraEnv = {}, timeoutMs = 30000) {
  return await new Promise((resolve, reject) => {
    const child = spawn(file, args, { cwd: repo, windowsHide: true,
      env: { ...process.env, ...extraEnv }, stdio: ['ignore', 'pipe', 'pipe'] });
    let diagnostic = '';
    for (const stream of [child.stdout, child.stderr]) {
      stream.on('data', data => { diagnostic = (diagnostic + data.toString()).slice(-4000); });
    }
    const timer = setTimeout(() => { child.kill(); reject(new Error(`${path.basename(file)} timed out`)); }, timeoutMs);
    child.on('error', error => { clearTimeout(timer); reject(new Error(`Cannot launch ${path.basename(file)}: ${error.code}`)); });
    child.on('exit', code => { clearTimeout(timer); resolve({ code, diagnostic }); });
  });
}

const metric = (summary, name) => summary.metrics[name]?.values;
const format = value => value === undefined ? 'n/a' : Number(value).toFixed(2);

try {
  const settings = JSON.parse(await readFile(settingsPath, 'utf8'));
  const runtime = JSON.parse(await readFile(runtimePath, 'utf8'));
  assert.equal(settings.disposableDatabase, true, 'Only the disposable E2E database is allowed.');
  const fixture = path.join(repo, 'backend', 'tools', 'E2EFixture', 'bin', 'Release', 'net8.0', 'E2EFixture.dll');
  const validated = await command('dotnet', [fixture, 'validate', settingsPath, runtimePath], {}, 120000);
  assert.equal(validated.code, 0, 'Isolated database validation failed.');

  const response = await fetch('http://127.0.0.1:5036/api/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: runtime.driver.email, password: runtime.driver.password }),
    signal: AbortSignal.timeout(20000),
  });
  assert.equal(response.status, 200, 'E2E driver login failed. Start e2e/Start-Backend.ps1.');
  const auth = await response.json();
  const claims = JSON.parse(Buffer.from(auth.accessToken.split('.')[1], 'base64url'));
  assert.equal(claims.iss, 'ChargeSyncE2E', 'Backend is not the isolated E2E API.');
  assert.equal(claims.sub, runtime.driver.id, 'Backend is not using the prepared test driver.');
  result.fixtureRunId = runtime.runId;

  const k6 = await executable(path.join(here, '.tools'));
  assert.ok(k6, 'Portable k6.exe missing from performance/.tools.');
  const summaryPath = path.join(output, 'k6-summary.json');
  console.log('Validated isolated E2E database and API. Running warm-up plus sustained k6 test for about 3.5 minutes.');
  const run = await command(k6, ['run', '--quiet', path.join(here, 'sustained-api-load.js')],
    { PERF_TOKEN: auth.accessToken, PERF_SUMMARY: summaryPath, K6_NO_USAGE_REPORT: 'true' }, 270000);
  assert.ok([0, 99].includes(run.code), `k6 exited ${run.code}: ${run.diagnostic.slice(-700)}`);
  const summary = JSON.parse(await readFile(summaryPath, 'utf8'));
  const phaseSettings = [['baseline', 1], ['moderate', 5], ['higher', 10]];
  for (const [name, users] of phaseSettings) {
    const requests = metric(summary, `http_reqs{phase:${name}}`)?.count;
    const failureRate = metric(summary, `http_req_failed{phase:${name}}`)?.rate;
    const checkRate = metric(summary, `checks{phase:${name}}`)?.rate;
    assert.ok(requests > 0 && failureRate !== undefined && checkRate !== undefined, `Missing k6 metrics for ${name}.`);
    const endpoints = ['stations', 'wallet', 'payment-history'].map(endpoint => {
      const values = metric(summary, `http_req_duration{phase:${name},endpoint:${endpoint}}`);
      assert.ok(values && Number.isFinite(values['p(95)']), `Missing duration metrics for ${name}/${endpoint}.`);
      return { endpoint, averageMs: values.avg, medianMs: values.med, p90Ms: values['p(90)'],
        p95Ms: values['p(95)'], p99Ms: values['p(99)'], maxMs: values.max,
        meets500MsP95: values['p(95)'] < result.targets.apiP95Ms };
    });
    result.phases.push({ name, users, durationSeconds: 60, requests,
      approximateRequestsPerSecond: requests / 60, failureRate, checkRate, endpoints });
    console.log(`${name}: ${requests} requests, ${format(requests / 60)} req/s, ${format(failureRate * 100)}% HTTP failures.`);
  }
  result.totalRequests = metric(summary, 'http_reqs')?.count;
  result.measuredRequests = result.phases.reduce((total, phase) => total + phase.requests, 0);
  result.warmupRequests = result.totalRequests - result.measuredRequests;
  result.overallFailureRate = metric(summary, 'http_req_failed')?.rate;
  result.overallCheckRate = metric(summary, 'checks')?.rate;
  result.thresholdsMet = result.phases.every(phase => phase.failureRate < result.targets.httpFailureRateBelow &&
    phase.checkRate > result.targets.applicationCheckRateAbove &&
    phase.endpoints.every(endpoint => endpoint.meets500MsP95));
  result.status = result.thresholdsMet ? 'passed' : 'target_not_met';
} catch (error) {
  result.status = 'execution_failed';
  result.error = error.message.split('\n')[0];
  console.error(result.error);
} finally {
  result.completedAt = new Date().toISOString();
  await writeFile(path.join(output, 'result.json'), JSON.stringify(result, null, 2));
  const rows = result.phases.flatMap(phase => phase.endpoints.map(endpoint =>
    `| ${phase.name} (${phase.users} users) | ${endpoint.endpoint} | ${format(endpoint.averageMs)} | ${format(endpoint.p95Ms)} | ${endpoint.meets500MsP95 ? 'Met' : 'Not met'} |`));
  await writeFile(path.join(output, 'report.md'), `# ChargeSync sustained API performance test\n\n` +
    `Status: **${result.status}**. Started: ${result.startedAt}. Completed: ${result.completedAt}.\n\n` +
    `${result.environment}. ${result.workload}.\n\n` +
    `Measured requests: **${result.measuredRequests ?? 'not measured'}**; warm-up requests: **${result.warmupRequests ?? 'not measured'}**; total requests: **${result.totalRequests ?? 'not measured'}**. Overall HTTP failure rate: **${format((result.overallFailureRate ?? 0) * 100)}%**; application check rate: **${format((result.overallCheckRate ?? 0) * 100)}%**.\n\n` +
    `| Phase | Endpoint | Average (ms) | p95 (ms) | 500 ms SRS target |\n|---|---|---:|---:|---|\n${rows.join('\n')}\n\n` +
    result.phases.map(phase => `- ${phase.name}: ${phase.users} users, ${phase.requests} requests in 60 seconds, approximately ${format(phase.approximateRequestsPerSecond)} req/s; HTTP failures ${format(phase.failureRate * 100)}%; response checks ${format(phase.checkRate * 100)}%.`).join('\n') + '\n\n' +
    `The 500 ms p95 target is from the ChargeSync group SRS for standard API calls. The <1% failure and >99% response-check criteria are team criteria. These are read-only GET requests using one test driver. The three phases are sequential; results do not measure writes, full E2E journey time, long-term capacity, or frontend rendering. Raw k6 metrics are in k6-summary.json.\n` +
    (result.error ? `\nExecution error: ${result.error}\n` : ''));
  console.log(`Sustained performance result: ${result.status}. Evidence: ${output}`);
}
process.exitCode = result.status === 'passed' ? 0 : 1;
