$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
$settingsPath = Join-Path $PSScriptRoot 'settings.local.json'
$runtimePath = Join-Path $PSScriptRoot 'runtime.local.json'
& dotnet run --project (Join-Path $repoPath 'backend/tools/E2EFixture/E2EFixture.csproj') --configuration Release -- validate $settingsPath $runtimePath
if ($LASTEXITCODE -ne 0) { throw 'The isolated E2E database has not been verified.' }
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$runtime = Get-Content -LiteralPath $runtimePath -Raw | ConvertFrom-Json
if (!$settings.agentServiceApiKey -or $settings.agentServiceApiKey.StartsWith('REPLACE')) {
    throw 'Set agentServiceApiKey in settings.local.json to the value of AGENT_SERVICE_API_KEY used by Python.'
}
if ($settings.agentServiceUrl -notmatch '^http://(127\.0\.0\.1|localhost):[0-9]+/?$') {
    throw 'Set agentServiceUrl to your local Python service URL.'
}
$overrides = @{
    ConnectionStrings__Postgres = $settings.postgresConnection
    Jwt__Key = $runtime.jwtKey
    Jwt__Issuer = 'ChargeSyncE2E'
    Jwt__Audience = 'ChargeSyncE2E'
    AGENT_SERVICE_BASE_URL = $settings.agentServiceUrl
    AGENT_SERVICE_API_KEY = $settings.agentServiceApiKey
    # The seeder skips these existing emails. Empty environment values on Windows
    # can remove an override and accidentally fall back to normal app settings.
    Seed__AdminEmail = $runtime.admin.email
    Seed__AdminPassword = $runtime.admin.password
    Seed__SupportManagerEmail = $runtime.admin.email
    Seed__SupportManagerPassword = $runtime.admin.password
    ASPNETCORE_ENVIRONMENT = 'Development'
    ASPNETCORE_URLS = 'http://127.0.0.1:5036'
}
$original = @{}
foreach ($key in $overrides.Keys) {
    $original[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
    [Environment]::SetEnvironmentVariable($key, $overrides[$key], 'Process')
}
try {
    Write-Host 'Starting the isolated E2E API on port 5036. Stop with Ctrl+C.'
    & dotnet run --project (Join-Path $repoPath 'backend/src/API/Api.csproj') --configuration Release --no-launch-profile
    if ($LASTEXITCODE -ne 0) { throw 'The E2E backend exited with an error.' }
}
finally {
    foreach ($key in $original.Keys) { [Environment]::SetEnvironmentVariable($key, $original[$key], 'Process') }
}
