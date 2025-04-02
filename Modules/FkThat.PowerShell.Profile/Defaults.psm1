# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values

$ErrorActionPreference = 'Stop'

$Global:PSDefaultParameterValues = @{
    # New-ModuleManifest
    'New-ModuleManifest:ModuleVersion' = '0.0.1'
    'New-ModuleManifest:Description' = 'Add some description here...'
    'New-ModuleManifest:Author' = 'fkthat'
    'New-ModuleManifest:CompanyName' = 'fkthat.pro'
    'New-ModuleManifest:Copyright' = '(c) fkthat.pro, 2025'
    'New-ModuleManifest:AliasesToExport' = @()
    'New-ModuleManifest:NestedModules' = @()
    'New-ModuleManifest:VariablesToExport' = @()
    'New-ModuleManifest:FunctionsToExport' = @()
    'New-ModuleManifest:CmdletsToExport' = @()
    # New-GitHubIssue
    'New-GitHubIssue:Project' = 'Pets'
}
