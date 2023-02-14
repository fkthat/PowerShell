
function Get-DiskInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string[]] $DeviceID
    )

    begin {
        if(-not $DeviceID) {
            $DeviceID = Get-CimInstance Win32_LogicalDisk |
                Select-Object -ExpandProperty DeviceID
        }
    }

    process {
        $DeviceID | ForEach-Object {
            Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$_'" |
            Select-Object DeviceId, Size, FreeSpace
        }
    }
}

function New-ItemLink {
	[CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)] [string] $Target,
        [Parameter(Position = 1, Mandatory = $false)] [string] $Path,
        [switch] $Hard,
        [switch] $Force
    )

    if(-not (Test-Path $Target)) {
        Write-Error "$Target does''n exist."
        return
    }

    if(-not $Path) {
        $Path = (Split-Path $Target -Leaf)
    }

    $targetItem = Get-Item $Target

    if($targetItem.PSIsContainer -and $Hard) {
        Write-Error 'Cannot hardlink a folder.'
        return
    }

    if($Hard) {
        New-Item -ItemType HardLink -Target $Target -Path $Path -Force:$Force
    }
    else {
        New-Item -ItemType SymbolicLink -Target $Target -Path $Path -Force:$Force
    }
}

# Touch file

function Set-ItemDateTime {
	[CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string[]] $Path,
        [Parameter()]
        [switch]
        $Force
    )

    process {
        $Path | ForEach-Object {
            if(Test-Path $_) {
                Set-ItemProperty $_ -Name LastWriteTime -Value (Get-Date)
            }
            else {
                New-Item $Path -ItemType File -Force:$Force
            }
        }
    }
}

function Invoke-GnuDiff {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]
        $Path1,
        [Parameter(Position = 1, Mandatory = $true)]
        [string]
        $Path2
    )

    & "${env:ProgramFiles}\Git\usr\bin\diff.exe" -rcs --color=always $Path1 $Path2
}

function Open-Hosts {
    $sudo = "${env:ProgramFiles(x86)}\gsudo\gsudo.exe"
    & $sudo { & $env:ProgramFiles\Vim\vim90\vim.exe `
        ${env:SystemRoot}\System32\drivers\etc\hosts }
}

function Start-AdminTerminal {
    Start-Process "$env:LocalAppData\Microsoft\WindowsApps\wt.exe" -Verb RunAs
}

function Set-EnvironmentVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [object]
        $Value,

        [Parameter(Mandatory = $false)]
        [Microsoft.Win32.RegistryValueKind]
        $Type = [Microsoft.Win32.RegistryValueKind]::String,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'Machine')]
        $Scope = 'User'
    )

    switch ($Scope) {
        'User' { $reg = 'HKCU:\Environment' }
        'Machine' { $reg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'}
    }

    Set-ItemProperty $reg -Name $Name -Value $Value -Type $Type
}

function Remove-EnvironmentVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet('User', 'Machine')]
        $Scope = 'User'
    )

    switch ($Scope) {
        'User' { $reg = 'HKCU:\Environment' }
        'Machine' { $reg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' }
    }

    if($null -ne (Get-Item $reg).GetValue($Name)) {
        Remove-ItemProperty $reg -Name $Name
    }
}

function Test-ElevatedUser {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    Write-Output $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Reset-Path {
    $MachinePath = `
        '%SystemRoot%\System32',
        '%SystemRoot%',
        '%SystemRoot%\System32\Wbem' |
        Join-String -Separator ";"

    $UserPath = `
        '%ProgramFiles%\Git\bin',
        '%ProgramFiles%\dotnet',
        '%USERPROFILE%\.dotnet\tools' |
        Join-String -Separator ";"

    if(Test-ElevatedUser) {
        Set-EnvironmentVariable 'PATH' -Value $MachinePath -Scope Machine -Type ExpandString
    }

    Set-EnvironmentVariable 'PATH' -Value $UserPath -Scope User -Type ExpandString
}

function New-DevelopmentCertificates {
    $ca = 'FkThat Development CA'
    $domain = 'fkthat.net'

    $password = Read-Host -AsSecureString "Password: "

    $caCert = New-SelfSignedCertificate `
        -DnsName $ca `
        -KeyLength 2048 `
        -KeyAlgorithm 'RSA' `
        -HashAlgorithm 'SHA256' `
        -KeyExportPolicy 'Exportable' `
        -NotAfter (Get-Date).AddYears(5) `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -KeyUsage 'CertSign', 'CRLSign'

    $cert = New-SelfSignedCertificate `
        -DnsName "*.$domain" `
        -Signer $caCert `
        -KeyLength 2048 `
        -KeyAlgorithm 'RSA' `
        -HashAlgorithm 'SHA256' `
        -KeyExportPolicy 'Exportable' `
        -NotAfter (Get-date).AddYears(2) `
        -CertStoreLocation 'Cert:\CurrentUser\My'

    $caCrtFile = ($ca -replace '\s+', '_') + '.crt'
    Export-Certificate -Cert $caCert -FilePath $caCrtFile -Force | Out-Null
    Import-Certificate -CertStoreLocation 'Cert:\CurrentUser\Root' -FilePath $caCrtFile
    $secure = $password
    Export-PfxCertificate $cert "${domain}.pfx" -Password $secure -Force | Out-Null
}

function Reset-WinTray {
    Remove-ItemProperty `
        'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify\' `
        -Name 'IconStreams','PastIconsStream'
}

function Split-Text {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]
        $Text,
        [Parameter(Mandatory = $false, Position = 1)]
        [int]
        $MaxLength = 80
    )

    process {
        $Text | ForEach-Object {
            $t = $_
            $i = 0
            while($i -lt $t.Length) {
                if($i + $MaxLength -lt $t.Length) {
                    Write-Output $t.Substring($i, $MaxLength)
                }
                else {
                    Write-Output $t.Substring($i)
                }
                $i += $MaxLength
            }
        }
    }
}

function Edit-File {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]
        $Path,
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]
        $Process,
        [Parameter(Mandatory = $false)]
        [scriptblock]
        $Begin = {},
        [Parameter(Mandatory = $false)]
        [scriptblock]
        $End = {}
    )

    process {
        $Path | ForEach-Object {
            $tmp = New-TemporaryFile
            Get-Content $_ |
                ForEach-Object -Begin $Begin -Process $Process -End $End |
                Out-File $tmp
            Copy-Item $tmp $_
            Remove-Item $tmp
        }
    }
}

function Publish-BB {
    [CmdletBinding()]
    param (
        # Resize the image to this percentage. Default is 50.
        [Parameter()]
        [int]
        $Scale = 50 # to 50% (i.e. 2 as smaller)
    )

    $dll = "${env:ProgramFiles}\dotnet\shared\Microsoft.WindowsDesktop.App\3.1.14\System.Windows.Forms.dll"
    [System.Reflection.Assembly]::LoadFrom($dll) | Out-Null

    $ApiKey = `
        '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000e4b16b938aa09249a4cb328c9969b496' +
        '000000000200000000001066000000010000200000008aac97451a45bb62bc6ff9767ada4682e3ee' +
        'a66aba7c3a71b50151267c138839000000000e8000000002000020000000445d4ceb76f1080f7426' +
        '40d088cc7702623df81a5a7e8f9c34933d7888f08cc550000000ed4f9ee60ca362e89d5f3d5ff10f' +
        '35e0d9c60e8e9dfe8e99648afc2064daaeba5b9e456727d501b95ee4d1ddbb881424b7170acf49e5' +
        '44bdb102ef75d28ce9ba9d644ecb557ed5a160b39c8ea12ee87440000000299cd00f1d1ae9bda5a3' +
        'ec9a225859d093eca16146b100d7297d81f6bf1db078c44e815ba8876bdadd779232863fe9a52c82' +
        'd4ea03c366eb93269dc344276317'

    $secret = ConvertTo-SecureString $ApiKey
    $secret = ConvertFrom-SecureString $secret -AsPlainText
    $Url = "https://api.imgbb.com/1/upload?key=$secret"

    $Img = [System.Windows.Forms.Clipboard]::GetImage()

    if ($Img) {
        try {
            [int] $W = $Img.Width * $Scale / 100
            [int] $H = $Img.Height * $Scale / 100
            $Scaled = New-Object 'System.Drawing.Bitmap' $Img, $W, $H

            try {
                $Buf = New-Object 'System.IO.MemoryStream'
                $Scaled.Save($Buf, [System.Drawing.Imaging.ImageFormat]::Png)
                $B64 = [System.Convert]::ToBase64String($Buf.ToArray())

                $Json = Invoke-WebRequest $Url -Method POST -Form @{ image = $B64 } |
                ConvertFrom-Json

                Write-Output $Json.data.url
            }
            finally {
                $Scaled.Dispose()
            }
        }
        finally {
            $Img.Dispose()
        }
    }
}

function Open-Vault {
    Start-Process "$env:OneDrive\Personal Vault"
}

function Compare-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Path1,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]
        $Path2
    )

    $c1 = Get-Content $Path1
    $c2 = Get-Content $Path2
    Compare-Object $c1 $c2
}

Set-Alias ln New-ItemLink
Set-Alias su Start-AdminTerminal
Set-Alias touch Set-ItemDateTime
Set-Alias fdiff Compare-File
Set-Alias gdiff Invoke-GnuDiff
Set-Alias sed Edit-File
Set-Alias split Split-Text
