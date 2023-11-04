$ErrorActionPreference = Stop

<#
.SYNOPSIS
Generates a new code coverage HTML report.
.OUTPUTS
The path to the generated report *.html file.
.NOTES
It's your concern to clean up th files in case they're
generated in th temporary folder.
#>
function New-CodeCoverageReport {
    [CmdletBinding()]
    param (
        # The path or glob to the report file. Default to **\coverage.*
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]]
        $Path = '**\coverage.*',

        # Output directory. If ommited a new temporary folder will be used.
        [Parameter()]
        [string]
        $OutDir = (Join-Path ([io.path]::GetTempPath()) `
            -ChildPath ([io.path]::GetRandomFileName())),

        [switch]
        # Open the report in the default browser after generation.
        $Open
    )

    begin {
        $reports = @()
    }

    process {
        $reports += $Path
    }

    end {
        $r = $reports -join ";"
        reportgenerator -reports:$r -targetdir:$OutDir

        if($?) {
            $index = Join-Path $OutDir -ChildPath "index.html"
            if($Open) { Start-Process $index | Out-Null }
            Write-Output $index
        }
    }
}

Set-Alias nccr New-CodeCoverageReport
