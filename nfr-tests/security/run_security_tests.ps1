# ChargeSync Platform - Automated OWASP Security Testing PowerShell Runner
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
python (Join-Path $scriptDir "run_security_tests.py")
