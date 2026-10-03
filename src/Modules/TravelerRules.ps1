function Ensure-SpecialSlotsForTraveler {
    param(
        $Traveler,
        $Registry
    )

    if (-not $Traveler -or -not $Registry) {
        return
    }

    $slots = [System.Collections.ArrayList]@(@($Registry.Slots))
    $hasBakingSlot = @($slots | Where-Object { $_.Kind -eq 'Baking' }).Count -gt 0
    $hasGoldenSampleSlot = @($slots | Where-Object { $_.Kind -eq 'GS' }).Count -gt 0
    $insertIndex = [Math]::Min(2, $slots.Count)

    if ($Traveler.BakingRequired -and -not $hasBakingSlot) {
        $null = $slots.Insert(
            $insertIndex,
            (New-Slot -Kind 'Baking')
        )
        $insertIndex++
    }

    if (-not $hasGoldenSampleSlot) {
        $null = $slots.Insert(
            $insertIndex,
            (New-Slot -Kind 'GS')
        )
    }

    $Registry.Slots = @($slots)
}

function Update-LockStyles {
    $maintenanceStyle = if ($Developer) {
        $Window.Resources['PrimaryBtn']
    }
    else {
        $Window.Resources['LockedBtn']
    }

    $RegisterBtn.Style = $maintenanceStyle
    $EditConfigBtn.Style = $maintenanceStyle
    $EditSetupBtn.Style = $maintenanceStyle
    $EditPagesBtn.Style = $maintenanceStyle
    $DeveloperBtn.Content = if ($Developer) { 'Developer Mode  ON' } else { 'Developer Mode' }
}

function Refresh-DeviceView {
    $script:CurrentTraveler = $null
    $TravelerList.Items.Clear()

    if (-not $CurrentDevice) {
        $DeviceCard.Visibility = 'Collapsed'
        $TravelerCard.Visibility = 'Collapsed'
        return
    }

    $DeviceCard.Visibility = 'Visible'
    $DeviceNameText.Text = $CurrentDevice.Device
    $DieText.Text = "Die: $($CurrentDevice.Die)"
    $FlowText.Text = "Device Flow: $($CurrentDevice.Flow)"

    foreach ($traveler in @($CurrentDevice.Travelers)) {
        if ($traveler -and $traveler.Workflow) {
            [void]$TravelerList.Items.Add($traveler.Workflow)
        }
    }

    if ($TravelerList.Items.Count -gt 0) {
        $TravelerCard.Visibility = 'Visible'
        $TravelerList.SelectedIndex = 0
    }
    else {
        $TravelerCard.Visibility = 'Collapsed'
    }
}

function Refresh-TravelerView {
    if (-not $CurrentDevice) {
        $script:CurrentTraveler = $null
        return
    }

    $travelers = @($CurrentDevice.Travelers)
    $selectedIndex = $TravelerList.SelectedIndex
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $travelers.Count) {
        $script:CurrentTraveler = $null
        return
    }

    $script:CurrentTraveler = $travelers[$selectedIndex]
    if (-not $CurrentTraveler) {
        return
    }

    $WorkflowTitle.Text = $CurrentTraveler.Workflow
    $SiteText.Text = $CurrentTraveler.Site
    $TesterText.Text = $CurrentTraveler.Tester
    $HandlerText.Text = $CurrentTraveler.Handler
    $BakingText.Text = if ($CurrentTraveler.BakingRequired) { 'Required' } else { 'Not Required' }
    $GsText.Text = if ($CurrentTraveler.GsRequired) { 'Required' } else { 'Not Required' }

    $registry = Get-Registry -Id $CurrentTraveler.RegistryId
    $RegistryText.Text = if ($registry -and $registry.Folder) {
        $registry.Folder
    }
    else {
        'Not Defined'
    }
}
