$ErrorActionPreference = "Stop"

$sudo = "$env:ProgramFiles\gsudo\Current\gsudo.exe"

function Start-AdminShell {
    & $sudo pwsh -Nologo
}

Set-Alias su Start-AdminShell
Set-Alias sudo $sudo
