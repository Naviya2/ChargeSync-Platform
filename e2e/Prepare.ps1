param([switch]$CheckConfigOnly, [switch]$KeepJwtKey)
$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
$settingsPath = Join-Path $PSScriptRoot 'settings.local.json'
$runtimePath = Join-Path $PSScriptRoot 'runtime.local.json'
$projectPath = Join-Path $repoPath 'backend/tools/E2EFixture/E2EFixture.csproj'
$mode = if ($CheckConfigOnly) { 'check-config' } else { 'prepare' }
$fixtureArguments = @($mode, $settingsPath, $runtimePath)
if ($KeepJwtKey) {
    if ($CheckConfigOnly) { throw 'KeepJwtKey applies only when preparing fresh fixtures.' }
    $fixtureArguments += '--keep-jwt'
}
& dotnet run --project $projectPath --configuration Release -- @fixtureArguments
if ($LASTEXITCODE -ne 0) { throw 'E2E preparation did not finish. See the message above.' }
