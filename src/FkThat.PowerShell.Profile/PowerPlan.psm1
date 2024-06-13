$ErrorActionPreference = "Stop"

$powercfg = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:windir\System32\powercfg.exe" }
    Default { $null }
}

if(-not $powercfg -or -not (Test-Path $powercfg)) {
    return
}

function Get-PowerPlan {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [ArgumentCompleter({
            Get-PowerPlan | Where-Object Name -like "$($args[2])*" |
                Select-Object -ExpandProperty Name |
                ForEach-Object { $_.Contains(" ") ? "'$_'" : $_ }
        })]
        [string]
        $Name = "*"
    )

    & $powercfg /l | Select-Object -Skip 2 | ForEach-Object {
        if($_ -match ':\s*(\S+)\s+\(([^\)]+)\)\s*(\*)?') {
            [pscustomobject]@{
                Id = $Matches[1]
                Name = $Matches[2]
                Active = -not -not $Matches[3]
            }
        }
    } | Where-Object Name -like $Name
}

Class PowerPlanValidateSetGenerator: System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-PowerPlan | Select-Object -ExpandProperty Name)
    }
}

function Switch-PowerPlan {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        [ValidateSet([PowerPlanValidateSetGenerator])]
        $Name
    )

    Get-PowerPlan $Name | ForEach-Object {
        & $powercfg /s $_.Id
    }
}

Set-Alias gpwp Get-PowerPlan
Set-Alias swpwp Switch-PowerPlan

Export-ModuleMember -Function * -Alias *
