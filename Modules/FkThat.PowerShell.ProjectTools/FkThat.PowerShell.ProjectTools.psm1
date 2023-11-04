$ErrorActionPreference = "Stop"

$baseDir = Resolve-Path "$PSScriptRoot\.."
$ns = "FkThat.PowerShell"

function Get-ProjectModule {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]]
        $Name = "*"
    )

    begin {
        $names = @()
    }

    process {
        $Name | ForEach-Object { Get-Item "${baseDir}\${ns}.${Name}"} |
            Select-Object -Unique | ForEach-Object {
                $names += $_.BaseName.Substring($ns.Length + 1)
            }
    }

    end {
        Write-Output $names | ForEach-Object {
            [PSCustomObject]@{
                Name = $_
            }
        }
    }
}

function New-ProjectModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]
        $Name
    )

    process {
        $Name | ForEach-Object {
            $dir = "${baseDir}\${ns}.$_"

            New-Item $dir -ItemType Directory

            New-ModuleManifest "$dir\$ns.$_.psd1" `
                -ModuleVersion "0.0.1" `
                -Author "fkthat" `
                -CompanyName "fkthat.net" `
                -Copyright '(c) fkthat.net. All rights reserved.' `
                -Description "$_ module." `
                -RootModule "$ns.$_.psm1" `
                -FunctionsToExport @() `
                -CmdletsToExport @() `
                -AliasesToExport @() `
                -VariablesToExport @()

            New-Item "$dir\$ns.$_.psm1"
        } | Out-Null
    }
}

Class ProjecNameValuesGenerator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-ProjectModule | Select-Object -ExpandProperty Name)
    }
}

function Rename-ProjectModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet([ProjecNameValuesGenerator])]
        [string[]]
        $Name,

        [Parameter(Mandatory, Position = 1)]
        [string[]]
        $NewName
    )

    $fullName = "${ns}.${Name}"
    $fullNewName = "${ns}.${NewName}"

    # Clone *.psm1 file
    Copy-Item "${baseDir}\${fullName}\${fullName}.psm1" `
        "${baseDir}\${fullName}\${fullNewName}.psm1"

    # Update RootModule
    Update-ModuleManifest "${baseDir}\${fullName}\${fullName}.psd1" `
        -RootModule "${fullNewName}.psm1"

    # Remove old *.psm1
    Remove-Item "${baseDir}\${fullName}\${fullName}.psm1"

    # Rename *.psd1
    Rename-Item "${baseDir}\${fullName}\${fullName}.psd1" "${fullNewName}.psd1"

    # Rename folder
    Rename-Item "${baseDir}\${fullName}" "${fullNewName}"
}

Set-Alias gpmo Get-ProjectModule
Set-Alias npmo New-ProjectModule
Set-Alias rnpmo Rename-ProjectModule

function Install-Profile {
    Set-Content $PROFILE "${baseDir};${env:PSModulePath}"
    Add-Content $PROFILE 'Import-Module FkThat.PowerShell.Profile'
}

function Build-ReadmeContent {
    Write-Output "# PowerShell"
    Write-Output ""
    Write-Output "## Modules"

    $cmdTypes = `
        @{ Type = "Function"; Header = "Functions" },
        @{ Type = "Alias"; Header = "Aliases" }

    Get-ChildItem "$PSScriptRoot\.." | ForEach-Object {
        $module = $_.Name

        Write-Output ""
        Write-Output "### ${module}"

        $cmdTypes | ForEach-Object {
            $cmds = Get-Command -CommandType "$($_.Type)" -Module $module

            if($cmds) {
                Write-Output ""
                Write-Output "#### $($_.Header)"

                Write-Output ""
                $cmds | ForEach-Object {
                    Write-Output "- $($_.Name)"
                }
            }
        }
    }
}
