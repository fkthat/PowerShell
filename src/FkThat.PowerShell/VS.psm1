$ErrorActionPreference = "Stop"

$devenv = "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"

function Start-VS {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path = "."
    )

    process {
        $Path |
            Get-Item |
            ForEach-Object {
                if($_ -is [System.IO.DirectoryInfo]) {
                    Get-ChildItem $_ -File -Filter '*.sln'
                }
                elseif ($_.Extension -eq '.sln') {
                    Write-Output $_
                }
            } | ForEach-Object {
                & $devenv $_
            }
    }
}

Set-Alias vs Start-VS
