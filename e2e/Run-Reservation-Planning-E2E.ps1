# ==============================================================================
# Forwarding Runner for Reservation & AI Planning E2E Tests
# Delegates to .\e2e\reservation_e2e\Run-Reservation-Planning-E2E.ps1
# ==============================================================================

param(
    [string]$ApiUrl = "http://localhost:5035",
    [string]$WebUrl = "http://localhost:5173",
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432",
    [string]$DbName = "ChargeSync-Test"
)

$targetScript = Join-Path $PSScriptRoot "reservation_e2e\Run-Reservation-Planning-E2E.ps1"
& $targetScript -ApiUrl $ApiUrl -WebUrl $WebUrl -DbHost $DbHost -DbPort $DbPort -DbName $DbName
