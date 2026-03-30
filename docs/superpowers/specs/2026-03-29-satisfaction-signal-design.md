# Design: Post-Execution Satisfaction Signal (PRD-010)

## Summary

Add a 1-5 satisfaction rating prompt at the end of the Update Memory phase for default/auto modes. Store ratings in cycle logs and memory.json. Force mode and decide-loop skip the prompt automatically.

## Architecture

Two existing files modified:

1. **`skills/decide/SKILL.md`** — Update Memory Phase: add Step 5b (satisfaction prompt)
2. **`skills/decide/prompts/state-templates.md`** — Schema docs: add satisfaction to cycle log, add satisfaction_history to memory.json

## Detailed Changes

### SKILL.md — Update Memory Phase Step 5b

After Step 5 (Commit All Changes), before Step 6 (Reset and Exit):

```markdown
### Step 5b: Satisfaction Signal

If mode is "default" or "auto":
- Output: "Rate this cycle's output (1-5, or skip): "
- Wait for user input.
- Accept: integer 1-5, "skip", or empty input (treated as skip).
- If invalid input, re-prompt once: "Please enter 1-5 or skip: ". If still invalid, treat as skip.
- If rating provided, optionally ask: "Any comment? (Enter to skip): "
- Store in the cycle log: `"satisfaction": { "rating": N, "comment": "..." }`
- Append to `memory.json` `satisfaction_history`: `{ "cycle": N, "rating": N, "prd": "filename" }`

If mode is "force" (or running in decide-loop):
- Do NOT prompt. Automatically store: `"satisfaction": { "rating": null, "comment": "force mode — skipped" }`
- Append to `memory.json` `satisfaction_history`: `{ "cycle": N, "rating": null, "prd": "filename" }`
```

### state-templates.md — Cycle Log Schema

Add to the cycle log JSON template:
```json
"satisfaction": {
  "rating": null,
  "comment": null
}
```

### state-templates.md — memory.json Schema

Add `satisfaction_history` to the memory.json template:
```json
"satisfaction_history": []
```

With field documentation:
```
- `satisfaction_history`: array of `{ "cycle": int, "rating": int|null, "prd": string }` — tracks user satisfaction ratings per cycle
```

## Scope Boundaries

- No scoring modifications based on ratings (future V2)
- No retroactive rating
- No force mode prompting
- No per-requirement ratings
