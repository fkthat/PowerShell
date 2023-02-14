#
# PSReadLine settings
#

Set-PSReadLineOption -EditMode vi -ViModeIndicator Script `
    -ViModeChangeHandler {
        if ($args[0] -eq 'Command') {
            # Set the cursor to a blinking block.
            Write-Host -NoNewLine "`e[1 q"
        } else {
            # Set the cursor to a blinking line.
            Write-Host -NoNewLine "`e[5 q"
        }
    }

#
# Custom PowerShell Prompt (UNIX-like)
#

function Prompt {
    $White = "`e[37m"
    $Green = "`e[32m"
    $Blue = "`e[34m"
    $Red = "`e[31m"
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal $identity
    $Elevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    $UserColor = $Elevated ? $Red : $Green
    $UserInfo = "$([System.Environment]::UserName)@$([System.Environment]::MachineName)"
    $Suffix = $Elevated ? "#" : "$"
    $ResetCursor = $env:TERM_PROGRAM -ne "vscode" ? "`e[5 q" : ""
    $H = [regex]::Escape($HOME)
    $S = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)
    $Path = (Get-Location).Path -replace "^$H(?<tail>$S.*)?",'~${tail}'
    Write-Output "${White}PS $UserColor$UserInfo${White}:$Blue$Path$White$Suffix ${ResetCursor}"
    $Host.UI.RawUI.WindowTitle = $Path
}

#
# WinGet CLI completion
#

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    & "${env:LocalAppData}\Microsoft\WindowsApps\winget.exe" complete `
        --word $wordToComplete --commandline $commandAst --position $cursorPosition |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

#
# GitHub & GitLab CLI completion
#

"$env:ProgramFiles\GitHub CLI\gh.exe",
"${env:ProgramFiles(x86)}\glab\glab.exe" |
    Where-Object { Test-Path $_ } |
    ForEach-Object {
        & $_ completion -s powershell | Out-String | Invoke-Expression
    }

#
# Dotnet CLI completion
# https://docs.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete#powershell
#

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    & "$env:ProgramFiles\dotnet\dotnet.exe" complete `
        --position $cursorPosition "$commandAst" |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

#
# 3rd party completions
#

Import-Module posh-git, DockerCompletion

#
# Aliases
#

Set-Alias scp "$env:SystemRoot\scp.exe"
Set-Alias ssh "$env:SystemRoot\ssh.exe"

Set-Alias 7z     "$env:ProgramFiles\7-zip\7z.exe"
Set-Alias docker "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"
Set-Alias gh     "$env:ProgramFiles\GitHub CLI\gh.exe"
Set-Alias git    "$env:ProgramFiles\Git\bin\git.exe"
Set-Alias less   "$env:ProgramFiles\Git\usr\bin\less.exe"
Set-Alias vim    "$env:ProgramFiles\Vim\vim90\vim.exe"

Set-Alias glab "${env:ProgramFiles(x86)}\glab\glab.exe"
Set-Alias sudo "${env:ProgramFiles(x86)}\gsudo\gsudo.exe"

Set-Alias mongo  "$env:LocalAppData\Programs\mongosh\mongosh.exe"
Set-Alias winget "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"
