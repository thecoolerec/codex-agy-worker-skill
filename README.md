# codex-agy-worker-skill

A Codex Skill that lets a strong planner/reviewer (Codex) delegate bounded, repetitive implementation work to Google Antigravity CLI (`agy`) workers while keeping architecture, ambiguity resolution, and final verification in Codex.

The core idea is **planner → typed task contract → executor → typed result → reviewer**, not free-form agent-to-agent chat.

## Why

Fast worker models are useful for boilerplate, repetitive refactors, tests, UI cleanup, mappings, and other implementation-heavy work. They are much less reliable when a task still contains hidden architectural decisions or ambiguous assumptions.

This skill makes delegation explicit:

```text
User
  ↓
Codex (plan / decide / inspect)
  ↓
Task Contract
  ↓
Antigravity / Flash (execute)
  ↓
Structured Result
  ↓
Codex (diff / tests / review)
```

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Codex with Agent Skills support
- Google Antigravity CLI available as `agy`
- An authenticated Antigravity CLI session
- An exact worker model slug from `agy models`

Antigravity headless mode supports one-shot prompts, JSON output, model/effort selection, JSON Schema-constrained output, and non-interactive execution. The wrapper uses those primitives directly.

## Install

From this repository:

```powershell
.\scripts\install.ps1 -ConfigureGlobalAgents
```

Use `-Force` to replace an existing installation:

```powershell
.\scripts\install.ps1 -ConfigureGlobalAgents -Force
```

By default the installer uses `$CODEX_HOME` when set, otherwise `$HOME\.codex`.

## Pin the worker model

Do not guess the model name. First inspect available model slugs:

```powershell
agy models
```

Then pin the exact Flash model you want:

```powershell
[Environment]::SetEnvironmentVariable(
  "AGY_WORKER_MODEL",
  "<exact-slug-from-agy-models>",
  "User"
)
```

Open a new terminal and verify:

```powershell
$env:AGY_WORKER_MODEL
```

The wrapper intentionally fails when no model is pinned so a delegation cannot silently fall back to an unintended model.

## How Codex invokes it

Codex builds a Task Contract using `templates/task-contract.md`, writes it to a UTF-8 file, then calls:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME/.codex/skills/agy-worker/scripts/invoke-agy.ps1" `
  -TaskFile "C:\path\to\task.md" `
  -WorkingDirectory "C:\path\to\repo"
```

Optional flags:

```text
-Model <slug>          Override AGY_WORKER_MODEL
-Effort low|medium|high
-Timeout 20m
-LogDirectory <path>   Persist runtime/result telemetry
-Unsafe                Pass --dangerously-skip-permissions
```

`-Unsafe` is deliberately opt-in. Prefer Antigravity's scoped permission rules.

## Contract semantics

The contract separates information by epistemic and authority type:

- `CONFIRMED_FACTS` — verified repository facts;
- `ASSUMPTIONS` — must be checked before use;
- `DECISIONS` — closed planner decisions;
- `MUST_NOT` — absolute prohibitions;
- `STOP_CONDITIONS` — conditions that require escalation instead of improvisation.

That separation matters more than whether the serialization format is Markdown, XML, YAML, or JSON: the worker needs explicit semantic roles and clear stop behavior.

## Result contract

`schemas/worker-result.schema.json` forces the worker to return one of:

- `SUCCESS`
- `BLOCKED`
- `FAILED`

A blocked result includes the observed repository state and the exact planner decision required. Codex then resolves the ambiguity and may issue a narrower rework contract.

## Permissions

Antigravity headless mode cannot stop for an interactive permission dialog. File operations inside the active workspace may be allowed by policy while commands that require approval can be soft-denied.

Prefer scoped Antigravity permission rules for the commands your projects actually need. Reserve `-Unsafe` for trusted workspaces where unrestricted approval is intentional.

## Validate

Static repository checks:

```powershell
python -m pip install pytest
python -m pytest -q
```

Optional live smoke test (this actually invokes `agy` in a temporary directory):

```powershell
.\tests\Test-Live.ps1
```

## Suggested workflow

Good delegation candidates:

- repetitive tests after behavior is understood;
- DTO/mapping boilerplate following existing patterns;
- known-scope mechanical refactors;
- responsive polish after UI rules are decided;
- straightforward lint/type fixes with known intended semantics.

Keep in Codex:

- architecture;
- ambiguous requirements;
- public API/schema design;
- unknown-root-cause debugging;
- cross-cutting design choices;
- security-sensitive decisions.

## Telemetry

Set an optional log directory to collect result/runtime metadata:

```powershell
[Environment]::SetEnvironmentVariable(
  "AGY_WORKER_LOG_DIR",
  "$HOME\.codex\agy-worker-logs",
  "User"
)
```

This makes it possible to evaluate which task classes Flash handles reliably and refine delegation rules over time.

## License

MIT
