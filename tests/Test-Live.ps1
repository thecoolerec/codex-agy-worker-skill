[CmdletBinding()]
param(
    [string]$Model = $env:AGY_WORKER_MODEL
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Model)) {
    throw "Set AGY_WORKER_MODEL or pass -Model with an exact slug from 'agy models'."
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("agy-worker-smoke-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $Temp | Out-Null

try {
    Set-Content -LiteralPath (Join-Path $Temp "README.txt") -Value "DO_NOT_CHANGE" -Encoding UTF8
    $Task = @'
# AGY Task Contract

## OBJECTIVE
Create `agy-worker-test.txt` at repository root containing exactly `AGY_WORKER_OK`.

## CONFIRMED_FACTS
- `README.txt` exists and must remain unchanged.

## ASSUMPTIONS
- None.

## UNKNOWNS
- None.

## SCOPE
Allowed changes:
- `agy-worker-test.txt`

## DECISIONS
- File name and contents are final.

## CONSTRAINTS
- Preserve README.txt unchanged.

## MUST_NOT
- Do not modify any existing file.
- Do not add dependencies.
- Do not modify files outside SCOPE.

## IMPLEMENTATION_TASKS
1. Create `agy-worker-test.txt` with exactly `AGY_WORKER_OK` and a trailing newline.

## ACCEPTANCE_CRITERIA
- `agy-worker-test.txt` exists.
- Its trimmed content equals `AGY_WORKER_OK`.
- README.txt remains unchanged.

## STOP_CONDITIONS
Return BLOCKED if the requested file cannot be created without modifying another file.
'@
    $TaskPath = Join-Path $Temp "task.md"
    Set-Content -LiteralPath $TaskPath -Value $Task -Encoding UTF8

    & (Join-Path $RepoRoot "scripts\invoke-agy.ps1") -TaskFile $TaskPath -WorkingDirectory $Temp -Model $Model

    $Value = (Get-Content -LiteralPath (Join-Path $Temp "agy-worker-test.txt") -Raw).Trim()
    if ($Value -ne "AGY_WORKER_OK") {
        throw "Smoke test failed: unexpected output file content '$Value'"
    }
    if ((Get-Content -LiteralPath (Join-Path $Temp "README.txt") -Raw).Trim() -ne "DO_NOT_CHANGE") {
        throw "Smoke test failed: README.txt was modified"
    }

    Write-Host "AGY worker live smoke test passed."
}
finally {
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}
