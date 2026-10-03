param(
    [string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
)

$moduleRoot = Join-Path $PSScriptRoot 'Modules'
$modules = @(
    'AppShell.ps1'
    'Data.ps1'
    'Traveler.ps1'
    'TravelerRules.ps1'
    'TemplateSetup.ps1'
    'PageEditor.ps1'
    'DeviceDialogs.ps1'
    'Main.ps1'
)

foreach ($module in $modules) {
    . (Join-Path $moduleRoot $module)
}
