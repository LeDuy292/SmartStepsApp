@echo off
setlocal

title SmartSteps Frontend
cd /d "%~dp0Frontend"

set "FLUTTER_CMD="
for /f "delims=" %%F in ('where flutter 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%F"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"

if not defined FLUTTER_CMD (
  echo Flutter was not found in PATH or %USERPROFILE%\flutter\bin.
  pause
  exit /b 1
)

echo Starting SmartSteps Frontend at http://localhost:3000...
echo Backend must be available at http://localhost:8080.
echo Press Ctrl+C to stop.
echo.

call "%FLUTTER_CMD%" run -d chrome --web-port=3000 ^
  --dart-define=SMARTSTEPS_API_BASE_URL=http://localhost:8080

if errorlevel 1 (
  echo.
  echo Frontend failed to start.
  pause
)

endlocal
