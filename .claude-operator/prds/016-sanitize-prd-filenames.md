# PRD-016: Sanitize PRD Filenames

## Objective

Add explicit filename sanitization in the Propose Phase to prevent path traversal when constructing PRD filenames. Currently, the feature name portion of NNN-feature-name.md is not sanitized before being used as a filesystem path, which could allow a crafted research finding to write files outside .claude-operator/prds/.

## User Problem

When the Propose Phase generates a PRD filename from NNN-feature-name.md, the feature name comes from research agent output or backlog item text. A compromised or malformed backlog item containing path separators could cause the PRD to be written outside the intended directory. While State Validation (Step 3b) catches invalid current_prd values after they are set, it does not prevent the file from being written to a bad path first.

## Target User

Operators running claude-decide against untrusted codebases or with user-contributed backlog items.

## Value

Security hardening flagged high severity by the security research agent. Small fix that closes a real path traversal vector. Aligns with the defense-in-depth pattern (Step 3b covers the read side; this covers the write side).

## Scope (V1)

- Add a filename sanitization step in the Propose Phase (Step 1) of SKILL.md
- Sanitization rules: strip path separators, whitespace to hyphens, lowercase, remove non-alphanumeric, truncate to 50 chars
- Add matching documentation in state-templates.md

## Out of Scope

- Sanitizing backlog item IDs or other state file fields
- Adding automated tests for sanitization
- Changing existing PRD filenames retroactively

## Requirements

1. SKILL.md Propose Phase Step 1 must include an explicit filename sanitization step before writing the PRD file
2. The sanitization must: (a) strip / and \\ characters, (b) replace spaces and underscores with hyphens, (c) lowercase the string, (d) remove any characters not matching [a-z0-9-], (e) collapse consecutive hyphens, (f) trim leading/trailing hyphens, (g) truncate to 50 characters
3. The final filename must match the pattern NNN-[a-z0-9-]+.md where NNN is zero-padded to 3 digits
4. state-templates.md must document the allowed filename pattern for current_prd
5. No existing PRD files are renamed or modified

## Technical Approach

Edit two files:

1. skills/decide/SKILL.md - Insert sanitization substep in Propose Phase Step 1
2. skills/decide/prompts/state-templates.md - Document allowed filename pattern

## Risks

- Extremely low risk. Existing filenames already follow this pattern by convention.
- Name collisions mitigated by unique NNN prefix.

## Open Questions

None.

## Experiment Plan

N/A - security hardening measure.

## Backlog Reference

- Source: BL-036
- Research agents: research-security
- Priority score: 0.65


## Outcome (Cycle 16)

- **Status**: completed
- **Requirements**: 5 of 5 passed
- **Approach deviations**: None
- **Lessons learned**: None
