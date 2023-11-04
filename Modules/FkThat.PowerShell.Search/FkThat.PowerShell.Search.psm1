$webData = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Web Data"
$tempWebData = New-TemporaryFile
$script:Engines = $null

function Get-SearchEngine {
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

function Export-SearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]
        $Path
    )

    $json = Get-SearchEngine | ConvertTo-Json

    if($Path) {
        Set-Content $Path $json
    }
    else {
        Write-Output $json
    }
}

function Import-SearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = "ByPath")]
        [string]
        $Path,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "ByInput")]
        [psobject[]]
        $InputObject,

        [switch]
        $Force
    )

    begin {
        $process = $true
        $msedge = Get-Process | Where-Object Name -eq msedge

        if($msedge) {
            if($Force) {
                $msedge | Stop-Process
            }
            else {
                $process = $false
            }
        }

        if($process) {
            $con = New-SQLiteConnection -DataSource $webData
            Invoke-SqliteQuery -Query "delete from keywords" -SQLiteConnection $con

            $q = 'insert into keywords ' +
                '(url, keyword, short_name, favicon_url) values ' +
                '(@Url, @Keyword, @ShortName, "")'

            if($Path) {
                $InputObject = Get-Content $Path | ConvertFrom-Json
            }
        }
        else {
            Write-Warning "Close all instances of Edge or set the '-Force' flag."
        }
    }

    process {
        if($process) {
            $InputObject | ForEach-Object {
                Invoke-SqliteQuery -Query $q -SQLiteConnection $con -SqlParameters @{
                    Url = $_.Url
                    Keyword = $_.Keyword
                    ShortName = $_.ShortName
                }
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
        return (Get-SearchEngine | Select-Object -ExpandProperty Keyword)
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
        $url = Get-SearchEngine |
            Where-Object Keyword -eq $Engine |
            Select-Object -ExpandProperty Url -First 1

        $t = $Terms | Join-String -Separator ' '
        $t = [Uri]::EscapeDataString($t)
        Start-Process ($url -replace '{searchTerms}', $t)
    }
}

function Search-Bing {
	[CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    Search-Web -Engine b $Terms
}

function Search-MS {
	[CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    Search-Web -Engine ms $Terms
}

function Search-Api {
	[CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    Search-Web -Engine api $Terms
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

Set-Alias gse Get-SearchEngine
Set-Alias epse Export-SearchEngine
Set-Alias ipse Import-SearchEngine
Set-Alias srweb Search-Web
Set-Alias srbing Search-Bing
Set-Alias srms Search-MS
Set-Alias srapi Search-Api
