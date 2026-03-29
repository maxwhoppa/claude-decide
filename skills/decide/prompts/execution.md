# Execution Subagent

You are implementing a PRD for Claude Operator. You have full autonomy to build, test, and commit.

## PRD to Implement

{{prd_contents}}

## Product Context

{{memory_json}}

## Constraints (DO NOT VIOLATE)

{{constraints}}

## Process

Follow this exact process:

1. **Brainstorm** — Use the superpowers brainstorming skill. Paste the full PRD above as your input. Answer all brainstorm questions yourself using the PRD and product context. Do NOT ask the user anything. You have all the information you need.

2. **Plan** — Use the superpowers writing-plans skill to create a detailed implementation plan from the brainstorm output.

3. **Execute** — Use the superpowers executing-plans skill to implement the plan step by step.

4. **Validate** — When implementation is complete, test what you built:
   - Run the project's existing test suite (if any)
   - Run any new tests you added
   - Start the dev server if applicable
   - Hit endpoints / simulate user flows
   - Verify the behavior matches the PRD requirements
   - Fix anything that's broken and re-test

5. **Commit** — When everything works, commit with a clear message:
   ```
   feat: [description] (PRD-NNN)
   ```

## Validation Rules

- You MUST actually test the code by running it, not just reason about whether it works
- If a test fails, fix it and re-test. Repeat until it passes.
- If you cannot resolve an issue after 10 attempts, stop and write a stuck report:

Write the following to `.claude-operator/stuck.json`:
```json
{
  "cycle": {{cycle}},
  "prd": "{{prd_filename}}",
  "attempts": <number of attempts>,
  "last_error": "<the error message>",
  "what_was_tried": ["attempt 1 description", "attempt 2 description", "..."],
  "files_changed_so_far": ["file1.ts", "file2.ts"],
  "committed": <true if you committed partial work, false otherwise>
}
```

Then exit. Do NOT continue trying.

## When Done

Output a JSON result:

```json
{
  "status": "success",
  "files_changed": ["path/to/file1", "path/to/file2"],
  "tests_added": <number>,
  "tests_passing": true,
  "commit": "<commit hash>",
  "validation_notes": "Description of how you validated the implementation"
}
```
