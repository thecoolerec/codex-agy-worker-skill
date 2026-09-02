[CmdletBinding()]
param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }),
    [switch]$ConfigureGlobalAgents,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Destination = Join-Path $CodexHome "skills\agy-worker"

if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
    throw "Destination already exists: $Destination. Re-run with -Force to replace it."
}

if (Test-Path -LiteralPath $Destination) {
    Remove-Item -LiteralPath $Destination -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$Items = @("SKILL.md", "scripts", "schemas", "templates")
foreach ($Item in $Items) {
    Copy-Item -LiteralPath (Join-Path $RepoRoot $Item) -Destination $Destination -Recurse -Force
}

Write-Host "Installed agy-worker skill to: $Destination"

if ($ConfigureGlobalAgents) {
    $AgentsPath = Join-Path $CodexHome "AGENTS.md"
    $SnippetPath = Join-Path $RepoRoot "AGENTS.snippet.md"
    $StartMarker = "<!-- agy-worker:start -->"
    $EndMarker = "<!-- agy-worker:end -->"
    $Snippet = Get-Content -LiteralPath $SnippetPath -Raw -Encoding UTF8

    if (Test-Path -LiteralPath $AgentsPath) {
        $Existing = Get-Content -LiteralPath $AgentsPath -Raw -Encoding UTF8
    } else {
        New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
        $Existing = ""
    }

    $Pattern = [regex]::Escape($StartMarker) + ".*?" + [regex]::Escape($EndMarker)
    $Block = $StartMarker + "`n" + $Snippet.Trim() + "`n" + $EndMarker

    if ([regex]::IsMatch($Existing, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
        $Updated = [regex]::Replace($Existing, $Pattern, $Block, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    } else {
        $Updated = $Existing.TrimEnd() + $(if ($Existing.Trim().Length -gt 0) { "`n`n" } else { "" }) + $Block + "`n"
    }

    $Updated | Set-Content -LiteralPath $AgentsPath -Encoding UTF8
    Write-Host "Configured global delegation guidance in: $AgentsPath"
}

Write-Host "Next: set AGY_WORKER_MODEL to an exact Flash model slug from 'agy models'."
