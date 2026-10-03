function Show-EditPages {
    if(-not (Require-Developer)){return}
    $trav=$CurrentTraveler
    $reg=Get-Registry $trav.RegistryId
    if(-not $reg){[System.Windows.MessageBox]::Show('Template Folder is not defined.','E-Traveler')|Out-Null;return}
    $draft=$reg | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    Ensure-SpecialSlotsForTraveler $trav $draft
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Edit Pages" Width="1120" Height="700" WindowStartupLocation="CenterOwner" Background="#F8FAFC">
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel>
      <TextBlock Name="Head" FontSize="21" FontWeight="Bold"/>
      <TextBlock Text="Drag pages to reorder, or use Move Up / Move Down. New page will be created as the next Page number." Foreground="#64748B" Margin="0,6,0,14" TextWrapping="Wrap"/>
    </StackPanel>
    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="380"/>
        <ColumnDefinition Width="18"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <ListBox Name="Pages" AllowDrop="True" FontSize="15" Padding="5"/>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Direct external .xls source" FontWeight="SemiBold"/>
        <TextBox Name="Path" Height="38" Margin="0,6,0,14" IsReadOnly="True" Padding="8"/>
        <WrapPanel>
          <Button Name="Replace" Content="Choose / Replace .xls" Padding="16,9" MinWidth="150" Margin="0,0,8,8"/>
          <Button Name="Location" Content="Open File Location" Padding="16,9" MinWidth="145" Margin="0,0,8,8"/>
          <Button Name="Add" Content="+ Add Page" Padding="16,9" MinWidth="110" Margin="0,0,8,8"/>
          <Button Name="Up" Content="Move Up" Padding="16,9" MinWidth="100" Margin="0,0,8,8"/>
          <Button Name="Down" Content="Move Down" Padding="16,9" MinWidth="110" Margin="0,0,8,8"/>
          <Button Name="Remove" Content="Remove Page" Padding="16,9" MinWidth="120" Margin="0,0,8,8"/>
        </WrapPanel>
      </StackPanel>
    </Grid>
    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button Name="Close" Content="Close" MinWidth="104" Padding="18,9" Margin="0,0,8,0"/>
      <Button Name="Save" Content="Save Changes" MinWidth="140" Padding="20,9" Background="#0F766E" Foreground="White"/>
    </StackPanel>
  </Grid>
</Window>
'@
    $w=Load-Xaml $x
    $w.Owner=$Window
    $w.FindName('Head').Text="$($trav.Workflow)  ·  $($trav.Site)  ·  $($trav.Tester)  ·  $($trav.Handler)"
    $list=$w.FindName('Pages')
    $path=$w.FindName('Path')

    function Local-Active {
        param($slots)
        Ensure-SpecialSlotsForTraveler $trav $draft
        $r=0
        $arr=@()
        foreach($s in @($slots)){
            if($s.Kind -eq 'Baking'){
                if($trav.BakingRequired){ $arr += [pscustomobject]@{Label='Baking (Required)'; Slot=$s; Path=$s.Path} }
                continue
            }
            if($s.Kind -eq 'GS'){
                $arr += [pscustomobject]@{Label=$(if($trav.GsRequired){'GS (Required)'}else{'GS (Not Required)'}); Slot=$s; Path=$(if($trav.GsRequired){$s.RequiredPath}else{$s.NotRequiredPath})}
                continue
            }
            $r++
            $arr += [pscustomobject]@{Label="Page $r"; Slot=$s; Path=$s.Path}
        }
        return @($arr)
    }
    function Refresh-LocalPages {
        $list.Items.Clear()
        $script:active = Local-Active $draft.Slots
        foreach($a in $active){ [void]$list.Items.Add($a.Label) }
        if($list.Items.Count -gt 0){ $list.SelectedIndex = 0 } else { $path.Text='' }
    }
    function Move-SelectedSlot([int]$delta){
        if($list.SelectedIndex -lt 0){ return }
        $from = $list.SelectedIndex
        $to = $from + $delta
        if($to -lt 0 -or $to -ge $active.Count){ return }
        $fromSlot = $active[$from].Slot
        $toSlot = $active[$to].Slot
        $slots = [System.Collections.ArrayList]@($draft.Slots)
        $fi = $slots.IndexOf($fromSlot)
        $ti = $slots.IndexOf($toSlot)
        if($fi -lt 0 -or $ti -lt 0){ return }
        $slots.RemoveAt($fi)
        if($fi -lt $ti){ $ti-- }
        $slots.Insert($ti, $fromSlot)
        $draft.Slots = @($slots)
        Refresh-LocalPages
        $list.SelectedIndex = $to
    }

    $script:dragItem = $null
    $list.Add_SelectionChanged({ if($list.SelectedIndex -ge 0){ $path.Text = $active[$list.SelectedIndex].Path } else { $path.Text='' } })
    $list.Add_PreviewMouseLeftButtonDown({ param($s,$e) $script:dragItem = $list.SelectedItem })
    $list.Add_PreviewMouseMove({
        param($s,$e)
        if($e.LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed -and $script:dragItem){
            [System.Windows.DragDrop]::DoDragDrop($list, $script:dragItem, [System.Windows.DragDropEffects]::Move) | Out-Null
        }
    })
    $list.Add_DragOver({ param($s,$e) $e.Effects = [System.Windows.DragDropEffects]::Move; $e.Handled = $true })
    $list.Add_Drop({
        param($s,$e)
        if(-not $script:dragItem){ return }
        $target = $e.OriginalSource
        while($target -and -not ($target -is [System.Windows.Controls.ListBoxItem])){ $target=[System.Windows.Media.VisualTreeHelper]::GetParent($target) }
        if(-not $target){ return }
        $to = $list.ItemContainerGenerator.IndexFromContainer($target)
        $from = $list.Items.IndexOf($script:dragItem)
        if($from -lt 0 -or $to -lt 0 -or $from -eq $to){ return }
        $fromSlot = $active[$from].Slot
        $toSlot = $active[$to].Slot
        $slots = [System.Collections.ArrayList]@($draft.Slots)
        $fi = $slots.IndexOf($fromSlot)
        $ti = $slots.IndexOf($toSlot)
        if($fi -lt 0 -or $ti -lt 0){ return }
        $slots.RemoveAt($fi)
        if($fi -lt $ti){ $ti-- }
        $slots.Insert($ti, $fromSlot)
        $draft.Slots = @($slots)
        Refresh-LocalPages
        $list.SelectedIndex = $to
        $script:dragItem = $null
    })
    $w.FindName('Replace').Add_Click({
        if($list.SelectedIndex -lt 0){ return }
        $p = Pick-Xls
        if(-not $p){ return }
        $s = $active[$list.SelectedIndex].Slot
        if($s.Kind -eq 'GS'){
            if($trav.GsRequired){ $s.RequiredPath = $p } else { $s.NotRequiredPath = $p }
        } else {
            $s.Path = $p
        }
        Refresh-LocalPages
        $list.SelectedIndex = [Math]::Min($list.Items.Count-1, $list.SelectedIndex)
    })
    $w.FindName('Location').Add_Click({
        if($path.Text -and (Test-Path -LiteralPath $path.Text)){ Start-Process explorer.exe -ArgumentList @('/select,',('"'+$path.Text+'"')) }
        elseif($path.Text){ [System.Windows.MessageBox]::Show('Selected .xls path does not exist yet.','E-Traveler') | Out-Null }
    })
    $w.FindName('Add').Add_Click({
        $draft.Slots += @(New-Slot 'Regular' '')
        Refresh-LocalPages
        if($list.Items.Count -gt 0){ $list.SelectedIndex = $list.Items.Count - 1 }
    })
    $w.FindName('Up').Add_Click({ Move-SelectedSlot -1 })
    $w.FindName('Down').Add_Click({ Move-SelectedSlot 1 })
    $w.FindName('Remove').Add_Click({
        if($list.SelectedIndex -lt 0){ return }
        $s = $active[$list.SelectedIndex].Slot
        if($s.Kind -ne 'Regular'){
            [System.Windows.MessageBox]::Show('Baking / GS special pages cannot be removed.','E-Traveler') | Out-Null
            return
        }
        $draft.Slots = @($draft.Slots | Where-Object { $_ -ne $s })
        Refresh-LocalPages
    })
    $w.FindName('Close').Add_Click({ $w.Close() })
    $w.FindName('Save').Add_Click({
        Ensure-SpecialSlotsForTraveler $trav $draft
        $reg.Slots = @($draft.Slots)
        Save-State
        $w.Close()
    })
    Refresh-LocalPages
    [void]$w.ShowDialog()
}
