@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\create-desktop-shortcut.ps1"
if errorlevel 1 (
  echo.
  echo Desktop shortcut creation did not finish.
  pause
  exit /b 1
)
echo.
echo Desktop shortcut created. Drag video files onto the mpv_r shortcut to open them.
pause
