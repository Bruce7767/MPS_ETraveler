function Show-EditPages {
    if (-not (Require-Developer)) {
        return
    }
    if (-not $CurrentTraveler) {
        return
    }

    $traveler = $CurrentTraveler
    $registry = Get-Registry -Id $traveler.RegistryId
    if (-not $registry) {
        [System.Windows.MessageBox]::Show('Template Folder is not defined.', 'E-Traveler') | Out-Null
        return
    }

    $draft = $registry | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    Ensure-SpecialSlotsForTraveler -Traveler $traveler -Registry $draft

    [xml]$editorXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Edit Pages"
        Width="1120" Height="700"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <StackPanel>
      <TextBlock Name="Head" FontSize="21" FontWeight="Bold"/>
      <TextBlock Text="Drag pages to reorder, or use Move Up / Move Down. New page will be created as the next Page number."
                 Foreground="#64748B" Margin="0,6,0,14" TextWrapping="Wrap"/>
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

    $dialog = Load-Xaml $editorXaml
    $dialog.Owner = $Window
    $dialog.FindName('Head').Text = "$($traveler.Workflow)  ·  $($traveler.Site)  ·  $($traveler.Tester)  ·  $($traveler.Handler)"

    $pageList = $dialog.FindName('Pages')
    $pathBox = $dialog.FindName('Path')
    $pageState = [pscustomobject]@{
        ActivePages = @()
        DragItem = $null
    }

    function Get-EditorPages {
        Ensure-SpecialSlotsForTraveler -Traveler $traveler -Registry $draft

        $pageNumber = 0
        $pages = @()
        foreach ($slot in @($draft.Slots)) {
            switch ($slot.Kind) {
                'Baking' {
                    if ($traveler.BakingRequired) {
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
                        Label = if ($traveler.GsRequired) { 'GS (Required)' } else { 'GS (Not Required)' }
                        Slot = $slot
                        Path = if ($traveler.GsRequired) { $slot.RequiredPath } else { $slot.NotRequiredPath }
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

    function Refresh-EditorPages {
        $pageList.Items.Clear()
        $pageState.ActivePages = @(Get-EditorPages)

        foreach ($page in $pageState.ActivePages) {
            [void]$pageList.Items.Add($page.Label)
        }

        if ($pageList.Items.Count -gt 0) {
            $pageList.SelectedIndex = 0
        }
        else {
            $pathBox.Text = ''
        }
    }

    function Reorder-Slot {
        param(
            $FromSlot,
            $ToSlot,
            [bool]$MoveAfterTarget
        )

        $slots = [System.Collections.ArrayList]@($draft.Slots)
        $sourceSlotIndex = $slots.IndexOf($FromSlot)
        $targetSlotIndex = $slots.IndexOf($ToSlot)

        if ($sourceSlotIndex -lt 0 -or $targetSlotIndex -lt 0 -or $FromSlot -eq $ToSlot) {
            return $false
        }

        $slots.RemoveAt($sourceSlotIndex)
        $targetSlotIndex = $slots.IndexOf($ToSlot)
        if ($targetSlotIndex -lt 0) {
            return $false
        }

        $insertIndex = $targetSlotIndex
        if ($MoveAfterTarget) {
            $insertIndex++
        }

        $insertIndex = [Math]::Min($insertIndex, $slots.Count)
        $slots.Insert($insertIndex, $FromSlot)
        $draft.Slots = @($slots)
        $true
    }

    function Move-SelectedPage {
        param([int]$Direction)

        $fromIndex = $pageList.SelectedIndex
        if ($fromIndex -lt 0) {
            return
        }

        $toIndex = $fromIndex + $Direction
        if ($toIndex -lt 0 -or $toIndex -ge $pageState.ActivePages.Count) {
            return
        }

        $fromSlot = $pageState.ActivePages[$fromIndex].Slot
        $toSlot = $pageState.ActivePages[$toIndex].Slot
        $moveAfterTarget = $Direction -gt 0

        if (-not (Reorder-Slot -FromSlot $fromSlot -ToSlot $toSlot -MoveAfterTarget $moveAfterTarget)) {
            return
        }

        Refresh-EditorPages
        $pageList.SelectedIndex = $toIndex
    }

    $pageList.Add_SelectionChanged({
        if ($pageList.SelectedIndex -ge 0) {
            $pathBox.Text = $pageState.ActivePages[$pageList.SelectedIndex].Path
        }
        else {
            $pathBox.Text = ''
        }
    })

    $pageList.Add_PreviewMouseLeftButtonDown({
        param($Sender, $EventArgs)

        $target = $EventArgs.OriginalSource
        while ($target -and -not ($target -is [System.Windows.Controls.ListBoxItem])) {
            if (-not ($target -is [System.Windows.DependencyObject])) {
                $target = $null
                break
            }
            $target = [System.Windows.Media.VisualTreeHelper]::GetParent($target)
        }

        if (-not $target) {
            $pageState.DragItem = $null
            return
        }

        $item = $pageList.ItemContainerGenerator.ItemFromContainer($target)
        if ($item -eq [System.Windows.DependencyProperty]::UnsetValue) {
            $pageState.DragItem = $null
            return
        }

        $pageList.SelectedItem = $item
        $pageState.DragItem = $item
    })

    $pageList.Add_PreviewMouseMove({
        param($Sender, $EventArgs)

        if (
            $EventArgs.LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed -and
            $pageState.DragItem
        ) {
            [System.Windows.DragDrop]::DoDragDrop(
                $pageList,
                $pageState.DragItem,
                [System.Windows.DragDropEffects]::Move
            ) | Out-Null
        }
    })

    $pageList.Add_DragOver({
        param($Sender, $EventArgs)

        $EventArgs.Effects = [System.Windows.DragDropEffects]::Move
        $EventArgs.Handled = $true
    })

    $pageList.Add_Drop({
        param($Sender, $EventArgs)

        try {
            if (-not $pageState.DragItem) {
                return
            }

            $target = $EventArgs.OriginalSource
            while ($target -and -not ($target -is [System.Windows.Controls.ListBoxItem])) {
                if (-not ($target -is [System.Windows.DependencyObject])) {
                    $target = $null
                    break
                }
                $target = [System.Windows.Media.VisualTreeHelper]::GetParent($target)
            }

            if (-not $target) {
                return
            }

            $toIndex = $pageList.ItemContainerGenerator.IndexFromContainer($target)
            $fromIndex = $pageList.Items.IndexOf($pageState.DragItem)
            if ($fromIndex -lt 0 -or $toIndex -lt 0 -or $fromIndex -eq $toIndex) {
                return
            }

            $fromSlot = $pageState.ActivePages[$fromIndex].Slot
            $toSlot = $pageState.ActivePages[$toIndex].Slot
            $moveAfterTarget = $fromIndex -lt $toIndex

            if (-not (Reorder-Slot -FromSlot $fromSlot -ToSlot $toSlot -MoveAfterTarget $moveAfterTarget)) {
                return
            }

            Refresh-EditorPages
            $pageList.SelectedIndex = $toIndex
        }
        finally {
            $pageState.DragItem = $null
        }
    })

    $dialog.FindName('Replace').Add_Click({
        if ($pageList.SelectedIndex -lt 0) {
            return
        }

        $selectedPath = Pick-Xls
        if (-not $selectedPath) {
            return
        }

        $slot = $pageState.ActivePages[$pageList.SelectedIndex].Slot
        if ($slot.Kind -eq 'GS') {
            if ($traveler.GsRequired) {
                $slot.RequiredPath = $selectedPath
            }
            else {
                $slot.NotRequiredPath = $selectedPath
            }
        }
        else {
            $slot.Path = $selectedPath
        }

        $selectedIndex = $pageList.SelectedIndex
        Refresh-EditorPages
        $pageList.SelectedIndex = [Math]::Min($pageList.Items.Count - 1, $selectedIndex)
    })

    $dialog.FindName('Location').Add_Click({
        if ($pathBox.Text -and (Test-Path -LiteralPath $pathBox.Text -PathType Leaf)) {
            Start-Process explorer.exe -ArgumentList @('/select,', ('"' + $pathBox.Text + '"'))
            return
        }

        if ($pathBox.Text) {
            [System.Windows.MessageBox]::Show('Selected .xls path does not exist yet.', 'E-Traveler') | Out-Null
        }
    })

    $dialog.FindName('Add').Add_Click({
        $draft.Slots += @(New-Slot -Kind 'Regular')
        Refresh-EditorPages
        if ($pageList.Items.Count -gt 0) {
            $pageList.SelectedIndex = $pageList.Items.Count - 1
        }
    })

    $dialog.FindName('Up').Add_Click({
        Move-SelectedPage -Direction -1
    })

    $dialog.FindName('Down').Add_Click({
        Move-SelectedPage -Direction 1
    })

    $dialog.FindName('Remove').Add_Click({
        if ($pageList.SelectedIndex -lt 0) {
            return
        }

        $slot = $pageState.ActivePages[$pageList.SelectedIndex].Slot
        if ($slot.Kind -ne 'Regular') {
            [System.Windows.MessageBox]::Show(
                'Baking / GS special pages cannot be removed.',
                'E-Traveler'
            ) | Out-Null
            return
        }

        $draft.Slots = @($draft.Slots | Where-Object { $_ -ne $slot })
        Refresh-EditorPages
    })

    $dialog.FindName('Close').Add_Click({
        $dialog.Close()
    })

    $dialog.FindName('Save').Add_Click({
        Ensure-SpecialSlotsForTraveler -Traveler $traveler -Registry $draft
        $registry.Slots = @($draft.Slots)
        Save-State
        $dialog.Close()
    })

    Refresh-EditorPages
    [void]$dialog.ShowDialog()
}
