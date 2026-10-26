@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\register-file-associations.ps1"
if errorlevel 1 (
  echo.
  echo File-association registration did not finish.
  pause
  exit /b 1
)
echo.
echo Registration complete. Choose mpv_r in Windows Default apps to make it the default.
pause
