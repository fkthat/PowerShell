$ErrorActionPreference = 'Stop'

$docker = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe" }
    "Unix" { which docker }
    Default { $null }
}

if(-not $docker -or -not (Test-Path $docker)) {
    return
}

Import-Module DockerCompletion -ErrorAction Continue

<#
.SYNOPSIS
Lists docker objects in the PowerShell format.
#>
function Get-DockerObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Container", "Image", "Volume")]
        [string]
        # Docker object type.
        $Type
    )

    & {
        switch($Type) {
            "Container" { & $docker ps --all --format "{{json .}}" }
            "Image" { & $docker image ls --all --format "{{json .}}" }
            "Volume" { & $docker volume ls --format "{{json .}}" }
        }
    } |
    ConvertFrom-Json | ForEach-Object {
        $_.PSObject.TypeNames.Insert(0, "$ns.$Type")
        Write-Output $_
    }
}

function Get-DockerContainer {
    Get-DockerObject Container
}

function Get-DockerImage {
    Get-DockerObject Image
}

function Get-DockerVolume {
    Get-DockerObject Volume
}

$ns = "FkThat.PowerShell.Docker"

Update-TypeData -TypeName "${ns}.Container" -Force `
    -MemberName "Name" -MemberType AliasProperty -Value "Names"

Update-TypeData -TypeName "${ns}.Container" -Force `
    -DefaultDisplayPropertySet "ID", "Image", "Name", "State", "Status"

Update-TypeData -TypeName "${ns}.Image" -Force `
    -DefaultDisplayPropertySet "ID", "Repository", "Tag", "Size"

Update-TypeData -TypeName "${ns}.Volume" -Force `
    -DefaultDisplayPropertySet "Driver", "Name"

Set-Alias docker $docker
Set-Alias gdobj Get-DockerObject
Set-Alias gdc Get-DockerContainer
Set-Alias gdimg Get-DockerImage
Set-Alias gdvol Get-DockerVolume

Export-ModuleMember -Function * -Alias *
