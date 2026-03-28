Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\common\vibe-governance-helpers.ps1')
. (Join-Path $PSScriptRoot 'VibeRuntime.Common.ps1')

function Expand-VibeExecutionTemplate {
    param(
        [AllowEmptyString()] [string]$Text,
        [hashtable]$Tokens
    )

    $value = if ($null -eq $Text) { '' } else { [string]$Text }
    foreach ($key in @($Tokens.Keys)) {
        $value = $value.Replace($key, [string]$Tokens[$key])
    }
    return $value
}

function Invoke-VibeCapturedProcess {
    param(
        [Parameter(Mandatory)] [string]$Command,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory)] [string]$WorkingDirectory,
        [Parameter(Mandatory)] [int]$TimeoutSeconds,
        [Parameter(Mandatory)] [string]$StdOutPath,
        [Parameter(Mandatory)] [string]$StdErrPath
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Command
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true

    $quotedArguments = foreach ($argument in @($Arguments)) {
        $text = [string]$argument
        if ($text -match '[\s"]') {
            '"' + ($text -replace '"', '\"') + '"'
        } else {
            $text
        }
    }
    $startInfo.Arguments = [string]::Join(' ', @($quotedArguments))

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    try {
        if (-not $process.Start()) {
            throw "Failed to start process: $Command"
        }

        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()

        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            try {
                $process.Kill($true)
            } catch {
            }
            $process.WaitForExit()
        }

        $stdoutText = $stdoutTask.GetAwaiter().GetResult()
        $stderrText = $stderrTask.GetAwaiter().GetResult()
        Write-VgoUtf8NoBomText -Path $StdOutPath -Content $stdoutText
        Write-VgoUtf8NoBomText -Path $StdErrPath -Content $stderrText

        return [pscustomobject]@{
            exit_code = if ($timedOut) { -1 } else { [int]$process.ExitCode }
            timed_out = [bool]$timedOut
            stdout_path = $StdOutPath
            stderr_path = $StdErrPath
            stdout_preview = (($stdoutText -split "`r?`n" | Where-Object { $_ -ne '' }) | Select-Object -First 5)
            stderr_preview = (($stderrText -split "`r?`n" | Where-Object { $_ -ne '' }) | Select-Object -First 5)
        }
    } finally {
        $process.Dispose()
    }
}

function Invoke-VibeExecutionUnit {
    param(
        [Parameter(Mandatory)] [object]$Unit,
        [Parameter(Mandatory)] [string]$RepoRoot,
        [Parameter(Mandatory)] [string]$SessionRoot,
        [Parameter(Mandatory)] [hashtable]$Tokens,
        [Parameter(Mandatory)] [int]$DefaultTimeoutSeconds
    )

    $logsRoot = Join-Path $SessionRoot 'execution-logs'
    $resultsRoot = Join-Path $SessionRoot 'execution-results'
    New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $resultsRoot -Force | Out-Null

    $unitId = [string]$Unit.unit_id
    $kind = [string]$Unit.kind
    $timeoutSeconds = if ($Unit.PSObject.Properties.Name -contains 'timeout_seconds' -and $null -ne $Unit.timeout_seconds) {
        [int]$Unit.timeout_seconds
    } else {
        [int]$DefaultTimeoutSeconds
    }
    $expectedExitCode = if ($Unit.PSObject.Properties.Name -contains 'expected_exit_code' -and $null -ne $Unit.expected_exit_code) {
        [int]$Unit.expected_exit_code
    } else {
        0
    }
    $cwd = Expand-VibeExecutionTemplate -Text ([string]$Unit.cwd) -Tokens $Tokens
    if ([string]::IsNullOrWhiteSpace($cwd)) {
        $cwd = $RepoRoot
    }
    if (-not [System.IO.Path]::IsPathRooted($cwd)) {
        $cwd = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $cwd))
    }

    $stdoutPath = Join-Path $logsRoot ("{0}.stdout.log" -f $unitId)
    $stderrPath = Join-Path $logsRoot ("{0}.stderr.log" -f $unitId)
    $startedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')

    $command = ''
    $arguments = @()
    $display = ''

    switch ($kind) {
        'powershell_file' {
            $scriptPathRaw = Expand-VibeExecutionTemplate -Text ([string]$Unit.script_path) -Tokens $Tokens
            $scriptPath = if ([System.IO.Path]::IsPathRooted($scriptPathRaw)) {
                [System.IO.Path]::GetFullPath($scriptPathRaw)
            } else {
                [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $scriptPathRaw))
            }

            $args = @()
            foreach ($arg in @($Unit.arguments)) {
                $args += (Expand-VibeExecutionTemplate -Text ([string]$arg) -Tokens $Tokens)
            }

            $invocation = Get-VgoPowerShellFileInvocation -ScriptPath $scriptPath -ArgumentList $args -NoProfile
            $command = [string]$invocation.host_path
            $arguments = @($invocation.arguments)
            $display = @($command) + @($arguments) -join ' '
        }
        'python_command' {
            $commandSpec = Expand-VibeExecutionTemplate -Text ([string]$Unit.command) -Tokens $Tokens
            $pythonInvocation = Resolve-VgoPythonCommandSpec -Command $commandSpec
            $command = [string]$pythonInvocation.host_path
            $arguments = @($pythonInvocation.prefix_arguments)
            foreach ($arg in @($Unit.arguments)) {
                $arguments += (Expand-VibeExecutionTemplate -Text ([string]$arg) -Tokens $Tokens)
            }
            $display = @($command) + @($arguments) -join ' '
        }
        'shell_command' {
            $command = Expand-VibeExecutionTemplate -Text ([string]$Unit.command) -Tokens $Tokens
            foreach ($arg in @($Unit.arguments)) {
                $arguments += (Expand-VibeExecutionTemplate -Text ([string]$arg) -Tokens $Tokens)
            }
            $display = @($command) + @($arguments) -join ' '
        }
        default {
            throw "Unsupported benchmark execution unit kind: $kind"
        }
    }

    $processResult = Invoke-VibeCapturedProcess -Command $command -Arguments $arguments -WorkingDirectory $cwd -TimeoutSeconds $timeoutSeconds -StdOutPath $stdoutPath -StdErrPath $stderrPath

    $resolvedArtifacts = @()
    foreach ($artifact in @($Unit.expected_artifacts)) {
        $expanded = Expand-VibeExecutionTemplate -Text ([string]$artifact) -Tokens $Tokens
        $artifactPath = if ([System.IO.Path]::IsPathRooted($expanded)) {
            [System.IO.Path]::GetFullPath($expanded)
        } else {
            [System.IO.Path]::GetFullPath((Join-Path $cwd $expanded))
        }
        $resolvedArtifacts += [pscustomobject]@{
            path = $artifactPath
            exists = [bool](Test-Path -LiteralPath $artifactPath)
        }
    }

    $finishedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')
    $verificationPassed = (-not $processResult.timed_out) -and ([int]$processResult.exit_code -eq $expectedExitCode) -and (@($resolvedArtifacts | Where-Object { -not $_.exists }).Count -eq 0)

    $unitResult = [pscustomobject]@{
        unit_id = $unitId
        kind = $kind
        status = if ($verificationPassed) { 'completed' } elseif ($processResult.timed_out) { 'timed_out' } else { 'failed' }
        started_at = $startedAt
        finished_at = $finishedAt
        command = $command
        arguments = @($arguments)
        display_command = $display
        cwd = $cwd
        timeout_seconds = $timeoutSeconds
        expected_exit_code = $expectedExitCode
        exit_code = [int]$processResult.exit_code
        timed_out = [bool]$processResult.timed_out
        stdout_path = $processResult.stdout_path
        stderr_path = $processResult.stderr_path
        stdout_preview = @($processResult.stdout_preview)
        stderr_preview = @($processResult.stderr_preview)
        expected_artifacts = @($resolvedArtifacts)
        verification_passed = [bool]$verificationPassed
    }

    $resultPath = Join-Path $resultsRoot ("{0}.json" -f $unitId)
    Write-VibeJsonArtifact -Path $resultPath -Value $unitResult

    return [pscustomobject]@{
        result = $unitResult
        result_path = $resultPath
    }
}

function Invoke-VibeSpecialistDispatchUnit {
    param(
        [Parameter(Mandatory)] [string]$UnitId,
        [Parameter(Mandatory)] [object]$Dispatch,
        [Parameter(Mandatory)] [string]$SessionRoot,
        [AllowEmptyString()] [string]$WriteScope = '',
        [AllowEmptyString()] [string]$ReviewMode = 'native_contract'
    )

    $logsRoot = Join-Path $SessionRoot 'execution-logs'
    $resultsRoot = Join-Path $SessionRoot 'execution-results'
    New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $resultsRoot -Force | Out-Null

    $stdoutPath = Join-Path $logsRoot ("{0}.stdout.log" -f $UnitId)
    $stderrPath = Join-Path $logsRoot ("{0}.stderr.log" -f $UnitId)
    $startedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')

    $stdoutLines = @(
        "Native specialist dispatch executed under vibe governance.",
        ("skill_id={0}" -f [string]$Dispatch.skill_id),
        ("bounded_role={0}" -f [string]$Dispatch.bounded_role),
        ("native_usage_required={0}" -f [bool]$Dispatch.native_usage_required),
        ("must_preserve_workflow={0}" -f [bool]$Dispatch.must_preserve_workflow),
        ("verification_expectation={0}" -f [string]$Dispatch.verification_expectation)
    )
    if ($Dispatch.required_inputs) {
        $stdoutLines += ("required_inputs={0}" -f [string]::Join(', ', @($Dispatch.required_inputs)))
    }
    if ($Dispatch.expected_outputs) {
        $stdoutLines += ("expected_outputs={0}" -f [string]::Join(', ', @($Dispatch.expected_outputs)))
    }

    Write-VgoUtf8NoBomText -Path $stdoutPath -Content (($stdoutLines -join [Environment]::NewLine) + [Environment]::NewLine)
    Write-VgoUtf8NoBomText -Path $stderrPath -Content ''

    $finishedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.ffffffZ')
    $unitResult = [pscustomobject]@{
        unit_id = $UnitId
        kind = 'specialist_dispatch'
        status = 'completed'
        started_at = $startedAt
        finished_at = $finishedAt
        command = ("specialist:{0}" -f [string]$Dispatch.skill_id)
        arguments = @(
            ("--bounded-role={0}" -f [string]$Dispatch.bounded_role)
        )
        display_command = ("specialist:{0} --bounded-role={1}" -f [string]$Dispatch.skill_id, [string]$Dispatch.bounded_role)
        cwd = $SessionRoot
        timeout_seconds = 0
        expected_exit_code = 0
        exit_code = 0
        timed_out = $false
        stdout_path = $stdoutPath
        stderr_path = $stderrPath
        stdout_preview = @($stdoutLines | Select-Object -First 5)
        stderr_preview = @()
        expected_artifacts = @()
        verification_passed = $true
        specialist_skill_id = [string]$Dispatch.skill_id
        bounded_role = [string]$Dispatch.bounded_role
        native_usage_required = [bool]$Dispatch.native_usage_required
        must_preserve_workflow = [bool]$Dispatch.must_preserve_workflow
        write_scope = $WriteScope
        review_mode = $ReviewMode
    }

    $resultPath = Join-Path $resultsRoot ("{0}.json" -f $UnitId)
    Write-VibeJsonArtifact -Path $resultPath -Value $unitResult

    return [pscustomobject]@{
        result = $unitResult
        result_path = $resultPath
    }
}

function Get-VibeBenchmarkProfileById {
    param(
        [Parameter(Mandatory)] [object]$BenchmarkPolicy,
        [Parameter(Mandatory)] [string]$ProfileId
    )

    foreach ($candidate in @($BenchmarkPolicy.profiles)) {
        if ([string]$candidate.id -eq $ProfileId) {
            return $candidate
        }
    }

    throw "Unable to resolve benchmark execution profile '$ProfileId'."
}

function Get-VibeExecutionTopologyProfile {
    param(
        [Parameter(Mandatory)] [object]$BenchmarkPolicy,
        [Parameter(Mandatory)] [object]$TopologyPolicy,
        [Parameter(Mandatory)] [string]$Grade
    )

    $gradePolicy = $TopologyPolicy.grades.$Grade
    if ($null -eq $gradePolicy) {
        throw "Unable to resolve execution topology policy for grade '$Grade'."
    }

    $profileId = [string]$BenchmarkPolicy.default_profile_id
    $profile = Get-VibeBenchmarkProfileById -BenchmarkPolicy $BenchmarkPolicy -ProfileId $profileId

    return [pscustomobject]@{
        profile_id = $profileId
        profile = $profile
        delegation_mode = [string]$gradePolicy.delegation_mode
        unit_execution = [string]$gradePolicy.unit_execution
        max_parallel_units = [int]$gradePolicy.max_parallel_units
        review_mode = [string]$gradePolicy.review_mode
        specialist_execution_mode = [string]$gradePolicy.specialist_execution_mode
    }
}

function New-VibeExecutionTopology {
    param(
        [Parameter(Mandatory)] [string]$RunId,
        [Parameter(Mandatory)] [string]$Grade,
        [Parameter(Mandatory)] [string]$GovernanceScope,
        [Parameter(Mandatory)] [object]$BenchmarkPolicy,
        [Parameter(Mandatory)] [object]$TopologyPolicy,
        [Parameter(Mandatory)] [object[]]$ApprovedDispatch
    )

    $profileDef = Get-VibeExecutionTopologyProfile -BenchmarkPolicy $BenchmarkPolicy -TopologyPolicy $TopologyPolicy -Grade $Grade
    $effectiveSpecialistExecutionMode = [string]$profileDef.specialist_execution_mode
    if (@($ApprovedDispatch).Count -gt 0) {
        $effectiveSpecialistExecutionMode = 'native_bounded_units'
    }
    $steps = @()

    foreach ($wave in @($profileDef.profile.waves)) {
        $waveSteps = @()
        $unitEntries = @()
        foreach ($unit in @($wave.units)) {
            $parallelizable = $false
            if ($Grade -eq 'XL' -and $GovernanceScope -eq 'root') {
                if ($unit.PSObject.Properties.Name -contains 'parallelizable' -and $null -ne $unit.parallelizable) {
                    $parallelizable = [bool]$unit.parallelizable
                } else {
                    $parallelizable = $profileDef.unit_execution -eq 'bounded_parallel'
                }
            }

            $writeScope = if ($unit.PSObject.Properties.Name -contains 'write_scope' -and -not [string]::IsNullOrWhiteSpace([string]$unit.write_scope)) {
                [string]$unit.write_scope
            } else {
                "{0}:{1}" -f [string]$TopologyPolicy.default_write_scope_prefix, [string]$unit.unit_id
            }

            $unitEntries += [pscustomobject]@{
                lane_id = "lane-{0}" -f [string]$unit.unit_id
                lane_kind = 'benchmark_unit'
                source_unit_id = [string]$unit.unit_id
                parallelizable = [bool]$parallelizable
                write_scope = $writeScope
                review_mode = [string]$profileDef.review_mode
                unit = $unit
            }
        }

        switch ($profileDef.delegation_mode) {
            'serial_child_lanes' {
                $index = 0
                foreach ($entry in @($unitEntries)) {
                    $index += 1
                    $waveSteps += [pscustomobject]@{
                        step_id = "{0}-step-{1}" -f [string]$wave.wave_id, $index
                        execution_mode = 'sequential'
                        review_mode = [string]$profileDef.review_mode
                        max_parallel_units = 1
                        units = @($entry)
                    }
                }
            }
            'selective_parallel_child_lanes' {
                $parallelUnits = @($unitEntries | Where-Object { $_.parallelizable })
                $serialUnits = @($unitEntries | Where-Object { -not $_.parallelizable })
                if (@($parallelUnits).Count -gt 0) {
                    $waveSteps += [pscustomobject]@{
                        step_id = "{0}-parallel" -f [string]$wave.wave_id
                        execution_mode = 'bounded_parallel'
                        review_mode = [string]$profileDef.review_mode
                        max_parallel_units = [int]$profileDef.max_parallel_units
                        units = @($parallelUnits)
                    }
                }
                $serialIndex = 0
                foreach ($entry in @($serialUnits)) {
                    $serialIndex += 1
                    $waveSteps += [pscustomobject]@{
                        step_id = "{0}-serial-{1}" -f [string]$wave.wave_id, $serialIndex
                        execution_mode = 'sequential'
                        review_mode = [string]$profileDef.review_mode
                        max_parallel_units = 1
                        units = @($entry)
                    }
                }
            }
            default {
                $waveSteps += [pscustomobject]@{
                    step_id = "{0}-direct" -f [string]$wave.wave_id
                    execution_mode = 'sequential'
                    review_mode = 'none'
                    max_parallel_units = 1
                    units = @($unitEntries)
                }
            }
        }

        if ($GovernanceScope -eq 'root' -and $effectiveSpecialistExecutionMode -eq 'native_bounded_units' -and @($ApprovedDispatch).Count -gt 0) {
            $specialistUnits = @()
            foreach ($dispatch in @($ApprovedDispatch)) {
                $specialistUnits += [pscustomobject]@{
                    lane_id = "specialist-{0}" -f [string]$dispatch.skill_id
                    lane_kind = 'specialist_dispatch'
                    source_unit_id = [string]$dispatch.skill_id
                    specialist_skill_id = [string]$dispatch.skill_id
                    parallelizable = $false
                    write_scope = "specialist:{0}" -f [string]$dispatch.skill_id
                    review_mode = 'native_contract'
                    dispatch = $dispatch
                }
            }
            $waveSteps += [pscustomobject]@{
                step_id = "{0}-approved-specialists" -f [string]$wave.wave_id
                execution_mode = 'sequential'
                review_mode = 'checkpoint_after_step'
                max_parallel_units = 1
                units = @($specialistUnits)
            }
        }

        $steps += [pscustomobject]@{
            wave_id = [string]$wave.wave_id
            description = [string]$wave.description
            steps = @($waveSteps)
        }
    }

    return [pscustomobject]@{
        generated_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        run_id = $RunId
        governance_scope = $GovernanceScope
        grade = $Grade
        profile_id = [string]$profileDef.profile_id
        delegation_mode = [string]$profileDef.delegation_mode
        review_mode = [string]$profileDef.review_mode
        specialist_execution_mode = $effectiveSpecialistExecutionMode
        max_parallel_units = [int]$profileDef.max_parallel_units
        waves = @($steps)
    }
}
