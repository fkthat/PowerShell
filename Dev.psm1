$ErrorActionPreference = 'Stop'

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
                Join-Path $PSScriptRoot "src" $_
            } |
            ForEach-Object {
                $moduleDir  = $_

                if(Test-Path $moduleDir) {
                    Write-Warning "$moduleDir already exists."
                    return
                }

                $moduleName = Split-Path $moduleDir -Leaf
                $moduleManifestPath = Join-Path $moduleDir "$moduleName.psd1"
                $modulePath = Join-Path $moduleDir "$moduleName.psm1"

                New-Item $modulePath -Force

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

function Clear-DevModule {
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
