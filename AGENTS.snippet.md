## Prefer Antigravity for bounded implementation work

A global `agy-worker` skill is available.

For coding tasks, actively identify bounded subwork that can be delegated to `agy-worker`.

Prefer delegation to `agy-worker` by default when the subtask is:

- implementation-heavy or repetitive;
- low-ambiguity after repository inspection;
- based on architecture and behavior already decided by Codex;
- locally scoped with identifiable allowed files or directories;
- objectively verifiable through diff review, tests, lint, typecheck, build, or explicit acceptance criteria.

Typical work that should normally be delegated includes:

- boilerplate and repetitive CRUD implementation;
- DTOs, mappings, adapters, fixtures, and serializers following established project patterns;
- expansion of tests from an existing testing pattern;
- mechanical refactors with a known target shape;
- repetitive lint or type fixes with known intended semantics;
- responsive UI polish after layout and interaction rules are already decided;
- propagation of already-decided fields, interfaces, or behavior across multiple files;
- other routine implementation work where Codex's reasoning capability is not the bottleneck.

Do not keep suitable work in Codex merely because Codex is capable of implementing it directly. Preserve Codex capacity for planning, repository understanding, architectural decisions, ambiguity resolution, difficult debugging, review, and verification.

Codex must retain work involving:

- unresolved architecture or module boundaries;
- ambiguous product requirements or user intent;
- unknown-root-cause debugging;
- public API or schema design;
- dependency selection;
- cross-cutting design choices;
- security-sensitive decisions;
- tasks whose correct implementation cannot yet be stated or verified precisely.

Before delegation, inspect enough of the repository to close important decisions and identify the context the worker must inspect.

Compile each delegated subtask into the `agy-worker` Delegation IR / Task Contract. Clearly separate confirmed facts, assumptions, decisions, required context, allowed scope, constraints, required actions, implementation hints, acceptance criteria, and stop conditions.

Antigravity is a bounded implementation worker, not a peer planner. It may make local implementation choices within the contract but must return `BLOCKED` rather than invent architecture or silently expand scope.

After every delegated run, Codex must independently inspect runtime evidence and the actual repository diff, verify scope compliance, run or verify appropriate checks, and judge the implementation against the original user intent. Never accept the worker's self-report as proof of correctness.
