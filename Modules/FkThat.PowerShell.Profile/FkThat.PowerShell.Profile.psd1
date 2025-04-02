@{
ModuleVersion = '0.0.7'
GUID = '466623f1-635e-4eba-a464-5cad5c9632d5'
Author = 'fkthat'
CompanyName = 'fkthat.pro'
Copyright = '(c) fkthat.pro, 2025'
Description = 'PowerShell profile.'

NestedModules = 'Prompt.psm1', 'PSReadLine.psm1', 'Git.psm1',
    'DotNet.psm1', 'Docker.psm1', 'GH.psm1', 'PSDefaultParameterValues.psm1',
    'Defaults.psm1'

FunctionsToExport = 'Prompt'
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = 'docker', 'gh'
}
