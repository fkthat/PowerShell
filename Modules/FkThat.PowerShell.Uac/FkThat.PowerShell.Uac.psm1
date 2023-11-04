$ErrorActionPreference = "Stop"

function Test-ElevatedUser {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $elevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Output $elevated
}
