# Design: Confidence-Gated Auto-Approval (PRD-009)

## Summary

Add an "auto" mode to Claude Operator that auto-approves PRDs when their backlog priority score meets a user-defined threshold, while routing lower-scored PRDs to the interactive collaborate phase. This creates a middle ground between force mode (approve everything) and default mode (approve nothing).

## Architecture

No new files. Four existing files modified:

1. **`skills/decide/SKILL.md`** — Phase Router Step 0 (arg parsing) + Propose Phase Step 3-4 (transition logic)
2. **`skills/decide/prompts/state-templates.md`** — Schema documentation for state.json
3. **`skills/decide/scripts/launcher.sh`** — `--auto` flag parsing
4. **`.claude-operator/state.json`** — Runtime state (written by operator at runtime)

## Detailed Changes

### state.json Schema

```json
{
  "mode": "default" | "force" | "auto",
  "auto_threshold": 0.75
}
```

- `auto_threshold` is optional. Only meaningful when mode is "auto". Default: 0.75.
- Existing fields unchanged. No migration needed — old state files without `auto_threshold` work fine (defaults applied at read time).

### Phase Router Step 0 (SKILL.md)

Current:
```
Check if args contain "force" → set mode to "force"
```

New:
```
Check if args contain "force" → set mode to "force"
Check if args contain "auto" → set mode to "auto". If next arg is a float (0.0-1.0), set auto_threshold to that value. Otherwise default 0.75.
```

### Propose Phase Step 3 (SKILL.md)

Current: "If mode is 'force', resolve open questions..."

New: "If mode is 'force' or 'auto' (and score >= threshold), resolve open questions..."

The condition check happens in Step 4 first to determine routing, then Step 3's resolution applies to auto-approved PRDs.

Actually, simpler: resolve open questions whenever mode is "force" OR mode is "auto". For auto mode below-threshold PRDs, the user will see and potentially modify the questions during collaboration anyway, so resolving them speculatively is harmless.

### Propose Phase Step 4 (SKILL.md)

Current (2 branches):
```
If mode is "force": → execute
If mode is "default": → collaborate
```

New (3 branches):
```
If mode is "force": → execute
If mode is "auto":
  Read the candidate backlog item's priority_score and state.json's auto_threshold (default 0.75).
  If priority_score >= auto_threshold:
    Output: "Auto-approved (priority [score] >= threshold [threshold]). Skipping collaboration."
    → execute
  Else:
    Output: "Priority [score] < threshold [threshold]. Routing to collaboration."
    → collaborate
If mode is "default": → collaborate
```

### launcher.sh

Add `--auto` and `--auto=N` argument parsing:

```bash
--auto)
  AUTO_MODE=true
  shift
  ;;
--auto=*)
  AUTO_MODE=true
  AUTO_THRESHOLD="${1#--auto=}"
  # Validate threshold is a float between 0 and 1
  shift
  ;;
```

Update the prompt template to include auto mode instructions when `AUTO_MODE=true`. Update usage text.

## Error Handling

- Invalid threshold (non-numeric, outside 0-1 range): launcher.sh rejects with error message. SKILL.md treats missing/invalid threshold as default 0.75.
- Missing `auto_threshold` in state.json when mode is "auto": default to 0.75.

## Testing

Verification is manual — these are markdown instruction files, not executable code. Requirements verified by reading the modified files and confirming the logic paths exist.

## Scope Boundaries

- No dynamic threshold adjustment
- No per-category thresholds
- No onboarding changes
- No UI for mid-session threshold changes
