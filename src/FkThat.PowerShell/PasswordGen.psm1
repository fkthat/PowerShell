$ErrorActionPreference = "Stop"

$CharKinds = @{
    LowerCase = Join-String -InputObject ('a'..'z')
    UpperCase = Join-String -InputObject ('A'..'Z')
    Digits = Join-String -InputObject ('0'..'9')
    Symbols = "~!#$%^&*-_+"
}

function Get-CharKind {
    $CharKinds.Keys
}

Class CharKindValidateSet: System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-CharKind)
    }
}

<#
.SYNOPSIS
Generates a new random password.
#>
function Get-RandomPassword {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]
        [ValidateRange(8, [int]::MaxValue)]
        # The password length.
        $Length = 12,

        [Parameter()]
        [int]
        [ValidateRange(1, [int]::MaxValue)]
        # The count of passwords to generate.
        $Count = 1,

        [Parameter()]
        [ValidateSet([CharKindValidateSet])]
        [string[]]
        # Character kinds to use.
        $Use = (Get-CharKind)
    )

    $charsToUse = ""

    # all chars to use
    $Use | ForEach-Object {
        $charsToUse += $CharKinds[$_]
    }

    1..$Count | ForEach-Object {
        while($true) {
            # generate probe password
            $probe = Get-Random -Minimum 0 -Maximum $charsToUse.Length -Count $Length |
                ForEach-Object { $charsToUse[$_] } |
                Join-String

            $ok = $true

            # validate probe password
            foreach($u in $Use) {
                $ok = $false

                foreach($c in [char[]]$CharKinds[$u]) {
                    if ($probe.Contains($c)) {
                        $ok = $true
                        break
                    }
                }

                if(-not $ok) {
                    break
                }
            }

            if($ok) {
                Write-Output $probe
                break
            }
        }
    }
}

Export-ModuleMember -Function Get-RandomPassword
