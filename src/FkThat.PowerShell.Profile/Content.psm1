$ErrorActionPreference = "Stop"

function Compare-Content {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Path1,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $Path2
    )

    $c1 = Get-Content $Path1
    $c2 = Get-Content $Path2
    Compare-Object $c1 $c2
}

function Update-Content {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
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

    process {
        $Path | Get-Item -ErrorAction SilentlyContinue |
            Where-Object { $_ -is [System.IO.FileInfo] } |
            ForEach-Object {
                (Get-Content $_ |
                    ForEach-Object -Begin $Begin -Process $Process -End $End) |
                    Set-Content $_
            }
    }
}

function Update-ContentEol {
    [CmdletBinding()]
    param (
        # The path to the file to update.
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path,

        # The EOL style (Unix/Dos)
        [Parameter(Mandatory)]
        [ValueSet('Unix', 'Dos')]
        [string]
        $Eol
    )

    begin {
        switch($Eol) {
            'Unix' {
                $eol = "`n"
            }
            'Dos' {
                $eol = "`r`n"
            }
        }
    }

    process {
        $Path | Get-Item -ErrorAction SilentlyContinue |
            Where-Object { $_ -is [System.IO.FileInfo] } |
            ForEach-Object {
                $content = Get-Content $_
                $content = $content -join $eol
                Set-Content $_ -Value $eol -NoNewline
            }
    }
}

function Update-ContentEolToUnix {
    [CmdletBinding()]
    param (
        # The path to the file to update.
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path
    )

    process {
        $Path | Update-ContentEol -Unix
    }
}

function Update-ContentEolToDos {
    [CmdletBinding()]
    param (
        # The path to the file to update.
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path
    )

    process {
        $Path | Update-ContentEol -Dos
    }
}

Set-Alias cdiff Compare-Content
Set-Alias sed Update-Content
Set-Alias ueol Update-ContentEol
Set-Alias dos2unix Update-ContentEolToUnix
Set-Alias unix2dos Update-ContentEolToDos

Export-ModuleMember -Function * -Alias *
