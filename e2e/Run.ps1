$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    if (!(Test-Path -LiteralPath 'node_modules/playwright')) {
        throw 'Run npm.cmd install inside the e2e folder first.'
    }
    & node run.mjs
    if ($LASTEXITCODE -ne 0) { throw 'The complete E2E test did not pass. Read the failure above.' }
}
finally { Pop-Location }
