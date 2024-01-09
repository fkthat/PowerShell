$ErrorActionPreference = "Stop"

$gh = "${env:ProgramFiles}\GitHub CLI\gh.exe"

if(Test-Path $gh) {
    & $gh completion -s powershell | Out-String | Invoke-Expression
}

function New-GitHubIssue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Title,

        [Parameter()]
        [string]
        $Assignee = '@me',

        [Parameter()]
        [string]
        $Label = 'enhancement',

        [Parameter()]
        [string]
        $Body = '',

        [Parameter()]
        [string]
        $Repo
    )

    if($Repo) {
        & $gh issue create --repo $Repo `
            -t $Title ` -a $Assignee ` -l $Label ` -b $Body ` -p 'FkThat'
    }
    else {
        & $gh issue create `
            -t $Title ` -a $Assignee ` -l $Label ` -b $Body ` -p 'FkThat'
    }
}

Set-Alias gh $gh
Set-Alias nghi New-GitHubIssue
