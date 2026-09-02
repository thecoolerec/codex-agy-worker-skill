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

    [switch]$Unsafe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw "[agy-worker] $Message"
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

if (-not (Test-Path -LiteralPath $SchemaPath -PathType Leaf)) {
    Fail "Result schema missing: $SchemaPath"
}
if (-not (Test-Path -LiteralPath $PreamblePath -PathType Leaf)) {
    Fail "Worker preamble missing: $PreamblePath"
}

$Task = Get-Content -LiteralPath $TaskPath -Raw -Encoding UTF8
$Preamble = Get-Content -LiteralPath $PreamblePath -Raw -Encoding UTF8
$Prompt = $Preamble.TrimEnd() + "`n`n" + $Task.Trim() + "`n"

$Args = @(
    "-p", $Prompt,
    "--output-format", "json",
    "--json-schema", $SchemaPath,
    "--model", $Model,
    "--effort", $Effort,
    "--print-timeout", $Timeout
)

if ($Unsafe) {
    $Args += "--dangerously-skip-permissions"
}

$StartedAt = [DateTimeOffset]::UtcNow
Push-Location -LiteralPath $RepoPath
try {
    # Keep stderr on the console so diagnostics/permission notices do not corrupt JSON stdout.
    $RawLines = & $AgyExecutable @Args
    $ExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
$FinishedAt = [DateTimeOffset]::UtcNow
$Raw = ($RawLines -join "`n").Trim()

if ([string]::IsNullOrWhiteSpace($Raw)) {
    Fail "agy produced no JSON on stdout (exit code: $ExitCode)."
}

try {
    $Envelope = $Raw | ConvertFrom-Json
}
catch {
    Fail "Could not parse agy JSON output. Exit code: $ExitCode. Raw stdout: $Raw"
}

$EnvelopeStatus = if ($Envelope.PSObject.Properties.Name -contains "status") { [string]$Envelope.status } else { "" }
if ($ExitCode -ne 0 -or $EnvelopeStatus -ne "SUCCESS") {
    $ErrorText = if ($Envelope.PSObject.Properties.Name -contains "error") { [string]$Envelope.error } else { "" }
    $Message = if (-not [string]::IsNullOrWhiteSpace($ErrorText)) { $ErrorText } else { "agy status=$EnvelopeStatus, exit=$ExitCode" }
    Fail $Message
}

if (-not ($Envelope.PSObject.Properties.Name -contains "structured_output") -or $null -eq $Envelope.structured_output) {
    Fail "agy returned SUCCESS but no structured_output. Ensure this Antigravity CLI build supports --json-schema."
}

$ConversationId = if ($Envelope.PSObject.Properties.Name -contains "conversation_id") { $Envelope.conversation_id } else { $null }
$DurationSeconds = if ($Envelope.PSObject.Properties.Name -contains "duration_seconds") { $Envelope.duration_seconds } else { $null }
$NumTurns = if ($Envelope.PSObject.Properties.Name -contains "num_turns") { $Envelope.num_turns } else { $null }
$Usage = if ($Envelope.PSObject.Properties.Name -contains "usage") { $Envelope.usage } else { $null }

$Result = [ordered]@{
    worker_result = $Envelope.structured_output
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
