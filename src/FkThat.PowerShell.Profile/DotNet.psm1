$ErrorActionPreference = 'Stop'

$dotnet = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:ProgramFiles\dotnet\dotnet.exe" }
    "Unix" { which dotnet }
    Default { $null }
}

if(-not $dotnet -or -not (Test-Path $dotnet)) {
    return
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    & $dotnet complete --position $cursorPosition $commandAst |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Set-Alias dotnet $dotnet
Export-ModuleMember -Alias *
