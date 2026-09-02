# AGY Task Contract

## OBJECTIVE

Add deterministic unit tests for the existing `normalizeSku` function covering whitespace and ASCII case normalization without changing production behavior.

## CONFIRMED_FACTS

- `src/catalog/normalizeSku.ts` exports `normalizeSku`.
- Existing tests use Vitest.
- The current behavior trims leading/trailing ASCII whitespace and lowercases ASCII letters.

## ASSUMPTIONS

- None.

## UNKNOWNS

- None.

## SCOPE

Allowed changes:

- `src/catalog/normalizeSku.test.ts`

## DECISIONS

- Production implementation must not change.
- Tests must follow the repository's existing Vitest style.

## CONSTRAINTS

- Preserve all current production behavior.
- Keep test cases deterministic and independent.

## MUST_NOT

- Do not modify `src/catalog/normalizeSku.ts`.
- Do not add dependencies.
- Do not modify files outside SCOPE.
- Do not perform unrelated refactors.

## IMPLEMENTATION_TASKS

1. Add cases for leading/trailing whitespace.
2. Add cases for mixed ASCII case.
3. Add a combined whitespace + case case.

## ACCEPTANCE_CRITERIA

- The new test file exists.
- Relevant Vitest tests pass.
- No production file is changed.

## STOP_CONDITIONS

Return `BLOCKED` if the confirmed export/test framework facts are false or if satisfying the task requires changing production code.
