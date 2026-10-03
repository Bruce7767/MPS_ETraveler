function Get-Registry {
    param([string]$Id)

    @($State.Registries | Where-Object { $_.Id -eq $Id }) | Select-Object -First 1
}

function Find-Registry {
    param(
        [string]$Workflow,
        [string]$Site,
        [string]$Tester,
        [string]$Handler
    )

    @(
        $State.Registries | Where-Object {
            $_.Workflow -eq $Workflow -and
            $_.Site -eq $Site -and
            $_.Tester -eq $Tester -and
            $_.Handler -eq $Handler
        }
    ) | Select-Object -First 1
}

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
        $bakingPath = if ($Registry.Folder) {
            Join-Path $Registry.Folder 'Baking_Required.xls'
        }
        else {
            ''
        }

        $null = $slots.Insert($insertIndex, (New-Slot -Kind 'Baking' -Path $bakingPath))
        $insertIndex++
    }

    if (-not $hasGoldenSampleSlot) {
        $requiredPath = if ($Registry.Folder) {
            Join-Path $Registry.Folder 'GS_Required.xls'
        }
        else {
            ''
        }

        $notRequiredPath = if ($Registry.Folder) {
            Join-Path $Registry.Folder 'GS_Not_Required.xls'
        }
        else {
            ''
        }

        $null = $slots.Insert(
            $insertIndex,
            (New-Slot -Kind 'GS' -Required $requiredPath -NotRequired $notRequiredPath)
        )
    }

    $Registry.Slots = @($slots)
}

function Get-ActivePages {
    param(
        $Traveler,
        $Registry
    )

    Ensure-SpecialSlotsForTraveler -Traveler $Traveler -Registry $Registry

    $pageNumber = 0
    $pages = @()

    foreach ($slot in @($Registry.Slots)) {
        switch ($slot.Kind) {
            'Baking' {
                if ($Traveler.BakingRequired) {
                    $pages += [pscustomobject]@{
                        Label = 'Baking (Required)'
                        Slot = $slot
                        Path = $slot.Path
                    }
                }
                continue
            }
            'GS' {
                $pages += [pscustomobject]@{
                    Label = if ($Traveler.GsRequired) { 'GS (Required)' } else { 'GS (Not Required)' }
                    Slot = $slot
                    Path = if ($Traveler.GsRequired) { $slot.RequiredPath } else { $slot.NotRequiredPath }
                }
                continue
            }
            default {
                $pageNumber++
                $pages += [pscustomobject]@{
                    Label = "Page $pageNumber"
                    Slot = $slot
                    Path = $slot.Path
                }
            }
        }
    }

    @($pages)
}

function Update-LockStyles {
    $maintenanceStyle = if ($Developer) {
        $Window.Resources['PrimaryBtn']
    }
    else {
        $Window.Resources['LockedBtn']
    }

    $EditConfigBtn.Style = $maintenanceStyle
    $EditSetupBtn.Style = $maintenanceStyle
    $EditPagesBtn.Style = $maintenanceStyle
    $DeveloperBtn.Content = if ($Developer) { 'Developer Mode  ON' } else { 'Developer Mode' }
}

function Refresh-DeviceView {
    if (-not $CurrentDevice) {
        $DeviceCard.Visibility = 'Collapsed'
        $TravelerCard.Visibility = 'Collapsed'
        return
    }

    $DeviceCard.Visibility = 'Visible'
    $TravelerCard.Visibility = 'Visible'
    $DeviceNameText.Text = $CurrentDevice.Device
    $DieText.Text = "Die: $($CurrentDevice.Die)"
    $FlowText.Text = "Device Flow: $($CurrentDevice.Flow)"

    $TravelerList.Items.Clear()
    foreach ($traveler in @($CurrentDevice.Travelers)) {
        [void]$TravelerList.Items.Add($traveler.Workflow)
    }

    if ($TravelerList.Items.Count -gt 0) {
        $TravelerList.SelectedIndex = 0
    }
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
    $RegistryText.Text = if ($registry) { $registry.Id } else { 'Not Defined' }
}

function Select-DeviceByName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return
    }

    $matches = @($State.Devices | Where-Object { $_.Device -like "*$Name*" })
    if ($matches.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Device not found.', 'E-Traveler') | Out-Null
        return
    }

    $script:CurrentDevice = $matches[0]
    Refresh-DeviceView
}

function Require-Developer {
    if ($Developer) {
        return $true
    }

    [xml]$loginXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Developer Login"
        Width="430" Height="245"
        WindowStartupLocation="CenterOwner"
        ResizeMode="NoResize"
        ShowInTaskbar="False"
        Background="#F8FAFC">
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Text="Developer Login" FontSize="22" FontWeight="Bold" Margin="0,0,0,18"/>
    <TextBlock Grid.Row="1" Text="Password" Margin="0,0,0,6"/>
    <PasswordBox Name="Password" Grid.Row="2" Height="38" FontSize="16" Padding="8"/>
    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button Name="Cancel" Content="Cancel" MinWidth="96" Padding="18,8" Margin="0,0,8,0"/>
      <Button Name="Login" Content="Login" MinWidth="96" Padding="18,8" Background="#2563EB" Foreground="White"/>
    </StackPanel>
  </Grid>
</Window>
'@

    $loginWindow = Load-Xaml $loginXaml
    $loginWindow.Owner = $Window
    $passwordBox = $loginWindow.FindName('Password')
    $loginButton = $loginWindow.FindName('Login')
    $cancelButton = $loginWindow.FindName('Cancel')
    $loginWindow.Tag = $false

    $submitLogin = {
        if ($passwordBox.Password -eq '1234') {
            $loginWindow.Tag = $true
            $loginWindow.DialogResult = $true
            return
        }

        [System.Windows.MessageBox]::Show('Incorrect password.', 'E-Traveler') | Out-Null
        $passwordBox.Clear()
        $passwordBox.Focus()
    }

    $loginButton.Add_Click($submitLogin)
    $cancelButton.Add_Click({
        $loginWindow.Tag = $false
        $loginWindow.DialogResult = $false
    })
    $passwordBox.Add_KeyDown({
        param($Sender, $EventArgs)

        if ($EventArgs.Key -eq 'Enter') {
            & $submitLogin
        }
    })

    $null = $passwordBox.Focus()
    [void]$loginWindow.ShowDialog()

    if ($loginWindow.Tag -ne $true) {
        return $false
    }

    $script:Developer = $true
    Update-LockStyles
    $true
}

function Pick-Folder {
    param([string]$Initial = '')

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select Template Folder'

    if ($Initial -and (Test-Path -LiteralPath $Initial)) {
        $dialog.SelectedPath = $Initial
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }

    $null
}

function Pick-Xls {
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = 'Excel 97-2003 Workbook (*.xls)|*.xls|All Files (*.*)|*.*'
    $dialog.Title = 'Select Traveler Page (.xls)'

    if ($dialog.ShowDialog($Window)) {
        return $dialog.FileName
    }

    $null
}

function ConvertTo-SafeFileName {
    param([string]$Value)

    $Value -replace '[\\/:*?"<>|]', '_'
}

function Release-ComObject {
    param($ComObject)

    if ($null -ne $ComObject) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($ComObject)
    }
}

function Compile-Traveler {
    param(
        $Traveler,
        [bool]$OpenAfter = $false
    )

    $registry = Get-Registry -Id $Traveler.RegistryId
    if (-not $registry) {
        [System.Windows.MessageBox]::Show('Template Folder is not defined.', 'E-Traveler') | Out-Null
        return
    }

    $pages = Get-ActivePages -Traveler $Traveler -Registry $registry
    $missingPages = @(
        $pages | Where-Object {
            -not $_.Path -or -not (Test-Path -LiteralPath $_.Path -PathType Leaf)
        }
    )

    if ($missingPages.Count -gt 0) {
        $details = $missingPages | ForEach-Object {
            "$($_.Label)`n$($_.Path)"
        }
        $message = "Compile blocked. Source .xls not found:`n`n" + ($details -join "`n`n")
        [System.Windows.MessageBox]::Show($message, 'E-Traveler') | Out-Null
        return
    }

    $deviceName = ConvertTo-SafeFileName $CurrentDevice.Device
    $dieName = ConvertTo-SafeFileName $CurrentDevice.Die
    $workflowName = ConvertTo-SafeFileName $Traveler.Workflow

    $outputDirectory = Join-Path (Join-Path $OutputDir $deviceName) $dieName
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    $outputPath = Join-Path $outputDirectory ($workflowName + '.xls')

    $excel = $null
    $destinationWorkbook = $null

    try {
        if (Test-Path -LiteralPath $outputPath) {
            Remove-Item -LiteralPath $outputPath -Force
        }

        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false
        $excel.ScreenUpdating = $false
        $excel.EnableEvents = $false

        $destinationWorkbook = $excel.Workbooks.Add()
        $defaultSheetCount = $destinationWorkbook.Worksheets.Count

        foreach ($page in $pages) {
            $sourceWorkbook = $null
            $sourceSheet = $null
            $afterSheet = $null

            try {
                $sourceWorkbook = $excel.Workbooks.Open($page.Path, 0, $true)
                $sourceSheet = $sourceWorkbook.Worksheets.Item(1)
                $afterSheet = $destinationWorkbook.Worksheets.Item($destinationWorkbook.Worksheets.Count)
                $sourceSheet.Copy($null, $afterSheet)
            }
            finally {
                Release-ComObject $afterSheet
                Release-ComObject $sourceSheet

                if ($sourceWorkbook) {
                    $sourceWorkbook.Close($false)
                    Release-ComObject $sourceWorkbook
                }
            }
        }

        for ($index = 0; $index -lt $defaultSheetCount; $index++) {
            $sheet = $destinationWorkbook.Worksheets.Item(1)
            $sheet.Delete()
            Release-ComObject $sheet
        }

        try {
            $destinationWorkbook.CheckCompatibility = $false
        }
        catch {
        }

        $destinationWorkbook.SaveAs($outputPath, 56)
        $destinationWorkbook.Close($true)
        Release-ComObject $destinationWorkbook
        $destinationWorkbook = $null

        $excel.Quit()
        Release-ComObject $excel
        $excel = $null

        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()

        if ($OpenAfter) {
            try {
                Start-Process excel.exe -ArgumentList @('/r', ('"' + $outputPath + '"'))
            }
            catch {
                Start-Process $outputPath
            }
            return
        }

        [System.Windows.MessageBox]::Show(
            "Traveler compiled successfully.`n`n$outputPath",
            'E-Traveler'
        ) | Out-Null
    }
    catch {
        try {
            if ($destinationWorkbook) {
                $destinationWorkbook.Close($false)
            }
        }
        catch {
        }

        try {
            if ($excel) {
                $excel.Quit()
            }
        }
        catch {
        }

        Release-ComObject $destinationWorkbook
        Release-ComObject $excel
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()

        [System.Windows.MessageBox]::Show(
            "Excel compilation failed:`n`n$($_.Exception.Message)",
            'E-Traveler'
        ) | Out-Null
    }
}
