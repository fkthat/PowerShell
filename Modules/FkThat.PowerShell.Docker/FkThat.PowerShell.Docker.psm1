$ErrorActionPreference = "Stop"

Set-Alias docker "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"

$ns = "FkThat.PowerShell.Docker"

function Get-DockerObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet("Container", "Image", "Volume")]
        [string]
        $Type
    )

    & {
        switch($Type) {
            "Container" { docker ps --all --format "{{json .}}" }
            "Image" { docker image ls --all --format "{{json .}}" }
            "Volume" { docker volume ls --format "{{json .}}" }
        }
    } |
    ConvertFrom-Json | ForEach-Object {
        $_.PSObject.TypeNames.Insert(0, "$ns.$Type")
        Write-Output $_
    }
}

Update-TypeData -TypeName "${ns}.Container" -Force `
    -MemberName "Name" -MemberType AliasProperty -Value "Names"

Update-TypeData -TypeName "${ns}.Container" -Force `
    -DefaultDisplayPropertySet "ID", "Image", "Name", "State", "Status"

Update-TypeData -TypeName "${ns}.Image" -Force `
    -DefaultDisplayPropertySet "ID", "Repository", "Tag", "Size"

Update-TypeData -TypeName "${ns}.Volume" -Force `
    -DefaultDisplayPropertySet "Driver", "Name"

Set-Alias gdobj Get-DockerObject
