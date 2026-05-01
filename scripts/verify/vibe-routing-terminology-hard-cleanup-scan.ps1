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

function ConvertTo-RepoRelativePath {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Root
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $pathFull.Substring($rootFull.Length).TrimStart('\', '/').Replace('\', '/')
    }
    return $pathFull.Replace('\', '/')
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

$historicalDocFiles = [ordered]@{}
foreach ($relative in @($config.historical_docs)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$relative)) {
        $historicalDocFiles[[string]$relative] = $true
    }
}

if ($config.PSObject.Properties.Name -contains 'historical_doc_roots') {
    foreach ($rootRelative in @($config.historical_doc_roots)) {
        if ([string]::IsNullOrWhiteSpace([string]$rootRelative)) {
            continue
        }
        $rootPath = Join-Path $RepoRoot ([string]$rootRelative)
        if (-not (Test-Path -LiteralPath $rootPath)) {
            continue
        }
        foreach ($file in @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter '*.md')) {
            $relativePath = ConvertTo-RepoRelativePath -Path $file.FullName -Root $RepoRoot
            $historicalDocFiles[$relativePath] = $true
        }
    }
}

$historicalDocExemptions = @{}
foreach ($relative in @($config.current_docs)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$relative)) {
        $historicalDocExemptions[[string]$relative] = $true
    }
}
if ($config.PSObject.Properties.Name -contains 'historical_doc_exemptions') {
    foreach ($relative in @($config.historical_doc_exemptions)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$relative)) {
            $historicalDocExemptions[[string]$relative] = $true
        }
    }
}

$historicalMarkedCount = 0
$historicalRetiredTermFileCount = 0
foreach ($relative in @($historicalDocFiles.Keys | Sort-Object)) {
    if ($historicalDocExemptions.Contains([string]$relative)) {
        continue
    }

    $fullPath = Join-Path $RepoRoot ([string]$relative)
    $lines = @(Get-TextFileLines -Path $fullPath)
    if ($lines.Count -eq 0) {
        continue
    }

    $hasRetiredTerm = $false
    foreach ($lineText in @($lines)) {
        $lineString = [string]$lineText
        foreach ($pattern in @($config.retired_terms)) {
            $patternString = [string]$pattern
            if (-not [string]::IsNullOrWhiteSpace($lineString) -and $lineString.IndexOf($patternString, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $hasRetiredTerm = $true
                break
            }
        }
        if ($hasRetiredTerm) { break }
    }
    if (-not $hasRetiredTerm) {
        continue
    }

    $historicalRetiredTermFileCount += 1
    $header = (@($lines | Select-Object -First 20) -join "`n")
    $hasMarker = $false
    foreach ($marker in @($config.historical_markers)) {
        if ($header.IndexOf([string]$marker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $hasMarker = $true
            break
        }
    }
    if ($hasMarker) {
        $historicalMarkedCount += 1
    } else {
        $findings.Add((New-Finding -Category 'historical_doc_unmarked_retired_term' -Path ([string]$relative) -Line 1 -Pattern 'historical_marker' -Text 'Historical document contains retired terms but lacks a retired/historical marker in the first 20 lines.')) | Out-Null
    }
}

$executionInternalCount = 0
foreach ($relative in @($config.execution_internal_scan_files)) {
    $fullPath = Join-Path $RepoRoot $relative
    $lines = @(Get-TextFileLines -Path $fullPath)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineText = [string]$lines[$index]
        if ([string]$lineText -and $lineText.IndexOf('specialist_dispatch', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $executionInternalCount += 1
            $findings.Add((New-Finding -Category 'execution_internal_specialist_dispatch_reference' -Path ([string]$relative) -Line ($index + 1) -Pattern 'specialist_dispatch' -Text $lineText)) | Out-Null
        }
    }
}

$currentPolicyHelperCount = 0
$currentPolicyHelperFiles = if ($config.PSObject.Properties.Name -contains 'current_policy_helper_files') {
    @($config.current_policy_helper_files)
} else {
    @()
}
$currentPolicyHelperForbiddenPatterns = if ($config.PSObject.Properties.Name -contains 'current_policy_helper_forbidden_patterns') {
    @($config.current_policy_helper_forbidden_patterns)
} else {
    @()
}
foreach ($relative in @($currentPolicyHelperFiles)) {
    $fullPath = Join-Path $RepoRoot ([string]$relative)
    $lines = @(Get-TextFileLines -Path $fullPath)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineText = [string]$lines[$index]
        foreach ($pattern in @($currentPolicyHelperForbiddenPatterns)) {
            if ([string]::IsNullOrWhiteSpace([string]$pattern)) {
                continue
            }
            if ($lineText.IndexOf([string]$pattern, [System.StringComparison]::Ordinal) -ge 0) {
                $currentPolicyHelperCount += 1
                $findings.Add((New-Finding -Category 'current_policy_helper_dispatch_vocabulary_reference' -Path ([string]$relative) -Line ($index + 1) -Pattern ([string]$pattern) -Text $lineText)) | Out-Null
            }
        }
    }
}

$summary = [pscustomobject]@{
    current_doc_retired_term_violation_count = @($findings | Where-Object { $_.category -eq 'current_doc_retired_term' }).Count
    current_behavior_test_retired_field_read_count = @($findings | Where-Object { $_.category -eq 'current_behavior_test_retired_field_read' }).Count
    historical_doc_retired_term_file_count = [int]$historicalRetiredTermFileCount
    historical_doc_marked_retired_term_count = [int]$historicalMarkedCount
    historical_doc_unmarked_retired_term_count = @($findings | Where-Object { $_.category -eq 'historical_doc_unmarked_retired_term' }).Count
    execution_internal_specialist_dispatch_reference_count = [int]$executionInternalCount
    current_policy_helper_dispatch_vocabulary_reference_count = [int]$currentPolicyHelperCount
    findings = [object[]]$findings.ToArray()
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 20
} else {
    '=== VCO Routing Terminology Hard Cleanup Scan ==='
    ('Current docs retired-term violations: {0}' -f [int]$summary.current_doc_retired_term_violation_count)
    ('Current behavior test retired-field reads: {0}' -f [int]$summary.current_behavior_test_retired_field_read_count)
    ('Historical docs with retired terms: {0}' -f [int]$summary.historical_doc_retired_term_file_count)
    ('Historical docs with retired marker: {0}' -f [int]$summary.historical_doc_marked_retired_term_count)
    ('Historical docs without retired marker: {0}' -f [int]$summary.historical_doc_unmarked_retired_term_count)
    ('Execution-internal specialist_dispatch allowlist references: {0}' -f [int]$summary.execution_internal_specialist_dispatch_reference_count)
    ('Current policy/helper dispatch vocabulary references: {0}' -f [int]$summary.current_policy_helper_dispatch_vocabulary_reference_count)
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
