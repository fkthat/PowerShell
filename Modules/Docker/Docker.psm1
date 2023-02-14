$docker = "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"

function Get-DockerContainer {
    & $docker ps -a --format '{{json .}}' | ConvertFrom-Json
}

function Get-DockerImage {
    & $docker image ls -a --digests --format '{{json .}}' | ConvertFrom-Json
}

function Get-DockerVolume {
    & $docker volume ls --format '{{json .}}' | ConvertFrom-Json
}

Set-Alias gdc Get-DockerContainer
Set-Alias gdimg Get-DockerImage
Set-Alias gdvol Get-DockerVolume
