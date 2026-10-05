import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServer } from 'node:http';
import { randomBytes } from 'node:crypto';
import { spawn, execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
import { chromium } from 'playwright';
import { install, Browser } from '@puppeteer/browsers';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.dirname(here);
const api = 'http://127.0.0.1:5036';
const portal = 'http://127.0.0.1:5174';
const runtime = JSON.parse(await readFile(path.join(here, 'runtime.local.json'), 'utf8'));
const settings = JSON.parse(await readFile(path.join(here, 'settings.local.json'), 'utf8'));
const token = randomBytes(32).toString('hex');
const artifacts = path.join(here, 'artifacts', `${runtime.runId}-${Date.now()}`);
await mkdir(artifacts, { recursive: true });
const children = new Set();
let browser, page, server, driverToken, adminToken;
let reviewState = { status: 'waiting' }, outcome;
const checks = [];
const startedAt = new Date().toISOString();
const secrets = [token, runtime.jwtKey, runtime.driver.password, runtime.owner.password,
  runtime.admin.password, settings.agentServiceApiKey, settings.postgresConnection];
const safe = value => secrets.filter(Boolean).reduce((text, secret) => text.split(secret).join('[redacted]'), String(value));
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const record = description => { checks.push(description); console.log(`PASS: ${description}`); };

async function command(file, args, cwd = repo) {
  return new Promise((resolve, reject) => {
    const child = spawn(file, args, { cwd, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
    children.add(child);
    const timeout = setTimeout(() => {
      stopChild(child);
      reject(new Error(`${path.basename(file)} exceeded the 15-minute E2E command limit.`));
    }, 15 * 60 * 1000);
    child.stdout.on('data', data => process.stdout.write(safe(data.toString())));
    child.stderr.on('data', data => process.stderr.write(safe(data.toString())));
    child.on('error', error => { clearTimeout(timeout); reject(error); });
    child.on('exit', code => {
      children.delete(child);
      clearTimeout(timeout);
      code === 0 ? resolve() : reject(new Error(`${path.basename(file)} exited with code ${code}.`));
    });
  });
}

function stopChild(child) {
  if (!child.pid || child.exitCode !== null) return;
  try {
    if (process.platform === 'win32') execFileSync('taskkill.exe', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore', windowsHide: true });
    else child.kill('SIGTERM');
  } catch { /* process already stopped */ }
}

async function request(route, authToken, body, expected = 200, base = api) {
  const response = await fetch(base + route, {
    method: body === undefined ? 'GET' : 'POST',
    headers: { 'Content-Type': 'application/json', ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    signal: AbortSignal.timeout(30000),
  });
  // Never include login payloads, credentials or raw response bodies in evidence.
  assert.equal(response.status, expected, `${route} returned HTTP ${response.status}; expected ${expected}`);
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function login(account) {
  const result = await request('/api/auth/login', undefined, { email: account.email, password: account.password });
  const claims = JSON.parse(Buffer.from(result.accessToken.split('.')[1], 'base64url').toString());
  assert.equal(claims.iss, 'ChargeSyncE2E', 'API is not the isolated E2E instance.');
  assert.equal(claims.sub, account.id);
  secrets.push(result.accessToken, result.refreshToken);
  return result.accessToken;
}

async function review(input) {
  assert.match(input.ticketId, /^[a-f0-9-]{36}$/i);
  const ticket = await request(`/api/support-tickets/${input.ticketId}`, adminToken);
  assert.equal(ticket.driverId, runtime.driver.id);
  assert.equal(ticket.invoiceId, input.invoiceId);
  assert.equal(ticket.subject, `E2E refund ${runtime.runId}`);
  const deadline = Date.now() + 180000;
  let snapshot;
  console.log('Waiting for the real AI workflow and backend validation…');
  while (Date.now() < deadline) {
    snapshot = await request(`/api/agent-workflows/support-ticket/${ticket.id}`, adminToken);
    if (snapshot.workflow.status === 'Failed') {
      throw new Error('Real AI workflow failed. Check the Python terminal and internal service key/provider configuration.');
    }
    if (snapshot.workflow.status === 'PendingApproval') break;
    await sleep(2000);
  }
  assert.equal(snapshot.workflow.status, 'PendingApproval', 'AI workflow did not reach PendingApproval.');
  assert.equal(snapshot.workflow.action, 'Refund');
  assert.equal(snapshot.workflow.amount, 20);
  assert.equal(snapshot.workflow.approvalRequired, true);
  assert.ok(snapshot.workflow.analysis?.suggestion, 'Missing structured AI suggestion.');
  assert.ok(snapshot.workflow.analysis?.completedSteps?.length, 'Missing AI execution steps.');
  assert.ok(snapshot.workflow.validationResults?.length, 'Missing backend validation results.');
  record('Real AI returned structured analysis; backend requires approval for LKR 20 refund');
  const walletBefore = await request('/api/wallet', driverToken);
  assert.equal(walletBefore.balance, input.beforeRefund);
  record('AI analysis alone did not credit the wallet');

  browser = await chromium.launch({ channel: 'chrome', headless: false });
  page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  page.setDefaultTimeout(30000);
  page.on('dialog', dialog => dialog.accept());
  await page.goto(portal + '/login');
  await page.getByLabel('Work email').fill(runtime.admin.email);
  await page.getByLabel('Password', { exact: true }).fill(runtime.admin.password);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await page.waitForURL('**/dashboard');
  await page.goto(portal + '/support');
  await page.getByLabel('Search tickets', { exact: true }).fill(input.subject);
  await page.getByRole('button').filter({ has: page.getByRole('heading', { name: input.subject, exact: true }) }).click();
  await page.locator('summary').filter({ hasText: 'Analysis & validation' }).click();
  const panel = page.locator('section').filter({ has: page.getByRole('heading', { name: 'Agent workflow', exact: true }) });
  await panel.getByRole('status').filter({ hasText: 'Pending Approval' }).waitFor();
  await panel.getByLabel('Workflow review note').fill('E2E: reviewed paid invoice, refund amount and unchanged wallet before approval.');
  await page.screenshot({ path: path.join(artifacts, 'react-pending-approval.png'), fullPage: true });
  await panel.screenshot({ path: path.join(artifacts, 'react-pending-approval-detail.png') });
  const approvalResponse = page.waitForResponse(response =>
    response.url().endsWith(`/api/agent-workflows/${snapshot.workflow.id}/approve`) && response.request().method() === 'POST');
  await panel.getByRole('button', { name: 'Approve', exact: true }).click();
  assert.equal((await approvalResponse).status(), 200, 'React approval failed.');
  await panel.getByRole('status').filter({ hasText: 'Completed' }).waitFor();
  await page.screenshot({ path: path.join(artifacts, 'react-refund-approved.png'), fullPage: true });
  await panel.screenshot({ path: path.join(artifacts, 'react-refund-approved-detail.png') });
  record('Admin approved the pending refund through the real React interface');
  const completed = await request(`/api/agent-workflows/support-ticket/${ticket.id}`, adminToken);
  assert.equal(completed.workflow.status, 'Completed');
  assert.equal(completed.workflow.decision, 'Approved');
  assert.equal((await request('/api/wallet', driverToken)).balance, input.beforeRefund + 20);
  // A second approval with the old version must be rejected and cannot double-credit.
  await request(`/api/agent-workflows/${snapshot.workflow.id}/approve`, adminToken,
    { version: snapshot.version, note: 'E2E duplicate approval check' }, 409);
  assert.equal((await request('/api/wallet', driverToken)).balance, input.beforeRefund + 20);
  record('Duplicate approval rejected; wallet credited exactly once');
  reviewState = { status: 'approved' };
}

try {
  const fixture = path.join(repo, 'backend/tools/E2EFixture/bin/Release/net8.0/E2EFixture.dll');
  assert.ok(existsSync(fixture), 'Build/prepare the E2E fixture first.');
  await command('dotnet', [fixture, 'validate', path.join(here, 'settings.local.json'), path.join(here, 'runtime.local.json')]);
  assert.ok((await fetch(portal, { signal: AbortSignal.timeout(5000) })).ok, 'Start-Web.ps1 is not running.');
  assert.ok((await fetch(settings.agentServiceUrl + '/health', { signal: AbortSignal.timeout(5000) })).ok,
    'Start the real Python AI service before running E2E.');
  driverToken = await login(runtime.driver);
  adminToken = await login(runtime.admin);
  const me = await request('/api/auth/me', adminToken, undefined, 200, portal);
  assert.equal(me.id, runtime.admin.id, 'React proxy is not connected to the E2E API.');
  const invoices = await request('/api/payments/invoices', driverToken);
  const bookings = await request('/api/reservations', driverToken);
  assert.equal(invoices.length, 0, 'Fixture already used. Prepare fresh accounts, then restart the E2E backend.');
  assert.equal((bookings.items ?? bookings.value ?? []).length, 0, 'Fixture already has reservations.');
  assert.equal((await request('/api/wallet', driverToken)).balance, runtime.initialWalletBalance);
  record('Isolated API, React proxy, Python service and fresh funded driver verified');

  server = createServer(async (req, res) => {
    const origin = req.headers.origin;
    if (origin && !/^http:\/\/(localhost|127\.0\.0\.1):7357$/.test(origin)) {
      res.writeHead(403).end(); return;
    }
    if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-E2E-Token');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Cache-Control', 'no-store');
    if (req.method === 'OPTIONS') { res.writeHead(204).end(); return; }
    if (req.headers['x-e2e-token'] !== token) { res.writeHead(403).end(); return; }
    const send = data => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(data)); };
    try {
      if (req.url === '/config' && req.method === 'GET') {
        console.log('Flutter requested its isolated fixture configuration.');
        send({ runId: runtime.runId, apiUrl: api, driver: runtime.driver, owner: runtime.owner,
          chargerId: runtime.chargerId, vehicleId: runtime.vehicleId, initialWalletBalance: runtime.initialWalletBalance });
      } else if (req.url === '/status' && req.method === 'GET') { send(reviewState); }
      else if (['/review', '/complete'].includes(req.url) && req.method === 'POST') {
        let body = '';
        for await (const chunk of req) {
          body += chunk;
          if (body.length > 10000) throw new Error('Coordinator payload too large.');
        }
        const input = JSON.parse(body);
        if (req.url === '/review') {
          assert.equal(reviewState.status, 'waiting', 'Review was already requested.');
          reviewState = { status: 'reviewing' };
          review(input).catch(async error => {
            reviewState = { status: 'failed', error: safe(error.message) };
            if (page) await page.screenshot({ path: path.join(artifacts, 'react-failure.png'), fullPage: true }).catch(() => {});
          });
        } else {
          assert.equal(reviewState.status, 'approved');
          outcome = input;
        }
        send({ accepted: true });
      } else { res.writeHead(404).end(); }
    } catch (error) { res.writeHead(400); send({ error: safe(error.message) }); }
  });
  await new Promise((resolve, reject) => { server.once('error', reject); server.listen(4567, '127.0.0.1', resolve); });
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const version = execFileSync('powershell.exe', ['-NoProfile', '-Command',
    `(Get-Item -LiteralPath '${chromePath}').VersionInfo.ProductVersion`], { encoding: 'utf8', windowsHide: true }).trim();
  assert.match(version, /^\d+\.\d+\.\d+\.\d+$/);
  console.log(`Preparing ChromeDriver for Chrome ${version}…`);
  const installed = await install({ browser: Browser.CHROMEDRIVER, buildId: version, cacheDir: path.join(here, '.browsers') });
  const driver = spawn(installed.executablePath, ['--port=4444'], { stdio: 'ignore', windowsHide: true });
  children.add(driver);
  driver.on('error', error => { reviewState = { status: 'failed', error: safe(error.message) }; });
  let ready = false;
  for (let i = 0; i < 30; i++) {
    try { ready = (await fetch('http://127.0.0.1:4444/status')).ok; } catch { /* starting */ }
    if (ready) break;
    await sleep(500);
  }
  assert.ok(ready, 'ChromeDriver did not start on port 4444.');
  console.log('Running Flutter Chrome checkout and support workflow…');
  await command('cmd.exe', ['/d', '/s', '/c',
    `flutter drive --no-pub --driver=test_driver/integration_test.dart --target=integration_test/student4_live_workflow_test.dart -d web-server --no-headless --browser-name=chrome --browser-dimension=1440,1000 --web-port=7357 --dart-define=E2E_BRIDGE_TOKEN=${token}`], path.join(repo, 'mobile-flutter'));
  assert.ok(outcome, 'Flutter did not complete all refund assertions.');
  await writeFile(path.join(artifacts, 'outcome.json'), JSON.stringify(outcome, null, 2));
  await command('dotnet', [fixture, 'verify', path.join(here, 'settings.local.json'), path.join(here, 'runtime.local.json'), path.join(artifacts, 'outcome.json')]);
  record('PostgreSQL persisted the completed session, invoice, approved workflow and exact wallet balance');
  await writeFile(path.join(artifacts, 'result.json'), JSON.stringify({ status: 'passed', runId: runtime.runId,
    startedAt, completedAt: new Date().toISOString(), checks, ...outcome }, null, 2));
  console.log(`E2E PASSED. Evidence: ${artifacts}`);
} catch (error) {
  const message = safe(error.message);
  await writeFile(path.join(artifacts, 'result.json'), JSON.stringify({ status: 'failed', runId: runtime.runId, startedAt, checks, error: message }, null, 2));
  console.error(`E2E FAILED: ${message}`);
  process.exitCode = 1;
} finally {
  await browser?.close();
  server?.close();
  for (const child of children) stopChild(child);
}
