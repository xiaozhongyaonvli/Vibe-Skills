Set-StrictMode -Version Latest

function Get-VgoAdapterRegistry {
    param([Parameter(Mandatory)] [string]$RepoRoot)

    $path = Join-Path $RepoRoot 'adapters\index.json'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "VGO adapter registry not found: $path"
    }

    try {
        return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        throw ("Failed to parse adapters/index.json: " + $_.Exception.Message)
    }
}

function Resolve-VgoAdapterAlias {
    param(
        [AllowEmptyString()] [string]$HostId = '',
        [Parameter(Mandatory)] [psobject]$Registry
    )

    $resolved = $HostId
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = if ($Registry.PSObject.Properties.Name -contains 'default_adapter_id') { [string]$Registry.default_adapter_id } else { 'codex' }
    }

    $normalized = $resolved.Trim().ToLowerInvariant()
    if ($Registry.PSObject.Properties.Name -contains 'aliases' -and $null -ne $Registry.aliases) {
        $aliases = $Registry.aliases.PSObject.Properties | ForEach-Object { @{ key = $_.Name.ToLowerInvariant(); value = [string]$_.Value } }
        foreach ($alias in $aliases) {
            if ($alias.key -eq $normalized) {
                return $alias.value
            }
        }
    }

    return $normalized
}

function Resolve-VgoAdapterDescriptor {
    param(
        [Parameter(Mandatory)] [string]$RepoRoot,
        [AllowEmptyString()] [string]$HostId = ''
    )

    $registry = Get-VgoAdapterRegistry -RepoRoot $RepoRoot
    $adapterId = Resolve-VgoAdapterAlias -HostId $HostId -Registry $registry
    $entry = @($registry.adapters | Where-Object { [string]$_.id -eq $adapterId } | Select-Object -First 1)[0]
    if ($null -eq $entry) {
        throw "Unsupported VGO host id: $HostId"
    }

    $hostProfilePath = Join-Path $RepoRoot ([string]$entry.host_profile)
    $settingsMapPath = if ($entry.PSObject.Properties.Name -contains 'settings_map' -and -not [string]::IsNullOrWhiteSpace([string]$entry.settings_map)) { Join-Path $RepoRoot ([string]$entry.settings_map) } else { $null }
    $closurePath = if ($entry.PSObject.Properties.Name -contains 'closure' -and -not [string]::IsNullOrWhiteSpace([string]$entry.closure)) { Join-Path $RepoRoot ([string]$entry.closure) } else { $null }
    $manifestPath = if ($entry.PSObject.Properties.Name -contains 'manifest' -and -not [string]::IsNullOrWhiteSpace([string]$entry.manifest)) { Join-Path $RepoRoot ([string]$entry.manifest) } else { $null }

    $hostProfile = if ($hostProfilePath -and (Test-Path -LiteralPath $hostProfilePath)) { Get-Content -LiteralPath $hostProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $settingsMap = if ($settingsMapPath -and (Test-Path -LiteralPath $settingsMapPath)) { Get-Content -LiteralPath $settingsMapPath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $closure = if ($closurePath -and (Test-Path -LiteralPath $closurePath)) { Get-Content -LiteralPath $closurePath -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }

    return [pscustomobject]@{
        id = [string]$entry.id
        status = [string]$entry.status
        install_mode = [string]$entry.install_mode
        check_mode = [string]$entry.check_mode
        bootstrap_mode = [string]$entry.bootstrap_mode
        default_target_root = $entry.default_target_root
        host_profile_path = $hostProfilePath
        settings_map_path = $settingsMapPath
        closure_path = $closurePath
        manifest_path = $manifestPath
        host_profile = $hostProfile
        settings_map = $settingsMap
        closure = $closure
    }
}
