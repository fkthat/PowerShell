$ErrorActionPreference = "Stop"

$code = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd" }
    Default { $null }
}

if(-not $code -or -not (Test-Path $code)) {
    return
}

<#
.SYNOPSIS
Starts VS Code with a folder or file as an argument.
#>
function Start-VSCode {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
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
                $paths += $_.FullName
            }
    }

    end {
        $paths | Select-Object -Unique |
            ForEach-Object {
                & $code -n $_
            }
    }
}

Set-Alias sacode Start-VSCode

Export-ModuleMember -Function 'Start-VSCode' -Alias 'sacode'
