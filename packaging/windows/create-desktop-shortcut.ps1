# Creates a current-user Desktop shortcut without changing Windows defaults.

$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$launcherPath = Join-Path $packageRoot 'mpv_r.exe'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "mpv_r.exe was not found next to this package's tools folder. Keep the extracted mpv_r folder together."
}

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'mpv_r.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcherPath
$shortcut.WorkingDirectory = $packageRoot
$shortcut.IconLocation = "$launcherPath,0"
$shortcut.Description = 'mpv_r video review player'
$shortcut.Save()

Write-Host "Created: $shortcutPath"
