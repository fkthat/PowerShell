$ErrorActionPreference = "Stop"

if(-not $IsWindows) { return }

Import-Module PSSQLite

$webData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Web Data"
$tempWebData = New-TemporaryFile
$script:Engines = $null

function Get-WebSearchEngine {
    if((-not $script:SearchEngines) -or `
        ((Get-Item $webData).LastWriteTime -gt (Get-Item $tempWebData).LastWriteTime)) {

        Copy-Item $webData $tempWebData

        $q = 'select * from keywords where is_active = 1 and keyword not like "@%"'

        $script:Engines =
            Invoke-SqliteQuery $q -DataSource $tempWebData |
            ForEach-Object {
                [PSCustomObject]@{
                    PSTypeName = "FkThat.PowerShell.Search.Engine"
                    Keyword = $_.keyword
                    ShortName = $_.short_name
                    Url = $_.url
                }
            }
    }

    $script:Engines
}

function Import-WebSearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "ByInput")]
        [psobject[]]
        $InputObject,

        [switch]
        $Force
    )

    begin {
        $msedge = Get-Process -Name msedge -ErrorAction SilentlyContinue

        if($msedge) {
            if($Force) {
                $msedge | Stop-Process
                $continue = $true
            }
            else {
                $continue = $false
            }
        }

        if($continue) {
            $con = New-SQLiteConnection -DataSource $webData
            Invoke-SqliteQuery -Query "delete from keywords" -SQLiteConnection $con

            $q = 'insert into keywords ' +
                '(url, keyword, short_name, favicon_url) values ' +
                '(@Url, @Keyword, @ShortName, "")'
        }
        else {
            Write-Error "Close all instances of Edge or set the '-Force' flag." `
             -TargetObject $MyInvocation.MyCommand -ErrorAction Stop
        }
    }

    process {
        $InputObject | ForEach-Object {
            Invoke-SqliteQuery -Query $q -SQLiteConnection $con -SqlParameters @{
                Url = $_.Url
                Keyword = $_.Keyword
                ShortName = $_.ShortName
            }
        }
    }

    end {
        if($con) {
            $con.Close()
        }
    }
}

Class EngineValuesGenerator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-WebSearchEngine | Select-Object -ExpandProperty Keyword)
    }
}

function Search-Web {
	[CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet([EngineValuesGenerator])]
        [string]
        $Engine,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    # ByEngine
    if($Engine) {
        $url = Get-WebSearchEngine |
            Where-Object Keyword -eq $Engine |
            Select-Object -ExpandProperty Url -First 1

        $t = $Terms | Join-String -Separator ' '
        $t = [Uri]::EscapeDataString($t)
        Start-Process ($url -replace '{searchTerms}', $t)
    }
}

function ConvertTo-VimiumSearch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [psobject[]]
        $InputObject
    )

    process {
        $InputObject | ForEach-Object {
            $keyword = $_.Keyword
            $url = $_.Url.Replace('{searchTerms}', '%s')
            $blank = [Uri]::new($url)
            $blank = "$($blank.Scheme)://$($blank.DnsSafeHost)/"
            $name = $_.ShortName
            Write-Output "${keyword}: ${url} blank=${blank} ${name}"
        }
    }
}

function Search-Bing {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    Search-Web b $Terms
}

function Search-Api {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    Search-Web api $Terms
}

Set-Alias gwse Get-WebSearchEngine
Set-Alias ipwse Import-WebSearchEngine
Set-Alias srweb Search-Web
Set-Alias srbing Search-Bing
Set-Alias srapi Search-Api

Export-ModuleMember -Function * -Alias *
