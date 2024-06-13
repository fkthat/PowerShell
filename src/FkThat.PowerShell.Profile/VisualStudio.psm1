$ErrorActionPreference = "Stop"

$devenv = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" }
    Default { $null }
}

if(-not $devenv -or -not (Test-Path $devenv)) {
    return
}

<#
.SYNOPSIS
Starts Visual Studio with a folder or file as an argument.
.DESCRIPTION
Searches the passed folders or files fo the Visual Studio solution files
and starts the Visual Studio with these solutions.
#>
function Start-VisualStudio {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]
        # The path to the folder or *.sln file. Can be a wildcard.
        $Path = "."
    )

    begin {
        $sln = @()
    }

    process {
        $Path |
            Get-Item -ErrorAction SilentlyContinue |
                ForEach-Object {
                    if($_ -is [System.IO.DirectoryInfo]) {
                        Get-ChildItem $_ -File -Filter '*.sln'
                    }
                    elseif ($_.Extension -eq '.sln') {
                        Write-Output $_
                    }
                } |
                ForEach-Object { $sln += $_ }
    }

    end {
        $sln | Select-Object -Unique |
            ForEach-Object { & $devenv $_ }
    }
}

Set-Alias savs Start-VisualStudio
Export-ModuleMember -Function * -Alias *
