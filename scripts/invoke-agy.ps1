[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TaskFile,

    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory,

    [string]$Model = $env:AGY_WORKER_MODEL,

    [ValidateSet("low", "medium", "high")]
    [string]$Effort = "medium",

    [ValidatePattern("^[0-9]+[smh]$")]
    [string]$Timeout = "20m",

    [string]$LogDirectory = $env:AGY_WORKER_LOG_DIR,

    [switch]$AllowDirty,

    [switch]$Unsafe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw "[agy-worker] $Message"
}

function Normalize-RepoPath([string]$Path) {
    return ($Path -replace "\\", "/").TrimStart("./")
}

function Test-ScopeMatch([string]$Path, [string[]]$Patterns) {
    $Normalized = Normalize-RepoPath $Path
    foreach ($Pattern in $Patterns) {
        $P = Normalize-RepoPath ([string]$Pattern)
        if ($Normalized -like $P) { return $true }
    }
    return $false
}

function Get-GitChangedFiles {
    $Lines = @(git status --porcelain=v1 --untracked-files=all 2>$null)
    $Paths = @()
    foreach ($Line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($Line) -or $Line.Length -lt 4) { continue }
        $RawPath = $Line.Substring(3)
        if ($RawPath -match " -> ") { $RawPath = ($RawPath -split " -> ")[-1] }
        $Paths += Normalize-RepoPath $RawPath.Trim('"')
    }
    return @($Paths | Sort-Object -Unique)
}

$Agy = Get-Command agy -ErrorAction SilentlyContinue
if (-not $Agy) {
    Fail "'agy' was not found on PATH. Install/configure Antigravity CLI and authenticate interactively once."
}
$AgyExecutable = if ($Agy.PSObject.Properties.Name -contains "Path" -and $Agy.Path) { $Agy.Path } else { $Agy.Source }

if ([string]::IsNullOrWhiteSpace($Model)) {
    Fail "No worker model is pinned. Pass -Model <slug> or set AGY_WORKER_MODEL to an exact Flash model slug from 'agy models'."
}

$TaskPath = (Resolve-Path -LiteralPath $TaskFile).Path
$RepoPath = (Resolve-Path -LiteralPath $WorkingDirectory).Path
$SkillRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$SchemaPath = Join-Path $SkillRoot "schemas\worker-result.schema.json"
$PreamblePath = Join-Path $SkillRoot "templates\worker-preamble.md"

if (-not (Test-Path -LiteralPath $SchemaPath -PathType Leaf)) { Fail "Result schema missing: $SchemaPath" }
if (-not (Test-Path -LiteralPath $PreamblePath -PathType Leaf)) { Fail "Worker preamble missing: $PreamblePath" }

$Task = Get-Content -LiteralPath $TaskPath -Raw -Encoding UTF8
$Preamble = Get-Content -LiteralPath $PreamblePath -Raw -Encoding UTF8

$MetaMatch = [regex]::Match($Task, '(?s)<!--\s*AGY_META\s*(\{.*?\})\s*AGY_META\s*-->')
if (-not $MetaMatch.Success) {
    Fail "Task contract is missing the AGY_META JSON block required by contract_version 2."
}
try {
    $Meta = $MetaMatch.Groups[1].Value | ConvertFrom-Json
}
catch {
    Fail "AGY_META is not valid JSON: $($_.Exception.Message)"
}

if ([string]$Meta.contract_version -ne "2") { Fail "Unsupported contract_version '$($Meta.contract_version)'. Expected '2'." }
if (-not $Meta.scope -or -not $Meta.scope.allow -or @($Meta.scope.allow).Count -eq 0) { Fail "AGY_META.scope.allow must contain at least one repo-relative path or glob." }
$AllowedScope = @($Meta.scope.allow | ForEach-Object { [string]$_ })
$DeniedScope = @()
if ($Meta.scope.PSObject.Properties.Name -contains "deny" -and $Meta.scope.deny) {
    $DeniedScope = @($Meta.scope.deny | ForEach-Object { [string]$_ })
}

$Prompt = $Preamble.TrimEnd() + "`n`n" + $Task.Trim() + "`n"
$Args = @(
    "-p", $Prompt,
    "--output-format", "json",
    "--json-schema", $SchemaPath,
    "--model", $Model,
    "--effort", $Effort,
    "--print-timeout", $Timeout
)
if ($Unsafe) { $Args += "--dangerously-skip-permissions" }

$StartedAt = [DateTimeOffset]::UtcNow
Push-Location -LiteralPath $RepoPath
try {
    $GitRoot = (git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($GitRoot)) {
        Fail "WorkingDirectory must be inside a Git repository for runtime evidence and scope validation."
    }
    $HeadBefore = (git rev-parse HEAD).Trim()
    $DirtyBefore = @(Get-GitChangedFiles)
    if ($DirtyBefore.Count -gt 0 -and -not $AllowDirty) {
        Fail "Git working tree is not clean. Commit/stash existing changes or pass -AllowDirty to explicitly downgrade attribution confidence."
    }

    # Keep stderr on the console so diagnostics/permission notices do not corrupt JSON stdout.
    $RawLines = & $AgyExecutable @Args
    $ExitCode = $LASTEXITCODE
    $ChangedAfter = @(Get-GitChangedFiles)
    $HeadAfter = (git rev-parse HEAD).Trim()
}
finally {
    Pop-Location
}
$FinishedAt = [DateTimeOffset]::UtcNow
$Raw = ($RawLines -join "`n").Trim()

if ([string]::IsNullOrWhiteSpace($Raw)) { Fail "agy produced no JSON on stdout (exit code: $ExitCode)." }
try { $Envelope = $Raw | ConvertFrom-Json }
catch { Fail "Could not parse agy JSON output. Exit code: $ExitCode. Raw stdout: $Raw" }

$EnvelopeStatus = if ($Envelope.PSObject.Properties.Name -contains "status") { [string]$Envelope.status } else { "" }
if ($ExitCode -ne 0 -or $EnvelopeStatus -ne "SUCCESS") {
    $ErrorText = if ($Envelope.PSObject.Properties.Name -contains "error") { [string]$Envelope.error } else { "" }
    $Message = if (-not [string]::IsNullOrWhiteSpace($ErrorText)) { $ErrorText } else { "agy status=$EnvelopeStatus, exit=$ExitCode" }
    Fail $Message
}
if (-not ($Envelope.PSObject.Properties.Name -contains "structured_output") -or $null -eq $Envelope.structured_output) {
    Fail "agy returned SUCCESS but no structured_output. Ensure this Antigravity CLI build supports --json-schema."
}

$OutOfScope = @()
foreach ($Path in $ChangedAfter) {
    $Allowed = Test-ScopeMatch $Path $AllowedScope
    $Denied = if ($DeniedScope.Count -gt 0) { Test-ScopeMatch $Path $DeniedScope } else { $false }
    if (-not $Allowed -or $Denied) { $OutOfScope += $Path }
}
$ScopeValid = ($OutOfScope.Count -eq 0)
$Attribution = if ($DirtyBefore.Count -eq 0) { "HIGH" } else { "LOW_DIRTY_BASELINE" }

$ConversationId = if ($Envelope.PSObject.Properties.Name -contains "conversation_id") { $Envelope.conversation_id } else { $null }
$DurationSeconds = if ($Envelope.PSObject.Properties.Name -contains "duration_seconds") { $Envelope.duration_seconds } else { $null }
$NumTurns = if ($Envelope.PSObject.Properties.Name -contains "num_turns") { $Envelope.num_turns } else { $null }
$Usage = if ($Envelope.PSObject.Properties.Name -contains "usage") { $Envelope.usage } else { $null }

$Result = [ordered]@{
    worker_result = $Envelope.structured_output
    runtime_evidence = [ordered]@{
        task_id = $Meta.task_id
        task_class = $Meta.task_class
        git_head_before = $HeadBefore
        git_head_after = $HeadAfter
        dirty_files_before = $DirtyBefore
        actual_files_changed = $ChangedAfter
        scope_allow = $AllowedScope
        scope_deny = $DeniedScope
        scope_valid = $ScopeValid
        out_of_scope_files = $OutOfScope
        attribution_confidence = $Attribution
    }
    runtime = [ordered]@{
        provider = "antigravity-cli"
        model = $Model
        effort = $Effort
        conversation_id = $ConversationId
        started_at_utc = $StartedAt.ToString("o")
        finished_at_utc = $FinishedAt.ToString("o")
        duration_seconds = $DurationSeconds
        num_turns = $NumTurns
        usage = $Usage
    }
}

$Json = $Result | ConvertTo-Json -Depth 100
if (-not [string]::IsNullOrWhiteSpace($LogDirectory)) {
    $ResolvedLogDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LogDirectory)
    New-Item -ItemType Directory -Force -Path $ResolvedLogDir | Out-Null
    $Stamp = [DateTimeOffset]::UtcNow.ToString("yyyyMMddTHHmmssfffZ")
    $LogPath = Join-Path $ResolvedLogDir "agy-worker-$Stamp.json"
    $Json | Set-Content -LiteralPath $LogPath -Encoding UTF8
}

$Json
