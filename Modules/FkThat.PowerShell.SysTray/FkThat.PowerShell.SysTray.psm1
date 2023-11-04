$ErrorActionPreference = Stop

function Reset-SysTray {
    Stop-Process -Name 'explorer.exe' -Force

    Remove-Item 'HKCU:\Control Panel\NotifyIconSettings' -Recurse -Force

    Remove-ItemProperty `
        'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify\' `
        -Name 'IconStreams','PastIconsStream' -ErrorAction SilentlyContinue

    Restart-Computer
}
