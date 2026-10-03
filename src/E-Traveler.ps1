param([string]$Root = (Split-Path -Parent $MyInvocation.MyCommand.Path))

$moduleRoot = Join-Path $PSScriptRoot 'Modules'
. (Join-Path $moduleRoot 'AppShell.ps1')
. (Join-Path $moduleRoot 'Data.ps1')
. (Join-Path $moduleRoot 'Traveler.ps1')
. (Join-Path $moduleRoot 'Dialogs.ps1')
. (Join-Path $moduleRoot 'Main.ps1')
