$sudo = "$env:ProgramFiles\gsudo\Current\gsudo.exe"

function Get-PowerPlan {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Name = "*"
    )

    if(Test-ElevatedUser) {
        Get-CimInstance -classname Win32_PowerPlan -Namespace "root\cimv2\power" |
            Where-Object ElementName -like $Name
    }
    else {
        & $sudo Get-PowerPlan $Name
    }
}

function  Switch-PowerPlan {
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )

    if(Test-ElevatedUser) {
        Get-CimInstance -classname Win32_PowerPlan -Namespace "root\cimv2\power" |
            Where-Object ElementName -like "${Name}*" | Select-Object -First 1 |
            ForEach-Object { Invoke-CimMethod -InputObject $_ -MethodName Activate } |
            Out-Null
    }
    else {
        & $sudo Switch-PowerPlan $Name
    }
}
