[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [string[]]
    $Name
)

begin {
    $ns = "FkThat.PowerShell"
}

process {
    $Name | ForEach-Object {
        $dir = "$PSScriptRoot\Modules\$dir\$ns.$_"

        New-Item $dir -ItemType Directory &&
            New-ModuleManifest "$dir\$ns.$_.psd1" `
                -ModuleVersion "0.0.1" `
                -Author "fkthat" `
                -CompanyName "fkthat.net" `
                -Copyright '(c) fkthat.net. All rights reserved.' `
                -Description "$_ module." `
                -RootModule "$ns.$_.psm1" `
                -FunctionsToExport @() `
                -CmdletsToExport @() `
                -AliasesToExport @() `
                -VariablesToExport @() &&
            New-Item "$dir\$ns.$_.psm1"
    }
}
