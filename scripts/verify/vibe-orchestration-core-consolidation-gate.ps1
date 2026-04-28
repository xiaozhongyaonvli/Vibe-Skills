param()

$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message,
        [string]$Details = ""
    )

    if ($Condition) {
        Write-Host "[PASS] $Message"
        return $true
    }

    if ($Details) {
        Write-Host "[FAIL] $Message - $Details" -ForegroundColor Red
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    }
    return $false
}

function Invoke-Route {
    param(
        [string]$Prompt,
        [string]$Grade,
        [string]$TaskType,
        [string]$RequestedSkill = ""
    )

    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $resolver = Join-Path $repoRoot "scripts\router\resolve-pack-route.ps1"
    $args = @{
        Prompt = $Prompt
        Grade = $Grade
        TaskType = $TaskType
    }
    if ($RequestedSkill) {
        $args.RequestedSkill = $RequestedSkill
    }

    return (& $resolver @args | ConvertFrom-Json)
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$manifest = Get-Content -LiteralPath (Join-Path $repoRoot "config\pack-manifest.json") -Raw | ConvertFrom-Json
$rules = Get-Content -LiteralPath (Join-Path $repoRoot "config\skill-routing-rules.json") -Raw | ConvertFrom-Json
$entrySurfaces = Get-Content -LiteralPath (Join-Path $repoRoot "config\vibe-entry-surfaces.json") -Raw | ConvertFrom-Json
$pack = @($manifest.packs) | Where-Object { $_.id -eq "orchestration-core" } | Select-Object -First 1

$results = @()

$expectedCandidates = @(
    "brainstorming",
    "writing-plans",
    "subagent-driven-development",
    "context-hunter",
    "think-harder",
    "dialectic",
    "local-vco-roles",
    "spec-kit-vibe-compat"
)
$expectedAuthorities = @(
    "brainstorming",
    "writing-plans",
    "subagent-driven-development",
    "spec-kit-vibe-compat"
)
$expectedStageAssistants = @(
    "context-hunter",
    "think-harder",
    "dialectic",
    "local-vco-roles"
)
$removedFromPack = @(
    "autonomous-builder",
    "cancel-ralph",
    "claude-skills",
    "context-fundamentals",
    "create-plan",
    "hive-mind-advanced",
    "planning-with-files",
    "ralph-loop",
    "superclaude-framework-compat",
    "speckit-analyze",
    "speckit-checklist",
    "speckit-clarify",
    "speckit-constitution",
    "speckit-implement",
    "speckit-plan",
    "speckit-specify",
    "speckit-tasks",
    "speckit-taskstoissues",
    "vibe"
)

$results += Assert-True -Condition ($null -ne $pack) -Message "orchestration-core pack exists"
$results += Assert-True -Condition (@($pack.skill_candidates).Count -eq 8) -Message "orchestration-core has 8 skill candidates"
$results += Assert-True -Condition (@($pack.route_authority_candidates).Count -eq 4) -Message "orchestration-core has 4 route authorities"
$results += Assert-True -Condition (@($pack.stage_assistant_candidates).Count -eq 4) -Message "orchestration-core has 4 stage assistants"

foreach ($skill in $expectedCandidates) {
    $results += Assert-True -Condition (@($pack.skill_candidates) -contains $skill) -Message "candidate retained: $skill"
}
foreach ($skill in $expectedAuthorities) {
    $results += Assert-True -Condition (@($pack.route_authority_candidates) -contains $skill) -Message "route authority retained: $skill"
}
foreach ($skill in $expectedStageAssistants) {
    $results += Assert-True -Condition (@($pack.stage_assistant_candidates) -contains $skill) -Message "stage assistant retained: $skill"
}
foreach ($skill in $removedFromPack) {
    $results += Assert-True -Condition (-not (@($pack.skill_candidates) -contains $skill)) -Message "removed from orchestration-core candidates: $skill"
}

$defaults = @($pack.defaults_by_task.PSObject.Properties | ForEach-Object { "$($_.Name)=$($_.Value)" })
$results += Assert-True -Condition (@($pack.defaults_by_task.PSObject.Properties).Count -eq 2) -Message "only planning and research defaults remain" -Details ($defaults -join ", ")
$results += Assert-True -Condition ([string]$pack.defaults_by_task.planning -eq "writing-plans") -Message "planning defaults to writing-plans"
$results += Assert-True -Condition ([string]$pack.defaults_by_task.research -eq "brainstorming") -Message "research defaults to brainstorming"
$results += Assert-True -Condition (-not ($pack.defaults_by_task.PSObject.Properties.Name -contains "coding")) -Message "coding has no orchestration-core default"
$results += Assert-True -Condition (-not ($pack.defaults_by_task.PSObject.Properties.Name -contains "debug")) -Message "debug has no orchestration-core default"
$results += Assert-True -Condition (-not ($pack.defaults_by_task.PSObject.Properties.Name -contains "review")) -Message "review has no orchestration-core default"

$subagentRule = $rules.skills.'subagent-driven-development'
$specKitRule = $rules.skills.'spec-kit-vibe-compat'
$results += Assert-True -Condition ($subagentRule.requires_positive_keyword_match -eq $true) -Message "subagent route requires positive keyword"
$results += Assert-True -Condition ($specKitRule.requires_positive_keyword_match -eq $true) -Message "spec-kit compat route requires positive keyword"
$results += Assert-True -Condition (@($subagentRule.canonical_for_task).Count -eq 0) -Message "subagent is not canonical for generic coding"
$results += Assert-True -Condition ([string]$entrySurfaces.canonical_runtime_skill -eq "vibe") -Message "canonical runtime skill remains vibe"

$blockedCases = @(
    [pscustomobject]@{ Name = "generic coding M"; Prompt = "实现这个功能并修改代码"; Grade = "M"; TaskType = "coding" },
    [pscustomobject]@{ Name = "generic coding L"; Prompt = "实现这个功能并修改代码"; Grade = "L"; TaskType = "coding" },
    [pscustomobject]@{ Name = "generic coding XL"; Prompt = "实现这个功能并修改代码"; Grade = "XL"; TaskType = "coding" }
)
foreach ($case in $blockedCases) {
    $route = Invoke-Route -Prompt $case.Prompt -Grade $case.Grade -TaskType $case.TaskType
    $badSelection = ([string]$route.selected.pack_id -eq "orchestration-core" -and [string]$route.selected.skill -eq "subagent-driven-development")
    $results += Assert-True -Condition (-not $badSelection) -Message "generic coding does not route to subagent: $($case.Name)" -Details ("selected={0}/{1}" -f $route.selected.pack_id, $route.selected.skill)
}

$positiveCases = @(
    [pscustomobject]@{ Name = "brainstorming"; Prompt = "先做头脑风暴，比较几个方案"; Grade = "L"; TaskType = "planning"; ExpectedSkill = "brainstorming" },
    [pscustomobject]@{ Name = "writing plans"; Prompt = "请输出实施计划和任务拆解"; Grade = "L"; TaskType = "planning"; ExpectedSkill = "writing-plans" },
    [pscustomobject]@{ Name = "subagent planning"; Prompt = "把任务拆成多个子代理并行执行"; Grade = "XL"; TaskType = "planning"; ExpectedSkill = "subagent-driven-development" },
    [pscustomobject]@{ Name = "subagent coding"; Prompt = "请用子代理并行执行这个代码修改"; Grade = "XL"; TaskType = "coding"; ExpectedSkill = "subagent-driven-development" },
    [pscustomobject]@{ Name = "speckit explicit"; Prompt = "/speckit.plan 生成技术计划"; Grade = "L"; TaskType = "planning"; ExpectedSkill = "spec-kit-vibe-compat" }
)
foreach ($case in $positiveCases) {
    $route = Invoke-Route -Prompt $case.Prompt -Grade $case.Grade -TaskType $case.TaskType
    $results += Assert-True -Condition ([string]$route.selected.pack_id -eq "orchestration-core") -Message "positive case selected orchestration-core: $($case.Name)" -Details ("selected={0}/{1}" -f $route.selected.pack_id, $route.selected.skill)
    $results += Assert-True -Condition ([string]$route.selected.skill -eq $case.ExpectedSkill) -Message "positive case selected expected skill: $($case.Name)" -Details ("selected={0}" -f $route.selected.skill)
}

$passCount = @($results | Where-Object { $_ }).Count
$failCount = @($results | Where-Object { -not $_ }).Count
$total = @($results).Count

Write-Host ""
Write-Host "=== Orchestration-Core Consolidation Summary ==="
Write-Host "Total assertions: $total"
Write-Host "Passed: $passCount"
Write-Host "Failed: $failCount"

if ($failCount -gt 0) {
    exit 1
}
