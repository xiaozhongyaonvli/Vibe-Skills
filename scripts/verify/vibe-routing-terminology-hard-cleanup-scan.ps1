param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Read-JsonFile {
    param([Parameter(Mandatory)] [string]$Path)
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-TextFileLines {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }
    return Get-Content -LiteralPath $Path -Encoding UTF8
}

function New-Finding {
    param(
        [Parameter(Mandatory)] [string]$Category,
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [int]$Line,
        [Parameter(Mandatory)] [string]$Pattern,
        [Parameter(Mandatory)] [string]$Text
    )
    [pscustomobject]@{
        category = $Category
        path = $Path
        line = $Line
        pattern = $Pattern
        text = $Text.Trim()
    }
}

function Test-LineHasRetiredContext {
    param([Parameter(Mandatory)] [string]$Line)
    foreach ($marker in @('retired', 'historical', 'old-format', 'old routing', 'not current', 'deprecated')) {
        if ($Line.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }
    return $false
}

$configPath = Join-Path $RepoRoot 'config\routing-terminology-hard-cleanup.json'
$config = Read-JsonFile -Path $configPath
$findings = New-Object System.Collections.Generic.List[object]

foreach ($relative in @($config.current_docs)) {
    $fullPath = Join-Path $RepoRoot $relative
    $lines = @(Get-TextFileLines -Path $fullPath)
    $insideCodeBlock = $false
    $insideRetiredSection = $false

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineText = [string]$lines[$index]
        $trimmedLine = $lineText.Trim()

        if ($trimmedLine.StartsWith('```')) {
            $insideCodeBlock = -not $insideCodeBlock
        }

        if (-not $insideCodeBlock -and $trimmedLine -match '^##\s+') {
            $insideRetiredSection = $trimmedLine -match '^##\s+Retired'
        }

        foreach ($pattern in @($config.retired_terms)) {
            if ($lineText.IndexOf([string]$pattern, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                continue
            }
            if (-not $insideRetiredSection -and -not (Test-LineHasRetiredContext -Line $lineText)) {
                $findings.Add((New-Finding -Category 'current_doc_retired_term' -Path $relative -Line ($index + 1) -Pattern ([string]$pattern) -Text $lineText)) | Out-Null
            }
        }
    }
}

foreach ($relative in @($config.current_behavior_tests)) {
    $fullPath = Join-Path $RepoRoot $relative
    $lines = @(Get-TextFileLines -Path $fullPath)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineText = [string]$lines[$index]
        if ($lineText.IndexOf('assertNotIn(', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            continue
        }
        foreach ($pattern in @($config.current_behavior_test_forbidden_patterns)) {
            if (
                [string]$pattern -eq 'specialist_recommendations' -and
                $lineText.IndexOf('no_specialist_recommendations', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
            ) {
                continue
            }
            if ($lineText.IndexOf([string]$pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $findings.Add((New-Finding -Category 'current_behavior_test_retired_field_read' -Path $relative -Line ($index + 1) -Pattern ([string]$pattern) -Text $lineText)) | Out-Null
            }
        }
    }
}

foreach ($relative in @($config.historical_docs)) {
    $fullPath = Join-Path $RepoRoot $relative
    $lines = @(Get-TextFileLines -Path $fullPath)
    if ($lines.Count -eq 0) {
        continue
    }

    $hasRetiredTerm = $false
    foreach ($lineText in @($lines)) {
        foreach ($pattern in @($config.retired_terms)) {
            if ([string]$lineText -and [string]$lineText.IndexOf([string]$pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $hasRetiredTerm = $true
                break
            }
        }
        if ($hasRetiredTerm) { break }
    }
    if (-not $hasRetiredTerm) {
        continue
    }

    $header = (@($lines | Select-Object -First 20) -join "`n")
    $hasMarker = $false
    foreach ($marker in @($config.historical_markers)) {
        if ($header.IndexOf([string]$marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $hasMarker = $true
            break
        }
    }
    if (-not $hasMarker) {
        $findings.Add((New-Finding -Category 'historical_doc_unmarked_retired_term' -Path $relative -Line 1 -Pattern 'historical_marker' -Text 'Historical document contains retired terms but lacks a retired/historical marker in the first 20 lines.')) | Out-Null
    }
}

$executionInternalCount = 0
foreach ($entry in @($config.execution_internal_allowlist)) {
    $relative = [string]$entry.path
    $fullPath = Join-Path $RepoRoot $relative
    foreach ($lineText in @(Get-TextFileLines -Path $fullPath)) {
        if ([string]$lineText -and $lineText.IndexOf('specialist_dispatch', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $executionInternalCount += 1
        }
    }
}

$summary = [pscustomobject]@{
    current_doc_retired_term_violation_count = @($findings | Where-Object { $_.category -eq 'current_doc_retired_term' }).Count
    current_behavior_test_retired_field_read_count = @($findings | Where-Object { $_.category -eq 'current_behavior_test_retired_field_read' }).Count
    historical_doc_unmarked_retired_term_count = @($findings | Where-Object { $_.category -eq 'historical_doc_unmarked_retired_term' }).Count
    execution_internal_specialist_dispatch_reference_count = [int]$executionInternalCount
    findings = [object[]]$findings.ToArray()
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 20
} else {
    '=== VCO Routing Terminology Hard Cleanup Scan ==='
    ('Current docs retired-term violations: {0}' -f [int]$summary.current_doc_retired_term_violation_count)
    ('Current behavior test retired-field reads: {0}' -f [int]$summary.current_behavior_test_retired_field_read_count)
    ('Historical docs without retired marker: {0}' -f [int]$summary.historical_doc_unmarked_retired_term_count)
    ('Execution-internal specialist_dispatch allowlist references: {0}' -f [int]$summary.execution_internal_specialist_dispatch_reference_count)
    foreach ($finding in @($summary.findings)) {
        '[FAIL] {0}:{1} [{2}] {3}' -f $finding.path, $finding.line, $finding.pattern, $finding.text
    }
    if (@($summary.findings).Count -eq 0) {
        'Gate Result: PASS'
    } else {
        'Gate Result: FAIL'
    }
}

if (@($summary.findings).Count -gt 0) {
    exit 1
}
exit 0
