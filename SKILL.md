---
name: agy-worker
description: Prefer this skill for bounded, low-ambiguity, repetitive or implementation-heavy coding work that can be delegated to Google Antigravity CLI workers while Codex retains planning, architecture, runtime verification, and final ownership.
---

# AGY Worker

Use Antigravity CLI (`agy`) as a subordinate implementation worker for repetitive, well-specified coding tasks.

The architectural model is not peer-to-peer agent chat. Treat delegation as a narrow ABI:

`user intent -> Codex decision/ambiguity reduction -> Delegation IR -> AGY execution -> worker report + runtime evidence -> Codex verification`

## Authority model

Codex is planner, architect, reviewer, and final authority.

Antigravity is an executor. It may make local implementation choices only inside the contract. It must not silently take ownership of architecture, product requirements, public API design, dependency selection, or cross-cutting decisions.

## When to delegate

Prefer delegation when the subtask is all or nearly all of the following:

- low ambiguity;
- locally scoped;
- repetitive or implementation-heavy;
- based on decisions Codex has already made;
- objectively verifiable;
- unlikely to require discovering the root cause of an unknown failure.

Good candidates include boilerplate, mappings/adapters/DTOs, repetitive tests, mechanical refactors, known-semantics lint/type fixes, responsive polish after layout decisions are closed, and implementation of an already-decided interface.

Do not keep suitable bounded work in Codex merely because Codex can implement it directly. Preserve Codex capacity for repository understanding, planning, architecture, ambiguity resolution, difficult debugging, review, and verification.

Keep unresolved architecture, ambiguous intent, unknown-root-cause debugging, security-sensitive design, dependency selection, database/schema architecture, public API design, broad directional refactors, and contradictory requirements in Codex.

## Delegation rubric

Before delegation, judge:

1. specification completeness;
2. scope boundedness;
3. decision closure;
4. verifiability.

When all four are strong, delegation should be the default rather than merely an option. When one or more are weak, keep the work in Codex or reduce it into a smaller bounded subtask first. This rubric is a bootstrap heuristic; use telemetry/evals over time to replace intuition with task-class reliability data.

## Delegation IR v2

Use `templates/task-contract.md`. It contains two layers:

1. **`AGY_META` JSON** — machine-readable metadata consumed by the wrapper;
2. **semantic Markdown** — model-readable objective, epistemic state, decisions, constraints, actions, hints, acceptance criteria, and stop conditions.

`AGY_META` must define:

- `contract_version: "2"`;
- stable `task_id`;
- `task_class` for telemetry/routing;
- authoritative `scope.allow` and optional `scope.deny`;
- planner-selected verification commands;
- whether a clean Git baseline is required.

Keep epistemic roles distinct:

- `CONFIRMED_FACTS` — verified facts;
- `ASSUMPTIONS` — worker must verify before relying on them;
- `UNKNOWNS` — non-blocking unknowns;
- `DECISIONS` — closed planner decisions;
- `CONSTRAINTS` — invariants;
- `MUST_NOT` — absolute prohibitions;
- `STOP_CONDITIONS` — conditions requiring escalation.

Never place an assumption in `CONFIRMED_FACTS`. Send decision results, not brainstorming or discarded alternatives.

## Actions vs hints

`REQUIRED_ACTIONS` are mandatory work/outcomes.

`IMPLEMENTATION_HINTS` are deliberately softer. They may guide the worker toward an existing pattern without turning the planner into a line-by-line macro recorder. The worker may choose an equivalent local implementation only if it remains inside scope and preserves decisions, constraints, and acceptance criteria.

## Mandatory stop behavior

Require `BLOCKED` when a confirmed fact is false, a required artifact is missing, work needs an unauthorized architectural/public-interface/dependency decision, implementation requires an out-of-scope file, or requirements conflict.

The worker reports the observed state and exact planner decision required instead of improvising replacement architecture.

## Invoke the worker

Write the contract to a UTF-8 file, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.codex/skills/agy-worker/scripts/invoke-agy.ps1" `
  -TaskFile "<task-contract>" `
  -WorkingDirectory "<repository-root>"
```

Pin the worker model via `-Model` or `AGY_WORKER_MODEL` using an exact slug returned by `agy models`.

By default the wrapper requires a clean Git working tree so it can attribute post-run changes to the worker. `-AllowDirty` is explicit opt-in and downgrades attribution confidence. `-Unsafe` remains explicit opt-in for unrestricted Antigravity permissions.

## Evidence model

Never treat the worker's self-assessment as proof.

The wrapper returns two separate layers:

- `worker_result` — worker-authored structured report;
- `runtime_evidence` — wrapper-observed repository state.

Runtime evidence includes Git head before/after, actual changed paths, allowed/denied scope, scope validity, out-of-scope files, dirty baseline, and attribution confidence.

If `runtime_evidence.scope_valid` is false, treat the delegation as a policy violation even if the worker reports `SUCCESS`.

## Handle results

### SUCCESS

Codex independently inspects the actual diff, scope evidence, relevant checks, and the original user intent. Accept, fix locally, or issue a narrower rework contract.

### BLOCKED

Read `blocker_type`, `observed_state`, and `requested_decision`. Resolve the missing decision and issue a new contract. Do not tell the worker to figure out architectural ambiguity.

### FAILED

Retry only for operational failures or when Codex can materially improve/narrow the contract.

## Rework

Preserve still-valid decisions, reference the observed defect/evidence, narrow scope when possible, and use a new attempt while retaining the same logical task identity when useful for telemetry.

## Evaluation

Use `evals/` to compare at least:

- Codex alone;
- Codex planner -> AGY worker -> Codex reviewer.

Track final correctness, first-pass success, rework count, scope violations, verification results, elapsed time, and token/cost data when available. The long-term goal is an empirical routing policy by task class, not an ever-growing static prompt rubric.

## Final ownership

Codex owns the final answer and repository state. Antigravity is a bounded worker, not a peer planner.
