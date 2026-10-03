function New-TravelersForFlow {
    param(
        [string]$Flow,
        [object[]]$ExistingTravelers = @()
    )

    $existingByWorkflow = @{}
    foreach ($traveler in @($ExistingTravelers)) {
        if ($traveler -and $traveler.Workflow) {
            $existingByWorkflow[$traveler.Workflow] = $traveler
        }
    }

    $travelers = @()
    foreach ($workflowText in ($Flow -split '->')) {
        $workflow = $workflowText.Trim()
        if ([string]::IsNullOrWhiteSpace($workflow)) {
            continue
        }

        if ($existingByWorkflow.ContainsKey($workflow)) {
            $travelers += @($existingByWorkflow[$workflow])
            continue
        }

        # New workflow entries start unassigned. Edit Setup must bind the exact
        # Workflow + Site + Tester + Handler registry before pages can compile.
        $travelers += @(
            New-Traveler `
                -Workflow $workflow `
                -Site '4 Sites' `
                -Tester 'CTA8280F' `
                -Handler 'TK-Handler-Turret' `
                -BakingRequired $false `
                -GsRequired $false `
                -RegistryId ''
        )
    }

    @($travelers)
}

function Show-EditConfig {
    if (-not (Require-Developer)) {
        return
    }
    if (-not $CurrentDevice) {
        return
    }

    $device = $CurrentDevice

    [xml]$configXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Edit Config"
        Width="900" Height="310"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <StackPanel Margin="24">
    <TextBlock Text="Edit Config" FontSize="22" FontWeight="Bold"/>
    <Grid Margin="0,22,0,0">
      <Grid.ColumnDefinitions>
        <ColumnDefinition/>
        <ColumnDefinition Width="20"/>
        <ColumnDefinition/>
      </Grid.ColumnDefinitions>
      <StackPanel>
        <TextBlock Text="Die"/>
        <ComboBox Name="Die" Height="38"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Device Flow"/>
        <ComboBox Name="Flow" Height="38"/>
      </StackPanel>
    </Grid>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,28,0,0">
      <Button Name="Cancel" Content="Cancel" Padding="18,9" Margin="0,0,8,0"/>
      <Button Name="Save" Content="Save &amp; Refresh Travelers" Padding="20,9" Background="#2563EB" Foreground="White"/>
    </StackPanel>
  </StackPanel>
</Window>
'@

    $dialog = Load-Xaml $configXaml
    $dialog.Owner = $Window
    $dieBox = $dialog.FindName('Die')
    $flowBox = $dialog.FindName('Flow')

    0..99 | ForEach-Object {
        [void]$dieBox.Items.Add("R$_")
    }
    foreach ($flow in @($State.Flows)) {
        [void]$flowBox.Items.Add($flow)
    }

    $dieBox.SelectedItem = $device.Die
    $flowBox.SelectedItem = $device.Flow

    $dialog.FindName('Cancel').Add_Click({
        $dialog.Close()
    })

    $dialog.FindName('Save').Add_Click({
        $newDie = [string]$dieBox.SelectedItem
        $newFlow = [string]$flowBox.SelectedItem

        if ([string]::IsNullOrWhiteSpace($newDie)) {
            [System.Windows.MessageBox]::Show('Select a Die.', 'E-Traveler') | Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($newFlow)) {
            [System.Windows.MessageBox]::Show('Select a Device Flow.', 'E-Traveler') | Out-Null
            return
        }

        $duplicate = @(
            $State.Devices | Where-Object {
                $_.Device -eq $device.Device -and
                $_.Die -eq $newDie -and
                $_ -ne $device
            }
        )
        if ($duplicate.Count -gt 0) {
            [System.Windows.MessageBox]::Show('This Device + Die already exists.', 'E-Traveler') | Out-Null
            return
        }

        $device.Die = $newDie
        $device.Flow = $newFlow
        $device.Travelers = @(
            New-TravelersForFlow -Flow $newFlow -ExistingTravelers @($device.Travelers)
        )

        Save-State
        $dialog.Close()
        Refresh-DeviceView
    })

    [void]$dialog.ShowDialog()
}

function Show-Register {
    if (-not (Require-Developer)) {
        return
    }

    [xml]$registerXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Register Device / Die"
        Width="940" Height="390"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <StackPanel Margin="24">
    <TextBlock Text="Register Device / Die" FontSize="22" FontWeight="Bold"/>
    <Grid Margin="0,22,0,0">
      <Grid.ColumnDefinitions>
        <ColumnDefinition/>
        <ColumnDefinition Width="20"/>
        <ColumnDefinition/>
      </Grid.ColumnDefinitions>
      <StackPanel>
        <TextBlock Text="Device Name"/>
        <TextBox Name="Device" Height="38" Padding="8"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Die"/>
        <ComboBox Name="Die" Height="38"/>
      </StackPanel>
    </Grid>
    <TextBlock Text="Device Flow" Margin="0,18,0,5"/>
    <ComboBox Name="Flow" Height="38"/>
    <WrapPanel Margin="0,18,0,0">
      <Button Name="AddFlow" Content="+ Add New Flow" Padding="16,9" Margin="0,0,8,0"/>
      <Button Name="DeleteFlow" Content="Delete Flow" Padding="16,9" Margin="0,0,18,0"/>
      <Button Name="Save" Content="Save" Padding="20,9" Background="#2563EB" Foreground="White" Margin="0,0,8,0"/>
      <Button Name="Cancel" Content="Cancel" Padding="18,9"/>
    </WrapPanel>
  </StackPanel>
</Window>
'@

    $dialog = Load-Xaml $registerXaml
    $dialog.Owner = $Window
    $deviceBox = $dialog.FindName('Device')
    $dieBox = $dialog.FindName('Die')
    $flowBox = $dialog.FindName('Flow')

    0..99 | ForEach-Object {
        [void]$dieBox.Items.Add("R$_")
    }
    $dieBox.SelectedIndex = 0

    foreach ($flow in @($State.Flows)) {
        [void]$flowBox.Items.Add($flow)
    }
    if ($flowBox.Items.Count -gt 0) {
        $flowBox.SelectedIndex = 0
    }

    $dialog.FindName('AddFlow').Add_Click({
        $newFlow = [Microsoft.VisualBasic.Interaction]::InputBox(
            'Enter complete Device Flow. Use -> between workflow travelers.',
            'Add New Flow',
            ''
        ).Trim()

        if ([string]::IsNullOrWhiteSpace($newFlow)) {
            return
        }
        if (@($State.Flows) -contains $newFlow) {
            [System.Windows.MessageBox]::Show('This Device Flow already exists.', 'E-Traveler') | Out-Null
            return
        }

        $State.Flows += @($newFlow)
        [void]$flowBox.Items.Add($newFlow)
        $flowBox.SelectedItem = $newFlow
        Save-State
    })

    $dialog.FindName('DeleteFlow').Add_Click({
        $selectedFlow = [string]$flowBox.SelectedItem
        if ([string]::IsNullOrWhiteSpace($selectedFlow)) {
            return
        }

        $usedBy = @($State.Devices | Where-Object { $_.Flow -eq $selectedFlow })
        if ($usedBy.Count -gt 0) {
            $shownDevices = @(
                $usedBy |
                    Select-Object -First 8 |
                    ForEach-Object { "$($_.Device) / $($_.Die)" }
            )
            $remainingText = if ($usedBy.Count -gt 8) {
                "`n...and $($usedBy.Count - 8) more"
            }
            else {
                ''
            }

            $message = @(
                "WARNING: This Device Flow is currently used by $($usedBy.Count) Device/Die configuration(s):"
                ''
                ($shownDevices -join "`n") + $remainingText
                ''
                'Deleting the Flow removes it from the Flow selection list only.'
                'Existing registered Device/Die records will remain unchanged.'
                ''
                'Proceed with delete?'
            ) -join "`n"

            $answer = [System.Windows.MessageBox]::Show(
                $message,
                'Delete Device Flow',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }
        }
        else {
            $answer = [System.Windows.MessageBox]::Show(
                "Delete this Device Flow?`n`n$selectedFlow",
                'Delete Device Flow',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }
        }

        $State.Flows = @($State.Flows | Where-Object { $_ -ne $selectedFlow })
        $flowBox.Items.Clear()
        foreach ($flow in @($State.Flows)) {
            [void]$flowBox.Items.Add($flow)
        }
        if ($flowBox.Items.Count -gt 0) {
            $flowBox.SelectedIndex = 0
        }
        Save-State
    })

    $dialog.FindName('Cancel').Add_Click({
        $dialog.Close()
    })

    $dialog.FindName('Save').Add_Click({
        $deviceName = $deviceBox.Text.Trim()
        $selectedDie = [string]$dieBox.SelectedItem
        $selectedFlow = [string]$flowBox.SelectedItem

        if ([string]::IsNullOrWhiteSpace($deviceName)) {
            [System.Windows.MessageBox]::Show('Device Name is required.', 'E-Traveler') | Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($selectedDie)) {
            [System.Windows.MessageBox]::Show('Select a Die.', 'E-Traveler') | Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($selectedFlow)) {
            [System.Windows.MessageBox]::Show('Select a Device Flow.', 'E-Traveler') | Out-Null
            return
        }

        $duplicate = @(
            $State.Devices | Where-Object {
                $_.Device -eq $deviceName -and $_.Die -eq $selectedDie
            }
        )
        if ($duplicate.Count -gt 0) {
            [System.Windows.MessageBox]::Show('This Device + Die already exists.', 'E-Traveler') | Out-Null
            return
        }

        $travelers = @(New-TravelersForFlow -Flow $selectedFlow)
        $newDevice = New-Device -Device $deviceName -Die $selectedDie -Flow $selectedFlow -Travelers $travelers
        $State.Devices += @($newDevice)
        Save-State

        $script:CurrentDevice = $newDevice
        $dialog.Close()
        Refresh-DeviceView
    })

    [void]$dialog.ShowDialog()
}

function Show-OtherDieList {
    if (-not $CurrentDevice) {
        return
    }

    $matches = @(
        $State.Devices |
            Where-Object { $_.Device -eq $CurrentDevice.Device } |
            Sort-Object Die
    )

    [xml]$dieListXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Other Die"
        Width="900" Height="520"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel>
      <TextBlock Name="Head" FontSize="22" FontWeight="Bold"/>
      <TextBlock Text="Select the Die configuration to open." Foreground="#64748B" Margin="0,5,0,0"/>
    </StackPanel>
    <DataGrid Name="Grid" Grid.Row="1" Margin="0,18,0,18" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Die" Binding="{Binding Die}" Width="110"/>
        <DataGridTextColumn Header="Device Flow" Binding="{Binding Flow}" Width="*"/>
      </DataGrid.Columns>
    </DataGrid>
    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="Close" Content="Close" Padding="18,9" Margin="0,0,8,0"/>
      <Button Name="Open" Content="Open" Padding="20,9" Background="#2563EB" Foreground="White"/>
    </StackPanel>
  </Grid>
</Window>
'@

    $dialog = Load-Xaml $dieListXaml
    $dialog.Owner = $Window
    $dialog.FindName('Head').Text = "$($CurrentDevice.Device) - Die Configurations"
    $grid = $dialog.FindName('Grid')
    $grid.ItemsSource = $matches

    if ($matches.Count -gt 0) {
        $currentIndex = [Array]::IndexOf($matches, $CurrentDevice)
        $grid.SelectedIndex = if ($currentIndex -ge 0) { $currentIndex } else { 0 }
    }

    $openSelectedDie = {
        if (-not $grid.SelectedItem) {
            return
        }

        $script:CurrentDevice = $grid.SelectedItem
        $dialog.Close()
        Refresh-DeviceView
    }

    $dialog.FindName('Open').Add_Click($openSelectedDie)
    $grid.Add_MouseDoubleClick($openSelectedDie)
    $dialog.FindName('Close').Add_Click({
        $dialog.Close()
    })

    [void]$dialog.ShowDialog()
}

function Show-AllDevices {
    [xml]$deviceListXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="All Devices"
        Width="1000" Height="600"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Text="All Device / Die Configurations" FontSize="22" FontWeight="Bold"/>
    <DataGrid Name="Grid" Grid.Row="1" Margin="0,18,0,18" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Device" Binding="{Binding Device}" Width="140"/>
        <DataGridTextColumn Header="Die" Binding="{Binding Die}" Width="90"/>
        <DataGridTextColumn Header="Device Flow" Binding="{Binding Flow}" Width="*"/>
      </DataGrid.Columns>
    </DataGrid>
    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="Close" Content="Close" Padding="18,9" Margin="0,0,8,0"/>
      <Button Name="Open" Content="Open" Padding="20,9" Background="#2563EB" Foreground="White"/>
    </StackPanel>
  </Grid>
</Window>
'@

    $dialog = Load-Xaml $deviceListXaml
    $dialog.Owner = $Window
    $grid = $dialog.FindName('Grid')
    $grid.ItemsSource = @($State.Devices)

    $openSelectedDevice = {
        if (-not $grid.SelectedItem) {
            return
        }

        $script:CurrentDevice = $grid.SelectedItem
        $dialog.Close()
        Refresh-DeviceView
    }

    $dialog.FindName('Close').Add_Click({
        $dialog.Close()
    })
    $dialog.FindName('Open').Add_Click($openSelectedDevice)
    $grid.Add_MouseDoubleClick($openSelectedDevice)

    [void]$dialog.ShowDialog()
}
