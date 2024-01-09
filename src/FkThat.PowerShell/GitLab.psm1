$ErrorActionPreference = "Stop"

$glab = "${env:ProgramFiles(x86)}\glab\glab.exe"

if(Test-Path $glab) {
    & $glab completion -s powershell | Out-String | Invoke-Expression
}

Set-Alias glab $glab
