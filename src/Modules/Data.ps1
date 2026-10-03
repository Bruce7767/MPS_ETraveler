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

function Restore-StateFromBackup {
    param([bool]$PreservePrimaryAsCorruptCopy = $false)

    $recoveredState = Import-StateFile -Path $DataBackupFile
    $corruptFile = $null

    if ($PreservePrimaryAsCorruptCopy -and (Test-Path -LiteralPath $DataFile -PathType Leaf)) {
        $corruptFile = Join-Path $DataDir (
            'E_Traveler_WPF_PreRelease.corrupt-{0}.json' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
        )
        Move-Item -LiteralPath $DataFile -Destination $corruptFile -Force
    }

    Copy-Item -LiteralPath $DataBackupFile -Destination $DataFile -Force
    $script:State = $recoveredState

    $message = if ($corruptFile) {
        "The primary local data file was damaged. E-Traveler recovered the previous valid backup.`n`nDamaged copy:`n$corruptFile"
    }
    else {
        'The primary local data file was missing. E-Traveler recovered the previous valid backup.'
    }

    [System.Windows.MessageBox]::Show(
        $message,
        'E-Traveler Data Recovery',
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    ) | Out-Null
}

if (Test-Path -LiteralPath $DataFile -PathType Leaf) {
    try {
        $script:State = Import-StateFile -Path $DataFile
    }
    catch {
        $primaryError = $_.Exception.Message
        if (-not (Test-Path -LiteralPath $DataBackupFile -PathType Leaf)) {
            throw "Local E-Traveler data could not be read. The existing file was not overwritten. $primaryError"
        }

        try {
            Restore-StateFromBackup -PreservePrimaryAsCorruptCopy $true
        }
        catch {
            throw "The primary E-Traveler data file could not be read and backup recovery also failed. No data was intentionally reset. Primary error: $primaryError Backup error: $($_.Exception.Message)"
        }
    }
}
elseif (Test-Path -LiteralPath $DataBackupFile -PathType Leaf) {
    try {
        Restore-StateFromBackup
    }
    catch {
        throw "The primary E-Traveler data file is missing and the backup could not be recovered. No empty database was created. $($_.Exception.Message)"
    }
}
else {
    $script:State = New-DefaultState
    Save-State
}

$script:Developer = $false
$script:CurrentDevice = $null
$script:CurrentTraveler = $null
