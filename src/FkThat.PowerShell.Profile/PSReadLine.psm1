$ErrorActionPreference = 'Stop'

$Cursor = @{
    BlinkingBlock = "`e[1 q"
    BlinkingBar = "`e[5 q"
}

Set-PSReadLineOption -EditMode vi -ViModeIndicator Script `
    -ViModeChangeHandler {
        if ($args[0] -eq 'Command') {
            Write-Host -NoNewLine $Cursor.BlinkingBlock
        } else {
            Write-Host -NoNewLine $Cursor.BlinkingBar
        }
    }
