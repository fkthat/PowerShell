Set-Content $PROFILE ('$env:PSModulePath = "' + "$PSScriptRoot\Modules" + ';$env:PSModulePath"')
Add-Content $PROFILE 'Import-Module FkThat.PowerShell.Profile'
