#
# Development tools.
#

function Start-VisualStudio {
    param(
        # Path to the solution or folder.
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Path = '.')

    begin {
        $vs = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"
    }

    process {
        $Path | Get-ChildItem -Filter *.sln  | Select-Object -Unique |
            Where-Object Extension -eq '.sln' | ForEach-Object { & $vs $_ }
    }
}

function Start-VSCode {
    param(
        # Path to the file or folder.
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Path = '.')

    begin {
        $code = "${env:LocalAppData}\Programs\Microsoft VS Code\bin\code.cmd"
    }

    process {
        $Path | Get-Item | Select-Object -Unique | ForEach-Object { & $code $_ -n }
    }
}

function Get-RandomPerson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet(
            'FirstName', 'LastName', 'Patronymic', 'DateOfBirth', 'Gender',
            'Company', 'Vacancy', 'BankName', 'BankCard', 'BankExp',
            'BankCVC', 'Login', 'Password', 'DocINN', 'DocSNILS', 'Address',
            'City', 'Street', 'House', 'Apartment', 'Phone', 'Email',
            'Website', 'CarBrand', 'CarModel', 'CarYear', 'CarColor', 'CarNum')]
        [string[]]
        $Fields = @(
            'FirstName', 'LastName', 'Patronymic', 'DateOfBirth', 'Gender',
            'Company', 'Vacancy', 'BankName', 'BankCard', 'BankExp',
            'BankCVC', 'Login', 'Password', 'DocINN', 'DocSNILS', 'Address',
            'City', 'Street', 'House', 'Apartment', 'Phone', 'Email',
            'Website', 'CarBrand', 'CarModel', 'CarYear', 'CarColor', 'CarNum'),
        [Parameter(Mandatory = $false)]
        [ValidateSet('male', 'female', 'random')]
        $Gender = 'random',
        [Parameter(Mandatory = $false)]
        [int]
        $Count = 1
    )

    $url = 'https://hit.ori.one/api'

    $token =  `
        '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000c393705e3ec62346aa1db1ce6b43cce2' + `
        '00000000020000000000106600000001000020000000d30beabdddb8117c8d58dec8c1a5c8fb5fa4' + `
        '2b86c228e3042579f0685f6a241d000000000e80000000020000200000006fc9323012cf0fa777ba' + `
        '39745142b0ed904f3950863b9f4f575b2a1cf46d3c8250000000f39a364302cd02671845fac7e6c9' + `
        'f05abb51a93c990d33827282b8e435af17bcb5ae0a0d2762471c77351b98db3717cb51d63761d67a' + `
        '86857c3e4d12ebd772240077be8915812387cdc43356213203f6400000002a8c1d3037958258d627' + `
        'f64ecd3ae0a0ffd41694fce5b986dd61ea1227fb18be2284a1dce91db09efecde08ef1727603c662' + `
        '014e98ab021434d88e3702d3749c' |
        ConvertTo-SecureString | ConvertFrom-SecureString -AsPlainText

    # Below looks strange but there're strange things on the server side happen...

    $body = @{
        token = $token;
        gender = $Gender;
        count = $Count;
        param = $Fields
    } | ConvertTo-Json

    $f = New-TemporaryFile
    Invoke-RestMethod -Uri $url -Method Post -Body $body -OutFile $f
    Get-Content $f | ConvertFrom-Json
    Remove-Item $f
}

function Get-RandomDateTime {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [datetime]
        $Min = [datetime]::MinValue,
        [Parameter(Position = 1, Mandatory = $false)]
        [datetime]
        $Max = [datetime]::MaxValue,
        [Parameter(Mandatory = $false)]
        [ValidateSet('none', 'json', 'csharp')]
        $Format = 'none'
    )

    $dt = New-Object datetime ([Random]::Shared.NextInt64($Min.Ticks, $Max.Ticks))

    switch($Format) {
        'none' {
            $dt
        }
        'json' {
            (ConvertTo-Json $dt).Trim('"')
        }
        'csharp' {
            [string]::Format("new DateTime({0:yyyy, MM, dd, hh, mm, ss})", $dt)
        }
    }
}

function Get-TemporaryPath {
    Join-Path ([System.IO.Path]::GetTempPath()) `
        ([System.IO.Path]::GetRandomFileName())
}

function New-CoverageReport {
    [CmdletBinding()]
    param (
        # The path or glob to the report file. Default to **\coverage.*
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Path = '**\coverage.*',
        # Output folder. Default to the generated temporary folder.
        [Parameter(Mandatory = $false)]
        [string]
        $OutDir = (Get-TemporaryPath),
        [Parameter()]
        [switch]
        $Open
    )

    begin {
        $reports = @()
    }

    process {
        $reports += $Path
    }

    end {
        $r = $reports -join ";"
        $log = reportgenerator -reports:$r -targetdir:$OutDir

        if($?) {
            $html = Join-Path $OutDir 'index.html'

            if($Open) {
                Start-Process "$html"
            }
            else {
                Write-Output "$html"
            }
        }
        else {
            Write-Host $log
        }
    }
}

function Start-Flow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ArgumentCompletions('feature/', 'fix/', 'bug/')]
        $Name,
        [Parameter(Mandatory = $false)]
        $Base = "main"
    )

    git checkout $Base -b $Name &&
        git fetch origin "${Base}:${Base}" &&
        git rebase $Base &&
        git push -u origin $Name `
        || &{Throw}
}

function Clear-GitRepo {
    git clean -dfX -e '!.vs' -e '!*.suo' -e '!.vscode/*'
}

function Find-CSProject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Path
    )

    begin {
        [System.IO.Directory]::SetCurrentDirectory($pwd)
    }

    process {
        $Path | ForEach-Object {
            $p = [System.IO.Path]::GetFullPath($_)
            while ($p) {
                if (Join-Path $p "*.csproj" | Test-Path -PathType Leaf) {
                    Get-ChildItem $p -File -Filter "*.csproj"
                    break
                }

                $p = Split-Path $p -Parent
            }
        }
    }
}

function Get-CSProjectNamespace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Path
    )

    process {
        $Path | ForEach-Object {
            $xml = [xml](Get-Content $_)
            $rns = $xml.SelectNodes("/Project/PropertyGroup/RootNamespace")

            if($rns -and $rns.Count -gt 0) {
                $rns | Select-Object -ExpandProperty InnerText
            }
            else {
                Split-Path $_ -LeafBase
            }
        }
    }
}

function New-CSharpItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $true)]
        [string[]]
        $Name,
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $Output = ".",
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("class", "interface", "enum", "controller", "worker")]
        $Template = "class",
        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("public", "internal")]
        $Visibility = "public",
        [switch]
        $Static
    )

    begin {
        # Throw if $Output is a file
        if ((Test-Output $Output) -and (Get-Item $Output) -is [System.IO.FileInfo]) {
            Throw "$Output is a file"
        }

        # Default names like 'Class', 'Interface', etc
        if (-not $Name) {
            $Name = $Template -replace "^.", $Template.Substring(0, 1).ToUpper()
        }
    }

    process {
        $Name | ForEach-Object {
            $csPath = (Join-Output $Output $Name) + ".cs"

            if (-not (Test-Output $csPath)) {
            }
            else {
                Write-Warning "$csPath alredy exists"
            }

            if (-not (Test-Output $Output)) {
                New-Item $Output -ItemType Directory
            }

            $Output | Find-CSProject | Get-CSProjectNamespace | Select-Object -First 1 |
                ForEach-Object {
                    if (-not $Static) {
                        dotnet new "ft-item" -o $Output `
                            -na $_ -v $Visibility -t $Template -n $Name
                    }
                    else {
                        dotnet new "ft-item" -o $Output `
                            -na $_ -v $Visibility -s -t $Template -n $Name
                    }
                }
        }
    }
}

Set-Alias clrepo Clear-GitRepo
Set-Alias vs Start-VisualStudio
Set-Alias code Start-VSCode
Set-Alias saflow Start-Flow
Set-Alias ncover New-CoverageReport
