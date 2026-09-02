# AGY Task Contract

<!-- AGY_META
{
  "contract_version": "2",
  "task_id": "<stable-task-id>",
  "task_class": "<e.g. dto-mapping|tests|mechanical-refactor|ui-polish|lint-fix>",
  "scope": {
    "allow": ["<repo-relative-path-or-glob>"],
    "deny": []
  },
  "verification": {
    "commands": ["<objective check command>"],
    "require_clean_git": true
  }
}
AGY_META -->

## OBJECTIVE

<One precise, externally observable outcome.>

## CONFIRMED_FACTS

- <Only facts verified by Codex from the repository or user-approved specification.>

## ASSUMPTIONS

- <Claims the worker must verify before relying on them. Use `None` when empty.>

## UNKNOWNS

- <Known unknowns that do not block execution. Use `None` when empty.>

## SCOPE

Allowed changes are defined authoritatively by `AGY_META.scope.allow` above.

Human-readable scope summary:

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

## REQUIRED_ACTIONS

1. <Outcome-relevant action that is mandatory.>
2. <Outcome-relevant action that is mandatory.>

## IMPLEMENTATION_HINTS

- <Optional preferred implementation path. The worker may choose an equivalent local implementation only if it preserves DECISIONS, CONSTRAINTS, SCOPE, and acceptance criteria.>

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
