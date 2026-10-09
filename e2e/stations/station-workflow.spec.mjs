import assert from 'node:assert/strict';
import { chromium } from 'playwright';
import path from 'node:path';

const portal = 'http://127.0.0.1:5174';

export async function runStationWorkflowE2E({ runtime, artifacts }) {
  console.log('Running Station & Charger Management E2E Workflow with Playwright...');
  let browser, page;
  
  try {
    browser = await chromium.launch({ channel: 'chrome', headless: false });
    page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
    page.setDefaultTimeout(30000);
    page.on('dialog', dialog => dialog.accept());

    // 1. Login as Station Owner
    await page.goto(portal + '/login');
    await page.getByLabel('Work email').fill(runtime.owner.email);
    await page.getByLabel('Password', { exact: true }).fill(runtime.owner.password);
    await page.getByRole('button', { name: 'Sign in', exact: true }).click();
    await page.waitForURL('**/dashboard');
    
    // 2. Navigate to Station Creation
    await page.waitForURL('**/dashboard');
    await page.goto(portal + '/stations/new');

    // 3. Fill Station Details
    const uniqueStationName = 'E2E Automated Station ' + Date.now();
    await page.getByLabel('Station Name').fill(uniqueStationName);
    await page.getByLabel('Address').fill('123 Test E2E Blvd');
    await page.locator('.leaflet-container').click();
    await page.locator('.leaflet-container').click();

    await page.route('**/image/upload', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ secure_url: 'https://example.com/e2e-image.png' })
      });
    });
    await page.locator('input[type="file"]').setInputFiles({
      name: 'dummy.png',
      mimeType: 'image/png',
      buffer: Buffer.from('fake image')
    });
    
    // Wait for upload to complete
    await page.waitForSelector('img[alt="Document 1"]');
    
    // Intercept the create response
    const createPromise = page.waitForResponse(response => 
      response.url().includes('/api/stations') && response.request().method() === 'POST'
    );
    
    await page.getByRole('button', { name: 'Register Station', exact: true }).click();
    await page.screenshot({ path: path.join(artifacts, 'before-register-click.png'), fullPage: true });
    
    const createRes = await createPromise;
    assert.equal(createRes.status(), 201, 'Station registration failed.');
    const stationData = await createRes.json();
    
    await page.screenshot({ path: path.join(artifacts, 'react-station-registered.png'), fullPage: true });

    // 4. Logout Owner and Login as Admin to Approve
    await page.goto(portal + '/logout');
    await page.goto(portal + '/login');
    await page.getByLabel('Work email').fill(runtime.admin.email);
    await page.getByLabel('Password', { exact: true }).fill(runtime.admin.password);
    await page.getByRole('button', { name: 'Sign in', exact: true }).click();
    await page.waitForURL('**/dashboard');
    
    // 5. Go to Pending Stations
    await page.goto(portal + '/approvals');
    await page.getByRole('heading', { name: uniqueStationName }).click();
    
    const approvePromise = page.waitForResponse(response => 
      response.url().includes(`/api/admin/stations/${stationData.id}/approve`) && response.request().method() === 'PUT'
    );
    
    await page.getByRole('button', { name: 'Approve Station', exact: true }).click();
    await approvePromise;
    
    await page.screenshot({ path: path.join(artifacts, 'react-station-approved.png'), fullPage: true });
    
    console.log('PASS: Station Onboarding Playwright E2E passed!');
    return true;
  } finally {
    if (browser) await browser.close();
  }
}
