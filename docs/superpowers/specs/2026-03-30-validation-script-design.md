# Design: Operator Validation Script (PRD-014)

## Summary

Single bash script (`skills/decide/scripts/validate.sh`) that validates structural integrity of all `.claude-operator/` state files. Uses python3 for JSON parsing. Exits 0/1.

## Checks

1. **state.json**: valid JSON, `status` in {running,paused}, `phase` in {research,propose,collaborate,execute,update_memory}, `mode` in {default,force,auto}, `cycle` is positive int
2. **backlog.json**: valid JSON, each item has id/idea/status/priority_score, status in {queued,proposed,completed,rejected}, priority_score is 0.0-1.0
3. **memory.json**: valid JSON, has product/features/feature_history/past_decisions top-level keys
4. **Cycle logs**: each file in logs/ is valid JSON with cycle/timestamp/prd/execution_result fields
5. **Cross-refs**: if state.json current_prd is set, file exists in prds/

## Architecture

```bash
#!/bin/bash
FAILURES=0
PASSES=0

check() { # helper: increment counters, print result }
check_state() { ... }
check_backlog() { ... }
check_memory() { ... }
check_logs() { ... }
check_crossrefs() { ... }

# Run all checks
# Print summary
# Exit with appropriate code
```
