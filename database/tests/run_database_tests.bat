@echo off
setlocal
title ChargeSync Database Tests

REM Check if Python is available in PATH
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo Python was not found in PATH.
    echo Trying user AppData path...
    if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" "%~dp0run_database_tests.py"
    ) else (
        echo Could not find python.exe. Please run the tests from your terminal:
        echo python database/tests/run_database_tests.py
    )
) else (
    python "%~dp0run_database_tests.py"
)

echo.
echo =====================================================================
echo Execution finished. Press any key to close this window.
echo =====================================================================
pause >nul
