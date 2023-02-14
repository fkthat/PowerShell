#
# Custom PowerShell Prompt
#

$Elevated = $false

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $Elevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

$ColorString = @{
    White = "`e[37m"
    Green = "`e[32m"
    Blue = "`e[34m"
    Red = "`e[31m"
}

$UserInfoColorString = $Elevated ? $ColorString.Red : $ColorString.Green
$UserInfo = "$([System.Environment]::UserName)@$([System.Environment]::MachineName)"
$PromptSuffix = $Elevated ? "#" : "$"
$ResetCursorString = $env:TERM_PROGRAM -ne "vscode" ? "`e[5 q" : ""

function Prompt {
    $h = [regex]::Escape($HOME)
    $s = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
    $PromptPath = (Get-Location).Path -replace "^${h}(?<tail>${s}.*)?",'~${tail}'

    $host.UI.RawUI.WindowTitle = $PromptPath

    "$($ColorString.White)PS " +
    "${UserInfoColorString}${UserInfo}" +
    "$($ColorString.White):" +
    "$($ColorString.Blue)${PromptPath}" +
    "$($ColorString.White)${PromptSuffix} " +
    "${ResetCursorString}"
}
