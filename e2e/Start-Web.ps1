$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
$originalProxy = $env:VITE_API_PROXY_TARGET
$env:VITE_API_PROXY_TARGET = 'http://127.0.0.1:5036'
Push-Location (Join-Path $repoPath 'web-react')
try {
    Write-Host 'Starting the E2E React portal on port 5174, connected to the E2E API on 5036.'
    & npm.cmd run dev -- --host 127.0.0.1 --port 5174 --strictPort
    if ($LASTEXITCODE -ne 0) { throw 'The E2E React server exited with an error.' }
}
finally {
    Pop-Location
    $env:VITE_API_PROXY_TARGET = $originalProxy
}
