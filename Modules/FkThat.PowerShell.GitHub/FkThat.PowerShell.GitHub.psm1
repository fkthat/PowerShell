$ErrorActionPreference = Stop

$gh = "${env:ProgramFiles}\GitHub CLI\gh.exe"

if(Test-Path $gh) {
    & $gh completion -s powershell | Out-String | Invoke-Expression
}

Set-Alias gh $gh
