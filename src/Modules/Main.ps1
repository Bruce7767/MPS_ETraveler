$DeveloperBtn.Add_Click({
    if ($Developer) {
        $script:Developer = $false
        Update-LockStyles
        return
    }

    [void](Require-Developer)
})

$SearchBtn.Add_Click({
    Select-DeviceByName -Name $SearchBox.Text
})

$SearchBox.Add_KeyDown({
    if ($_.Key -eq 'Enter') {
        Select-DeviceByName -Name $SearchBox.Text
    }
})

$RefreshBtn.Add_Click({
    $SearchBox.Text = ''
    $script:CurrentDevice = $null
    $script:CurrentTraveler = $null
    Refresh-DeviceView
})

$ViewAllBtn.Add_Click({
    Show-AllDevices
})

$RegisterBtn.Add_Click({
    Show-Register
})

$OtherDieBtn.Add_Click({
    Show-OtherDieList
})

$EditConfigBtn.Add_Click({
    Show-EditConfig
})

$TravelerList.Add_SelectionChanged({
    Refresh-TravelerView
})

$ViewXlsBtn.Add_Click({
    if ($CurrentTraveler) {
        Compile-Traveler -Traveler $CurrentTraveler -OpenAfter $true
    }
})

$CompileBtn.Add_Click({
    if ($CurrentTraveler) {
        Compile-Traveler -Traveler $CurrentTraveler -OpenAfter $false
    }
})

$OpenFolderBtn.Add_Click({
    Show-TemplateFolder
})

$EditSetupBtn.Add_Click({
    Show-EditSetup
})

$EditPagesBtn.Add_Click({
    Show-EditPages
})

Update-LockStyles
[void]$Window.ShowDialog()
