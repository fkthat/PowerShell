$EnvRegKey = @{
    User = 'HKCU:\Environment'
    Machine = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
}

function Get-Env {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]
        $Scope
    )

    $EnvRegKey.Keys | ForEach-Object {
        $scope = $_
        $key = Get-Item $EnvRegKey[$scope]
        $key.GetValueNames() | ForEach-Object {
            [PSCustomObject]@{
                Scope = $scope
                Name = $_
                Value = $key.GetValue($_, $null, 'DoNotExpandEnvironmentNames')
            }
        }
    } |
    Where-Object { -not $Name -or $_.Name -eq $Name } |
        Where-Object { -not $Scope -or $_.Scope -eq $Scope }
}

function Set-Env {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $Value,

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]
        $Scope = 'User'
    )

    Set-ItemProperty $envRegKey[$Scope] `
        -Name $Name -Value $Value -Type ExpandString |
        Out-Null
}

function Remove-Env {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $Name,

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]
        $Scope = 'User'
    )

    Remove-ItemProperty $envRegKey[$Scope] -Name $Name | Out-Null
}

function Import-Env {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName ="ByPath")]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "ByInput")]
        [psobject[]]
        $InputObject
    )

    begin {
        if($Path) {
            $InputObject = Get-Content $Path | ConvertFrom-Json
        }
    }

    process {
        $InputObject | ForEach-Object {
            Set-Env $_.Name $_.Value -Scope $_.Scope
        }
    }
}

Set-Alias genv Get-Env
Set-Alias senv Set-Env
Set-Alias renv Remove-Env
Set-Alias ipenv Import-Env
