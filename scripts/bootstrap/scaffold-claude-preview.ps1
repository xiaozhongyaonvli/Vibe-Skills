param(
    [Parameter(Mandatory)] [string]$RepoRoot,
    [Parameter(Mandatory)] [string]$TargetRoot,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $RepoRoot 'scripts\common\vibe-governance-helpers.ps1')

function Copy-DirContent {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path -LiteralPath $Source)) { return }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -Path (Join-Path $Source '*') -Destination $Destination -Recurse -Force
}

$settingsTemplate = Join-Path $RepoRoot 'config\settings.template.claude.json'
$settingsTarget = Join-Path $TargetRoot 'settings.json'
if ($Force -or -not (Test-Path -LiteralPath $settingsTarget)) {
    Copy-Item -LiteralPath $settingsTemplate -Destination $settingsTarget -Force
}
Copy-DirContent -Source (Join-Path $RepoRoot 'hooks') -Destination (Join-Path $TargetRoot 'hooks')

[pscustomobject]@{
    result = 'PASS'
    host_id = 'claude-code'
    target_root = [System.IO.Path]::GetFullPath($TargetRoot)
    settings_path = [System.IO.Path]::GetFullPath($settingsTarget)
    hooks_root = [System.IO.Path]::GetFullPath((Join-Path $TargetRoot 'hooks'))
} | ConvertTo-Json -Depth 10
