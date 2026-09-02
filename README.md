# codex-agy-worker-skill

A Codex Skill for delegating bounded implementation work to Google Antigravity CLI (`agy`) workers while Codex keeps architecture, ambiguity resolution, verification, and final ownership.

The core model is a narrow delegation ABI, not free-form agent chat:

```text
User intent
   ↓
Codex (inspect / decide / reduce ambiguity)
   ↓
Delegation IR v2
   ↓
Antigravity / Flash (bounded execution)
   ↓
worker report + runtime evidence
   ↓
Codex (diff / tests / intent review)
```

## Why

Fast worker models are useful for boilerplate, repetitive refactors, tests, UI cleanup, mappings, adapters, and other implementation-heavy work. They become much less reliable when hidden architectural decisions or ambiguous assumptions remain.

This project therefore separates:

- **planning authority** from **execution capacity**;
- facts from assumptions and decisions;
- mandatory actions from implementation hints;
- worker claims from runtime-observed evidence.

## Delegation IR v2

`templates/task-contract.md` contains a machine-readable `AGY_META` JSON block plus model-readable Markdown.

The metadata carries:

- `contract_version`;
- stable `task_id`;
- `task_class` for telemetry and future routing;
- authoritative `scope.allow` / `scope.deny`;
- planner-selected verification commands;
- Git-baseline requirements.

The Markdown preserves semantic roles such as `CONFIRMED_FACTS`, `ASSUMPTIONS`, `DECISIONS`, `CONSTRAINTS`, `MUST_NOT`, `REQUIRED_ACTIONS`, `IMPLEMENTATION_HINTS`, `ACCEPTANCE_CRITERIA`, and `STOP_CONDITIONS`.

That separation is intentional: the worker should know what is true, what must be verified, what has already been decided, and exactly when it must stop instead of improvising.

## Runtime evidence

The wrapper does not trust the worker's `files_changed` field as the source of truth.

After execution it independently returns:

```text
runtime_evidence.git_head_before
runtime_evidence.git_head_after
runtime_evidence.actual_files_changed
runtime_evidence.scope_valid
runtime_evidence.out_of_scope_files
runtime_evidence.attribution_confidence
```

By default the Git working tree must be clean before delegation so post-run changes can be attributed reliably. `-AllowDirty` explicitly downgrades that confidence.

If scope validation fails, Codex should treat the run as a policy violation even if the worker reports `SUCCESS`.

## Good delegation candidates

- repetitive tests after behavior is understood;
- DTO/mapping/adapter boilerplate following an established pattern;
- known-scope mechanical refactors;
- responsive polish after UI/layout rules are decided;
- straightforward lint/type fixes with known intended semantics;
- implementation of an already-decided interface.

Keep architecture, ambiguous requirements, public API/schema design, dependency selection, unknown-root-cause debugging, cross-cutting design, and security-sensitive decisions in Codex.

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Codex with Agent Skills support
- Google Antigravity CLI available as `agy`
- authenticated Antigravity CLI session
- exact worker model slug from `agy models`
- Git repository for runtime evidence/scope validation

## Install

```powershell
.\scripts\install.ps1 -ConfigureGlobalAgents
```

Use `-Force` to replace an existing installation.

## Pin the worker model

```powershell
agy models
```

Then set the exact slug you want:

```powershell
[Environment]::SetEnvironmentVariable(
  "AGY_WORKER_MODEL",
  "<exact-slug-from-agy-models>",
  "User"
)
```

The wrapper intentionally fails when no model is pinned.

## Invoke

Codex writes a v2 task contract and calls:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File "$HOME/.codex/skills/agy-worker/scripts/invoke-agy.ps1" `
  -TaskFile "C:\path\to\task.md" `
  -WorkingDirectory "C:\path\to\repo"
```

Options:

```text
-Model <slug>          Override AGY_WORKER_MODEL
-Effort low|medium|high
-Timeout 20m
-LogDirectory <path>   Persist report/evidence/runtime telemetry
-AllowDirty            Allow a dirty Git baseline; attribution becomes low-confidence
-Unsafe                Pass --dangerously-skip-permissions
```

`-Unsafe` is deliberately opt-in. Prefer scoped Antigravity permissions.

## Result model

`schemas/worker-result.schema.json` constrains the worker report to:

- `SUCCESS`
- `BLOCKED`
- `FAILED`

A blocked result includes observed state and the planner decision required. Codex resolves the ambiguity and may issue a narrower rework contract.

The outer wrapper result separates:

```text
worker_result      # worker-authored claim/report
runtime_evidence   # wrapper-observed repository evidence
runtime            # provider/model/time/usage telemetry
```

## Evaluation and routing

`evals/` seeds a real delegation benchmark. Compare:

- **A — Codex alone**
- **B — Codex planner → AGY worker → Codex reviewer**

Track final correctness, first-pass success, rework count, scope violations, verification results, elapsed time, and token/cost data when available.

The four-part delegation rubric (specification completeness, scope boundedness, decision closure, verifiability) is only a bootstrap. The long-term goal is to learn which task classes are reliably delegable from actual telemetry instead of relying forever on intuition.

## Validate

```powershell
python -m pip install pytest
python -m pytest -q
```

Optional live smoke test:

```powershell
.\tests\Test-Live.ps1
```

## License

MIT
