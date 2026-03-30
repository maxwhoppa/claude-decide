# PRD-014: Operator Validation Script

## Objective

Create a bash validation script that checks the structural integrity of the operator's state files after a cycle completes. Since the operator can't invoke itself programmatically for a true E2E test, this script validates that state files are well-formed, internally consistent, and follow expected schemas — catching the class of bugs that would cause silent failures.

## User Problem

There's no way to verify the operator's state is healthy without manually reading JSON files. After 13+ cycles, schema drift, missing fields, or corrupted state could silently break future cycles. The operator has been its own E2E test (running against the claude-decide repo), but there's no automated check that confirms everything is structurally sound.

## Target User

Developers running the operator who want confidence that state files are valid before or after running cycles.

## Value

Structural validation catches the bugs that matter most: malformed JSON, missing required fields, invalid enum values, broken references between files. This is the practical E2E validation possible for a skill-based system.

## Scope (V1)

- Create `skills/decide/scripts/validate.sh` that checks all operator state files
- Validate JSON syntax for all files in `.claude-operator/`
- Validate state.json fields against expected enums and types
- Validate backlog.json item structure and status values
- Validate memory.json required fields
- Validate cycle logs have required fields
- Validate PRD files exist for referenced filenames
- Exit 0 on success, exit 1 on any failure with descriptive errors

## Out of Scope

- Running the operator (true E2E)
- Fixing found issues (validation only, not repair)
- CI/CD integration

## Requirements

1. `bash skills/decide/scripts/validate.sh` runs all checks and outputs results.
2. Exits with code 0 if all checks pass, code 1 if any fail.
3. Validates state.json: JSON syntax, phase enum, mode enum, status enum, cycle is positive integer.
4. Validates backlog.json: JSON syntax, each item has id/idea/status/priority_score, status is valid enum.
5. Validates memory.json: JSON syntax, has product/features/feature_history/past_decisions fields.
6. Validates each cycle log in logs/: JSON syntax, has cycle/timestamp/prd/execution_result fields.
7. Cross-references: if state.json has current_prd set, the file exists in prds/.
8. Outputs a summary: "Validation passed: N checks OK" or "Validation FAILED: [list of failures]".

## Technical Approach

Single bash script using `python3 -c` for JSON parsing (available on macOS/Linux). Each check is a function that outputs PASS/FAIL. No external dependencies beyond python3.

## Risks

- python3 availability — mitigated by being standard on macOS and most Linux.

## Open Questions

None.

## Experiment Plan

N/A.

## Backlog Reference

- Source: BL-006
- Research agents that flagged this: onboarding-detected
- Priority score: 0.70

## Outcome (Cycle 14)

- **Status**: completed
- **Requirements**: 8 of 8 passed
- **Approach deviations**: Also fixed 2 old cycle logs (002, 008) that used `prd_filename` instead of `prd` — schema drift from early cycles.
- **Lessons learned**: Validation script immediately found real issues (old schema fields). Validates the value of the tool.
