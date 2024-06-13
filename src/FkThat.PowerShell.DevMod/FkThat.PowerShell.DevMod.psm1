$ErrorActionPreference = 'Stop'

function _Get_DevModPsd {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]
        $Name,

        [Parameter()]
        [string]
        $SrcBase = '.'
    )

    begin {
        $psds = @{}
    }

    process {
        $Name | ForEach-Object {
            Join-Path $SrcBase "src" |
                Get-ChildItem -Filter $_ -Directory -ErrorAction SilentlyContinue
            } |
            ForEach-Object {
                $psd1 = Join-Path $_.FullName "$($_.Name).psd1"

                if(Test-Path $psd1 -PathType Leaf) {
                    $psds[$psd1] = $true
                }
            }
    }

    end {
        Write-Output $psds.Keys
    }
}

function Get-DevMod {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter({ Get-DevMod "$($args[2])*" | Select-Object -ExpandProperty Name })]
        [string[]]
        $Name = "*",

        [Parameter()]
        [string]
        $SrcBase = '.'
    )

    begin {
        $psds = @{}
    }

    process {
        $Name | _Get_DevModPsd -SrcBase $SrcBase |
            ForEach-Object {
                $psds[$_] = $true
            }
    }

    end {
        $psds.Keys | ForEach-Object {
            [PSCustomObject]@{
                Name = Split-Path $_ -LeafBase
            }
        }
    }
}

function New-DevMod {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Name,

        [Parameter()]
        [string]
        $SrcBase = '.',

        [switch]
        $Force
    )

    begin {
        if ($Force -and -not $Confirm){
            $ConfirmPreference = 'None'
        }
    }

    process {
        $Name | ForEach-Object {
                Join-Path $SrcBase "src" $_
            } |
            ForEach-Object {
                $dir = $_
                $mname = Split-Path $dir -Leaf

                # Check if the src/<mod name> exists but is a file
                if(Test-Path -LiteralPath $dir -PathType Leaf) {
                    Remove-Item -LiteralPath $dir
                }

                # Check if the src/<mod name>/<mod name>.psm1 exists but is a folder
                $psm1 = Join-Path $dir "$mname.psm1"
                if(Test-Path -LiteralPath $psm1 -PathType Container) {
                    Remove-Item -LiteralPath $psm1 -Recurse
                }

                # Check if the src/<mod name>/<mod name>.psd1 exists
                $psd1 = Join-Path $dir "$mname.psd1"
                if(Test-Path -LiteralPath $psd1)  {
                    Remove-Item -LiteralPath $psd1 -Recurse
                }

                if(-not (Test-Path $dir)) {
                    $null = New-Item $dir -ItemType Directory -Force
                }

                if(-not (Test-Path $psm1)) {
                    $null = New-Item $psm1 -Force
                }

                New-ModuleManifest `
                    -Path $psd1 `
                    -RootModule "$mname.psm1" `
                    -ModuleVersion "1.0.0" `
                    -Description "The $mname module." `
                    -Author "fkthat" `
                    -Company "fkthat.net" `
                    -Copyright "(c) fkthat.net, $(Get-Date -Format 'yyyy')" `
                    -VariablesToExport @() `
                    -CmdletsToExport @() `
                    -FunctionsToExport @() `
                    -AliasesToExport @() `
                    -RequiredModules @() `
                    -NestedModules @()
            }
    }
}

function Clear-DevMod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter({ Get-DevMod "$($args[2])*" | Select-Object -ExpandProperty Name })]
        [string[]]
        $Name,

        [Parameter()]
        [string]
        $SrcBase = '.'
    )

    begin {
        $psds = @{}
    }

    process {
        $Name | _Get_DevModPsd -SrcBase $SrcBase |
            ForEach-Object {
                $psds[$_] = $true
            }
    }

    end {
        $psds.Keys | ForEach-Object {
            (Get-Content $_ | ForEach-Object {
                if ($_ -match '\S' -and $_ -notmatch '^\s*#') {
                    Write-Output $_
                }
            }) | Out-File $_
        }
    }
}

function Update-DevMod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter({ Get-DevMod "$($args[2])*" | Select-Object -ExpandProperty Name })]
        [string[]]
        $Name,

        [Parameter()]
        [string]
        $SrcBase = '.'
    )

    begin {
        $psds = @{}
    }

    process {
        $Name | _Get_DevModPsd -SrcBase $SrcBase |
            ForEach-Object {
                $psds[$_] = $true
            }
    }

    end {
        $psds.Keys | ForEach-Object {
            $psd1 = $_
            $dir = Split-Path $psd1 -Parent
            $name = Split-Path $psd1 -LeafBase

            $root = Get-ChildItem $dir -Filter "$name.psm1"

            $nested = Get-ChildItem $dir -Recurse -File -Filter "*.psm1" |
                Where-Object FullName -NE (Join-Path $dir  "$name.psm1") |
                ForEach-Object { $_.FullName.Substring($dir.Length + 1) }

            $funcs = @()
            $aliases = @()

            Get-ChildItem $dir -Recurse -File -Filter "*.psm1" |
                ForEach-Object {
                    Import-Module $_

                    Get-Module $_.BaseName | ForEach-Object {
                        $funcs += $_.ExportedFunctions.Keys |
                            Where-Object { -not $_.StartsWith("_") }
                        $aliases += $_.ExportedAliases.Keys
                    }

                    Remove-Module $_.BaseName
                }

            Update-PSModuleManifest `
                -Path $psd1 `
                -RootModule $root `
                -NestedModules $nested `
                -FunctionsToExport $funcs `
                -AliasesToExport $aliases `
                -VariablesToExport @()
        }
    }
}

function Publish-DevMod {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({ Get-DevMod "$($args[2])*" | Select-Object -ExpandProperty Name })]
        [string[]]
        $Name = "*",

        [Parameter()]
        [string]
        $SrcBase = '.'
    )

    begin {
        $psds = @{}
    }

    process {
        $Name | _Get_DevModPsd -SrcBase $SrcBase |
            ForEach-Object {
                $psds[$_] = $true
            }
    }

    end {
        $psds.Keys | ForEach-Object {
            $dir = Split-Path $_ -Parent
            Publish-PSResource $dir -ErrorAction Continue
        }
    }
}
