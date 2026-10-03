function Show-TemplateFolder {
    param(
        $TargetRegistry = $null,
        [System.Windows.Window]$Owner = $Window
    )

    $registry = $TargetRegistry
    if (-not $registry) {
        if (-not $CurrentTraveler) {
            return
        }
        $registry = Get-Registry -Id $CurrentTraveler.RegistryId
    }

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
    $dialog.Owner = $Owner
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

        if ([string]::IsNullOrWhiteSpace($pathBox.Text)) {
            [System.Windows.MessageBox]::Show('Template Folder is required.', 'E-Traveler') | Out-Null
            return
        }
        if (-not (Test-Path -LiteralPath $pathBox.Text -PathType Container)) {
            [System.Windows.MessageBox]::Show('Template Folder does not exist.', 'E-Traveler') | Out-Null
            return
        }

        $registry.Folder = $pathBox.Text
        Save-State
        [System.Windows.MessageBox]::Show('Folder path saved.', 'E-Traveler') | Out-Null
        Refresh-TravelerView
    })

    $dialog.FindName('Open').Add_Click({
        if (Test-Path -LiteralPath $pathBox.Text -PathType Container) {
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
    if (-not $CurrentTraveler) {
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
      <Button Name="Folder" Content="Template Folder..." MinWidth="140" Padding="18,9" Margin="0,0,8,0"/>
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
        [void]$bakingBox.Items.Add($_)
        [void]$goldenSampleBox.Items.Add($_)
    }

    $siteBox.SelectedItem = $traveler.Site
    $testerBox.SelectedItem = $traveler.Tester
    $handlerBox.SelectedItem = $traveler.Handler
    $bakingBox.SelectedItem = if ($traveler.BakingRequired) { 'Required' } else { 'Not Required' }
    $goldenSampleBox.SelectedItem = if ($traveler.GsRequired) { 'Required' } else { 'Not Required' }

    $dialog.FindName('Folder').Add_Click({
        $site = [string]$siteBox.SelectedItem
        $tester = [string]$testerBox.SelectedItem
        $handler = [string]$handlerBox.SelectedItem

        if (
            [string]::IsNullOrWhiteSpace($site) -or
            [string]::IsNullOrWhiteSpace($tester) -or
            [string]::IsNullOrWhiteSpace($handler)
        ) {
            [System.Windows.MessageBox]::Show('Select Site, Tester and Handler first.', 'E-Traveler') | Out-Null
            return
        }

        $selectedRegistry = Find-Registry `
            -Workflow $traveler.Workflow `
            -Site $site `
            -Tester $tester `
            -Handler $handler

        if (-not $selectedRegistry) {
            [System.Windows.MessageBox]::Show(
                'This setup does not have a Template Folder yet. Save the setup first to create it.',
                'E-Traveler'
            ) | Out-Null
            return
        }

        Show-TemplateFolder -TargetRegistry $selectedRegistry -Owner $dialog
    })

    $dialog.FindName('Cancel').Add_Click({
        $dialog.Close()
    })

    $dialog.FindName('Save').Add_Click({
        $site = [string]$siteBox.SelectedItem
        $tester = [string]$testerBox.SelectedItem
        $handler = [string]$handlerBox.SelectedItem

        if (
            [string]::IsNullOrWhiteSpace($site) -or
            [string]::IsNullOrWhiteSpace($tester) -or
            [string]::IsNullOrWhiteSpace($handler)
        ) {
            [System.Windows.MessageBox]::Show('Site, Tester and Handler are required.', 'E-Traveler') | Out-Null
            return
        }

        $registry = Find-Registry `
            -Workflow $traveler.Workflow `
            -Site $site `
            -Tester $tester `
            -Handler $handler

        if (-not $registry) {
            $folder = Pick-Folder
            if (-not $folder) {
                return
            }

            $registryId = 'REG' + ('{0:D3}' -f (@($State.Registries).Count + 1))
            $slots = @(
                (New-Slot -Kind 'Regular'),
                (New-Slot -Kind 'Regular'),
                (New-Slot -Kind 'Regular')
            )

            $registry = New-Registry `
                -Id $registryId `
                -Workflow $traveler.Workflow `
                -Site $site `
                -Tester $tester `
                -Handler $handler `
                -Folder $folder `
                -Slots $slots

            $State.Registries += @($registry)
        }

        $traveler.Site = $site
        $traveler.Tester = $tester
        $traveler.Handler = $handler
        $traveler.BakingRequired = $bakingBox.SelectedItem -eq 'Required'
        $traveler.GsRequired = $goldenSampleBox.SelectedItem -eq 'Required'
        $traveler.RegistryId = $registry.Id

        Ensure-SpecialSlotsForTraveler -Traveler $traveler -Registry $registry
        Save-State
        $dialog.Close()
        Refresh-TravelerView
    })

    [void]$dialog.ShowDialog()
}
