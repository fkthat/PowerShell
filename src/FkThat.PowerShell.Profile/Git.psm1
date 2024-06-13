$ErrorActionPreference = 'Stop'

$git = switch($PSVersionTable.Platform) {
    "Win32NT" { "$env:ProgramFiles\Git\bin\git.exe" }
    "Unix" { which git }
    Default { $null }
}

if(-not $git -or -not (Test-Path $git)) {
    return
}

Import-Module Posh-Git -ErrorAction Continue

function Start-GitFlow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        # The name of a new working branch.
        $Name,

        [Parameter()]
        [string]
        # The base branch for the flow.
        $Base = (& $git branch --show-current)
    )

    & $git checkout $Base -b $Name &&
        & $git fetch origin "${Base}:${Base}" &&
        & $git rebase $Base &&
        & $git push -u origin $Name
}

function Clear-Git {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]]
        # Path to the git repository directory.
        $Path = ".",

        [switch]
        # Clean untracked files as well
        $CleanUntracked
    )

    begin {
        $x = $CleanUntracked ? "-x" : "-X"
    }

    process {
        $RepoDir | ForEach-Object {
            & $git clean -df $x -e '!.vs' -e '!*.suo' -e '!.vscode/*'
        }
    }
}

Set-Alias git $git
Set-Alias saflow Start-GitFlow
Set-Alias clgit Invoke-GitClean

Export-ModuleMember -Function * -Alias *
