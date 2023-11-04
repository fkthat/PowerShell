$ErrorActionPreference = "Stop"

Set-Alias winget "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    winget complete --word $wordToComplete --commandline $commandAst --position $cursorPosition |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}
