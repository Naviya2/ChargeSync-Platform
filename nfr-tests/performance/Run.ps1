param([switch]$SkipAI)
$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
Push-Location $repoPath
try {
    & dotnet build backend/tools/PerformanceProbe/PerformanceProbe.csproj --configuration Release --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Could not build the database performance probe.' }
    $arguments = @('performance/run.mjs')
    if ($SkipAI) { $arguments += '--skip-ai' }
    & node @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Performance checks failed. See the saved report for measured results.' }
}
finally { Pop-Location }
