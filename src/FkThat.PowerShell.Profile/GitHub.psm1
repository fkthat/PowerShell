$ErrorActionPreference = "Stop"

$gh = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:ProgramFiles\GitHub CLI\gh.exe" }
    "Unix" { which gh }
    Default { $null }
}

if(-not $gh -or -not (Test-Path $gh)) {
    return
}

# Register completion for GH
& $gh completion -s powershell | Out-String | Invoke-Expression

[Flags()]
enum PackageType {
    NuGet = 1
    Container = 2
    All = 3
}

function Get-GitHubPackage {
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]
        $Name = "*",

        [Parameter()]
        [PackageType]
        $Type = [PackageType]::All
    )

    begin {
        $all = [Enum]::GetValues([PackageType]) |
            Where-Object { $_ -ne [PackageType]::All} |
            Where-Object { $_ -band $Type } |
            ForEach-Object {
                $pt = [Enum]::GetName($_).ToLower()
                $json = & $gh api "user/packages?package_type=$pt" 2> $null | ConvertFrom-Json

                if($?) {
                    $json | ForEach-Object {
                        [PSCustomObject]@{
                            Id = $_.id
                            Type = [PackageType]$_.package_type
                            Name = $_.name
                            Visibility = $_.visibility
                            VersionCount = $_.version_count
                        }
                    }
                }
                else {
                    Write-Warning $json.message
                }
            }

        $unique = @{}
    }

    process {
        $Name | ForEach-Object {
                $fltr = $_
                $all | Where-Object Name -Like $fltr
            } |
            ForEach-Object {
                $unique[$_.Id] = $_
            }
    }

    end {
        Write-Output $unique.Values
    }
}

function Remove-GitHubPackage {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]
        $Name,

        [Parameter()]
        [PackageType]
        $Type = 'All'
    )

    begin {
        $filteredByType = Get-GitHubPackage -Type $Type
        $filteredByName = @{}
    }

    process {
        $Name | ForEach-Object {
            $filteredByType | Where-Object Name -like $_ |
                ForEach-Object {
                    $filteredByName[$_.Id] = @{ Name = $_.Name; Type = $_.Type }
                }
        }
    }

    end {
        $filteredByName.Values | ForEach-Object {
            $pt = $_.Type.ToString().ToLower()
            $pn = $_.Name

            if($PSCmdlet.ShouldProcess("$pn ($pt)")) {
                $response = & $gh api "user/packages/$pt/$pn" --method Delete 2> $null |
                    ConvertFrom-Json

                if(-not $?) {
                    Write-Warning "$pn ($pt) - $($response.message)"
                }
            }
        }
    }
}

Set-Alias gh $gh
Set-Alias gghpkg Get-GitHubPackage
Set-Alias rghpkg Remove-GitHubPackage

Export-ModuleMember -Function * -Alias *
