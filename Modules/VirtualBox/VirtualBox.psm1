$vbman = "${env:VBOX_MSI_INSTALL_PATH}\VBoxManage.exe"
$vbox = New-Object -ComObject 'VirtualBox.VirtualBox'
$guestOSTypes = $null

Enum MachineState {
    None                   =  0
    Stopped                =  1
    Saved                  =  2
    Teleported             =  3
    Aborted                =  4
    Running                =  5
    Paused                 =  6
    Stuck                  =  7
    Snapshotting           =  8
    Starting               =  9
    Stopping               = 10
    Restoring              = 11
    TeleportingPausedVM    = 12
    TeleportingIn          = 13
    FaultTolerantSync      = 14
    DeletingSnapshotOnline = 15
    DeletingSnapshot       = 16
    SettingUp              = 17
}

function Add-ComObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [System.__ComObject]
        $ComObject,
        [Parameter(ValueFromPipeline)]
        [psobject]
        $InputObject
    )

    $InputObject | Add-Member NoteProperty -Name ComObject -Value $ComObject
}

function Get-VBoxGuestType {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string[]]
        [ArgumentCompleter({
            $w = $args[2]
            $w += -not $w.EndsWith("*") ? "*" : ""
            Get-VBoxGuestType "$w" | Select-Object -ExpandProperty Id
        })]
        $Filter = "*"
    )

    $guestOSTypes ??= $vbox.GuestOSTypes | ForEach-Object {
        [PSCustomObject]@{
            Id = $_.Id
            Description = $_.Description
            ComObject = $_
        }
    }

    $guestOSTypes | ForEach-Object {
        foreach($f in $Filter) {
            if($gt.Id -like $f) {
                Write-Output $_
                break
            }
        }
    }
}

class GuestTypeValidateSetGenerator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return Get-VBoxGuestType | Select-Object -ExpandProperty Id
    }
}

function New-VBoxMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]
        $Name,
        [Parameter(Mandatory)]
        [string]
        [ValidateSet([GuestTypeValidateSetGenerator])]
        $GuestType,
        [Parameter()]
        [string[]]
        $Group,
        [Parameter()]
        [switch]
        $Force
    )

    begin {
        $gt = Get-VBoxGuestType $GuestType |
            Select-Object -ExpandProperty ComObject
    }

    process {
        $Name | ForEach-Object {
            $vm = $vbox.CreateMachine(
                "", # settingsFile
                $_, # name
                [array]::Empty[string](), # groups
                $gt.Id, # guestOSType
                $Force ? "forceOwerwrite=1" : "", # flags
                "", # cipher,
                "", # passwordId,
                "" # password
            )

            $vm.CPUCount = $gt.RecommendedCPUCount
            $vm.MemorySize = $gt.RecommendedRAM
            $vm.GraphicsAdapter.GraphicsControllerType = $gt.RecommendedGraphicsController
            $vm.GraphicsAdapter.VRAMSize = $gt.RecommendedVRAM

            $vbox.RegisterMachine($vm)

            [PSCustomObject]@{
                Id = $vm.Id
                Name = $vm.Name
                State = [MachineState]$vm.State
            } | Add-ComObject $_
        }
    }
}

function Get-VBoxMachine {
    [CmdletBinding()]
    param (
    )

    begin {
    }

    process {
    }

    end {
    }
}

function Remove-VBoxMachine {
    [CmdletBinding()]
    param (
    )

    begin {
    }

    process {
    }

    end {
    }
}

function Start-VBoxMachine {
    [CmdletBinding()]
    param (
    )

    process {
    }
}

function Start-VM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [ArgumentCompleter({
            param ($x, $y, $w)
            Get-VM | Where-Object { -not $_.Running -and $_.Name -like "$w*" } |
            Select-Object -ExpandProperty Name
        })]
        [string[]]
        $Name = @() + (Get-VM | Where-Object -not Running | Select-Object -ExpandProperty Name),

        [Parameter(Mandatory = $false)]
        [ValidateSet('gui', 'headless')]
        $GuiType = 'headless'
    )

    process {
        $Name | ForEach-Object {
            & $vbman startvm $_ --type $GuiType
        }
    }
}

function Stop-VM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [ArgumentCompleter({
            param ($x, $y, $w)
            Get-VM | Where-Object { $_.Running -eq $true -and $_.Name -like "$w*" } |
            Select-Object -ExpandProperty Name
        })]
        [string[]]
        $Name = @() + (Get-VM | Where-Object Running | Select-Object -ExpandProperty Name)
    )

    process {
        $Name | ForEach-Object {
            & $vbman controlvm $_ acpipowerbutton
        }
    }
}

function New-VMSnaphot {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $Name
    )

    $timestamp = [datetime]::Now.ToString('yyyy/MM/dd HH:mm:ss')
    $snapshot = "$($Name): $timestamp"
    & $vbman snapshot $Name take $snapshot
}

function Compress-VMDisk {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]] $Path
    )

    process {
        $Path | Foreach-Object {
            if (Test-Path $_ -PathType Leaf) {
                & $vbman modifymedium disk $_ -compact
            }
        }
    }
}

Set-Alias vbman $vbman
Set-Alias nvm New-VBoxMachine
Set-Alias gvm Get-VBoxMachine
Set-Alias savm Start-VM
Set-Alias spvm Stop-VM
