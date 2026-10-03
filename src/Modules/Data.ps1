$DataDir = Join-Path $Root 'Data'
$OutputDir = Join-Path $Root 'Output'
$DataFile = Join-Path $DataDir 'E_Traveler_WPF_PreRelease.json'

New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

function New-Slot {
    param(
        [string]$Kind,
        [string]$Path = '',
        [string]$Required = '',
        [string]$NotRequired = ''
    )

    [pscustomobject]@{
        Kind = $Kind
        Path = $Path
        RequiredPath = $Required
        NotRequiredPath = $NotRequired
    }
}

function New-Registry {
    param(
        [string]$Id,
        [string]$Workflow,
        [string]$Site,
        [string]$Tester,
        [string]$Handler,
        [string]$Folder,
        [object[]]$Slots
    )

    [pscustomobject]@{
        Id = $Id
        Workflow = $Workflow
        Site = $Site
        Tester = $Tester
        Handler = $Handler
        Folder = $Folder
        Slots = @($Slots)
    }
}

function New-Traveler {
    param(
        [string]$Workflow,
        [string]$Site,
        [string]$Tester,
        [string]$Handler,
        [bool]$BakingRequired,
        [bool]$GsRequired,
        [string]$RegistryId
    )

    [pscustomobject]@{
        Workflow = $Workflow
        Site = $Site
        Tester = $Tester
        Handler = $Handler
        BakingRequired = $BakingRequired
        GsRequired = $GsRequired
        RegistryId = $RegistryId
    }
}

function New-Device {
    param(
        [string]$Device,
        [string]$Die,
        [string]$Flow,
        [object[]]$Travelers
    )

    [pscustomobject]@{
        Device = $Device
        Die = $Die
        Flow = $Flow
        Travelers = @($Travelers)
    }
}

function New-DefaultState {
    [pscustomobject]@{
        Flows = @()
        Registries = @()
        Devices = @()
    }
}

function Save-State {
    $script:State |
        ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $DataFile -Encoding UTF8
}

if (Test-Path -LiteralPath $DataFile) {
    try {
        $script:State = Get-Content -LiteralPath $DataFile -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        $script:State = New-DefaultState
        Save-State
    }
}
else {
    $script:State = New-DefaultState
    Save-State
}

$script:Developer = $false
$script:CurrentDevice = $null
$script:CurrentTraveler = $null
