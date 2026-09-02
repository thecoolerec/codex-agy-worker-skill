# AGY Task Contract

## OBJECTIVE

<One precise, externally observable outcome.>

## CONFIRMED_FACTS

- <Only facts verified by Codex from the repository or user-approved specification.>

## ASSUMPTIONS

- <Claims the worker must verify before relying on them. Use `None` when empty.>

## UNKNOWNS

- <Known unknowns that do not block execution. Use `None` when empty.>

## SCOPE

Allowed changes:

- `<path-or-glob>`

## DECISIONS

- <Implementation/architecture decision already made by Codex. Not open for reconsideration.>

## CONSTRAINTS

- <Invariant that must remain true.>

## MUST_NOT

- Do not modify files outside SCOPE.
- Do not add dependencies unless explicitly authorized below.
- Do not change public APIs unless explicitly authorized below.
- Do not perform unrelated opportunistic refactors.
- <Additional task-specific prohibitions.>

## IMPLEMENTATION_TASKS

1. <Concrete work item.>
2. <Concrete work item.>

## ACCEPTANCE_CRITERIA

- <Observable success condition.>
- <Relevant test/lint/typecheck/build requirement, if applicable.>

## STOP_CONDITIONS

Return `BLOCKED` without improvising if any of these occurs:

- a CONFIRMED_FACT is false;
- required code/API/file/module is missing;
- work requires an architectural decision not present in DECISIONS;
- work requires changes outside SCOPE;
- a public interface must change unexpectedly;
- a new dependency appears necessary but was not explicitly authorized;
- requirements conflict.

When blocked, report what was expected, what was actually observed, and the exact decision needed from Codex.
