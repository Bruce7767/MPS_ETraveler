function Show-EditConfig {
    if(-not (Require-Developer)){return};$d=$CurrentDevice
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Edit Config" Width="900" Height="310" WindowStartupLocation="CenterOwner" Background="#F8FAFC"><StackPanel Margin="24"><TextBlock Text="Edit Config" FontSize="22" FontWeight="Bold"/><Grid Margin="0,22,0,0"><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="20"/><ColumnDefinition/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="Die"/><ComboBox Name="Die" Height="38"/></StackPanel><StackPanel Grid.Column="2"><TextBlock Text="Device Flow"/><ComboBox Name="Flow" Height="38"/></StackPanel></Grid><StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,28,0,0"><Button Name="Cancel" Content="Cancel" Padding="18,9" Margin="0,0,8,0"/><Button Name="Save" Content="Save &amp; Refresh Travelers" Padding="20,9" Background="#2563EB" Foreground="White"/></StackPanel></StackPanel></Window>
'@
    $w=Load-Xaml $x;$w.Owner=$Window;$die=$w.FindName('Die');$flow=$w.FindName('Flow');0..99|%{[void]$die.Items.Add("R$_")};foreach($f in @($State.Flows)){[void]$flow.Items.Add($f)};$die.SelectedItem=$d.Die;$flow.SelectedItem=$d.Flow
    $w.FindName('Cancel').Add_Click({$w.Close()});$w.FindName('Save').Add_Click({$newDie=$die.SelectedItem;$newFlow=$flow.SelectedItem;$dup=@($State.Devices|Where-Object{$_.Device -eq $d.Device -and $_.Die -eq $newDie -and $_ -ne $d});if($dup.Count){[System.Windows.MessageBox]::Show('This Device + Die already exists.','E-Traveler')|Out-Null;return};$old=@{};foreach($t in @($d.Travelers)){$old[$t.Workflow]=$t};$new=@();foreach($wf in ($newFlow -split '->')){$wf=$wf.Trim();if($old.ContainsKey($wf)){$new+=@($old[$wf])}else{$reg=@($State.Registries|Where-Object{$_.Workflow -eq $wf})|Select-Object -First 1;if($reg){$new+=@(New-Traveler $wf $reg.Site $reg.Tester $reg.Handler $false $false $reg.Id)}else{$new+=@(New-Traveler $wf '4 Sites' 'CTA8280F' 'TK-Handler-Turret' $false $false '')}}};$d.Die=$newDie;$d.Flow=$newFlow;$d.Travelers=@($new);Save-State;$w.Close();Refresh-DeviceView});[void]$w.ShowDialog()
}
function Show-Register {
    if(-not (Require-Developer)){ return }
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Register Device / Die" Width="940" Height="390" WindowStartupLocation="CenterOwner" Background="#F8FAFC">
  <StackPanel Margin="24">
    <TextBlock Text="Register Device / Die" FontSize="22" FontWeight="Bold"/>
    <Grid Margin="0,22,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="20"/><ColumnDefinition/></Grid.ColumnDefinitions>
      <StackPanel><TextBlock Text="Device Name"/><TextBox Name="Device" Height="38" Padding="8"/></StackPanel>
      <StackPanel Grid.Column="2"><TextBlock Text="Die"/><ComboBox Name="Die" Height="38"/></StackPanel>
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
    $w=Load-Xaml $x
    $w.Owner=$Window
    $dev=$w.FindName('Device')
    $die=$w.FindName('Die')
    $flow=$w.FindName('Flow')
    0..99|%{[void]$die.Items.Add("R$_")}
    $die.SelectedIndex=0
    foreach($f in @($State.Flows)){[void]$flow.Items.Add($f)}
    if($flow.Items.Count -gt 0){$flow.SelectedIndex=0}

    $w.FindName('AddFlow').Add_Click({
        $nf=[Microsoft.VisualBasic.Interaction]::InputBox('Enter complete Device Flow. Use -> between workflow travelers.','Add New Flow','')
        if($nf -and -not (@($State.Flows) -contains $nf)){
            $State.Flows+=@($nf)
            [void]$flow.Items.Add($nf)
            $flow.SelectedItem=$nf
            Save-State
        }
    })

    $w.FindName('DeleteFlow').Add_Click({
        $selected=[string]$flow.SelectedItem
        if([string]::IsNullOrWhiteSpace($selected)){ return }
        $usedBy=@($State.Devices | Where-Object { $_.Flow -eq $selected })
        if($usedBy.Count -gt 0){
            $shown=@($usedBy | Select-Object -First 8 | ForEach-Object { "$($_.Device) / $($_.Die)" })
            $more=if($usedBy.Count -gt 8){"`n...and $($usedBy.Count-8) more"}else{''}
            $msg="WARNING: This Device Flow is currently used by $($usedBy.Count) Device/Die configuration(s):`n`n" + ($shown -join "`n") + $more + "`n`nDeleting the Flow removes it from the Flow selection list only. Existing registered Device/Die records will remain unchanged.`n`nProceed with delete?"
            $ans=[System.Windows.MessageBox]::Show($msg,'Delete Device Flow',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($ans -ne [System.Windows.MessageBoxResult]::Yes){ return }
        } else {
            $ans=[System.Windows.MessageBox]::Show("Delete this Device Flow?`n`n$selected",'Delete Device Flow',[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
            if($ans -ne [System.Windows.MessageBoxResult]::Yes){ return }
        }
        $State.Flows=@($State.Flows | Where-Object { $_ -ne $selected })
        $flow.Items.Clear()
        foreach($f in @($State.Flows)){[void]$flow.Items.Add($f)}
        if($flow.Items.Count -gt 0){$flow.SelectedIndex=0}
        Save-State
    })

    $w.FindName('Cancel').Add_Click({$w.Close()})
    $w.FindName('Save').Add_Click({
        if(-not $dev.Text){return}
        if(-not $flow.SelectedItem){[System.Windows.MessageBox]::Show('Select a Device Flow.','E-Traveler')|Out-Null;return}
        if(@($State.Devices|Where-Object{$_.Device -eq $dev.Text -and $_.Die -eq $die.SelectedItem}).Count){
            [System.Windows.MessageBox]::Show('This Device + Die already exists.','E-Traveler')|Out-Null
            return
        }
        $trav=@()
        foreach($wf in ($flow.SelectedItem -split '->')){
            $wf=$wf.Trim()
            $reg=@($State.Registries|Where-Object{$_.Workflow -eq $wf})|Select-Object -First 1
            if($reg){$trav+=@(New-Traveler $wf $reg.Site $reg.Tester $reg.Handler $false $false $reg.Id)}
            else{$trav+=@(New-Traveler $wf '4 Sites' 'CTA8280F' 'TK-Handler-Turret' $false $false '')}
        }
        $new=New-Device $dev.Text $die.SelectedItem $flow.SelectedItem $trav
        $State.Devices+=@($new)
        Save-State
        $script:CurrentDevice=$new
        $w.Close()
        Refresh-DeviceView
    })
    [void]$w.ShowDialog()
}
function Show-OtherDieList {
    if(-not $CurrentDevice){ return }
    $matches=@($State.Devices | Where-Object { $_.Device -eq $CurrentDevice.Device } | Sort-Object Die)
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Other Die" Width="900" Height="520" WindowStartupLocation="CenterOwner" Background="#F8FAFC">
  <Grid Margin="24">
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
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
    $w=Load-Xaml $x
    $w.Owner=$Window
    $w.FindName('Head').Text="$($CurrentDevice.Device) - Die Configurations"
    $g=$w.FindName('Grid')
    $g.ItemsSource=$matches
    if($matches.Count -gt 0){
        $currentIndex=[Array]::IndexOf($matches,$CurrentDevice)
        if($currentIndex -ge 0){$g.SelectedIndex=$currentIndex}else{$g.SelectedIndex=0}
    }
    $openAction={
        if($g.SelectedItem){
            $script:CurrentDevice=$g.SelectedItem
            $w.Close()
            Refresh-DeviceView
        }
    }
    $w.FindName('Open').Add_Click($openAction)
    $g.Add_MouseDoubleClick($openAction)
    $w.FindName('Close').Add_Click({$w.Close()})
    [void]$w.ShowDialog()
}

function Show-AllDevices {
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="All Devices" Width="1000" Height="600" WindowStartupLocation="CenterOwner" Background="#F8FAFC"><Grid Margin="24"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition/><RowDefinition Height="Auto"/></Grid.RowDefinitions><TextBlock Text="All Device / Die Configurations" FontSize="22" FontWeight="Bold"/><DataGrid Name="Grid" Grid.Row="1" Margin="0,18,0,18" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Single"><DataGrid.Columns><DataGridTextColumn Header="Device" Binding="{Binding Device}" Width="140"/><DataGridTextColumn Header="Die" Binding="{Binding Die}" Width="90"/><DataGridTextColumn Header="Device Flow" Binding="{Binding Flow}" Width="*"/></DataGrid.Columns></DataGrid><StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right"><Button Name="Close" Content="Close" Padding="18,9" Margin="0,0,8,0"/><Button Name="Open" Content="Open" Padding="20,9" Background="#2563EB" Foreground="White"/></StackPanel></Grid></Window>
'@
    $w=Load-Xaml $x;$w.Owner=$Window;$g=$w.FindName('Grid');$g.ItemsSource=@($State.Devices);$w.FindName('Close').Add_Click({$w.Close()});$w.FindName('Open').Add_Click({if($g.SelectedItem){$script:CurrentDevice=$g.SelectedItem;$w.Close();Refresh-DeviceView}});[void]$w.ShowDialog()
}
