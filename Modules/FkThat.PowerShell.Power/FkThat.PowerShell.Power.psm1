function Get-PowerPlan {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Name = "*"
    )

    powercfg.exe /l | Select-Object -Skip 2 | ForEach-Object {
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
        powercfg.exe /s $_.Id
    }
}

Set-Alias gpwr Get-PowerPlan
Set-Alias swpwr Switch-PowerPlan
