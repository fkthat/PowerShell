$ErrorActionPreference = "Stop"

<#
Updates the content of a text file according to the given scripts.
#>
function Update-Content {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        # The path to the file to update.
        $Path,

        [Parameter(Position = 1, Mandatory)]
        [scriptblock]
        # The script block to execute for every line of the file.
        # The line will be replaced with the output of this block
        # if output is empty the line will be removed.
        $Process,

        [Parameter()]
        [scriptblock]
        # The script block to execute before processing the file.
        $Begin = {},

        [Parameter()]
        [scriptblock]
        # The script block to execute  after processing the file.
        $End = {}
    )

    begin {
        $tmp = New-TemporaryFile
    }

    process {
        $Path | Get-Item | ForEach-Object {
            Get-Content $_ |
                ForEach-Object -Begin $Begin -Process $Process -End $End |
                Out-File $tmp

            Copy-Item $tmp $_
        }
    }

    end {
        Remove-Item $tmp
    }
}

function ConvertTo-UnixText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path
    )

    process {
        $Path | ForEach-Object {
            Get-Item $_ | ForEach-Object {
                $txt = Get-Content $_ -Raw
                $txt = $txt -replace "`r",""
                Set-Content $_ -Value $txt -NoNewline
            }
        }
    }
}

Set-Alias sed Update-Content
Set-Alias dos2unix ConvertTo-UnixText
