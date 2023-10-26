function Test-ElevatedUser {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $elevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Output $elevated
}

function Prompt {
    $h = [regex]::Escape($HOME)
    $s = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
    $Path = (Get-Location).Path -replace "^$h(?<tail>$s.*)?",'~${tail}'
    $Host.UI.RawUI.WindowTitle = $Path

    $White = "`e[37m"
    $Green = "`e[32m"
    $Blue = "`e[34m"
    $Red = "`e[31m"

    $ResetCursor = $env:TERM_PROGRAM -ne "vscode" ? "`e[5 q" : ""

    $elevated = Test-ElevatedUser

    if($elevated) {
        $UserColor = $Red
        $Suffix = "#"
    } else {
        $UserColor = $Green
        $Suffix = '$'
    }

    $UserName = [System.Environment]::UserName
    $MachineName = [System.Environment]::MachineName

    "${White}PS " +
    "$UserColor$UserName@$MachineName" +
    "${White}:" +
    "${Blue}$Path" +
    "${White}$Suffix " +
    "$ResetCursor"
}

