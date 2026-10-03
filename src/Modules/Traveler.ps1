function Get-Registry([string]$id) { @($State.Registries | Where-Object { $_.Id -eq $id }) | Select-Object -First 1 }
function Find-Registry($wf,$site,$tester,$handler) { @($State.Registries | Where-Object { $_.Workflow -eq $wf -and $_.Site -eq $site -and $_.Tester -eq $tester -and $_.Handler -eq $handler }) | Select-Object -First 1 }
function Ensure-SpecialSlotsForTraveler {
    param($trav,$reg)
    if(-not $trav -or -not $reg){ return }
    $slots = [System.Collections.ArrayList]@(@($reg.Slots))
    $hasBake = @($slots | Where-Object { $_.Kind -eq 'Baking' }).Count -gt 0
    $hasGs = @($slots | Where-Object { $_.Kind -eq 'GS' }).Count -gt 0
    $insertAt = [Math]::Min(2, $slots.Count)
    if($trav.BakingRequired -and -not $hasBake){
        $bakePath = if($reg.Folder){ Join-Path $reg.Folder 'Baking_Required.xls' } else { '' }
        $null = $slots.Insert($insertAt, (New-Slot 'Baking' $bakePath))
        $insertAt++
    }
    if(-not $hasGs){
        $reqPath = if($reg.Folder){ Join-Path $reg.Folder 'GS_Required.xls' } else { '' }
        $notReqPath = if($reg.Folder){ Join-Path $reg.Folder 'GS_Not_Required.xls' } else { '' }
        $null = $slots.Insert($insertAt, (New-Slot 'GS' '' $reqPath $notReqPath))
    }
    $reg.Slots = @($slots)
}
function Get-ActivePages($trav,$reg) {
    Ensure-SpecialSlotsForTraveler $trav $reg
    $regular=0; $result=@()
    foreach($slot in @($reg.Slots)) {
        if($slot.Kind -eq 'Baking') {
            if($trav.BakingRequired){
                $result += [pscustomobject]@{Label='Baking (Required)'; Slot=$slot; Path=$slot.Path}
            }
            continue
        }
        if($slot.Kind -eq 'GS') {
            $result += [pscustomobject]@{
                Label = $(if($trav.GsRequired){'GS (Required)'}else{'GS (Not Required)'})
                Slot = $slot
                Path = $(if($trav.GsRequired){$slot.RequiredPath}else{$slot.NotRequiredPath})
            }
            continue
        }
        $regular++
        $result += [pscustomobject]@{Label="Page $regular"; Slot=$slot; Path=$slot.Path}
    }
    return @($result)
}
function Update-LockStyles {
    $style = if($Developer){$Window.Resources['PrimaryBtn']}else{$Window.Resources['LockedBtn']}
    $EditConfigBtn.Style=$style; $EditSetupBtn.Style=$style; $EditPagesBtn.Style=$style
    $DeveloperBtn.Content=if($Developer){'Developer Mode  ON'}else{'Developer Mode'}
}
function Refresh-DeviceView {
    if(-not $CurrentDevice){ $DeviceCard.Visibility='Collapsed'; $TravelerCard.Visibility='Collapsed'; return }
    $DeviceCard.Visibility='Visible'; $TravelerCard.Visibility='Visible'
    $DeviceNameText.Text=$CurrentDevice.Device; $DieText.Text="Die: $($CurrentDevice.Die)"; $FlowText.Text="Device Flow: $($CurrentDevice.Flow)"
    $TravelerList.Items.Clear(); foreach($t in @($CurrentDevice.Travelers)){ [void]$TravelerList.Items.Add($t.Workflow) }
    if($TravelerList.Items.Count -gt 0){ $TravelerList.SelectedIndex=0 }
}
function Refresh-TravelerView {
    if(-not $CurrentDevice -or $TravelerList.SelectedIndex -lt 0){return}
    $script:CurrentTraveler=@($CurrentDevice.Travelers)[$TravelerList.SelectedIndex]
    $WorkflowTitle.Text=$CurrentTraveler.Workflow; $SiteText.Text=$CurrentTraveler.Site; $TesterText.Text=$CurrentTraveler.Tester; $HandlerText.Text=$CurrentTraveler.Handler
    $BakingText.Text=if($CurrentTraveler.BakingRequired){'Required'}else{'Not Required'}; $GsText.Text=if($CurrentTraveler.GsRequired){'Required'}else{'Not Required'}
    $reg=Get-Registry $CurrentTraveler.RegistryId; $RegistryText.Text=if($reg){$reg.Id}else{'Not Defined'}
}
function Select-DeviceByName([string]$name) {
    $matches=@($State.Devices | Where-Object { $_.Device -like "*$name*" }); if($matches.Count -eq 0){[System.Windows.MessageBox]::Show('Device not found.','E-Traveler')|Out-Null;return}
    $script:CurrentDevice=$matches[0]; Refresh-DeviceView
}
function Require-Developer {
    if($Developer){ return $true }
    [xml]$x=@'
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
    <PasswordBox Name="P" Grid.Row="2" Height="38" FontSize="16" Padding="8"/>
    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,18,0,0">
      <Button Name="Cancel" Content="Cancel" MinWidth="96" Padding="18,8" Margin="0,0,8,0"/>
      <Button Name="OK" Content="Login" MinWidth="96" Padding="18,8" Background="#2563EB" Foreground="White"/>
    </StackPanel>
  </Grid>
</Window>
'@
    $w=Load-Xaml $x
    $w.Owner=$Window
    $p=$w.FindName('P')
    $ok=$w.FindName('OK')
    $cancel=$w.FindName('Cancel')
    $w.Tag=$false
    $ok.Add_Click({
        if($p.Password -eq '1234'){
            $w.Tag = $true
            $w.DialogResult = $true
            $w.Close()
        } else {
            [System.Windows.MessageBox]::Show('Incorrect password.','E-Traveler') | Out-Null
            $p.Clear()
            $p.Focus()
        }
    })
    $cancel.Add_Click({
        $w.Tag = $false
        $w.DialogResult = $false
        $w.Close()
    })
    $p.Add_KeyDown({
        param($s,$e)
        if($e.Key -eq 'Enter'){
            if($p.Password -eq '1234'){
                $w.Tag = $true
                $w.DialogResult = $true
                $w.Close()
            } else {
                [System.Windows.MessageBox]::Show('Incorrect password.','E-Traveler') | Out-Null
                $p.Clear()
                $p.Focus()
            }
        }
    })
    $null = $p.Focus()
    [void]$w.ShowDialog()
    if($w.Tag -eq $true){
        $script:Developer = $true
        Update-LockStyles
        return $true
    }
    return $false
}
function Pick-Folder([string]$initial='') {
    $d=New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description='Select Template Folder'; if($initial -and (Test-Path $initial)){$d.SelectedPath=$initial}
    if($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){return $d.SelectedPath}; return $null
}
function Pick-Xls {
    $d=New-Object Microsoft.Win32.OpenFileDialog; $d.Filter='Excel 97-2003 Workbook (*.xls)|*.xls|All Files (*.*)|*.*'; $d.Title='Select Traveler Page (.xls)'
    if($d.ShowDialog($Window)){return $d.FileName};return $null
}
function Compile-Traveler($trav,[bool]$openAfter=$false) {
    $reg=Get-Registry $trav.RegistryId; if(-not $reg){[System.Windows.MessageBox]::Show('Template Folder is not defined.','E-Traveler')|Out-Null;return}
    $pages=Get-ActivePages $trav $reg; $missing=@($pages | Where-Object { -not $_.Path -or -not (Test-Path -LiteralPath $_.Path -PathType Leaf) })
    if($missing.Count){[System.Windows.MessageBox]::Show("Compile blocked. Source .xls not found:`n`n" + (($missing|ForEach-Object{"$($_.Label)`n$($_.Path)"}) -join "`n`n"),'E-Traveler')|Out-Null;return}
    $devSafe=$CurrentDevice.Device -replace '[\/:*?"<>|]','_'; $dieSafe=$CurrentDevice.Die -replace '[\/:*?"<>|]','_'; $wfSafe=$trav.Workflow -replace '[\/:*?"<>|]','_'
    $dir=Join-Path (Join-Path (Join-Path $OutputDir $devSafe) $dieSafe) ''; New-Item -ItemType Directory -Path $dir -Force|Out-Null; $output=Join-Path $dir ($wfSafe+'.xls')
    $excel=$null;$dest=$null
    try {
      if(Test-Path $output){Remove-Item $output -Force}
      $excel=New-Object -ComObject Excel.Application; $excel.Visible=$false;$excel.DisplayAlerts=$false;$excel.ScreenUpdating=$false;$excel.EnableEvents=$false
      $dest=$excel.Workbooks.Add();$defaultCount=$dest.Worksheets.Count
      foreach($p in $pages){$wb=$null;$sheet=$null;try{$wb=$excel.Workbooks.Open($p.Path,0,$true);$sheet=$wb.Worksheets.Item(1);$after=$dest.Worksheets.Item($dest.Worksheets.Count);$sheet.Copy($null,$after);[void][Runtime.InteropServices.Marshal]::ReleaseComObject($after)}finally{if($sheet){[void][Runtime.InteropServices.Marshal]::ReleaseComObject($sheet)};if($wb){$wb.Close($false);[void][Runtime.InteropServices.Marshal]::ReleaseComObject($wb)}}}
      1..$defaultCount|ForEach-Object{$dest.Worksheets.Item(1).Delete()};try{$dest.CheckCompatibility=$false}catch{};$dest.SaveAs($output,56);$dest.Close($true);[void][Runtime.InteropServices.Marshal]::ReleaseComObject($dest);$dest=$null;$excel.Quit();[void][Runtime.InteropServices.Marshal]::ReleaseComObject($excel);$excel=$null;[GC]::Collect();[GC]::WaitForPendingFinalizers()
      if($openAfter){try{Start-Process excel.exe -ArgumentList @('/r',('"'+$output+'"'))}catch{Start-Process $output}}else{[System.Windows.MessageBox]::Show("Traveler compiled successfully.`n`n$output",'E-Traveler')|Out-Null}
    } catch {try{if($dest){$dest.Close($false)}}catch{};try{if($excel){$excel.Quit()}}catch{};[System.Windows.MessageBox]::Show("Excel compilation failed:`n`n$($_.Exception.Message)",'E-Traveler')|Out-Null}
}
