param(
    [switch]$WriteArtifacts
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\common\vibe-governance-helpers.ps1')

function Assert-Collect {
    param(
        [bool]$Condition,
        [string]$Message,
        [object]$Details = $null
    )

    if ($Condition) {
        Write-Host "[PASS] $Message"
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    }

    return [pscustomobject]@{
        pass = $Condition
        message = $Message
        details = $Details
    }
}

function Resolve-ManifestPath {
    param(
        [string]$RepoRoot,
        [string]$PathValue
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $PathValue))
}

$context = Get-VgoGovernanceContext -ScriptPath $PSCommandPath -EnforceExecutionContext
$repoRoot = $context.repoRoot
$manifestPath = Join-Path $repoRoot 'config\upstream-corpus-manifest.json'
$results = New-Object System.Collections.Generic.List[object]
[void]$results.Add((Assert-Collect -Condition (Test-Path -LiteralPath $manifestPath) -Message '存在 upstream corpus manifest'))
if (@($results | Where-Object { -not $_.pass }).Count -gt 0) {
    exit 1
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$entryLookup = @{}
foreach ($entry in @($manifest.entries)) {
    $entryLookup[[string]$entry.slug] = $entry
}
$scopeSlugs = @($manifest.freshness_policy.scope_slugs | ForEach-Object { [string]$_ })
$scopeEntries = foreach ($slug in $scopeSlugs) {
    if ($entryLookup.ContainsKey($slug)) {
        $entryLookup[$slug]
    }
}
$roots = @($manifest.mirror_roots)
[void]$results.Add((Assert-Collect -Condition ($scopeSlugs.Count -eq 15) -Message 'manifest freshness scope 包含 15 个 mirror-managed slugs'))
[void]$results.Add((Assert-Collect -Condition ($scopeEntries.Count -eq $scopeSlugs.Count) -Message 'manifest freshness scope slugs 均可解析到 entry'))
[void]$results.Add((Assert-Collect -Condition ($roots.Count -ge 1) -Message 'manifest 至少声明了一个 mirror root'))

$rootResults = @()
$requiredPassCount = 0
$requiredRootCount = 0

foreach ($root in $roots) {
    $resolvedPath = Resolve-ManifestPath -RepoRoot $repoRoot -PathValue ([string]$root.path)
    $required = [bool]$root.required_for_freshness_gate
    if ($required) {
        $requiredRootCount++
    }

    $missing = New-Object System.Collections.Generic.List[string]
    $nonGit = New-Object System.Collections.Generic.List[string]
    $drift = New-Object System.Collections.Generic.List[object]
    $matched = New-Object System.Collections.Generic.List[string]
    $present = New-Object System.Collections.Generic.List[string]

    [void]$results.Add((Assert-Collect -Condition ([int]$root.expected_entry_count -eq $scopeEntries.Count) -Message ('root {0} expected_entry_count 与 freshness scope 一致' -f $root.id) -Details ([ordered]@{ expected_entry_count = [int]$root.expected_entry_count; scope_count = $scopeEntries.Count })))

    foreach ($entry in $scopeEntries) {
        $slug = [string]$entry.slug
        $expected = [string]$entry.observed_head_sha
        $repoDir = Join-Path $resolvedPath $slug

        if (-not (Test-Path -LiteralPath $repoDir)) {
            [void]$missing.Add($slug)
            continue
        }

        [void]$present.Add($slug)
        if (-not (Test-Path -LiteralPath (Join-Path $repoDir '.git'))) {
            [void]$nonGit.Add($slug)
            continue
        }

        $actual = ''
        try {
            $actual = [string](git -C $repoDir rev-parse HEAD 2>$null | Select-Object -First 1)
        } catch {
            $actual = ''
        }

        if ([string]::IsNullOrWhiteSpace($actual)) {
            [void]$nonGit.Add($slug)
            continue
        }

        if ($actual -eq $expected) {
            [void]$matched.Add($slug)
        } else {
            [void]$drift.Add([pscustomobject]@{
                    slug = $slug
                    expected = $expected
                    actual = $actual
                })
        }
    }

    $fullCoverage = (Test-Path -LiteralPath $resolvedPath) -and
        ($missing.Count -eq 0) -and
        ($nonGit.Count -eq 0) -and
        ($drift.Count -eq 0) -and
        ($matched.Count -eq $scopeEntries.Count)

    if ($required -and $fullCoverage) {
        $requiredPassCount++
    }

    $rootResults += [pscustomobject]@{
        id = [string]$root.id
        role = [string]$root.role
        path = $resolvedPath
        required_for_freshness_gate = $required
        exists = [bool](Test-Path -LiteralPath $resolvedPath)
        expected_entry_count = [int]$root.expected_entry_count
        present_count = $present.Count
        matched_count = $matched.Count
        missing = [string[]]$missing.ToArray()
        non_git = [string[]]$nonGit.ToArray()
        drift = [object[]]$drift.ToArray()
        full_coverage_and_match = $fullCoverage
    }

    if ($required) {
        [void]$results.Add((Assert-Collect -Condition (Test-Path -LiteralPath $resolvedPath) -Message ('required root {0} 存在' -f $root.id) -Details $resolvedPath))
        [void]$results.Add((Assert-Collect -Condition $fullCoverage -Message ('required root {0} 满足全量 coverage + HEAD match' -f $root.id)))
    } else {
        $info = [ordered]@{
            path = $resolvedPath
            present_count = $present.Count
            missing_count = $missing.Count
            non_git_count = $nonGit.Count
            drift_count = $drift.Count
        }
        [void]$results.Add((Assert-Collect -Condition $true -Message ('non-required root {0} 已记录为 informational state' -f $root.id) -Details $info))
    }
}

[void]$results.Add((Assert-Collect -Condition ($requiredRootCount -ge 1) -Message '至少配置了一个 required freshness root'))
[void]$results.Add((Assert-Collect -Condition ($requiredPassCount -ge 1) -Message '至少一个 required freshness root 完整且 HEAD 对齐'))

$total = $results.Count
$passed = @($results | Where-Object { $_.pass }).Count
$failed = $total - $passed
$gatePass = ($failed -eq 0)
$gateResultText = if ($gatePass) { 'PASS' } else { 'FAIL' }

Write-Host ''
Write-Host '=== Summary ==='
Write-Host ('Total assertions: ' + $total)
Write-Host ('Passed: ' + $passed)
Write-Host ('Failed: ' + $failed)
Write-Host ('Gate Result: ' + $gateResultText)

if ($WriteArtifacts) {
    $outDir = Join-Path $repoRoot 'outputs\verify'
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    $jsonPath = Join-Path $outDir 'vibe-upstream-mirror-freshness-gate.json'
    $mdPath = Join-Path $outDir 'vibe-upstream-mirror-freshness-gate.md'
    $assertionSummary = @{
        total = $total
        passed = $passed
        failed = $failed
    }

    $artifact = @{
        generated_at = [DateTime]::UtcNow.ToString('o')
        gate_result = $gateResultText
        assertions = $assertionSummary
        manifest_path = $manifestPath
        root_results = [object[]]$rootResults
        results = [object[]]$results
    }

    Write-VgoUtf8NoBomText -Path $jsonPath -Content ($artifact | ConvertTo-Json -Depth 50)

    $mdLines = @()
    $mdLines += "# VCO Upstream Mirror Freshness Gate"
    $mdLines += ""
    $mdLines += "- Gate Result: **$($artifact.gate_result)**"
    $mdLines += "- Assertions: total=$total, passed=$passed, failed=$failed"
    $mdLines += ""
    $mdLines += "## Root Results"
    $mdLines += ""

    foreach ($rootResult in $rootResults) {
        $mdLines += "- Root $($rootResult.id): required=$($rootResult.required_for_freshness_gate), present=$($rootResult.present_count), matched=$($rootResult.matched_count), missing=$($rootResult.missing.Count), non_git=$($rootResult.non_git.Count), drift=$($rootResult.drift.Count), full_coverage=$($rootResult.full_coverage_and_match)"
    }

    Write-VgoUtf8NoBomText -Path $mdPath -Content ($mdLines -join [Environment]::NewLine)
}

if (-not $gatePass) {
    exit 1
}
