@echo off
setlocal

title SmartSteps Backend
cd /d "%~dp0Backend"

echo Starting SmartSteps Backend at http://localhost:8080...
echo Press Ctrl+C to stop.
echo.

dotnet run

if errorlevel 1 (
  echo.
  echo Backend failed to start.
  pause
)

endlocal
