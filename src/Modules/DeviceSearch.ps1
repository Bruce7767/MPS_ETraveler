function Sort-DeviceRecords {
    param([object[]]$Records)

    @(
        $Records |
            Sort-Object `
                @{ Expression = { $_.Device } }, `
                @{ Expression = {
                    if ([string]$_.Die -match '^R(\d+)$') {
                        [int]$Matches[1]
                    }
                    else {
                        [int]::MaxValue
                    }
                } }, `
                @{ Expression = { $_.Die } }
    )
}

function Show-DeviceSearchResults {
    param(
        [object[]]$Matches,
        [string]$Title = 'Device Search Results'
    )

    $records = @(Sort-DeviceRecords -Records $Matches)
    if ($records.Count -eq 0) {
        return
    }

    [xml]$searchResultsXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Device Search Results"
        Width="1000" Height="560"
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
      <TextBlock Text="Select the exact Device / Die configuration to open."
                 Foreground="#64748B" Margin="0,5,0,0"/>
    </StackPanel>
    <DataGrid Name="Grid" Grid.Row="1" Margin="0,18,0,18"
              AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single">
      <DataGrid.Columns>
        <DataGridTextColumn Header="Device" Binding="{Binding Device}" Width="160"/>
        <DataGridTextColumn Header="Die" Binding="{Binding Die}" Width="100"/>
        <DataGridTextColumn Header="Device Flow" Binding="{Binding Flow}" Width="*"/>
      </DataGrid.Columns>
    </DataGrid>
    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
      <Button Name="Cancel" Content="Cancel" Padding="18,9" Margin="0,0,8,0"/>
      <Button Name="Open" Content="Open" Padding="20,9" Background="#2563EB" Foreground="White"/>
    </StackPanel>
  </Grid>
</Window>
'@

    $dialog = Load-Xaml $searchResultsXaml
    $dialog.Owner = $Window
    $dialog.FindName('Head').Text = $Title
    $grid = $dialog.FindName('Grid')
    $grid.ItemsSource = $records
    $grid.SelectedIndex = 0

    $openSelection = {
        if (-not $grid.SelectedItem) {
            return
        }

        $script:CurrentDevice = $grid.SelectedItem
        $dialog.Close()
        Refresh-DeviceView
    }

    $dialog.FindName('Open').Add_Click($openSelection)
    $grid.Add_MouseDoubleClick($openSelection)
    $dialog.FindName('Cancel').Add_Click({ $dialog.Close() })

    [void]$dialog.ShowDialog()
}

function Select-DeviceByName {
    param([string]$Name)

    $query = $Name.Trim()
    if ([string]::IsNullOrWhiteSpace($query)) {
        return
    }

    $exactMatches = @(
        $State.Devices | Where-Object { [string]$_.Device -ieq $query }
    )

    if ($exactMatches.Count -eq 1) {
        $script:CurrentDevice = $exactMatches[0]
        Refresh-DeviceView
        return
    }

    if ($exactMatches.Count -gt 1) {
        Show-DeviceSearchResults `
            -Matches $exactMatches `
            -Title "$query - Die Configurations"
        return
    }

    $partialMatches = @(
        $State.Devices | Where-Object {
            ([string]$_.Device).IndexOf(
                $query,
                [System.StringComparison]::OrdinalIgnoreCase
            ) -ge 0
        }
    )

    if ($partialMatches.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Device not found.', 'E-Traveler') | Out-Null
        return
    }

    if ($partialMatches.Count -eq 1) {
        $script:CurrentDevice = $partialMatches[0]
        Refresh-DeviceView
        return
    }

    Show-DeviceSearchResults -Matches $partialMatches -Title 'Device Search Results'
}
