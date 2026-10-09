param([switch]$SkipAI, [switch]$Sustained)
$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
Push-Location $repoPath
try {
    if ($Sustained) {
        & node performance/run-sustained.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Sustained performance target was not met or execution failed. See performance/artifacts for measured results.' }
        return
    }
    & dotnet build backend/tools/PerformanceProbe/PerformanceProbe.csproj --configuration Release --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Could not build the database performance probe.' }
    $arguments = @('performance/run.mjs')
    if ($SkipAI) { $arguments += '--skip-ai' }
    & node @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Performance checks failed. See the saved report for measured results.' }
}
finally { Pop-Location }
