@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Invoke-eMASPreSalesAssessment.ps1"
set EXITCODE=%ERRORLEVEL%
echo.
if not "%EXITCODE%"=="0" echo eMAS Pre-Sales collection ended with error code %EXITCODE%.
pause
exit /b %EXITCODE%
