$ErrorActionPreference = "Stop"

# $PasswordChars = "!#%+23456789:=?@ABCDEFGHJKLMNPRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
# $PasswordChars = "!#%+23456789:?@ABCDEFGHJKLMNPRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

$PasswordChars = @{
    UpperCase = 'A'..'Z'
    LowerCase = 'a'..'z'
    Digit = [char]'2'..[char]'9'
    Symbol  = "!#%+:?@".ToCharArray()
}

Class CharKindValuesGenerator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return ($script:PasswordChars.Keys)
    }
}

function Test-PasswordStrength {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [SecureString[]]
        $Password,

        [Parameter()]
        [int]
        [ValidateRange(8, [int]::MaxValue)]
        # The password length.
        $Length = 16,

        [Parameter()]
        [ValidateSet([CharKindValuesGenerator])]
        [string[]]
        # Character kinds to use.
        $Require = $CharKind.Keys
    )

    process {
        $Password | ConvertFrom-SecureString -AsPlainText |
            ForEach-Object {
                if($_.Length -lt $Length) {
                    return $false
                }

                foreach ($r in $Require) {
                   $ok = $false
                   foreach($c in $_.ToCharArray()) {
                     if($PasswordChars[$r] -ccontains $c) {
                        $ok = $true
                        break;
                     }
                   }
                   if(-not $ok) {
                    return $false
                   }
                }

                return $true
            }
    }
}

<#
.SYNOPSIS
Generates a random password.
#>
function New-RandomPassword {
    [CmdletBinding()]
    [OutputType([SecureString])]
    param (
        # The password length.
        [Parameter()]
        [ValidateRange(8, [int]::MaxValue)]
        [int]
        $Length = 16,

        # The count of passwords to generate.
        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Count = 1,

        [Parameter()]
        [ValidateSet([CharKindValuesGenerator])]
        [string[]]
        # Character kinds to use.
        $Require = $PasswordChars.Keys
    )

    $chars = @()

    $Require | ForEach-Object {
        $chars += $PasswordChars[$_]
    }

    $c = $Count
    while($c-- -gt 0) {
        while($true) {
            $p = Get-Random -Minimum 0 -Maximum $chars.Length -Count $Length |
                ForEach-Object { $chars[$_ ] } |
                Join-String | ConvertTo-SecureString -AsPlainText -Force

            if(Test-PasswordStrength $p -Length $Length -Require $Require) {
                Write-Output $p
                break
            }
        }
    }
}

Export-ModuleMember -Function '*'
