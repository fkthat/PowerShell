Set-PSRepository "PSGallery" -InstallationPolicy Trusted

Install-Module "DockerCompletion",
    # "PSSQLite",
    "Posh-Git"

Set-ItemProperty "HKCU:\Environment" -Name "PSModulePath" -Value "$PSScriptRoot\Modules"
New-Item $PROFILE -ItemType SymbolicLink -Target "$PSScriptRoot\Profile.ps1" -Force
