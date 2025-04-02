$ErrorActionPreference = 'Stop'

$gh = $IsWindows ? "$env:ProgramFiles\GitHub CLI\gh.exe" : (which gh)

if(-not (Test-Path $gh)) {
    return
}

function New-GitHubIssue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Repo,

        [Parameter()]
        [string]
        $Assignee = '@me',

        [Parameter()]
        [string]
        $Body = '',

        [Parameter()]
        [ArgumentCompletions('enhancement', 'bug', 'documentation')]
        [string]
        $Label = 'enhancement',

        [Parameter()]
        [string]
        $Project,

        [Parameter()]
        [switch]
        $Editor
    )

    $p = "issue", "create",
         "--title", $Title,
         "--assignee", $Assignee,
         "--body", $Body,
         "--label", $Label

    if($Editor) {
        $p += "--editor"
    }

    if($Repo) {
        $p += "--repo", $Repo
    }

    if($Project) {
        $p += "--project", $Project
    }

    & $gh $p
}

Set-Alias nghiss New-GitHubIssue
