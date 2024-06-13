$ErrorActionPreference = "Stop"

$winget = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe" }
    Default { $null }
}

if(-not $winget -or -not (Test-Path $winget)) {
    return
}

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    & $winget complete --word $wordToComplete --commandline $commandAst --position $cursorPosition |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Set-Alias winget $winget
Export-ModuleMember -Alias 'winget'
