---
name: agy-worker
description: Delegate bounded, low-ambiguity implementation work from Codex to Google Antigravity CLI workers while Codex retains planning, architecture, and final verification.
---

# AGY Worker

Use Antigravity CLI (`agy`) as a subordinate implementation worker for repetitive, well-specified coding tasks.

## Authority model

Codex is the planner, architect, reviewer, and final authority.

Antigravity is an executor. It may make local implementation choices only inside the boundaries of a task contract. It must not silently take ownership of architecture, product requirements, public API design, or cross-cutting decisions.

## When to delegate

Delegate when the subtask is all or nearly all of the following:

- low ambiguity;
- locally scoped;
- repetitive or implementation-heavy;
- based on decisions Codex has already made;
- easy to verify with a diff, tests, lint, typecheck, or explicit acceptance criteria;
- unlikely to require discovering the root cause of an unknown failure.

Typical candidates:

- boilerplate and repetitive CRUD;
- filling out mappings, adapters, DTOs, fixtures, or test cases from an established pattern;
- mechanical refactors with a known target shape;
- lint/type fixes after Codex understands the intended semantics;
- responsive/UI cleanup after layout rules are decided;
- documentation or config updates with explicit source-of-truth requirements;
- implementation of an already-decided interface.

## When Codex must keep the work

Do not delegate unresolved work involving:

- architecture or module boundaries;
- ambiguous user intent;
- root-cause debugging when the cause is unknown;
- security-sensitive design;
- dependency selection;
- database/schema architecture;
- public API design;
- broad refactors whose direction is not already decided;
- contradictory requirements.

If a task is useful to delegate but still ambiguous, Codex must first inspect the repository and reduce it into a bounded execution unit.

## Delegation rubric

Before delegation, score the candidate subtask mentally on four properties:

1. **Specification completeness** — can the desired end state be stated precisely?
2. **Scope boundedness** — can allowed files/directories be named?
3. **Decision closure** — are architectural/product choices already settled?
4. **Verifiability** — can success be checked objectively?

Delegate only when all four are strong. Otherwise keep the task or split it further.

## Build the task contract

Use `templates/task-contract.md` as the canonical structure.

The contract must contain these semantic classes:

- `OBJECTIVE`: one precise outcome;
- `CONFIRMED_FACTS`: facts Codex verified from the repository;
- `ASSUMPTIONS`: claims the worker must verify before relying on them;
- `UNKNOWNS`: unresolved facts that are allowed to remain unresolved only if they do not block the task;
- `SCOPE`: files/directories the worker may change;
- `DECISIONS`: choices already made by Codex and not open for reconsideration;
- `CONSTRAINTS`: invariants that must remain true;
- `MUST_NOT`: prohibited actions;
- `IMPLEMENTATION_TASKS`: concrete execution steps or work items;
- `ACCEPTANCE_CRITERIA`: observable success conditions;
- `STOP_CONDITIONS`: conditions requiring `BLOCKED` instead of improvisation.

### Epistemic discipline

Never place an assumption in `CONFIRMED_FACTS`.

Do not send brainstorming, discarded options, or unresolved chain-of-thought to the worker. Send the decision result and only the rationale needed to prevent misinterpretation.

A statement such as “there may already be a shared store” belongs in `ASSUMPTIONS`, never `CONFIRMED_FACTS`.

## Mandatory stop behavior

At minimum, require `BLOCKED` when:

- a confirmed fact is false;
- a required file/API/module does not exist;
- implementation requires an architectural change not authorized by the contract;
- implementation requires modifying outside `SCOPE`;
- a public interface must change unexpectedly;
- requirements conflict;
- a new dependency appears necessary but is not explicitly authorized.

The worker must report the observed state and request a planner decision instead of inventing a replacement design.

## Invoke the worker

1. Write the final contract to a UTF-8 temporary Markdown file.
2. Run the wrapper from the target repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.codex/skills/agy-worker/scripts/invoke-agy.ps1" `
  -TaskFile "<absolute-or-relative-task-contract>" `
  -WorkingDirectory "<repository-root>"
```

The model must be pinned through either `-Model` or `AGY_WORKER_MODEL`. Prefer an explicit Flash model slug returned by `agy models`; do not guess a model slug.

The wrapper calls Antigravity in headless mode, enforces `schemas/worker-result.schema.json`, and returns a machine-readable envelope.

## Handle results

### SUCCESS

Codex must independently:

1. inspect the actual diff;
2. check that changed files stayed within scope;
3. run or verify relevant tests/checks when appropriate;
4. compare the implementation against the original user intent, not merely the worker report;
5. accept, fix locally, or send a narrower rework contract.

Never treat the worker's self-assessment as proof of correctness.

### BLOCKED

Read `blocker_type`, `observed_state`, and `requested_decision`.

Codex resolves the ambiguity or makes the missing decision, then issues a new contract. Do not tell the worker to “figure it out.”

### FAILED

Inspect the failure. Retry only if the failure is operational or if Codex can produce a materially clearer contract.

## Rework

A rework contract should reference the observed defect, preserve all still-valid decisions, and narrow scope further whenever possible. Do not resend a vague version of the original task.

## Permission policy

Do not use `-Unsafe` by default.

Prefer Antigravity's scoped permission allow-list for known commands and paths. Use `-Unsafe` only when the user has deliberately chosen unrestricted tool approval for a trusted local workspace.

## Final ownership

Codex owns the final answer and repository state. Antigravity is a worker, not a peer planner.
