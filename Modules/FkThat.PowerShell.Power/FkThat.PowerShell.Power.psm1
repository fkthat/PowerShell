function Get-PowerPlan {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Name = "*"
    )

    Get-CimInstance -classname Win32_PowerPlan -Namespace "root\cimv2\power" |
        Where-Object ElementName -like $Name
}

function Switch-PowerPlan {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )

    $plans = Get-PowerPlan $Name

    if(($plans | Measure-Object | Select-Object -ExpandProperty Count) -gt 1) {
        Write-Error "Ambiguous power plan pattern $Name"
        return
    }

    $plan = $plans | Select-Object -First 1

    if(-not $plan) {
        Write-Error "Power plan not found for pattern $Name"
        return
    }

    Invoke-CimMethod -InputObject $plan -MethodName Activate | Out-Null
}

Set-Alias gpwr Get-PowerPlan
Set-Alias swpwr Switch-PowerPlan
