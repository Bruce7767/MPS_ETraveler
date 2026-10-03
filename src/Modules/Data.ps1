$DataDir = Join-Path $Root 'Data'
$OutputDir = Join-Path $Root 'Output'
$DataFile = Join-Path $DataDir 'E_Traveler_WPF_PreRelease.json'
$DataBackupFile = Join-Path $DataDir 'E_Traveler_WPF_PreRelease.bak.json'

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

function Assert-StateShape {
    param($StateObject)

    if (-not $StateObject) {
        throw 'State data is empty.'
    }

    $requiredProperties = @('Flows', 'Registries', 'Devices')
    foreach ($propertyName in $requiredProperties) {
        if (-not ($StateObject.PSObject.Properties.Name -contains $propertyName)) {
            throw "State data is missing required property '$propertyName'."
        }
    }
}

function Import-StateFile {
    param([string]$Path)

    $stateObject = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-StateShape -StateObject $stateObject
    $stateObject
}

function Save-State {
    $temporaryFile = Join-Path $DataDir ("state-{0}.tmp" -f [guid]::NewGuid().ToString('N'))

    try {
        $script:State |
            ConvertTo-Json -Depth 12 |
            Set-Content -LiteralPath $temporaryFile -Encoding UTF8

        # Validate the serialized copy before replacing the current database.
        $null = Import-StateFile -Path $temporaryFile

        if (Test-Path -LiteralPath $DataFile -PathType Leaf) {
            if (Test-Path -LiteralPath $DataBackupFile -PathType Leaf) {
                Remove-Item -LiteralPath $DataBackupFile -Force
            }

            [System.IO.File]::Replace(
                $temporaryFile,
                $DataFile,
                $DataBackupFile
            )
        }
        else {
            [System.IO.File]::Move($temporaryFile, $DataFile)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryFile -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryFile -Force -ErrorAction SilentlyContinue
        }
    }
}

if (Test-Path -LiteralPath $DataFile -PathType Leaf) {
    try {
        $script:State = Import-StateFile -Path $DataFile
    }
    catch {
        if (-not (Test-Path -LiteralPath $DataBackupFile -PathType Leaf)) {
            throw "Local E-Traveler data could not be read. The existing file was not overwritten. $($_.Exception.Message)"
        }

        try {
            $recoveredState = Import-StateFile -Path $DataBackupFile
            $corruptFile = Join-Path $DataDir (
                'E_Traveler_WPF_PreRelease.corrupt-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
            )

            Move-Item -LiteralPath $DataFile -Destination $corruptFile -Force
            Copy-Item -LiteralPath $DataBackupFile -Destination $DataFile -Force
            $script:State = $recoveredState

            [System.Windows.MessageBox]::Show(
                "The primary local data file was damaged. E-Traveler recovered the previous valid backup.`n`nDamaged copy:`n$corruptFile",
                'E-Traveler Data Recovery',
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        }
        catch {
            throw "Both the primary E-Traveler data file and its backup could not be read. No data was overwritten. $($_.Exception.Message)"
        }
    }
}
else {
    $script:State = New-DefaultState
    Save-State
}

$script:Developer = $false
$script:CurrentDevice = $null
$script:CurrentTraveler = $null
