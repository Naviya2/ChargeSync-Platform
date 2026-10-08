import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import assert from 'node:assert/strict';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.dirname(here);
const settingsPath = path.join(repo, 'e2e/settings.local.json');
const runtimePath = path.join(repo, 'e2e/runtime.local.json');
const runtime = JSON.parse(await readFile(runtimePath, 'utf8'));
const settings = JSON.parse(await readFile(settingsPath, 'utf8'));
const output = path.join(here, 'artifacts', new Date().toISOString().replace(/[:.]/g, '-'));
await mkdir(output, { recursive: true });
const result = {
  startedAt: new Date().toISOString(), status: 'running', fixtureRunId: runtime.runId,
  environment: 'Local Release ASP.NET Core :5036; separate cloud Supabase; local Python AI',
  scope: 'Minimal baseline; 9 API load requests, 9 EXPLAIN ANALYZE measurements, 2 concurrent real AI requests. Additional authentication, database validation and row-count queries.',
  targets: { apiP95Ms: 2000, apiFailureRateBelow: .01, applicationCheckRateAbove: .99, databaseServerMs: 100, aiRequestMs: 60000 },
  targetSource: 'Proposed team targets; not specified by the assignment.', api: [], ai: [],
};
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function executable(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const name = path.join(dir, entry.name);
    if (entry.isFile() && entry.name === 'k6.exe') return name;
    if (entry.isDirectory()) { const found = await executable(name); if (found) return found; }
  }
}
async function command(file, args, extraEnv = {}) {
  await new Promise((resolve, reject) => {
    const child = spawn(file, args, { cwd: repo, windowsHide: true,
      env: { ...process.env, ...extraEnv }, stdio: ['ignore', 'pipe', 'pipe'] });
    // Do not forward arbitrary child output: no connection strings or tokens in evidence.
    let diagnostic = '';
    child.stdout.on('data', data => { diagnostic += data.toString(); });
    child.stderr.on('data', data => { diagnostic += data.toString(); });
    const timer = setTimeout(() => { child.kill(); reject(new Error(`${path.basename(file)} timed out.`)); }, 120000);
    child.on('error', error => { clearTimeout(timer); reject(new Error(`Cannot launch ${path.basename(file)}: ${error.code}`)); });
    child.on('exit', code => {
      clearTimeout(timer);
      // k6 exits 99 when measurement thresholds fail. Preserve those actual results.
      if (code === 0 || path.basename(file) === 'k6.exe' && code === 99) resolve();
      else reject(new Error(`${path.basename(file)} exited ${code}. Credentials and raw diagnostics withheld.`));
    });
  });
}
async function login() {
  const response = await fetch('http://127.0.0.1:5036/api/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: runtime.driver.email, password: runtime.driver.password }),
    signal: AbortSignal.timeout(20000),
  });
  assert.equal(response.status, 200, 'E2E driver login failed.');
  const data = await response.json();
  const claims = JSON.parse(Buffer.from(data.accessToken.split('.')[1], 'base64url'));
  assert.equal(claims.iss, 'ChargeSyncE2E', 'Backend must be the isolated E2E instance.');
  assert.equal(claims.sub, runtime.driver.id, 'Backend must use the prepared test driver.');
  return data.accessToken;
}
async function measureAI(index) {
  const workflowId = randomUUID();
  const input = {
    workflowId, revision: 1, objective: 'Review this test technical support request and provide read-only advice.',
    ticket: { id: randomUUID(), driverId: runtime.driver.id, subject: `Performance baseline ${index}`,
      description: 'The charging screen is slow to refresh. Please suggest troubleshooting steps. This is a test request; no refund or account changes are requested.',
      category: 'Technical', priority: 'Medium', messages: [], invoiceId: null, requestedRefundAmount: null, refundStatus: 'NotRequested' },
    session: null, invoice: null, loyalty: null,
    validationResults: [{ code: 'NO_LINKED_INVOICE', outcome: 'Info', message: 'No linked invoice; billing checks were not performed.' }],
    approvalRequired: false, action: 'None', revisionNote: null,
  };
  const start = performance.now();
  const measurement = { index, workflowId, success: false };
  try {
    const response = await fetch(settings.agentServiceUrl.replace(/\/$/, '') + '/api/workflows/support', {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Agent-Service-Key': settings.agentServiceApiKey },
      body: JSON.stringify(input), signal: AbortSignal.timeout(65000),
    });
    measurement.httpStatus = response.status;
    const text = await response.text();
    measurement.responseMs = performance.now() - start;
    if (response.status !== 200) throw new Error(`HTTP ${response.status}`);
    const data = JSON.parse(text);
    assert.equal(data.workflowId, workflowId);
    assert.equal(data.revision, 1);
    assert.ok(data.plan?.length && data.completedSteps?.length && data.toolResults?.length);
    assert.ok(typeof data.suggestion?.draftReply === 'string' && data.suggestion.draftReply.trim());
    assert.ok(data.completedSteps.every(s => Number.isFinite(Date.parse(s.startedAt)) && Date.parse(s.completedAt) >= Date.parse(s.startedAt)));
    measurement.steps = data.completedSteps.map(s => ({ agent: s.agent, step: s.step,
      elapsedMs: Date.parse(s.completedAt) - Date.parse(s.startedAt) }));
    measurement.success = true;
  } catch (error) {
    measurement.responseMs ??= performance.now() - start;
    measurement.error = error.name === 'AssertionError' ? 'Structured output check failed' :
      /^HTTP \d+$/.test(error.message) ? error.message : `${error.name}: request or output failed`;
  }
  measurement.meetsTarget = measurement.success && measurement.responseMs < result.targets.aiRequestMs;
  return measurement;
}
const ms = number => Number(number).toFixed(2);
try {
  assert.equal(settings.disposableDatabase, true, 'Only the disposable E2E database is allowed.');
  assert.match(settings.agentServiceUrl, /^http:\/\/(127\.0\.0\.1|localhost):\d+\/?$/);
  await command('dotnet', [path.join(repo, 'backend/tools/E2EFixture/bin/Release/net8.0/E2EFixture.dll'), 'validate', settingsPath, runtimePath]);
  const token = await login();
  const k6 = await executable(path.join(here, '.tools'));
  assert.ok(k6, 'Portable k6.exe missing from performance/.tools.');
  console.log('Verified isolated E2E backend and database. Starting minimal API test.');
  for (const users of [1, 2]) {
    const summaryPath = path.join(output, `api-${users}-users.json`);
    await command(k6, ['run', '--quiet', path.join(here, 'api-load.js')],
      { PERF_TOKEN: token, PERF_USERS: String(users), PERF_SUMMARY: summaryPath, K6_NO_USAGE_REPORT: 'true' });
    const summary = JSON.parse(await readFile(summaryPath, 'utf8'));
    const metrics = summary.metrics;
    const endpoints = ['stations', 'wallet', 'payment-history'].map(endpoint => ({ endpoint,
      ...metrics[`http_req_duration{endpoint:${endpoint}}`].values }));
    const thresholdsPassed = Object.values(metrics).every(metric => Object.values(metric.thresholds || {}).every(t => t.ok));
    const entry = { users, requests: metrics.http_reqs.values.count, failedRequests: metrics.http_req_failed.values.passes,
      failureRate: metrics.http_req_failed.values.rate, checkRate: metrics.checks.values.rate,
      requestsPerSecond: metrics.http_reqs.values.rate, endpoints, thresholdsPassed };
    assert.equal(entry.requests, users * 3, 'Unexpected API request count.');
    result.api.push(entry);
    console.log(`${users} concurrent user(s): ${entry.requests} requests, ${ms(entry.failureRate * 100)}% HTTP failures; thresholds ${thresholdsPassed ? 'PASS' : 'FAIL'}.`);
  }
  console.log('Measuring read-only PostgreSQL queries.');
  await command('dotnet', [path.join(repo, 'backend/tools/PerformanceProbe/bin/Release/net8.0/PerformanceProbe.dll'),
    settingsPath, runtimePath, path.join(output, 'database.json')]);
  result.database = JSON.parse(await readFile(path.join(output, 'database.json'), 'utf8'));
  result.database.meetsTarget = result.database.queries.every(q => q.serverExecutionMs.maximum < result.targets.databaseServerMs && q.firstServerMs < result.targets.databaseServerMs);
  if (!process.argv.includes('--skip-ai')) {
    console.log('Sending exactly two concurrent requests to the real Python AI workflow endpoint; no tickets or financial changes are persisted.');
    // Small stagger still permits overlap while avoiding a burst at the exact same millisecond.
    result.ai = await Promise.all([measureAI(1), (async () => { await sleep(100); return measureAI(2); })()]);
    for (const item of result.ai) console.log(`AI ${item.index}: ${ms(item.responseMs)} ms; ${item.success ? 'valid structured response' : item.error}; target ${item.meetsTarget ? 'PASS' : 'FAIL'}.`);
  } else { result.aiSkipped = true; }
  result.status = result.api.every(run => run.thresholdsPassed) && result.database.meetsTarget &&
    !result.aiSkipped && result.ai.every(run => run.meetsTarget) ? 'passed' : result.aiSkipped ? 'partial' : 'failed';
} catch (error) {
  result.status = 'failed';
  result.error = error.name === 'AssertionError' ? error.message.split('\n')[0] :
    /^(k6.exe|dotnet|Cannot launch)/.test(error.message) ? error.message : `${error.name}: setup or request failed. Check the running test services.`;
  console.error(result.error);
} finally {
  result.completedAt = new Date().toISOString();
  await writeFile(path.join(output, 'result.json'), JSON.stringify(result, null, 2));
  const rows = result.api.flatMap(run => run.endpoints.map(e => `| API ${e.endpoint} | ${run.users} user(s) | ${ms(e.avg)} ms average | ${ms(e['p(95)'])} ms p95 | ${ms(run.failureRate * 100)}% HTTP failures (whole run) |`));
  for (const q of result.database?.queries || []) rows.push(`| DB ${q.name} (${q.tableRows} table rows) | 3 executions | ${ms(q.serverExecutionMs.average)} ms warm server average | ${ms(q.clientRoundTripMs.average)} ms warm client round trip | First server: ${ms(q.firstServerMs)} ms |`);
  for (const ai of result.ai) rows.push(`| AI analysis ${ai.index} | 2 overlapping requests | ${ms(ai.responseMs)} ms | Structured output: ${ai.success ? 'PASS' : 'FAIL'} | Target: ${ai.meetsTarget ? 'PASS' : 'FAIL'} |`);
  await writeFile(path.join(output, 'report.md'), `# ChargeSync minimal performance baseline\n\nMeasured ${result.startedAt}. Status: **${result.status}**.\n\n${result.scope}\n\n| Test | Load | Measurement | Measurement | Result |\n|---|---|---|---|---|\n${rows.join('\n')}\n\nTargets are team proposals, not assignment requirements. API p95 < 2000 ms; HTTP failure rate < 1%; checks > 99%; every database server observation < 100 ms; each AI response < 60 s.\n\nThis small sample cannot establish capacity, a statistically reliable p95, or an operational error rate. The shared test driver is used for authenticated reads. DB measurements are sequential with a persistent connection; round-trip timings include cloud network and EXPLAIN overhead. AI uses the real provider with synthetic technical-support snapshots through Python; no backend queue, frontend or human approval time is included. No refund, payment or reservation writes occur. AI calls are not retried by this runner.\n\n${result.error ? `Failure: ${result.error}\n` : ''}`);
  console.log(`Performance result: ${result.status}. Evidence: ${output}`);
}
process.exitCode = result.status === 'passed' ? 0 : 1;
