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

function Refresh-TravelerView {
    if (-not $CurrentDevice -or $TravelerList.SelectedIndex -lt 0) {
        return
    }

    $script:CurrentTraveler = @($CurrentDevice.Travelers)[$TravelerList.SelectedIndex]

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
