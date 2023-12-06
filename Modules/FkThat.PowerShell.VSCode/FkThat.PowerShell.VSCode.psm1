$ErrorActionPreference = "Stop"

$code = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"

function Start-VSCode {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path = '.'
    )

    process {
        $Path | ForEach-Object {
            cmd -ArgumentList @("/c", $code, "-n", $_)
        }
    }
}

Set-Alias vsc Start-VSCode
