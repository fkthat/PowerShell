$ErrorActionPreference = "Stop"

function Reset-SysTray {
    Stop-Process -Name 'explorer' -Force

    Remove-Item 'HKCU:\Control Panel\NotifyIconSettings' -Recurse -Force `
        -ErrorAction SilentlyContinue

    Remove-ItemProperty `
        'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify\' `
        -Name 'IconStreams','PastIconsStream' -ErrorAction SilentlyContinue

    Start-Process 'explorer.exe'
}
