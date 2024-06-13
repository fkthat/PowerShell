$ErrorActionPreference = 'Stop'

$White = "`e[37m"; $null = $White
$Green = "`e[32m"; $null = $Green
$Blue = "`e[34m"; $null = $Blue
$Red = "`e[31m"; $null = $Red

$Template = @{
    Default = '${White}PS ' +
        '${Green}${User}@${Machine}' +
        '${White}:' +
        '${Blue}${Dir}' +
        '${White}`$ '

    Admin = '${White}PS ' +
        '${Red}${User}@${Machine}' +
        '${Red}:' +
        '${Red}${Dir}' +
        '${White}`# '
}

function _Test_Admin {
    if($IsWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal $identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    if($IsLinux) {
        return  ((id -u) -eq 0)
    }

    return $false
}

function _Get_User {
    [System.Environment]::UserName
}

function _Get_Host {
    [System.Environment]::MachineName
}

function _Get_Dir {
    $h = [regex]::Escape($HOME)
    $s = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
    (Get-Location).Path -replace "^$h(?<tail>$s.*)?",'~${tail}'
}

function Prompt {
    $template = (_Test_Admin) ? $Template.Admin : $Template.Default

    $User = _Get_User; $null = $User
    $Machine = _Get_Host; $null = $Machine
    $Dir = _Get_Dir

    $Host.UI.RawUI.WindowTitle = $Dir

    $expression = '"' + $template + '"'
    Invoke-Expression $expression
}

Export-ModuleMember -Function 'Prompt'
