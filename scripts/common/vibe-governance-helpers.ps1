Set-StrictMode -Version Latest

function New-VgoUtf8NoBomEncoding {
    return [System.Text.UTF8Encoding]::new($false)
}

function Write-VgoUtf8NoBomText {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [AllowEmptyString()] [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, (New-VgoUtf8NoBomEncoding))
}

function Append-VgoUtf8NoBomText {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [AllowEmptyString()] [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::AppendAllText($Path, $Content, (New-VgoUtf8NoBomEncoding))
}

function Test-VgoUtf8BomBytes {
    param([byte[]]$Bytes)
    return ($null -ne $Bytes -and $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF)
}

function Get-VgoFileBomInfo {
    param([Parameter(Mandatory)] [string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    return [pscustomobject]@{
        path = [System.IO.Path]::GetFullPath($Path)
        has_utf8_bom = [bool](Test-VgoUtf8BomBytes -Bytes $bytes)
        byte_count = [int]$bytes.Length
        first_three_hex = if ($bytes.Length -ge 3) { ('{0:X2}{1:X2}{2:X2}' -f $bytes[0], $bytes[1], $bytes[2]) } else { $null }
    }
}

function ConvertTo-VgoFullPath {
    param(
        [Parameter(Mandatory)] [string]$BasePath,
        [Parameter(Mandatory)] [string]$RelativePath
    )

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $RelativePath))
}

function Test-VgoPathWithin {
    param(
        [Parameter(Mandatory)] [string]$ParentPath,
        [Parameter(Mandatory)] [string]$ChildPath
    )

    if ([string]::IsNullOrWhiteSpace($ParentPath) -or [string]::IsNullOrWhiteSpace($ChildPath)) {
        return $false
    }

    $parentFull = [System.IO.Path]::GetFullPath($ParentPath)
    $childFull = [System.IO.Path]::GetFullPath($ChildPath)
    if (-not $parentFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $parentFull += [System.IO.Path]::DirectorySeparatorChar
    }

    return $childFull.StartsWith($parentFull, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-VgoRepoRoot {
    param(
        [Parameter(Mandatory)] [string]$StartPath
    )

    $resolved = Resolve-Path -LiteralPath $StartPath -ErrorAction Stop
    $current = [string]$resolved.Path
    if (Test-Path -LiteralPath $current -PathType Leaf) {
        $current = Split-Path -Parent $current
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    while (-not [string]::IsNullOrWhiteSpace($current)) {
        $governancePath = Join-Path $current 'config\version-governance.json'
        if (Test-Path -LiteralPath $governancePath) {
            [void]$candidates.Add([System.IO.Path]::GetFullPath($current))
        }

        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
            break
        }
        $current = $parent
    }

    if ($candidates.Count -eq 0) {
        throw "Unable to resolve VCO repo root from: $StartPath"
    }

    $gitCandidates = @($candidates | Where-Object { Test-Path -LiteralPath (Join-Path $_ '.git') })
    if ($gitCandidates.Count -gt 0) {
        return [System.IO.Path]::GetFullPath($gitCandidates[-1])
    }

    return [System.IO.Path]::GetFullPath($candidates[$candidates.Count - 1])
}

function Get-VgoParentPath {
    param(
        [AllowEmptyString()] [string]$Path,
        [switch]$AllowFilesystemRoot
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    try {
        $fullPath = [System.IO.Path]::GetFullPath($Path)
    } catch {
        return ''
    }

    $parent = Split-Path -Parent $fullPath
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $fullPath) {
        return ''
    }

    try {
        $parentFull = [System.IO.Path]::GetFullPath($parent)
    } catch {
        return ''
    }

    $root = [System.IO.Path]::GetPathRoot($parentFull)
    if (-not $AllowFilesystemRoot -and -not [string]::IsNullOrWhiteSpace($root) -and $parentFull -eq $root) {
        return ''
    }

    return $parentFull
}

function Test-VgoCanonicalRepoExecution {
    param(
        [AllowEmptyString()] [string]$StartPath
    )

    if ([string]::IsNullOrWhiteSpace($StartPath)) {
        return $false
    }

    try {
        $repoRoot = Resolve-VgoRepoRoot -StartPath $StartPath
    } catch {
        return $false
    }

    return (Test-Path -LiteralPath (Join-Path $repoRoot '.git'))
}

function Resolve-VgoHomeDirectory {
    param(
        [AllowEmptyString()] [string]$HomePath = ''
    )

    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($HomePath)) {
        [void]$candidates.Add($HomePath)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:HOME)) {
        [void]$candidates.Add($env:HOME)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        [void]$candidates.Add($env:USERPROFILE)
    }
    if (-not [string]::IsNullOrWhiteSpace($env:HOMEDRIVE) -and -not [string]::IsNullOrWhiteSpace($env:HOMEPATH)) {
        [void]$candidates.Add(($env:HOMEDRIVE + $env:HOMEPATH))
    }

    try {
        $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        if (-not [string]::IsNullOrWhiteSpace($userProfile)) {
            [void]$candidates.Add($userProfile)
        }
    } catch {
    }

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        try {
            return [System.IO.Path]::GetFullPath($candidate)
        } catch {
            continue
        }
    }

    throw 'Unable to resolve a platform-neutral user home directory.'
}

function Resolve-VgoHostId {
    param(
        [AllowEmptyString()] [string]$HostId = ''
    )

    $resolved = $HostId
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = $env:VCO_HOST_ID
    }
    if ([string]::IsNullOrWhiteSpace($resolved)) {
        $resolved = 'codex'
    }

    $normalized = $resolved.Trim().ToLowerInvariant()
    switch ($normalized) {
        'codex' { return 'codex' }
        'claude' { return 'claude-code' }
        'claude-code' { return 'claude-code' }
        'cursor' { return 'cursor' }
        'windsurf' { return 'windsurf' }
        'openclaw' { return 'openclaw' }
        'opencode' { return 'opencode' }
        'generic' { return 'generic' }
        default {
            throw "Unsupported VCO host id: $resolved. Supported values: codex, claude-code, cursor, windsurf, openclaw, opencode, generic"
        }
    }
}

function Resolve-VgoDefaultTargetRoot {
    param(
        [AllowEmptyString()] [string]$HostId = ''
    )

    $resolvedHostId = Resolve-VgoHostId -HostId $HostId
    $homeDir = Resolve-VgoHomeDirectory
    switch ($resolvedHostId) {
        'codex' {
            if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
                return [System.IO.Path]::GetFullPath($env:CODEX_HOME)
            }
            return [System.IO.Path]::GetFullPath((Join-Path $homeDir '.codex'))
        }
        'claude-code' {
            if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_HOME)) {
                return [System.IO.Path]::GetFullPath($env:CLAUDE_HOME)
            }
            return [System.IO.Path]::GetFullPath((Join-Path $homeDir '.claude'))
        }
        'cursor' {
            if (-not [string]::IsNullOrWhiteSpace($env:CURSOR_HOME)) {
                return [System.IO.Path]::GetFullPath($env:CURSOR_HOME)
            }
            return [System.IO.Path]::GetFullPath((Join-Path $homeDir '.cursor'))
        }
        'windsurf' {
            if (-not [string]::IsNullOrWhiteSpace($env:WINDSURF_HOME)) {
                return [System.IO.Path]::GetFullPath($env:WINDSURF_HOME)
            }
            return [System.IO.Path]::GetFullPath((Join-Path $homeDir '.codeium\windsurf'))
        }
        'openclaw' {
            if (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_HOME)) {
                return [System.IO.Path]::GetFullPath($env:OPENCLAW_HOME)
            }
            return [System.IO.Path]::GetFullPath((Join-Path $homeDir '.openclaw'))
        }
        'opencode' {
            if (-not [string]::IsNullOrWhiteSpace($env:OPENCODE_HOME)) {
                return [System.IO.Path]::GetFullPath($env:OPENCODE_HOME)
            }
            return [System.IO.Path]::GetFullPath((Join-Path (Join-Path $homeDir '.config') 'opencode'))
        }
        'generic' {
            return [System.IO.Path]::GetFullPath((Join-Path (Join-Path $homeDir '.vibe-skills') 'generic'))
        }
        default {
            throw "Unsupported VCO host id: $resolvedHostId"
        }
    }
}

function Resolve-VgoTargetRoot {
    param(
        [AllowEmptyString()] [string]$TargetRoot = '',
        [AllowEmptyString()] [string]$HostId = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($TargetRoot)) {
        return [System.IO.Path]::GetFullPath($TargetRoot)
    }

    return Resolve-VgoDefaultTargetRoot -HostId $HostId
}

function Assert-VgoOfficialRuntimeHost {
    param(
        [AllowEmptyString()] [string]$HostId = ''
    )

    $resolvedHostId = Resolve-VgoHostId -HostId $HostId
    if ($resolvedHostId -ne 'codex') {
        throw ([string]::Format(
            "The governed install/check closure lane currently supports only host='codex'. For host='{0}', use the matching supported host path instead of claiming governed closure.",
            $resolvedHostId
        ))
    }
}

function Assert-VgoTargetRootMatchesHostIntent {
    param(
        [Parameter(Mandatory)] [string]$TargetRoot,
        [AllowEmptyString()] [string]$HostId = ''
    )

    $resolvedHostId = Resolve-VgoHostId -HostId $HostId
    $fullTargetRoot = [System.IO.Path]::GetFullPath($TargetRoot)
    $leaf = Split-Path -Leaf $fullTargetRoot
    $normalizedLeaf = if ([string]::IsNullOrWhiteSpace($leaf)) { '' } else { $leaf.Trim().ToLowerInvariant() }
    $normalizedTargetPath = [System.IO.Path]::GetFullPath($TargetRoot).Replace('\', '/').TrimEnd('/').ToLowerInvariant()
    $isClaudeRoot = ($normalizedLeaf -eq '.claude')
    $isCodexRoot = ($normalizedLeaf -eq '.codex')
    $isCursorRoot = ($normalizedLeaf -eq '.cursor')
    $isWindsurfRoot = $normalizedTargetPath.EndsWith('/.codeium/windsurf')
    $isOpenClawRoot = ($normalizedLeaf -eq '.openclaw')
    $looksLikeOpenCodeRoot = ($normalizedLeaf -eq '.opencode') -or $normalizedTargetPath.EndsWith('/.config/opencode')

    switch ($resolvedHostId) {
        'codex' {
            if ($isClaudeRoot -or $isWindsurfRoot -or $isOpenClawRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a non-Codex host root, but HostId resolved to 'codex'. Pass the matching host id or use a Codex target root.",
                    $TargetRoot
                ))
            }
            if ($isCursorRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Cursor home, but HostId resolved to 'codex'. Pass -HostId cursor or use a Codex target root.",
                    $TargetRoot
                ))
            }
            if ($looksLikeOpenCodeRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like an OpenCode root, but HostId resolved to 'codex'. Pass -HostId opencode for the OpenCode preview lane or use a Codex target root.",
                    $TargetRoot
                ))
            }
        }
        'claude-code' {
            if ($isCodexRoot -or $isWindsurfRoot -or $isOpenClawRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a non-Claude host root, but HostId resolved to 'claude-code'. Pass the matching host id or use a Claude Code target root.",
                    $TargetRoot
                ))
            }
            if ($isCursorRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Cursor home, but HostId resolved to 'claude-code'. Pass -HostId cursor or choose a Claude Code target root.",
                    $TargetRoot
                ))
            }
            if ($looksLikeOpenCodeRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like an OpenCode root, but HostId resolved to 'claude-code'. Use -HostId opencode for the OpenCode preview lane or choose a Claude Code target root.",
                    $TargetRoot
                ))
            }
        }
        'windsurf' {
            if ($isCodexRoot -or $isClaudeRoot -or $isOpenClawRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a non-Windsurf host root, but HostId resolved to 'windsurf'. Pass the matching host id or use a Windsurf target root.",
                    $TargetRoot
                ))
            }
            if ($isCursorRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Cursor home, but HostId resolved to 'windsurf'. Pass -HostId cursor or choose a Windsurf target root.",
                    $TargetRoot
                ))
            }
        }
        'cursor' {
            if ($normalizedLeaf -eq '.codex') {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Codex home, but HostId resolved to 'cursor'. Use -HostId codex for the official closure lane or choose a Cursor target root.",
                    $TargetRoot
                ))
            }
            if ($normalizedLeaf -eq '.claude') {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Claude Code home, but HostId resolved to 'cursor'. Use -HostId claude-code or choose a Cursor target root.",
                    $TargetRoot
                ))
            }
            if ($isWindsurfRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Windsurf home, but HostId resolved to 'cursor'. Use -HostId windsurf or choose a Cursor target root.",
                    $TargetRoot
                ))
            }
            if ($isOpenClawRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like an OpenClaw home, but HostId resolved to 'cursor'. Use -HostId openclaw or choose a Cursor target root.",
                    $TargetRoot
                ))
            }
        }
        'openclaw' {
            if ($isCodexRoot -or $isClaudeRoot -or $isWindsurfRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a non-OpenClaw host root, but HostId resolved to 'openclaw'. Pass the matching host id or use an OpenClaw target root.",
                    $TargetRoot
                ))
            }
            if ($isCursorRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Cursor home, but HostId resolved to 'openclaw'. Use -HostId cursor or choose an OpenClaw target root.",
                    $TargetRoot
                ))
            }
        }
        'opencode' {
            if ($isCodexRoot -or $isWindsurfRoot -or $isOpenClawRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a non-OpenCode host root, but HostId resolved to 'opencode'. Pass the matching host id or use an OpenCode target root.",
                    $TargetRoot
                ))
            }
            if ($isCodexRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Codex home, but HostId resolved to 'opencode'. Use -HostId codex for the official closure lane or choose an OpenCode target root.",
                    $TargetRoot
                ))
            }
            if ($isClaudeRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Claude Code home, but HostId resolved to 'opencode'. Use -HostId claude-code for Claude preview guidance or choose an OpenCode target root.",
                    $TargetRoot
                ))
            }
            if ($isCursorRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a Cursor home, but HostId resolved to 'opencode'. Use -HostId cursor or choose an OpenCode target root.",
                    $TargetRoot
                ))
            }
        }
        'generic' {
            if ($normalizedLeaf -eq '.codex' -or $normalizedLeaf -eq '.claude' -or $normalizedLeaf -eq '.cursor' -or $normalizedLeaf -eq '.openclaw' -or $isWindsurfRoot -or $looksLikeOpenCodeRoot) {
                throw ([string]::Format(
                    "TargetRoot '{0}' looks like a host-native root, but HostId resolved to 'generic'. Use a neutral generic target root instead.",
                    $TargetRoot
                ))
            }
        }
    }
}

function Resolve-VgoInstalledSkillsRoot {
    param(
        [AllowEmptyString()] [string]$TargetRoot = '',
        [AllowEmptyString()] [string]$HostId = ''
    )

    return [System.IO.Path]::GetFullPath((Join-Path (Resolve-VgoTargetRoot -TargetRoot $TargetRoot -HostId $HostId) 'skills'))
}

function Resolve-VgoExternalRoot {
    param(
        [AllowEmptyString()] [string]$TargetRoot = '',
        [AllowEmptyString()] [string]$HostId = ''
    )

    return [System.IO.Path]::GetFullPath((Join-Path (Resolve-VgoTargetRoot -TargetRoot $TargetRoot -HostId $HostId) '_external'))
}

function Resolve-VgoPathSpec {
    param(
        [AllowEmptyString()] [string]$PathSpec = '',
        [AllowEmptyString()] [string]$RepoRoot = '',
        [AllowEmptyString()] [string]$TargetRoot = '',
        [AllowEmptyString()] [string]$HostId = ''
    )

    if ([string]::IsNullOrWhiteSpace($PathSpec)) {
        return ''
    }

    $expanded = [string]$PathSpec
    $codexRoot = Resolve-VgoTargetRoot -TargetRoot $TargetRoot -HostId $HostId
    $skillsRoot = Resolve-VgoInstalledSkillsRoot -TargetRoot $TargetRoot -HostId $HostId
    $externalRoot = Resolve-VgoExternalRoot -TargetRoot $TargetRoot -HostId $HostId

    $expanded = $expanded.Replace('${CODEX_HOME}', $codexRoot)
    $expanded = $expanded.Replace('${CODEX_SKILLS_ROOT}', $skillsRoot)
    $expanded = $expanded.Replace('${VCO_EXTERNAL_ROOT}', $externalRoot)

    if ($expanded -eq '~') {
        return (Resolve-VgoHomeDirectory)
    }
    if ($expanded.StartsWith('~/') -or $expanded.StartsWith('~\')) {
        $suffix = $expanded.Substring(2)
        return [System.IO.Path]::GetFullPath((Join-Path (Resolve-VgoHomeDirectory) $suffix))
    }

    if ([System.IO.Path]::IsPathRooted($expanded)) {
        return [System.IO.Path]::GetFullPath($expanded)
    }

    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $expanded))
    }

    return [System.IO.Path]::GetFullPath($expanded)
}

function Get-VgoPowerShellCommand {
    $currentProcessPath = $null
    try {
        $currentProcessPath = (Get-Process -Id $PID -ErrorAction Stop).Path
    } catch {
        $currentProcessPath = $null
    }

    $candidates = @(
        $currentProcessPath,
        (Join-Path $PSHOME 'pwsh.exe'),
        (Join-Path $PSHOME 'pwsh'),
        (Join-Path $PSHOME 'powershell.exe'),
        (Join-Path $PSHOME 'powershell'),
        (Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Get-Command powershell -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Get-Command pwsh.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Get-Command powershell.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
    )

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        if (Test-Path -LiteralPath $candidate) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }

    throw 'Unable to resolve a PowerShell host for governed sub-process execution.'
}

function Get-VgoPythonCommand {
    $python = Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not [string]::IsNullOrWhiteSpace($python) -and (Test-Path -LiteralPath $python)) {
        return [pscustomobject]@{
            host_path = [System.IO.Path]::GetFullPath($python)
            host_leaf = [System.IO.Path]::GetFileName($python).ToLowerInvariant()
            prefix_arguments = @()
        }
    }

    $python3 = Get-Command python3 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not [string]::IsNullOrWhiteSpace($python3) -and (Test-Path -LiteralPath $python3)) {
        return [pscustomobject]@{
            host_path = [System.IO.Path]::GetFullPath($python3)
            host_leaf = [System.IO.Path]::GetFileName($python3).ToLowerInvariant()
            prefix_arguments = @()
        }
    }

    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not [string]::IsNullOrWhiteSpace($pyLauncher) -and (Test-Path -LiteralPath $pyLauncher)) {
        return [pscustomobject]@{
            host_path = [System.IO.Path]::GetFullPath($pyLauncher)
            host_leaf = [System.IO.Path]::GetFileName($pyLauncher).ToLowerInvariant()
            prefix_arguments = @('-3')
        }
    }

    throw "Unable to resolve a Python host for governed execution. Tried 'python', 'python3', and 'py -3'."
}

function Resolve-VgoPythonCommandSpec {
    param(
        [AllowEmptyString()] [string]$Command = ''
    )

    $normalized = if ($null -eq $Command) { '' } else { ([string]$Command).Trim() }
    if ([string]::IsNullOrWhiteSpace($normalized) -or $normalized -in @('python', 'python3', 'py', '${VGO_PYTHON}')) {
        return Get-VgoPythonCommand
    }

    if ([System.IO.Path]::IsPathRooted($normalized) -and (Test-Path -LiteralPath $normalized)) {
        return [pscustomobject]@{
            host_path = [System.IO.Path]::GetFullPath($normalized)
            host_leaf = [System.IO.Path]::GetFileName($normalized).ToLowerInvariant()
            prefix_arguments = @()
        }
    }

    $resolved = Get-Command $normalized -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if (-not [string]::IsNullOrWhiteSpace($resolved) -and (Test-Path -LiteralPath $resolved)) {
        return [pscustomobject]@{
            host_path = [System.IO.Path]::GetFullPath($resolved)
            host_leaf = [System.IO.Path]::GetFileName($resolved).ToLowerInvariant()
            prefix_arguments = @()
        }
    }

    throw "Unable to resolve requested Python command spec: $normalized"
}

function Get-VgoPowerShellFileInvocation {
    param(
        [Parameter(Mandatory)] [string]$ScriptPath,
        [string[]]$ArgumentList = @(),
        [switch]$NoProfile
    )

    $hostPath = Get-VgoPowerShellCommand
    $hostLeaf = [System.IO.Path]::GetFileName($hostPath).ToLowerInvariant()
    $args = @()

    if ($NoProfile) {
        $args += '-NoProfile'
    }

    if ($hostLeaf -like 'powershell*') {
        $args += @('-ExecutionPolicy', 'Bypass')
    }

    $args += @('-File', [System.IO.Path]::GetFullPath($ScriptPath))
    if ($ArgumentList.Count -gt 0) {
        $args += $ArgumentList
    }

    return [pscustomobject]@{
        host_path = $hostPath
        host_leaf = $hostLeaf
        arguments = @($args)
    }
}

function Invoke-VgoPowerShellFile {
    param(
        [Parameter(Mandatory)] [string]$ScriptPath,
        [string[]]$ArgumentList = @(),
        [switch]$NoProfile
    )

    $invocation = Get-VgoPowerShellFileInvocation -ScriptPath $ScriptPath -ArgumentList $ArgumentList -NoProfile:$NoProfile
    $global:LASTEXITCODE = 0
    $scriptOutput = @(& $invocation.host_path @($invocation.arguments))
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }

    return [pscustomobject]@{
        host_path = [string]$invocation.host_path
        arguments = @($invocation.arguments)
        exit_code = $exitCode
        output = @($scriptOutput)
    }
}

function Get-VgoRelativePathPortable {
    param(
        [Parameter(Mandatory)] [string]$BasePath,
        [Parameter(Mandatory)] [string]$TargetPath
    )

    $baseFull = [System.IO.Path]::GetFullPath($BasePath)
    $targetFull = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not $baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $baseFull += [System.IO.Path]::DirectorySeparatorChar
    }

    if ($targetFull.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $targetFull.Substring($baseFull.Length).Replace('\', '/')
    }

    $baseUri = [System.Uri]::new($baseFull)
    $targetUri = [System.Uri]::new($targetFull)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('\', '/')
}

function Remove-VgoIgnoredKeys {
    param(
        [object]$Node,
        [string[]]$IgnoreKeys
    )

    if ($null -eq $Node) {
        return $null
    }

    if ($Node -is [System.Management.Automation.PSCustomObject]) {
        $ordered = [ordered]@{}
        foreach ($prop in @($Node.PSObject.Properties) | Sort-Object -Property Name) {
            $key = [string]$prop.Name
            if ($IgnoreKeys -contains $key) {
                continue
            }
            $ordered[$key] = Remove-VgoIgnoredKeys -Node $prop.Value -IgnoreKeys $IgnoreKeys
        }
        return $ordered
    }

    if ($Node -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in @($Node.Keys) | Sort-Object) {
            $keyText = [string]$key
            if ($IgnoreKeys -contains $keyText) {
                continue
            }
            $ordered[$keyText] = Remove-VgoIgnoredKeys -Node $Node[$key] -IgnoreKeys $IgnoreKeys
        }
        return $ordered
    }

    if ($Node -is [System.Collections.IEnumerable] -and -not ($Node -is [string])) {
        $items = @()
        foreach ($item in $Node) {
            $items += Remove-VgoIgnoredKeys -Node $item -IgnoreKeys $IgnoreKeys
        }
        return $items
    }

    return $Node
}

function Get-VgoNormalizedJsonHash {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [string[]]$IgnoreKeys = @()
    )

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $obj = $raw | ConvertFrom-Json
    $normalizedObj = Remove-VgoIgnoredKeys -Node $obj -IgnoreKeys $IgnoreKeys
    $normalized = $normalizedObj | ConvertTo-Json -Depth 100 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
    $stream = [System.IO.MemoryStream]::new($bytes)
    try {
        return (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash
    } finally {
        $stream.Dispose()
    }
}

function Test-VgoFileParity {
    param(
        [Parameter(Mandatory)] [string]$ReferencePath,
        [Parameter(Mandatory)] [string]$CandidatePath,
        [string[]]$IgnoreJsonKeys = @()
    )

    if (-not (Test-Path -LiteralPath $ReferencePath) -or -not (Test-Path -LiteralPath $CandidatePath)) {
        return $false
    }

    $referenceExt = [System.IO.Path]::GetExtension($ReferencePath).ToLowerInvariant()
    $candidateExt = [System.IO.Path]::GetExtension($CandidatePath).ToLowerInvariant()
    if ($referenceExt -eq '.json' -and $candidateExt -eq '.json') {
        return (Get-VgoNormalizedJsonHash -Path $ReferencePath -IgnoreKeys $IgnoreJsonKeys) -eq (Get-VgoNormalizedJsonHash -Path $CandidatePath -IgnoreKeys $IgnoreJsonKeys)
    }

    return (Get-FileHash -LiteralPath $ReferencePath -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash
}

function Get-VgoRelativeFileList {
    param(
        [Parameter(Mandatory)] [string]$RootPath
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $RootPath -Recurse -File | ForEach-Object {
            Get-VgoRelativePathPortable -BasePath $RootPath -TargetPath $_.FullName
        } | Sort-Object -Unique
    )
}

function Get-VgoLatestJsonlRecord {
    param(
        [Parameter(Mandatory)] [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $lines = Get-Content -LiteralPath $Path -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    for ($index = $lines.Count - 1; $index -ge 0; $index--) {
        try {
            return ($lines[$index] | ConvertFrom-Json)
        } catch {
            continue
        }
    }

    return $null
}

function Get-VgoPackagingManifestSpecs {
    param(
        [Parameter(Mandatory)] [psobject]$Packaging
    )

    $manifestInput = if ($Packaging.PSObject.Properties.Name -contains 'manifests') { $Packaging.manifests } else { $null }
    $specs = @()
    if ($null -eq $manifestInput) {
        return @()
    }

    if ($manifestInput -is [System.Collections.IEnumerable] -and -not ($manifestInput -is [string])) {
        foreach ($item in @($manifestInput)) {
            if ($null -eq $item) {
                continue
            }

            $manifestId = if ($item.PSObject.Properties.Name -contains 'id') { [string]$item.id } else { '' }
            $manifestPath = if ($item.PSObject.Properties.Name -contains 'path') { [string]$item.path } else { '' }
            if ([string]::IsNullOrWhiteSpace($manifestPath)) {
                continue
            }

            $specs += [pscustomobject]@{
                id = $manifestId
                path = $manifestPath.Replace('\', '/')
            }
        }
        return @($specs)
    }

    $names = @()
    if ($manifestInput -is [System.Collections.IDictionary]) {
        $names = @($manifestInput.Keys)
    } else {
        $names = @($manifestInput.PSObject.Properties.Name)
    }

    foreach ($name in $names) {
        $value = if ($manifestInput -is [System.Collections.IDictionary]) { $manifestInput[$name] } else { $manifestInput.$name }
        if ($null -eq $value) {
            continue
        }

        $manifestPath = if ($value.PSObject.Properties.Name -contains 'path') { [string]$value.path } else { [string]$value }
        if ([string]::IsNullOrWhiteSpace($manifestPath)) {
            continue
        }

        $specs += [pscustomobject]@{
            id = [string]$name
            path = $manifestPath.Replace('\', '/')
        }
    }

    return @($specs)
}

function Get-VgoPackagingContract {
    param(
        [Parameter(Mandatory)] [psobject]$Governance,
        [AllowEmptyString()] [string]$RepoRoot = ''
    )

    $defaults = [ordered]@{
        runtime_payload = [ordered]@{
            files = @('SKILL.md', 'check.ps1', 'check.sh', 'install.ps1', 'install.sh')
            directories = @('config', 'protocols', 'references', 'docs', 'scripts')
        }
        target_overrides = [ordered]@{}
        allow_installed_only = @()
        normalized_json_ignore_keys = @('updated', 'generated_at')
    }

    $packaging = if ($Governance.PSObject.Properties.Name -contains 'packaging') { $Governance.packaging } else { $null }
    if ($null -eq $packaging) {
        return [pscustomobject]$defaults
    }

    $runtimePayload = $null
    if ($packaging.PSObject.Properties.Name -contains 'runtime_payload' -and $null -ne $packaging.runtime_payload) {
        $runtimePayload = $packaging.runtime_payload
    } elseif ($packaging.PSObject.Properties.Name -contains 'mirror' -and $null -ne $packaging.mirror) {
        $runtimePayload = $packaging.mirror
    }
    $mirrorFiles = if ($null -ne $runtimePayload -and $runtimePayload.PSObject.Properties.Name -contains 'files') { @($runtimePayload.files) } else { @($defaults.runtime_payload.files) }
    $mirrorDirs = if ($null -ne $runtimePayload -and $runtimePayload.PSObject.Properties.Name -contains 'directories') { @($runtimePayload.directories) } else { @($defaults.runtime_payload.directories) }
    $targetOverridesInput = if ($packaging.PSObject.Properties.Name -contains 'target_overrides' -and $null -ne $packaging.target_overrides) { $packaging.target_overrides } else { $null }
    $manifestSpecs = Get-VgoPackagingManifestSpecs -Packaging $packaging
    $allowBundledOnly = if ($packaging.PSObject.Properties.Name -contains 'allow_installed_only') {
        @($packaging.allow_installed_only)
    } elseif ($packaging.PSObject.Properties.Name -contains 'allow_bundled_only') {
        @($packaging.allow_bundled_only)
    } else {
        @($defaults.allow_installed_only)
    }
    $ignoreKeys = if ($packaging.PSObject.Properties.Name -contains 'normalized_json_ignore_keys') { @($packaging.normalized_json_ignore_keys) } else { @($defaults.normalized_json_ignore_keys) }

    if (-not [string]::IsNullOrWhiteSpace($RepoRoot)) {
        foreach ($manifestSpec in $manifestSpecs) {
            $manifestPath = Join-Path $RepoRoot $manifestSpec.path
            if (-not (Test-Path -LiteralPath $manifestPath)) {
                throw "packaging manifest not found: $manifestPath"
            }

            $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($manifest.PSObject.Properties.Name -contains 'files' -and $null -ne $manifest.files) {
                $mirrorFiles += @($manifest.files)
            }
            if ($manifest.PSObject.Properties.Name -contains 'directories' -and $null -ne $manifest.directories) {
                $mirrorDirs += @($manifest.directories)
            }
        }
    }

    $targetOverrides = [ordered]@{}
    if ($null -ne $targetOverridesInput) {
        $targetNames = @()
        if ($targetOverridesInput -is [System.Collections.IDictionary]) {
            $targetNames = @($targetOverridesInput.Keys)
        } else {
            if ($null -ne $targetOverridesInput.PSObject -and $null -ne $targetOverridesInput.PSObject.Properties) {
                $targetNames = @($targetOverridesInput.PSObject.Properties | ForEach-Object { $_.Name })
            }
        }

        foreach ($targetName in $targetNames) {
            $targetValue = if ($targetOverridesInput -is [System.Collections.IDictionary]) { $targetOverridesInput[$targetName] } else { $targetOverridesInput.$targetName }
            if ($null -eq $targetValue) {
                continue
            }

            $targetFiles = if ($targetValue.PSObject.Properties.Name -contains 'files') { @($targetValue.files) } else { @() }
            $targetDirs = if ($targetValue.PSObject.Properties.Name -contains 'directories') { @($targetValue.directories) } else { @() }
            $targetOverrides[[string]$targetName] = [pscustomobject]@{
                files = @($targetFiles)
                directories = @($targetDirs)
            }
        }
    }

    return [pscustomobject]@{
        runtime_payload = [pscustomobject]@{
            files = @($mirrorFiles | ForEach-Object { ([string]$_).Replace('\', '/') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
            directories = @($mirrorDirs | ForEach-Object { ([string]$_).Replace('\', '/') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
        }
        mirror = [pscustomobject]@{
            files = @($mirrorFiles | ForEach-Object { ([string]$_).Replace('\', '/') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
            directories = @($mirrorDirs | ForEach-Object { ([string]$_).Replace('\', '/') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
        }
        manifests = @($manifestSpecs)
        target_overrides = [pscustomobject]$targetOverrides
        allow_installed_only = @($allowBundledOnly)
        allow_bundled_only = @($allowBundledOnly)
        normalized_json_ignore_keys = @($ignoreKeys)
    }
}

function Get-VgoEffectiveTargetPackaging {
    param(
        [Parameter(Mandatory)] [psobject]$Packaging,
        [AllowEmptyString()] [string]$TargetId = ''
    )

    $baseFiles = @($Packaging.mirror.files)
    $baseDirs = @($Packaging.mirror.directories)
    $targetOnlyFiles = @()
    $targetOnlyDirs = @()

    if (-not [string]::IsNullOrWhiteSpace($TargetId) -and $Packaging.PSObject.Properties.Name -contains 'target_overrides' -and $null -ne $Packaging.target_overrides) {
        $targetOverrides = $Packaging.target_overrides
        $override = $null
        if ($targetOverrides -is [System.Collections.IDictionary]) {
            if ($targetOverrides.Contains($TargetId)) {
                $override = $targetOverrides[$TargetId]
            }
        } else {
            $overrideNames = @()
            if ($null -ne $targetOverrides.PSObject -and $null -ne $targetOverrides.PSObject.Properties) {
                $overrideNames = @($targetOverrides.PSObject.Properties | ForEach-Object { $_.Name })
            }
            if ($overrideNames -contains $TargetId) {
                $override = $targetOverrides.$TargetId
            }
        }

        if ($null -ne $override) {
            $targetOnlyFiles = if ($override.PSObject.Properties.Name -contains 'files') { @($override.files) } else { @() }
            $targetOnlyDirs = if ($override.PSObject.Properties.Name -contains 'directories') { @($override.directories) } else { @() }
        }
    }

    return [pscustomobject]@{
        files = @($baseFiles + $targetOnlyFiles | Select-Object -Unique)
        directories = @($baseDirs + $targetOnlyDirs | Select-Object -Unique)
        target_only_files = @($targetOnlyFiles)
        target_only_directories = @($targetOnlyDirs)
    }
}

function Test-VgoGovernedMirrorRelativePath {
    param(
        [Parameter(Mandatory)] [string]$RelativePath,
        [Parameter(Mandatory)] [psobject]$Packaging,
        [AllowEmptyString()] [string]$TargetId = ''
    )

    $rel = $RelativePath.Replace('\', '/')
    $effective = Get-VgoEffectiveTargetPackaging -Packaging $Packaging -TargetId $TargetId
    if (@($effective.files) -contains $rel) {
        return $true
    }

    foreach ($dir in @($effective.directories)) {
        $prefix = ('{0}/' -f $dir).Replace('\', '/')
        if ($rel.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Get-VgoInstalledRuntimeConfig {
    param(
        [Parameter(Mandatory)] [psobject]$Governance
    )

    $defaults = [ordered]@{
        target_relpath = 'skills/vibe'
        receipt_relpath = 'skills/vibe/outputs/runtime-freshness-receipt.json'
        post_install_gate = 'scripts/verify/vibe-installed-runtime-freshness-gate.ps1'
        coherence_gate = 'scripts/verify/vibe-release-install-runtime-coherence-gate.ps1'
        receipt_contract_version = 1
        shell_degraded_behavior = 'warn_and_skip_authoritative_runtime_gate'
        required_runtime_markers = @(
            'SKILL.md',
            'config/version-governance.json',
            'install.ps1',
            'check.ps1',
            'scripts/common/vibe-governance-helpers.ps1',
            'scripts/verify/vibe-installed-runtime-freshness-gate.ps1',
            'scripts/verify/vibe-release-install-runtime-coherence-gate.ps1',
            'scripts/router/resolve-pack-route.ps1'
        )
        require_nested_bundled_root = $false
    }

    $runtimeConfig = $null
    if ($Governance.PSObject.Properties.Name -contains 'runtime' -and $null -ne $Governance.runtime) {
        if ($Governance.runtime.PSObject.Properties.Name -contains 'installed_runtime') {
            $runtimeConfig = $Governance.runtime.installed_runtime
        }
    }

    if ($null -eq $runtimeConfig) {
        return [pscustomobject]$defaults
    }

    $merged = [ordered]@{}
    foreach ($key in $defaults.Keys) {
        if ($key -eq 'required_runtime_markers') {
            if ($runtimeConfig.PSObject.Properties.Name -contains $key -and $null -ne $runtimeConfig.$key) {
                $merged[$key] = @($runtimeConfig.$key)
            } else {
                $merged[$key] = @($defaults[$key])
            }
            continue
        }

        if ($runtimeConfig.PSObject.Properties.Name -contains $key -and $null -ne $runtimeConfig.$key -and -not (($runtimeConfig.$key -is [string]) -and [string]::IsNullOrWhiteSpace([string]$runtimeConfig.$key))) {
            $merged[$key] = $runtimeConfig.$key
        } else {
            $merged[$key] = $defaults[$key]
        }
    }

    return [pscustomobject]$merged
}

function Get-VgoMirrorTopologyTargets {
    param(
        [Parameter(Mandatory)] [psobject]$Governance,
        [Parameter(Mandatory)] [string]$RepoRoot
    )

    $targets = @()
    $topology = if ($Governance.PSObject.Properties.Name -contains 'mirror_topology') { $Governance.mirror_topology } else { $null }
    if ($null -ne $topology -and $topology.PSObject.Properties.Name -contains 'targets' -and $null -ne $topology.targets) {
        $targets = @($topology.targets)
    }

    if ($targets.Count -eq 0) {
        $legacy = if ($Governance.PSObject.Properties.Name -contains 'source_of_truth') { $Governance.source_of_truth } else { $null }
        $canonicalRel = if ($null -ne $legacy -and $legacy.PSObject.Properties.Name -contains 'canonical_root') { [string]$legacy.canonical_root } else { '.' }
        if ([string]::IsNullOrWhiteSpace($canonicalRel)) {
            $canonicalRel = '.'
        }
        $targets = @(
            [pscustomobject]@{ id = 'canonical'; path = $canonicalRel; role = 'canonical'; required = $true; presence_policy = 'required'; sync_enabled = $false; parity_policy = 'authoritative' }
        )
        $bundledRel = if ($null -ne $legacy -and $legacy.PSObject.Properties.Name -contains 'bundled_root') { [string]$legacy.bundled_root } else { $null }
        if (-not [string]::IsNullOrWhiteSpace($bundledRel)) {
            $targets += [pscustomobject]@{ id = 'bundled'; path = $bundledRel; role = 'mirror'; required = $true; presence_policy = 'required'; sync_enabled = $true; parity_policy = 'full' }
        }
        $nestedRel = if ($null -ne $legacy -and $legacy.PSObject.Properties.Name -contains 'nested_bundled_root') { [string]$legacy.nested_bundled_root } else { $null }
        if (-not [string]::IsNullOrWhiteSpace($nestedRel)) {
            $targets += [pscustomobject]@{ id = 'nested_bundled'; path = $nestedRel; role = 'mirror'; required = $false; presence_policy = 'if_present_must_match'; sync_enabled = $false; parity_policy = 'full'; materialization_mode = 'release_install_only' }
        }
    }

    $topologyTargets = @()
    foreach ($target in $targets) {
        $targetId = if ($target.PSObject.Properties.Name -contains 'id') { [string]$target.id } else { $null }
        if ([string]::IsNullOrWhiteSpace($targetId)) {
            continue
        }

        $targetPath = if ($target.PSObject.Properties.Name -contains 'path') { [string]$target.path } else { $null }
        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            continue
        }

        $fullPath = ConvertTo-VgoFullPath -BasePath $RepoRoot -RelativePath $targetPath
        $role = if ($target.PSObject.Properties.Name -contains 'role' -and -not [string]::IsNullOrWhiteSpace([string]$target.role)) { [string]$target.role } else { 'mirror' }
        $required = if ($target.PSObject.Properties.Name -contains 'required') { [bool]$target.required } else { $false }
        $presencePolicy = if ($target.PSObject.Properties.Name -contains 'presence_policy' -and -not [string]::IsNullOrWhiteSpace([string]$target.presence_policy)) { [string]$target.presence_policy } else { if ($required) { 'required' } else { 'optional' } }
        $syncEnabled = if ($target.PSObject.Properties.Name -contains 'sync_enabled') { [bool]$target.sync_enabled } else { -not ($role -eq 'canonical') }
        $parityPolicy = if ($target.PSObject.Properties.Name -contains 'parity_policy' -and -not [string]::IsNullOrWhiteSpace([string]$target.parity_policy)) { [string]$target.parity_policy } else { if ($role -eq 'canonical') { 'authoritative' } else { 'full' } }
        $materializationMode = if ($target.PSObject.Properties.Name -contains 'materialization_mode' -and -not [string]::IsNullOrWhiteSpace([string]$target.materialization_mode)) { [string]$target.materialization_mode } else { if ($targetId -eq 'nested_bundled' -and -not $syncEnabled) { 'release_install_only' } else { 'tracked_mirror' } }

        $materializationMarker = Join-Path $fullPath 'SKILL.md'
        $targetExists = (Test-Path -LiteralPath $fullPath)
        if ($targetExists) {
            $targetExists = (Test-Path -LiteralPath $materializationMarker)
        }

        $topologyTargets += [pscustomobject]@{
            id = $targetId
            path = $targetPath.Replace('\', '/')
            fullPath = $fullPath
            role = $role
            required = $required
            presence_policy = $presencePolicy
            sync_enabled = $syncEnabled
            parity_policy = $parityPolicy
            materialization_mode = $materializationMode
            exists = $targetExists
            isCanonical = ($role -eq 'canonical')
        }
    }

    return @($topologyTargets)
}

function Get-VgoMirrorTarget {
    param(
        [Parameter(Mandatory)] [object[]]$Targets,
        [Parameter(Mandatory)] [string]$Id
    )

    $match = @($Targets | Where-Object { $_.id -eq $Id } | Select-Object -First 1)
    if ($match.Count -eq 0) {
        return $null
    }

    return $match[0]
}

function Get-VgoLegacySourceOfTruthCompatibility {
    param(
        [Parameter(Mandatory)] [psobject]$Governance,
        [Parameter(Mandatory)] [object[]]$Targets
    )

    $legacy = if ($Governance.PSObject.Properties.Name -contains 'source_of_truth') { $Governance.source_of_truth } else { $null }
    $mismatches = New-Object System.Collections.Generic.List[object]
    if ($null -eq $legacy) {
        return [pscustomobject]@{
            isCompatible = $false
            mismatches = @(
                [pscustomobject]@{ field = 'source_of_truth'; expected = '<present>'; actual = '<missing>' }
            )
        }
    }

    $checks = @(
        [pscustomobject]@{ field = 'canonical_root'; targetId = 'canonical' },
        [pscustomobject]@{ field = 'bundled_root'; targetId = 'bundled' },
        [pscustomobject]@{ field = 'nested_bundled_root'; targetId = 'nested_bundled' }
    )

    foreach ($check in $checks) {
        $target = Get-VgoMirrorTarget -Targets $Targets -Id $check.targetId
        if ($null -eq $target) {
            continue
        }

        $actual = if ($legacy.PSObject.Properties.Name -contains $check.field) { [string]$legacy.($check.field) } else { $null }
        $expected = [string]$target.path
        if ([string]::IsNullOrWhiteSpace($actual) -and -not [string]::IsNullOrWhiteSpace($expected)) {
            [void]$mismatches.Add([pscustomobject]@{ field = $check.field; expected = $expected; actual = '<missing>' })
            continue
        }

        $normalizedActual = ([string]$actual).Replace('\', '/').Trim('/')
        $normalizedExpected = ([string]$expected).Replace('\', '/').Trim('/')
        if ($normalizedActual -ne $normalizedExpected) {
            [void]$mismatches.Add([pscustomobject]@{ field = $check.field; expected = $expected; actual = $actual })
        }
    }

    return [pscustomobject]@{
        isCompatible = ($mismatches.Count -eq 0)
        mismatches = @($mismatches.ToArray())
    }
}

function Test-VgoInstalledRuntimeMaterialization {
    param(
        [AllowEmptyString()] [string]$RepoRoot,
        [AllowNull()] [psobject]$RuntimeConfig
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot) -or $null -eq $RuntimeConfig) {
        return $false
    }

    $requiredMarkers = @()
    if ($RuntimeConfig.PSObject.Properties.Name -contains 'required_runtime_markers' -and $null -ne $RuntimeConfig.required_runtime_markers) {
        $requiredMarkers = @($RuntimeConfig.required_runtime_markers)
    }
    if (@($requiredMarkers).Count -eq 0) {
        return $false
    }

    foreach ($marker in @($requiredMarkers)) {
        if ([string]::IsNullOrWhiteSpace([string]$marker)) {
            continue
        }

        $markerPath = Join-Path $RepoRoot ([string]$marker)
        if (-not (Test-Path -LiteralPath $markerPath)) {
            return $false
        }
    }

    return $true
}

function Assert-VgoCanonicalExecutionContext {
    param(
        [Parameter(Mandatory)] [psobject]$Context
    )

    $policy = $Context.execution_context_policy
    $requireOuterGitRoot = $true
    $failIfScriptUnderMirror = $true

    if ($null -ne $policy) {
        if ($policy.PSObject.Properties.Name -contains 'require_outer_git_root') {
            $requireOuterGitRoot = [bool]$policy.require_outer_git_root
        }
        if ($policy.PSObject.Properties.Name -contains 'fail_if_script_path_is_under_mirror_root') {
            $failIfScriptUnderMirror = [bool]$policy.fail_if_script_path_is_under_mirror_root
        }
    }

    $hasOuterGitRoot = (Test-Path -LiteralPath (Join-Path $Context.repoRoot '.git'))
    $hasInstalledRuntimeMaterialization = Test-VgoInstalledRuntimeMaterialization -RepoRoot ([string]$Context.repoRoot) -RuntimeConfig $Context.runtimeConfig
    if ($requireOuterGitRoot -and -not $hasOuterGitRoot -and -not $hasInstalledRuntimeMaterialization) {
        throw "Execution-context lock failed: resolved repo root is not the outer git root -> $($Context.repoRoot)"
    }

    if ($failIfScriptUnderMirror) {
        $scriptPath = [System.IO.Path]::GetFullPath([string]$Context.script_path)
        $matchedTargets = @(
            $Context.mirrorTargets | Where-Object {
                -not $_.isCanonical -and (Test-VgoPathWithin -ParentPath $_.fullPath -ChildPath $scriptPath)
            }
        )

        if ($matchedTargets.Count -gt 0) {
            $targetIds = ($matchedTargets | ForEach-Object { $_.id }) -join ', '
            throw "Execution-context lock failed: governance/verify scripts must run from the canonical repo tree, not from mirror targets. targets=$targetIds script=$scriptPath repoRoot=$($Context.repoRoot)"
        }
    }

    return $true
}

function Get-VgoGovernanceContext {
    param(
        [Parameter(Mandatory)] [string]$ScriptPath,
        [switch]$EnforceExecutionContext
    )

    $resolvedScript = Resolve-Path -LiteralPath $ScriptPath -ErrorAction Stop
    $repoRoot = Resolve-VgoRepoRoot -StartPath $resolvedScript.Path
    $governancePath = Join-Path $repoRoot 'config\version-governance.json'
    if (-not (Test-Path -LiteralPath $governancePath)) {
        throw "version-governance config not found: $governancePath"
    }

    $governance = Get-Content -LiteralPath $governancePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $packaging = Get-VgoPackagingContract -Governance $governance -RepoRoot $repoRoot
    $runtimeConfig = Get-VgoInstalledRuntimeConfig -Governance $governance
    $mirrorTargets = Get-VgoMirrorTopologyTargets -Governance $governance -RepoRoot $repoRoot

    $mirrorTargetMap = [ordered]@{}
    foreach ($target in $mirrorTargets) {
        $mirrorTargetMap[$target.id] = $target
    }

    $topology = if ($governance.PSObject.Properties.Name -contains 'mirror_topology') { $governance.mirror_topology } else { $null }
    $canonicalTargetId = if ($null -ne $topology -and $topology.PSObject.Properties.Name -contains 'canonical_target_id' -and -not [string]::IsNullOrWhiteSpace([string]$topology.canonical_target_id)) { [string]$topology.canonical_target_id } else { 'canonical' }
    $syncSourceTargetId = if ($null -ne $topology -and $topology.PSObject.Properties.Name -contains 'sync_source_target_id' -and -not [string]::IsNullOrWhiteSpace([string]$topology.sync_source_target_id)) { [string]$topology.sync_source_target_id } else { $canonicalTargetId }

    $canonicalTarget = Get-VgoMirrorTarget -Targets $mirrorTargets -Id $canonicalTargetId
    if ($null -eq $canonicalTarget) {
        $canonicalTarget = @($mirrorTargets | Where-Object { $_.role -eq 'canonical' } | Select-Object -First 1)[0]
    }
    if ($null -eq $canonicalTarget) {
        throw 'mirror topology does not define a canonical target.'
    }

    $bundledTarget = Get-VgoMirrorTarget -Targets $mirrorTargets -Id 'bundled'
    $nestedTarget = Get-VgoMirrorTarget -Targets $mirrorTargets -Id 'nested_bundled'
    $syncSourceTarget = Get-VgoMirrorTarget -Targets $mirrorTargets -Id $syncSourceTargetId
    if ($null -eq $syncSourceTarget) {
        $syncSourceTarget = $canonicalTarget
    }

    $executionContextPolicy = $null
    if ($governance.PSObject.Properties.Name -contains 'execution_context_policy') {
        $executionContextPolicy = $governance.execution_context_policy
    } elseif ($governance.PSObject.Properties.Name -contains 'packaging' -and $governance.packaging -and $governance.packaging.PSObject.Properties.Name -contains 'execution_context_policy') {
        $executionContextPolicy = $governance.packaging.execution_context_policy
    }

    $legacyCompatibility = Get-VgoLegacySourceOfTruthCompatibility -Governance $governance -Targets $mirrorTargets

    $context = [pscustomobject]@{
        repoRoot = [System.IO.Path]::GetFullPath($repoRoot)
        governancePath = [System.IO.Path]::GetFullPath($governancePath)
        governance = $governance
        packaging = $packaging
        runtimeConfig = $runtimeConfig
        mirrorTargets = @($mirrorTargets)
        mirrorTargetMap = $mirrorTargetMap
        canonicalTarget = $canonicalTarget
        bundledTarget = $bundledTarget
        nestedTarget = $nestedTarget
        syncSourceTarget = $syncSourceTarget
        canonicalRoot = [string]$canonicalTarget.fullPath
        bundledRoot = if ($null -ne $bundledTarget) { [string]$bundledTarget.fullPath } else { $null }
        nestedBundledRoot = if ($null -ne $nestedTarget) { [string]$nestedTarget.fullPath } else { $null }
        legacySourceOfTruthCompatibility = $legacyCompatibility
        execution_context_policy = $executionContextPolicy
        script_path = [System.IO.Path]::GetFullPath([string]$resolvedScript.Path)
    }

    if ($EnforceExecutionContext) {
        Assert-VgoCanonicalExecutionContext -Context $context | Out-Null
    }

    return $context
}
