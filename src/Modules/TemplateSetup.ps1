function Show-TemplateFolder {
    if(-not $CurrentTraveler){return};$reg=Get-Registry $CurrentTraveler.RegistryId;if(-not $reg){[System.Windows.MessageBox]::Show('Template Folder is not defined.','E-Traveler')|Out-Null;return}
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Template Folder" Width="820" Height="300" WindowStartupLocation="CenterOwner" Background="#F8FAFC"><StackPanel Margin="24"><TextBlock Name="Head" FontSize="20" FontWeight="Bold"/><TextBlock Text="Folder Path" Margin="0,20,0,6"/><TextBox Name="Path" Height="38" FontSize="14" Padding="8"/><WrapPanel Margin="0,18,0,0"><Button Name="Select" Content="Select Folder Path" Padding="16,9" Margin="0,0,8,0"/><Button Name="Save" Content="Save Folder Path" Padding="16,9" Margin="0,0,8,0"/><Button Name="Open" Content="Open Folder" Padding="16,9" Margin="0,0,8,0"/><Button Name="Close" Content="Close" Padding="16,9"/></WrapPanel></StackPanel></Window>
'@
    $w=Load-Xaml $x;$w.Owner=$Window;$w.FindName('Head').Text="$($reg.Workflow)  ·  $($reg.Site)  ·  $($reg.Tester)  ·  $($reg.Handler)";$path=$w.FindName('Path');$path.Text=$reg.Folder
    $w.FindName('Select').Add_Click({if(Require-Developer){$p=Pick-Folder $path.Text;if($p){$path.Text=$p}}});$w.FindName('Save').Add_Click({if(Require-Developer){$reg.Folder=$path.Text;Save-State;[System.Windows.MessageBox]::Show('Folder path saved.','E-Traveler')|Out-Null}});$w.FindName('Open').Add_Click({if(Test-Path $path.Text){Start-Process explorer.exe $path.Text}else{[System.Windows.MessageBox]::Show('Folder does not exist.','E-Traveler')|Out-Null}});$w.FindName('Close').Add_Click({$w.Close()});[void]$w.ShowDialog()
}
function Show-EditSetup {
    if(-not (Require-Developer)){return}
    $t=$CurrentTraveler
    [xml]$x=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Edit Setup" Width="920" Height="420" WindowStartupLocation="CenterOwner" Background="#F8FAFC">
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
    $w=Load-Xaml $x
    $w.Owner=$Window
    $w.FindName('Head').Text="$($CurrentDevice.Device) / $($CurrentDevice.Die)    $($t.Workflow)"
    $site=$w.FindName('Site');$tester=$w.FindName('Tester');$handler=$w.FindName('Handler');$bake=$w.FindName('Bake');$gs=$w.FindName('GS')
    @('1 Site','2 Sites','4 Sites','6 Sites','8 Sites')|%{[void]$site.Items.Add($_)}
    @('ASL1000-XP','CTA8280F','CTA8290DP','EAGLE','STS8200')|%{[void]$tester.Items.Add($_)}
    @('TK-Handler-Gravity','TK-Handler-Gravity-TriTemp','TK-Handler-PNP','TK-Handler-PNP-TriTemp','TK-Handler-Turret')|%{[void]$handler.Items.Add($_)}
    @('Not Required','Required')|%{[void]$bake.Items.Add($_);[void]$gs.Items.Add($_)}
    $site.SelectedItem=$t.Site
    $tester.SelectedItem=$t.Tester
    $handler.SelectedItem=$t.Handler
    $bake.SelectedItem=if($t.BakingRequired){'Required'}else{'Not Required'}
    $gs.SelectedItem=if($t.GsRequired){'Required'}else{'Not Required'}
    $w.FindName('Cancel').Add_Click({$w.Close()})
    $w.FindName('Save').Add_Click({
        $reg=Find-Registry $t.Workflow $site.SelectedItem $tester.SelectedItem $handler.SelectedItem
        if(-not $reg){
            $folder=Pick-Folder
            if(-not $folder){ return }
            $id='REG'+('{0:D3}' -f (@($State.Registries).Count+1))
            $old=Get-Registry $t.RegistryId
            $slots=@()
            if($old){
                foreach($s in @($old.Slots)){
                    $slots += New-Slot $s.Kind $s.Path $s.RequiredPath $s.NotRequiredPath
                }
            } else {
                $slots=@((New-Slot 'Regular'),(New-Slot 'Regular'),(New-Slot 'Regular'))
            }
            $reg=New-Registry $id $t.Workflow $site.SelectedItem $tester.SelectedItem $handler.SelectedItem $folder $slots
            $State.Registries += @($reg)
        }
        $t.Site=$site.SelectedItem
        $t.Tester=$tester.SelectedItem
        $t.Handler=$handler.SelectedItem
        $t.BakingRequired=($bake.SelectedItem -eq 'Required')
        $t.GsRequired=($gs.SelectedItem -eq 'Required')
        $t.RegistryId=$reg.Id
        Ensure-SpecialSlotsForTraveler $t $reg
        Save-State
        $w.Close()
        Refresh-TravelerView
    })
    [void]$w.ShowDialog()
}
