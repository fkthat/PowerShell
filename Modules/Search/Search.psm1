#
# Search WEB
#

Class SearchEngines : System.Management.Automation.IValidateSetValuesGenerator {
    static $engines;

    [string[]] GetValidValues() {
        return [SearchEngines]::GetAll() | Select-Object -ExpandProperty Keyword
    }

    static [psobject[]] GetAll() {
        if(-not [SearchEngines]::engines) {
            [SearchEngines]::engines = Get-SearchEngine
        }

        return [SearchEngines]::engines
    }
}

function Search-Web {
	[CmdletBinding()]
    param (
        # Search engine keyword. Default to 'b' (Bing).
        [Parameter(Position = 0)]
        [ValidateSet([SearchEngines])]
        $Engine = 'b',

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]
        $Terms
    )

    $t = $Terms | Join-String -Separator ' '
    $t = [Uri]::EscapeDataString($t)

    $url = [SearchEngines]::GetAll() |
        Where-Object Keyword -eq $Engine |
        Select-Object -ExpandProperty Url -First 1

    $url = $url -replace '{searchTerms}', $t
    Start-Process $url
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

function Get-SearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $ProfilePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
    )

    $webData = Join-Path $ProfilePath "Web Data"
    $tempWebData = New-TemporaryFile
    Copy-Item $webData $tempWebData

    try {
        $q = 'select * from keywords where is_active = 1'

        Invoke-SqliteQuery $q -DataSource $tempWebData |
            ForEach-Object {
                New-Object psobject -Property @{
                    Keyword = $_.keyword
                    ShortName = $_.short_name
                    Url = $_.url
                }
            }
    }
    finally {
        Remove-Item $tempWebData
    }
}

function Clear-SearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $ProfilePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
    )

    $webData = Join-Path $ProfilePath "Web Data"
    $q = "delete from keywords"
    Invoke-SqliteQuery $q -DataSource $webData
}

function Import-SearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [psobject[]]
        $InputObject,
        [Parameter(Mandatory = $false)]
        [string]
        $ProfilePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
    )

    begin {
        $webData = Join-Path $ProfilePath "Web Data"
        $con = New-SQLiteConnection -DataSource $webData

        $q = 'insert into keywords ' +
            '(url, keyword, short_name, favicon_url) values ' +
            '(@Url, @Keyword, @ShortName, "")'
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
        $con.Close()
    }
}

function ConvertTo-VimiumSearch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
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

Set-Alias srweb Search-Web
Set-Alias srbing Search-Bing
