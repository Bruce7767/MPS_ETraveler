$ErrorActionPreference = 'Stop'

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

$testRoot = Join-Path $env:TEMP ('ETravelerTests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

try {
    $Root = $testRoot
    $moduleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\Modules'

    . (Join-Path $moduleRoot 'Data.ps1')
    . (Join-Path $moduleRoot 'Traveler.ps1')
    . (Join-Path $moduleRoot 'TravelerRules.ps1')
    . (Join-Path $moduleRoot 'DeviceDialogs.ps1')

    Assert-True -Condition (Test-Path -LiteralPath $DataFile -PathType Leaf) -Message 'Initial state file should be created.'

    $State.Flows += @('A->B')
    Save-State
    Assert-True -Condition (Test-Path -LiteralPath $DataBackupFile -PathType Leaf) -Message 'A previous valid state backup should be retained.'

    $primaryState = Import-StateFile -Path $DataFile
    $backupState = Import-StateFile -Path $DataBackupFile
    Assert-True -Condition (@($primaryState.Flows).Count -eq 1) -Message 'Primary state should contain the latest saved flow.'
    Assert-True -Condition (@($backupState.Flows).Count -eq 0) -Message 'Backup state should preserve the previous valid state.'

    $registry = New-Registry `
        -Id 'REG001' `
        -Workflow 'A' `
        -Site '4 Sites' `
        -Tester 'CTA8280F' `
        -Handler 'TK-Handler-Turret' `
        -Folder 'C:\Template' `
        -Slots @(
            (New-Slot -Kind 'Regular' -Path 'C:\P1.xls'),
            (New-Slot -Kind 'Regular' -Path 'C:\P2.xls'),
            (New-Slot -Kind 'Regular' -Path 'C:\P3.xls')
        )

    $State.Registries = @($registry)
    $match = Find-Registry `
        -Workflow 'A' `
        -Site '4 Sites' `
        -Tester 'CTA8280F' `
        -Handler 'TK-Handler-Turret'

    Assert-True -Condition ($match.Id -eq 'REG001') -Message 'Registry lookup should require the exact traveler key.'

    $wrongMatch = Find-Registry `
        -Workflow 'A' `
        -Site '2 Sites' `
        -Tester 'CTA8280F' `
        -Handler 'TK-Handler-Turret'

    Assert-True -Condition ($null -eq $wrongMatch) -Message 'A different Site must not match the same registry.'

    $traveler = New-Traveler `
        -Workflow 'A' `
        -Site '4 Sites' `
        -Tester 'CTA8280F' `
        -Handler 'TK-Handler-Turret' `
        -BakingRequired $false `
        -GsRequired $false `
        -RegistryId 'REG001'

    Ensure-SpecialSlotsForTraveler -Traveler $traveler -Registry $registry
    $pages = @(Get-ActivePages -Traveler $traveler -Registry $registry)

    Assert-True -Condition (@($pages | Where-Object { $_.Label -like 'Baking*' }).Count -eq 0) -Message 'Baking Not Required must not show a Baking page.'
    Assert-True -Condition (@($pages | Where-Object { $_.Label -eq 'GS (Not Required)' }).Count -eq 1) -Message 'GS Not Required must still show one GS page.'

    $traveler.BakingRequired = $true
    $traveler.GsRequired = $true
    Ensure-SpecialSlotsForTraveler -Traveler $traveler -Registry $registry
    $pages = @(Get-ActivePages -Traveler $traveler -Registry $registry)

    Assert-True -Condition (@($pages | Where-Object { $_.Label -eq 'Baking (Required)' }).Count -eq 1) -Message 'Baking Required must show exactly one Baking page.'
    Assert-True -Condition (@($pages | Where-Object { $_.Label -eq 'GS (Required)' }).Count -eq 1) -Message 'GS Required must show exactly one GS page.'

    $existingTraveler = New-Traveler `
        -Workflow 'A' `
        -Site '8 Sites' `
        -Tester 'STS8200' `
        -Handler 'TK-Handler-PNP' `
        -BakingRequired $true `
        -GsRequired $true `
        -RegistryId 'REG999'

    $flowTravelers = @(
        New-TravelersForFlow `
            -Flow 'A->B' `
            -ExistingTravelers @($existingTraveler)
    )

    Assert-True -Condition ($flowTravelers.Count -eq 2) -Message 'A two-workflow flow should create two travelers.'
    Assert-True -Condition ($flowTravelers[0].RegistryId -eq 'REG999') -Message 'Existing workflow configuration should be preserved.'
    Assert-True -Condition ([string]::IsNullOrWhiteSpace($flowTravelers[1].RegistryId)) -Message 'A newly introduced workflow must start unassigned.'

    Write-Host 'E-Traveler core logic checks passed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
