$ErrorActionPreference = "Stop"

if(-not $IsWindows) {
    Write-Error 'Not supported platform.'
}

function Reset-SysTray {
    Stop-Process -Name 'explorer' -Force

    Remove-Item 'HKCU:\Control Panel\NotifyIconSettings' -Recurse -Force `
        -ErrorAction SilentlyContinue

    Remove-ItemProperty `
        'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify\' `
        -Name 'IconStreams','PastIconsStream' -ErrorAction SilentlyContinue

    Start-Process 'explorer'
}

Set-Alias rstray Reset-SysTray

