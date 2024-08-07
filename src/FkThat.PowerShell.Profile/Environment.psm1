$ErrorActionPreference = "Stop"

if(-not $IsWindows) { return }

$EnvRegKey = @{
    User = 'HKCU:\Environment'
    Machine = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
}

[Flags()]
enum Scope {
    User = 1
    Machine = 2
    All = 3
}

function _Get_EnvironmentVariable {
    $EnvRegKey.Keys | ForEach-Object {
            $scope = $_
            $key = Get-Item $EnvRegKey[$scope]

            $key.GetValueNames() | ForEach-Object {
                [PSCustomObject]@{
                    Scope = [Scope]$scope
                    Name = $_
                    Value = $key.GetValue($_, $null, 'DoNotExpandEnvironmentNames')
                }
            }
        }
}

function _Get_UserEnvironmentVariable {

}

function _Get_MachineEnvironmentVariable {

}

function Get-UserEnvironmentVariable {

}

function Get-MachineEnvironmentVariable {

}

function Get-EnvironmentVariable {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter({
            _Get_EnvironmentVariable_All |
                Where-Object Name -Like "$($args[2])*" |
                Select-Object -ExpandProperty Name
        })]
        [string]
        $Name,

        [Parameter()]
        [Scope]
        $Scope = 'All'
    )

    begin {
        $allInScope = ForEach-Object {
            $s = $_
            $key = Get-Item $EnvRegKey[$s]
            $key.GetValueNames() | ForEach-Object {
                [PSCustomObject]@{
                    Scope = $s
                    Name = $_
                    Value = $key.GetValue($_, $null, 'DoNotExpandEnvironmentNames')
                }
            }
        }

        $filtered
    }

    process {
        $Name | ForEach-Object {

        }
    }

    # get all
    $EnvRegKey.Keys | |
    # filter
    Where-Object {
        ((-not $Name) -or ($_.Name -like $Name)) -and
        ((-not $Scope) -or ($_.Scope -eq $Scope))
    }
}

function Set-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess)]
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

function Remove-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess)]
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

function Import-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName ="ByPath")]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "ByInput")]
        [psobject[]]
        $InputObject,

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]
        $Scope
    )

    begin {
        if($Path) {
            $InputObject = Get-Content $Path | ConvertFrom-Json
        }
    }

    process {
        $InputObject |
            Where-Object {
                (-not $Scope) -or ($_.Scope -eq $Scope)
            } |
            ForEach-Object {
                Set-Env $_.Name $_.Value -Scope $_.Scope
            }
    }
}

Set-Alias genv Get-EnvironmentVariable
Set-Alias senv Set-EnvironmentVariable
Set-Alias renv Remove-EnvironmentVariable
Set-Alias ipenv Import-EnvironmentVariable

Export-ModuleMember -Function * -Alias *
