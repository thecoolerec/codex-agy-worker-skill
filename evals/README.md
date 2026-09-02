# Delegation evals

The skill should be evaluated as a routing/orchestration system, not only as a prompt template.

For each real task, compare at least:

- **A — Codex alone**
- **B — Codex planner → AGY worker → Codex reviewer**

Record objective outcomes rather than worker self-assessment.

## Minimum metrics

- task class;
- scope size;
- worker model and effort;
- final correctness;
- first-pass success;
- rework count;
- out-of-scope violation count;
- verification pass/fail;
- elapsed time;
- strong-model cost/tokens when available;
- worker cost/tokens when available.

## Suggested first task classes

1. DTO/mapping boilerplate
2. repetitive unit-test expansion
3. mechanical rename/refactor
4. responsive UI polish after layout decisions are closed
5. lint/type fixes with known semantics
6. known-pattern CRUD/adapters
7. documentation/config updates with explicit source of truth

Do not start the benchmark with architecture, dependency selection, schema design, or unknown-root-cause debugging; those are intentionally non-delegation classes.

`cases.jsonl` is a seed manifest. Add real repository-backed cases over time and use telemetry to turn the static delegation rubric into an empirical routing policy.
