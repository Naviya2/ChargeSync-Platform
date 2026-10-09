# ==============================================================================
# ChargeSync Platform - Reservation & AI Planning E2E Runner (PowerShell)
# Runs the automated E2E test against local ASP.NET Core API (:5035),
# React Web Portal (:5173), and local PostgreSQL (localhost:5432 / ChargeSync-Test).
# ==============================================================================

param(
    [string]$ApiUrl = "http://localhost:5035",
    [string]$WebUrl = "http://localhost:5173",
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432",
    [string]$DbName = "ChargeSync-Test"
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " [RUNNER] Launching Reservation & AI Charging Planning E2E Suite" -ForegroundColor Cyan
Write-Host " Target API      : $ApiUrl" -ForegroundColor Gray
Write-Host " Target Web UI   : $WebUrl" -ForegroundColor Gray
Write-Host " Target Database : $DbName on $DbHost`:$DbPort" -ForegroundColor Gray
Write-Host "================================================================================" -ForegroundColor Cyan

Push-Location $PSScriptRoot
try {
    $env:API_URL = $ApiUrl
    $env:WEB_URL = $WebUrl
    $env:DB_HOST = $DbHost
    $env:DB_PORT = $DbPort
    $env:DB_NAME = $DbName
    $env:PGPASSWORD = "navi18572"

    & node run_reservation_planning_e2e.mjs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "E2E Test Execution finished with errors."
    }
}
finally {
    Pop-Location
}
