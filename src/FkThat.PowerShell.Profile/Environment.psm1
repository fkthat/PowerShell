$ErrorActionPreference = "Stop"

if(-not $IsWindows) { return }

$EnvRegKey = @{
    User = 'HKCU:\Environment'
    Machine = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
}

function Get-EnvironmentVariable {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]
        $Scope
    )

    # get all
    $EnvRegKey.Keys | ForEach-Object {
        $s = $_
        $key = Get-Item $EnvRegKey[$s]
        $key.GetValueNames() | ForEach-Object {
            [PSCustomObject]@{
                Scope = $s
                Name = $_
                Value = $key.GetValue($_, $null, 'DoNotExpandEnvironmentNames')
            }
        }
    } |
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

Set-Alias genv Get-Env
Set-Alias senv Set-Env
Set-Alias renv Remove-Env
Set-Alias ipenv Import-Env

Export-ModuleMember -Function * -Alias *
