@{
RootModule = 'GitHub.psm1'
ModuleVersion = '0.0.3'
GUID = 'e9e988a8-ef13-44d1-ba75-8d101398fb21'
Author = 'fkthat'
CompanyName = 'fkthat.pro'
Copyright = '(c) fkthat.pro, 2025'
Description = 'GitHub tools.'
NestedModules = 'Package.psm1','Issue.psm1'
FunctionsToExport = 'Get-GitHubPackage', 'Get-GitHubPackageVersion', 'New-GitHubIssue'
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = 'gghpkg', 'gghpkv', 'nghiss'
}
