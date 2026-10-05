# ChargeSync Platform - Database Test Suite PowerShell Runner
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
python (Join-Path $scriptDir "run_database_tests.py")
