$ErrorActionPreference = 'Stop'

function Get-DevModule {
    Join-Path $PSScriptRoot 'src' |
        Get-ChildItem -Recurse -Filter *.psd1 |
        ForEach-Object {
            $v = (Get-Content $_ -Raw | Invoke-Expression).ModuleVersion
            [PSCustomObject]@{
                Name = $_.BaseName
                Version = [System.Version]::new($v)
            }
        }
    }

function New-DevModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Name
    )

    process {
        $Name |
            ForEach-Object {
                $moduleName = $_
                $moduleDir  = Join-Path $PSScriptRoot 'src' $moduleName

                if(Test-Path $moduleDir) {
                    Write-Warning "$moduleDir already exists."
                    return
                }

                $moduleManifestPath = Join-Path $moduleDir "$moduleName.psd1"
                $modulePath = Join-Path $moduleDir "$moduleName.psm1"

                $null = New-Item $modulePath -Force

                $null = New-ModuleManifest `
                    -Path $moduleManifestPath `
                    -RootModule "$moduleName.psm1" `
                    -ModuleVersion "1.0.0" `
                    -Description "The $moduleName module." `
                    -Author "fkthat" `
                    -Company "fkthat.net" `
                    -Copyright "(c) fkthat.net, $(Get-Date -Format 'yyyy')" `
                    -VariablesToExport @() `
                    -CmdletsToExport @() `
                    -FunctionsToExport @() `
                    -AliasesToExport @() `
                    -RequiredModules @() `
                    -NestedModules @()

                (Get-Content $moduleManifestPath | ForEach-Object {
                    $_ -replace '^# VariablesToExport .*','VariablesToExport = @()'
                }) | Set-Content $moduleManifestPath
            }
    }
}

function Clear-DevModuleComments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter({
            Join-Path $PSScriptRoot "src" |
                Get-ChildItem -Filter "$($args[2])*" |
                Select-Object -ExpandProperty Name
        })]
        [string[]]
        $Name
    )

    process {
        $Name |
            ForEach-Object { Join-Path $PSScriptRoot "src" $_ } |
            Get-Item -ErrorAction SilentlyContinue |
            Select-Object -Unique |
            ForEach-Object { Join-Path $_ "$($_.Name).psd1" } |
            Where-Object { Test-Path $_ -PathType Leaf } |
            ForEach-Object {
                (Get-Content $_ |
                    ForEach-Object {
                        if ($_ -match '\S' -and $_ -notmatch '^\s*#') { Write-Output $_ }
                    }) |
                Out-File $_
            }
    }
}

function Compare-Version {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Version,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $CompareTo
    )

    begin {
        $right =  [System.Version]::new($CompareTo)
    }

    process {
        $Version | ForEach-Object {
            Write-Output ([System.Version]::new($_)).CompareTo($right)
        }
    }
}

function Register-GitHubResourceRepository {
    Register-PSResourceRepository GitHub `
        -Uri "https://nuget.pkg.github.com/$env:GITHUB_REPOSITORY_OWNER/index.json"
}

function Publish-DevModule {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ArgumentCompleter({
            Join-Path $PSScriptRoot "src" |
                Get-ChildItem -Filter "$($args[2])*" |
                Select-Object -ExpandProperty Name
        })]
        [string[]]
        $Name = '*'
    )

    begin {
        $password = ConvertTo-SecureString $env:GITHUB_TOKEN -AsPlainText -Force
        $credential = [pscredential]::new($env:GITHUB_REPOSITORY_OWNER, $password)
    }

    process {
        $Name |
            ForEach-Object { Join-Path $PSScriptRoot "src" $_ } |
            Get-Item -ErrorAction SilentlyContinue |
            Select-Object -Unique |
            ForEach-Object {
                $modPath = $_
                $modName = $modPath.Name
                $modManifest = Join-Path $modPath "$modName.psd1"

                if(Test-Path $modManifest -PathType Leaf) {
                    $modVersion = (Get-Content $modManifest -Raw | Invoke-Expression).ModuleVersion

                    $currentModVersion = Find-PSResource $modName -Repository GitHub `
                        -Credential $credential -ErrorAction SilentlyContinue |
                        Select-Object -ExpandProperty Version


                    if(-not $currentModVersion -or (Compare-Version $modVersion $currentModVersion) -gt 0) {
                        Publish-PSResource -Path $modPath -Repository GitHub -Credential $credential
                    }
                }
            }
    }
}

function Set-DevPSModulePath {
    $env:PSModulePath = "$(Join-Path $PSScriptRoot 'src');$env:PSModulePath"
}

function Measure-DevModule {
    Join-Path $PSScriptRoot 'src' 'fkthat.powershell' |
        Get-ChildItem -Filter *.psm1 |
        ForEach-Object {
            $path = $_.FullName
            $name = $_.BaseName

            $loadTime = Measure-Command { Import-Module $path } |
                Select-Object -ExpandProperty TotalMilliseconds

            Remove-Module $name

            [PSCustomObject]@{
                Name = $name
                LoadTime = $loadTime
            }
        }
}

function Update-DevModule {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string[]]
        $Name = '*',

        [Parameter()]
        [Version]
        $Version
    )

    begin {
        $psds = Join-Path $PSScriptRoot 'src' |
            Get-ChildItem -Directory |
            Get-ChildItem -File -Filter *.psd1 |
            Where-Object { $_.BaseName -eq $_.Directory.Name }
    }

    process {
        $Name | ForEach-Object {
            $filter = $_
            $psds = $psds | Where-Object { $_.BaseName -like $filter }
        }
    }

    end {
        $psds | ForEach-Object {
            $psd = $_
            $rootModule = $psd.FullName -replace '\.psd1$','.psm1'
            $rootModule = (Test-Path $rootModule) ? $rootModule : $null
            $nestedModules = Get-ChildItem $psd.Directory -Recurse -File -Filter *.psm1

            $functions = @{}
            $aliases = @{}

            $nestedModules | ForEach-Object {
                pwsh { Import-Module $args[0] -PassThru } -args $_ |
                    ForEach-Object {
                        $_.ExportedFunctions.Keys | ForEach-Object { $functions[$_] = $true }
                        $_.ExportedAliases.Keys | ForEach-Object { $aliases[$_] = $true }
                    }
            }

            $functions = $functions.Keys |
                Where-Object { Get-Verb ($_ -replace '-.*','') } |
                Sort-Object { $_ -replace '^[^-]*-','' }

            $aliases = $aliases.Keys

            Write-Output $functions
            # Write-Output $aliases
        }
    }
}


function Move-DevModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [string]
        $Name
    )

    begin {
        $modules = Join-Path $PSScriptRoot "src" "fkthat.powershell" |
            Get-ChildItem -File -Filter *.psm1
    }

    process {
        $Name | ForEach-Object {
            $wildCard = $_
            $modules = $modules | Where-Object {
                $_.BaseName -like $wildCard
            }
        }
    }

    end {
        $modules | ForEach-Object {
            $module = $_
            $newModuleName = "fkthat.powershell.$($module.BaseName.ToLower())"
            $newModuleDir = Join-Path $PSScriptRoot 'src' $newModuleName

            if(Test-Path $newModuleDir) {
                Write-Warning "$newModuleDir already exists. Skipped."
                return
            }

            $newModulePsd = Join-Path $newModuleDir "$newModuleName.psd1"
            $newModulePsm = Join-Path $newModuleDir "$newModuleName.psm1"
            New-Item $newModuleDir -ItemType Directory
            Copy-Item $module $newModulePsm
            $manifest = pwsh { Import-Module $args[0] -Force -PassThru } -args $module

            New-ModuleManifest $newModulePsd  `
                -RootModule "$newModuleName.psm1" `
                -FunctionsToExport ([string[]]$manifest.ExportedFunctions.Keys) `
                -AliasesToExport ([string[]]$manifest.ExportedAliases.Keys) `
                -VariablesToExport ([string[]]$manifest.ExportedVariables.Keys) `
                -CmdletsToExport ([string[]]$manifest.ExportedCmdLets.Keys) `
                -Description "The FkThat's $($module.BaseName) module." `
                -Company 'fkthat.net'
        }
    }
}
