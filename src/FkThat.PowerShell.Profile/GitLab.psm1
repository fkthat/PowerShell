$ErrorActionPreference = "Stop"

$glab = switch($PSVersionTable.Platform) {
    "Win32NT" { "${env:ProgramFiles(x86)}\glab\glab.exe" }
    "Unix" { which glab }
    Default { $null }
}

if(-not $glab -or -not (Test-Path $glab)) {
    return
}

& $glab completion -s powershell | Out-String | Invoke-Expression

Set-Alias glab $glab
Export-ModuleMember -Alias *
