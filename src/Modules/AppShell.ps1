$ErrorActionPreference = 'Stop'
$DiagnosticLogPath = Join-Path $env:TEMP 'E_Traveler_Error.log'
trap {
    try {
        ($_ | Out-String) | Set-Content -LiteralPath $DiagnosticLogPath -Encoding UTF8
        [System.Windows.MessageBox]::Show(
            "E-Traveler could not start.`n`nDiagnostic log:`n$DiagnosticLogPath`n`n$($_.Exception.Message)",
            'E-Traveler Pre-Release',
            'OK',
            'Error'
        ) | Out-Null
    } catch {}
    exit 1
}


Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

[xml]$MainXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="E-Traveler Pre-Release"
        Width="1200" Height="760" MinWidth="960" MinHeight="620"
        WindowStartupLocation="Manual"
        WindowStyle="SingleBorderWindow"
        ResizeMode="CanResizeWithGrip"
        ShowInTaskbar="True"
        Topmost="False"
        Background="#F1F5F9" FontFamily="Segoe UI"
        UseLayoutRounding="True" SnapsToDevicePixels="True">
  <Window.Resources>
    <SolidColorBrush x:Key="Navy" Color="#0F172A"/>
    <SolidColorBrush x:Key="Primary" Color="#2563EB"/>
    <SolidColorBrush x:Key="Teal" Color="#0F766E"/>
    <SolidColorBrush x:Key="Border" Color="#CBD5E1"/>
    <SolidColorBrush x:Key="Text" Color="#0F172A"/>
    <SolidColorBrush x:Key="Muted" Color="#64748B"/>
    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="White"/><Setter Property="BorderBrush" Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness" Value="1"/><Setter Property="CornerRadius" Value="12"/><Setter Property="Padding" Value="18"/>
    </Style>
    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Background" Value="{StaticResource Primary}"/><Setter Property="Foreground" Value="White"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Padding" Value="18,10"/><Setter Property="MinWidth" Value="110"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="14"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Margin" Value="0,0,10,0"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" CornerRadius="7" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="SecondaryBtn" TargetType="Button" BasedOn="{StaticResource PrimaryBtn}">
      <Setter Property="Background" Value="White"/><Setter Property="Foreground" Value="{StaticResource Text}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Border}"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border></ControlTemplate></Setter.Value></Setter>
    </Style>
    <Style x:Key="TealBtn" TargetType="Button" BasedOn="{StaticResource PrimaryBtn}"><Setter Property="Background" Value="{StaticResource Teal}"/></Style>
    <Style x:Key="LockedBtn" TargetType="Button" BasedOn="{StaticResource SecondaryBtn}"><Setter Property="Background" Value="#E2E8F0"/><Setter Property="Foreground" Value="#475569"/></Style>
    <Style x:Key="FieldCard" TargetType="Border"><Setter Property="Background" Value="#F8FAFC"/><Setter Property="BorderBrush" Value="#E2E8F0"/><Setter Property="BorderThickness" Value="1"/><Setter Property="CornerRadius" Value="8"/><Setter Property="Padding" Value="12"/><Setter Property="Margin" Value="0,0,10,10"/></Style>
    <Style TargetType="TextBox"><Setter Property="FontSize" Value="15"/><Setter Property="Padding" Value="11"/><Setter Property="BorderBrush" Value="{StaticResource Border}"/><Setter Property="BorderThickness" Value="1"/></Style>
    <Style TargetType="ComboBox"><Setter Property="FontSize" Value="14"/><Setter Property="Padding" Value="8"/><Setter Property="MinHeight" Value="36"/></Style>
  </Window.Resources>
  <Grid>
    <Grid.ColumnDefinitions><ColumnDefinition Width="195"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
    <Border Grid.Column="0" Background="{StaticResource Navy}">
      <Grid Margin="18,22"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel>
          <TextBlock Text="E-TRAVELER" Foreground="White" FontWeight="Bold" FontSize="24"/>
          <TextBlock Text="PRE-RELEASE" Foreground="#94A3B8" FontSize="12" Margin="0,4,0,0"/>
        </StackPanel>
        <Button x:Name="DeveloperBtn" Grid.Row="1" Content="Developer Mode" Margin="0,38,0,0" Style="{StaticResource SecondaryBtn}" MinWidth="0"/>
        <StackPanel Grid.Row="3"><TextBlock Text="OFFLINE" Foreground="#5EEAD4" FontWeight="SemiBold"/><TextBlock Text="Windows Desktop" Foreground="#64748B" FontSize="12"/></StackPanel>
      </Grid>
    </Border>
    <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
      <StackPanel Margin="28,24,28,30">
        <DockPanel Margin="0,0,0,18">
          <StackPanel DockPanel.Dock="Left"><TextBlock Text="Device Management" FontWeight="Bold" FontSize="30" Foreground="{StaticResource Text}"/><TextBlock Text="Offline Windows application · Excel .xls traveler compiler" Foreground="{StaticResource Muted}" FontSize="13" Margin="0,5,0,0"/></StackPanel>
          <Border DockPanel.Dock="Right" Background="#DCFCE7" CornerRadius="14" Padding="12,6" HorizontalAlignment="Right" VerticalAlignment="Top"><TextBlock Text="OFFLINE MODE" Foreground="#047857" FontWeight="SemiBold"/></Border>
        </DockPanel>

        <Border Style="{StaticResource Card}" Margin="0,0,0,16">
          <StackPanel><TextBlock Text="Find Device" FontWeight="Bold" FontSize="19" Margin="0,0,0,12"/>
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <TextBox x:Name="SearchBox" Grid.Column="0" Height="42" VerticalContentAlignment="Center"/>
              <Button x:Name="SearchBtn" Grid.Column="1" Content="Search" Style="{StaticResource PrimaryBtn}" Margin="12,0,8,0"/>
              <Button x:Name="RefreshBtn" Grid.Column="2" Content="Refresh" Style="{StaticResource SecondaryBtn}" Margin="0,0,8,0"/>
              <Button x:Name="ViewAllBtn" Grid.Column="3" Content="View All Devices" Style="{StaticResource SecondaryBtn}" Margin="0" MinWidth="145"/>
            </Grid>
            <Button x:Name="RegisterBtn" Content="+ Register Device / Die" Style="{StaticResource SecondaryBtn}" HorizontalAlignment="Left" Margin="0,12,0,0" MinWidth="190"/>
          </StackPanel>
        </Border>

        <Border x:Name="DeviceCard" Style="{StaticResource Card}" Margin="0,0,0,16" Visibility="Collapsed">
          <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
            <StackPanel><StackPanel Orientation="Horizontal"><TextBlock x:Name="DeviceNameText" FontWeight="Bold" FontSize="26"/><Border Background="#DBEAFE" CornerRadius="15" Padding="10,5" Margin="12,0,0,0"><TextBlock x:Name="DieText" Foreground="#1D4ED8" FontWeight="Bold"/></Border><Border Background="#DCFCE7" CornerRadius="15" Padding="10,5" Margin="8,0,0,0"><TextBlock Text="ACTIVE" Foreground="#047857" FontWeight="Bold"/></Border></StackPanel><TextBlock x:Name="FlowText" Margin="0,10,0,0" FontSize="14" TextWrapping="Wrap"/></StackPanel>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Top"><Button x:Name="OtherDieBtn" Content="Other Die" Style="{StaticResource SecondaryBtn}"/><Button x:Name="EditConfigBtn" Content="Edit Config" Style="{StaticResource LockedBtn}" Margin="0"/></StackPanel>
          </Grid>
        </Border>

        <Border x:Name="TravelerCard" Style="{StaticResource Card}" Visibility="Collapsed">
          <StackPanel><TextBlock Text="Travelers" FontWeight="Bold" FontSize="19" Margin="0,0,0,12"/>
            <Grid MinWidth="720"><Grid.ColumnDefinitions><ColumnDefinition Width="260" MinWidth="220"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*" MinWidth="430"/></Grid.ColumnDefinitions>
              <ListBox x:Name="TravelerList" Grid.Column="0" MinHeight="280" MaxHeight="420" BorderBrush="{StaticResource Border}" BorderThickness="1" FontSize="15" Padding="4"/>
              <StackPanel Grid.Column="2">
                <TextBlock x:Name="WorkflowTitle" FontSize="20" FontWeight="Bold" Margin="0,0,0,12"/>
                <UniformGrid Columns="3" Rows="2" Margin="0,0,0,8">
                  <Border Style="{StaticResource FieldCard}"><StackPanel><TextBlock Text="SITE" Foreground="{StaticResource Muted}" FontSize="11"/><TextBlock x:Name="SiteText" FontWeight="SemiBold" FontSize="15" Margin="0,4,0,0"/></StackPanel></Border>
                  <Border Style="{StaticResource FieldCard}"><StackPanel><TextBlock Text="TESTER" Foreground="{StaticResource Muted}" FontSize="11"/><TextBlock x:Name="TesterText" FontWeight="SemiBold" FontSize="15" Margin="0,4,0,0"/></StackPanel></Border>
                  <Border Style="{StaticResource FieldCard}"><StackPanel><TextBlock Text="HANDLER" Foreground="{StaticResource Muted}" FontSize="11"/><TextBlock x:Name="HandlerText" FontWeight="SemiBold" FontSize="15" Margin="0,4,0,0" TextWrapping="Wrap"/></StackPanel></Border>
                  <Border Style="{StaticResource FieldCard}"><StackPanel><TextBlock Text="BAKING" Foreground="{StaticResource Muted}" FontSize="11"/><TextBlock x:Name="BakingText" FontWeight="SemiBold" FontSize="15" Margin="0,4,0,0"/></StackPanel></Border>
                  <Border Style="{StaticResource FieldCard}"><StackPanel><TextBlock Text="GOLDEN SAMPLE" Foreground="{StaticResource Muted}" FontSize="11"/><TextBlock x:Name="GsText" FontWeight="SemiBold" FontSize="15" Margin="0,4,0,0"/></StackPanel></Border>
                  <Border Style="{StaticResource FieldCard}"><StackPanel><TextBlock Text="TEMPLATE FOLDER" Foreground="{StaticResource Muted}" FontSize="11"/><TextBlock x:Name="RegistryText" FontWeight="SemiBold" FontSize="15" Margin="0,4,0,0"/></StackPanel></Border>
                </UniformGrid>
                <WrapPanel Margin="0,5,0,0">
                  <Button x:Name="ViewXlsBtn" Content="View .xls" Style="{StaticResource SecondaryBtn}"/>
                  <Button x:Name="OpenFolderBtn" Content="Open Folder" Style="{StaticResource SecondaryBtn}"/>
                  <Button x:Name="CompileBtn" Content="Compile .xls" Style="{StaticResource TealBtn}"/>
                  <Button x:Name="EditSetupBtn" Content="Edit Setup" Style="{StaticResource LockedBtn}"/>
                  <Button x:Name="EditPagesBtn" Content="Edit Pages" Style="{StaticResource LockedBtn}" Margin="0"/>
                </WrapPanel>
              </StackPanel>
            </Grid>
          </StackPanel>
        </Border>
      </StackPanel>
    </ScrollViewer>
  </Grid>
</Window>
'@

function Load-Xaml {
    param([xml]$Xaml)

    $reader = New-Object System.Xml.XmlNodeReader $Xaml
    [Windows.Markup.XamlReader]::Load($reader)
}

function Find-Control {
    param(
        [System.Windows.Window]$Window,
        [string]$Name
    )

    $Window.FindName($Name)
}

$Window = Load-Xaml $MainXaml

$workArea = [System.Windows.SystemParameters]::WorkArea
$windowWidth = [Math]::Min(1240.0, [Math]::Max(960.0, $workArea.Width * 0.90))
$windowHeight = [Math]::Min(820.0, [Math]::Max(620.0, $workArea.Height * 0.88))

$Window.Width = $windowWidth
$Window.Height = $windowHeight
$Window.Left = $workArea.Left + (($workArea.Width - $windowWidth) / 2)
$Window.Top = $workArea.Top + (($workArea.Height - $windowHeight) / 2)
$Window.ResizeMode = [System.Windows.ResizeMode]::CanResizeWithGrip
$Window.WindowStyle = [System.Windows.WindowStyle]::SingleBorderWindow
$Window.ShowInTaskbar = $true
$Window.Topmost = $false
$controlNames = @(
    'DeveloperBtn', 'SearchBox', 'SearchBtn', 'RefreshBtn', 'ViewAllBtn', 'RegisterBtn',
    'DeviceCard', 'DeviceNameText', 'DieText', 'FlowText', 'OtherDieBtn', 'EditConfigBtn',
    'TravelerCard', 'TravelerList', 'WorkflowTitle', 'SiteText', 'TesterText', 'HandlerText',
    'BakingText', 'GsText', 'RegistryText', 'ViewXlsBtn', 'OpenFolderBtn', 'CompileBtn',
    'EditSetupBtn', 'EditPagesBtn'
)

foreach ($controlName in $controlNames) {
    $control = Find-Control -Window $Window -Name $controlName
    Set-Variable -Name $controlName -Value $control -Scope Script
}
