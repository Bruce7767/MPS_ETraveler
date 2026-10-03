$OutputDir = Join-Path $Root 'Output'
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$DataFile = Join-Path $DataDir 'E_Traveler_WPF_PreRelease.json'

function New-Slot([string]$kind,[string]$path='', [string]$required='', [string]$notRequired='') {
    [pscustomobject]@{ Kind=$kind; Path=$path; RequiredPath=$required; NotRequiredPath=$notRequired }
}
function New-Registry([string]$id,[string]$wf,[string]$site,[string]$tester,[string]$handler,[string]$folder,[object[]]$slots) {
    [pscustomobject]@{ Id=$id; Workflow=$wf; Site=$site; Tester=$tester; Handler=$handler; Folder=$folder; Slots=@($slots) }
}
function New-Traveler([string]$wf,[string]$site,[string]$tester,[string]$handler,[bool]$baking,[bool]$gs,[string]$reg) {
    [pscustomobject]@{ Workflow=$wf; Site=$site; Tester=$tester; Handler=$handler; BakingRequired=$baking; GsRequired=$gs; RegistryId=$reg }
}
function New-Device([string]$device,[string]$die,[string]$flow,[object[]]$travelers) {
    [pscustomobject]@{ Device=$device; Die=$die; Flow=$flow; Travelers=@($travelers) }
}

function New-DefaultState {
    [pscustomobject]@{ Flows=@(); Registries=@(); Devices=@() }
}

function Save-State { $script:State | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $DataFile -Encoding UTF8 }
if (Test-Path -LiteralPath $DataFile) {
    try { $script:State = Get-Content -LiteralPath $DataFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $script:State = New-DefaultState; Save-State }
} else { $script:State = New-DefaultState; Save-State }
$script:Developer=$false; $script:CurrentDevice=$null; $script:CurrentTraveler=$null
