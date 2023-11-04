$ErrorActionPreference = Stop

$gdiff = "${env:ProgramFiles}\Git\usr\bin\diff.exe"

function Compare-Content {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Path1,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $Path2,

        [switch]
        $GnuDiff
    )

    if($GnuDiff) {
       & $gdiff -rcs --color=always $Path1 $Path2
    }
    else {
        $c1 = Get-Content $Path1
        $c2 = Get-Content $Path2
        Compare-Object $c1 $c2
    }
}

Set-Alias cdiff Compare-Content
