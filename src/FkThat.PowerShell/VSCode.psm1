$ErrorActionPreference = "Stop"

$code = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"

<#
.SYNOPSIS
Starts VS Code with a folder or file as an argument.
#>
function Start-VSCode {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards]
        [string[]]
        # The path to the folder or file. Can be a wildcard.
        $Path = '.'
    )

    begin {
        $paths = @()
    }

    process {
        $Path | Get-Item -ErrorAction SilentlyContinue |
            ForEach-Object {
                $paths += $_
            }
    }

    end {
        $paths | Select-Object -Unique |
            ForEach-Object {
                cmd -ArgumentList @("/c", $code, "-n", $_)
            }
    }
}

Set-Alias vsc Start-VSCode
