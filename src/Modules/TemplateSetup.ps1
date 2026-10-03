function Show-TemplateFolder {
    if (-not $CurrentTraveler) {
        return
    }

    $registry = Get-Registry -Id $CurrentTraveler.RegistryId
    if (-not $registry) {
        [System.Windows.MessageBox]::Show('Template Folder is not defined.', 'E-Traveler') | Out-Null
        return
    }

    [xml]$folderXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Template Folder"
        Width="820" Height="300"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <StackPanel Margin="24">
    <TextBlock Name="Head" FontSize="20" FontWeight="Bold"/>
    <TextBlock Text="Folder Path" Margin="0,20,0,6"/>
    <TextBox Name="Path" Height="38" FontSize="14" Padding="8"/>
    <WrapPanel Margin="0,18,0,0">
      <Button Name="Select" Content="Select Folder Path" Padding="16,9" Margin="0,0,8,0"/>
      <Button Name="Save" Content="Save Folder Path" Padding="16,9" Margin="0,0,8,0"/>
      <Button Name="Open" Content="Open Folder" Padding="16,9" Margin="0,0,8,0"/>
      <Button Name="Close" Content="Close" Padding="16,9"/>
    </WrapPanel>
  </StackPanel>
</Window>
'@

    $dialog = Load-Xaml $folderXaml
    $dialog.Owner = $Window
    $dialog.FindName('Head').Text = "$($registry.Workflow)  ·  $($registry.Site)  ·  $($registry.Tester)  ·  $($registry.Handler)"

    $pathBox = $dialog.FindName('Path')
    $pathBox.Text = $registry.Folder

    $dialog.FindName('Select').Add_Click({
        if (-not (Require-Developer)) {
            return
        }

        $selectedPath = Pick-Folder -Initial $pathBox.Text
        if ($selectedPath) {
            $pathBox.Text = $selectedPath
        }
    })

    $dialog.FindName('Save').Add_Click({
        if (-not (Require-Developer)) {
            return
        }

        $registry.Folder = $pathBox.Text
        Save-State
        [System.Windows.MessageBox]::Show('Folder path saved.', 'E-Traveler') | Out-Null
    })

    $dialog.FindName('Open').Add_Click({
        if (Test-Path -LiteralPath $pathBox.Text) {
            Start-Process explorer.exe $pathBox.Text
            return
        }

        [System.Windows.MessageBox]::Show('Folder does not exist.', 'E-Traveler') | Out-Null
    })

    $dialog.FindName('Close').Add_Click({
        $dialog.Close()
    })

    [void]$dialog.ShowDialog()
}

function Show-EditSetup {
    if (-not (Require-Developer)) {
        return
    }

    $traveler = $CurrentTraveler

    [xml]$setupXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Edit Setup"
        Width="920" Height="420"
        WindowStartupLocation="CenterOwner"
        Background="#F8FAFC">
  <StackPanel Margin="24">
    <TextBlock Name="Head" FontSize="21" FontWeight="Bold"/>
    <UniformGrid Columns="3" Margin="0,22,0,0">
      <StackPanel Margin="0,0,12,12"><TextBlock Text="Site"/><ComboBox Name="Site" Height="38"/></StackPanel>
      <StackPanel Margin="0,0,12,12"><TextBlock Text="Tester"/><ComboBox Name="Tester" Height="38"/></StackPanel>
      <StackPanel Margin="0,0,0,12"><TextBlock Text="Handler"/><ComboBox Name="Handler" Height="38"/></StackPanel>
      <StackPanel Margin="0,0,12,12"><TextBlock Text="Baking"/><ComboBox Name="Bake" Height="38"/></StackPanel>
      <StackPanel Margin="0,0,12,12"><TextBlock Text="Golden Sample"/><ComboBox Name="GS" Height="38"/></StackPanel>
    </UniformGrid>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button Name="Cancel" Content="Cancel" MinWidth="104" Padding="18,9" Margin="0,0,8,0"/>
      <Button Name="Save" Content="Save" MinWidth="104" Padding="22,9" Background="#0F766E" Foreground="White"/>
    </StackPanel>
  </StackPanel>
</Window>
'@

    $dialog = Load-Xaml $setupXaml
    $dialog.Owner = $Window
    $dialog.FindName('Head').Text = "$($CurrentDevice.Device) / $($CurrentDevice.Die)    $($traveler.Workflow)"

    $siteBox = $dialog.FindName('Site')
    $testerBox = $dialog.FindName('Tester')
    $handlerBox = $dialog.FindName('Handler')
    $bakingBox = $dialog.FindName('Bake')
    $goldenSampleBox = $dialog.FindName('GS')

    @('1 Site', '2 Sites', '4 Sites', '6 Sites', '8 Sites') | ForEach-Object {
        [void]$siteBox.Items.Add($_)
    }
    @('ASL1000-XP', 'CTA8280F', 'CTA8290DP', 'EAGLE', 'STS8200') | ForEach-Object {
        [void]$testerBox.Items.Add($_)
    }
    @(
        'TK-Handler-Gravity',
        'TK-Handler-Gravity-TriTemp',
        'TK-Handler-PNP',
        'TK-Handler-PNP-TriTemp',
        'TK-Handler-Turret'
    ) | ForEach-Object {
        [void]$handlerBox.Items.Add($_)
    }
    @('Not Required', 'Required') | ForEach-Object {
        [void]$BakingBox.Items.Add($_)
        [void]$SampleBox.Items.Add($_)
    }

    $siteBox.SelectedItem = $Traveler.Site
    $testerBox.SelectedItem = $Traveler.Tester
    $handlerBox.SelectedItem = $Traveler.Handler
    $bakingBox.SelectedItem = if ($Traveler.BakingRequired) { 'Required' } else { 'Not Required' }
    $sampleBox.SelectedItem = if ($Traveler.GsRequired) { 'Required' } else { 'Not Required' }

    $dialog.FindName('Cancel').Add_Click({
        $dialog.Close()
    })

    $dialog.FindName('Save').Add_Click({
        $registry = Find-Registry -Workflow $Traveler.Workflow -Site $siteBox.SelectedItem -Tester $testerBox.SelectedItem -Handler $handlerBox.SelectedItem

        if (-not $registry) {
            $folder = Pick-Folder
            if (-not $folder) {
                return
            }

            $registryId = 'REG' + ('{0:D3}' -f (@($State.Registries).Count + 1))
            $oldRegistry = Get-Registry -Id $Traveler.RegistryId
            $slots = @()

            if ($oldRegistry) {
                foreach ($slot in @($oldRegistry.Slots)) {
                    $slots += New-Slot -Kind $slot.Kind -Path $slot.Path -Required $slot.RequiredPath -NotRequired $slot.NotRequiredPath
                }
            }
            else {
                $slots = @(
                    (New-Slot -Kind 'Regular'),
                    (New-Slot -Kind 'Regular'),
                    (New-Slot -Kind 'Regular')
                )
            }

            $registry = New-Registry -Id $registryId -Workflow $Traveler.Workflow -Site $siteBox.SelectedItem -Tester $testerBox.SelectedItem -Handler $handlerBox.SelectedItem -Folder $folder -Slots $slots

            $State.Registries += @($registry)
        }

        $Traveler.Site = $siteBox.SelectedItem
        $Traveler.Tester = $testerBox.SelectedItem
        $Traveler.Handler = $handlerBox.SelectedItem
        $Traveler.BakingRequired = $bakingBox.SelectedItem -eq 'Required'
        $Traveler.GsRequired = $sampleBox.SelectedItem -eq 'Required'
        $Traveler.RegistryId = $registry.Id

        Ensure-SpecialSlotsForTraveler -Traveler $Traveler -Registry $registry
        Save-State
        $dialog.Close()
        Refresh-TravelerView
    })

    [void]$dialog.ShowDialog()
}
