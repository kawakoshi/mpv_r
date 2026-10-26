# Registers mpv_r for the current Windows user only. It deliberately does not
# set a default file handler: Windows owns that choice through its Default apps UI.

$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$launcherPath = Join-Path $packageRoot 'mpv_r.exe'
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "mpv_r.exe was not found next to this package's tools folder. Keep the extracted mpv_r folder together."
}

$progId = 'mpv_r.video'
$appKey = 'mpv_r'
$extensions = @('.mp4', '.m4v', '.mov', '.mkv', '.avi', '.webm')
$classesRoot = 'HKCU:\Software\Classes'
$quotedLauncher = '"' + $launcherPath + '"'

New-Item -Path "$classesRoot\$progId\DefaultIcon" -Force | Out-Null
Set-Item -Path "$classesRoot\$progId" -Value 'mpv_r video file'
Set-Item -Path "$classesRoot\$progId\DefaultIcon" -Value ($quotedLauncher + ',0')
New-Item -Path "$classesRoot\$progId\shell\open\command" -Force | Out-Null
Set-Item -Path "$classesRoot\$progId\shell\open\command" -Value ($quotedLauncher + ' "%1"')

New-Item -Path "$classesRoot\Applications\mpv_r.exe\DefaultIcon" -Force | Out-Null
Set-Item -Path "$classesRoot\Applications\mpv_r.exe" -Value 'mpv_r'
Set-Item -Path "$classesRoot\Applications\mpv_r.exe\DefaultIcon" -Value ($quotedLauncher + ',0')
New-Item -Path "$classesRoot\Applications\mpv_r.exe\shell\open\command" -Force | Out-Null
Set-Item -Path "$classesRoot\Applications\mpv_r.exe\shell\open\command" -Value ($quotedLauncher + ' "%1"')

New-Item -Path "HKCU:\Software\$appKey\Capabilities\FileAssociations" -Force | Out-Null
Set-Item -Path "HKCU:\Software\$appKey\Capabilities" -Value 'mpv_r'
New-ItemProperty -Path "HKCU:\Software\$appKey\Capabilities" -Name 'ApplicationDescription' -Value 'Video review player' -PropertyType String -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\$appKey\Capabilities" -Name 'ApplicationName' -Value 'mpv_r' -PropertyType String -Force | Out-Null
foreach ($extension in $extensions) {
    New-ItemProperty -Path "HKCU:\Software\$appKey\Capabilities\FileAssociations" -Name $extension -Value $progId -PropertyType String -Force | Out-Null
    New-Item -Path "$classesRoot\$extension\OpenWithProgids" -Force | Out-Null
    New-ItemProperty -Path "$classesRoot\$extension\OpenWithProgids" -Name $progId -Value '' -PropertyType String -Force | Out-Null
}
New-Item -Path 'HKCU:\Software\RegisteredApplications' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\Software\RegisteredApplications' -Name 'mpv_r' -Value "Software\$appKey\Capabilities" -PropertyType String -Force | Out-Null

$ie4uinit = Join-Path $env:WINDIR 'System32\ie4uinit.exe'
if (Test-Path -LiteralPath $ie4uinit -PathType Leaf) {
    Start-Process -FilePath $ie4uinit -ArgumentList '-show' -Wait
}

Write-Host 'mpv_r is now registered as an available video app for this Windows user.'
Write-Host 'Open Settings > Apps > Default apps, choose mpv_r, then assign the extensions you want.'
