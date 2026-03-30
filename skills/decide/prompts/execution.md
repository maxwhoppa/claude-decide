# Execution Constraints

These constraints apply during the Execute Phase, on top of the superpowers executing-plans skill.

## Commit Format

```
Cycle {{cycle}} -- [short description] (PRD-{{prd_number}})
```

Example: `Cycle 3 -- add progress indicators (PRD-003)`

## Validation (after implementation, before committing)

**Requirement-by-requirement verification:**
Go through EACH numbered requirement in the PRD's "Requirements" section. For every requirement:
1. Describe how you will verify it
2. Actually run the verification (execute a command, read the output, check the behavior)
3. Record PASS or FAIL with evidence (command output, file contents, etc.)

If ANY requirement fails, fix it and re-verify ALL requirements.

**Mechanical checks (run all that apply):**
- Shell scripts: `bash -n <file>` for syntax, `shellcheck <file>` if available
- JavaScript/TypeScript: `npm test`, `npx tsc --noEmit`
- Python: `python -m pytest`, `python -m py_compile <file>`
- Any language: run the project's existing test suite
- Run any new tests you added

**Existing test suite (MANDATORY):**
1. Discover test infrastructure: `package.json` scripts, `pytest.ini`, `Makefile` test targets, `*.test.*` files, `tests/` directories
2. If tests exist, run them ALL — not just the ones related to your changes.
3. If any test fails, fix it. Do NOT skip or ignore failing tests.
4. Re-run the full suite after fixes to confirm everything passes.

If the project has no tests, note "No existing test suite found" in validation notes.

Fix anything broken and re-test. Do not commit until ALL requirements pass and ALL tests pass.

## Stuck Report

If you cannot resolve an issue after 10 attempts, write `.claude-operator/stuck.json`:

```json
{
  "cycle": {{cycle}},
  "prd": "{{prd_filename}}",
  "attempts": 10,
  "last_error": "<the error message>",
  "what_was_tried": ["attempt 1 description", "..."],
  "files_changed_so_far": ["file1.ts", "..."],
  "committed": false
}
```

Then stop. Do NOT continue trying.

## Scope

- Do NOT add features, refactoring, or improvements beyond what the PRD specifies
- Keep changes minimal and focused on the PRD scope
- Follow existing code patterns and conventions
