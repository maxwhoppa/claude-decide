# Operator Validation Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a bash validation script that checks structural integrity of all `.claude-operator/` state files.

**Architecture:** Single bash script with python3 -c for JSON parsing. Five check functions (state, backlog, memory, logs, crossrefs) each print PASS/FAIL lines. A counter tallies results and the script exits 0 (all pass) or 1 (any fail).

**Tech Stack:** Bash, Python 3 (stdlib only — json, sys modules)

---

### Task 1: Create validate.sh

**Files:**
- Create: `skills/decide/scripts/validate.sh`

- [ ] **Step 1: Write the complete script**

Create `skills/decide/scripts/validate.sh` with this content:

```bash
#!/bin/bash
# Claude Operator State Validator
# Checks structural integrity of .claude-operator/ state files.
#
# Usage: bash skills/decide/scripts/validate.sh
#
# Exit codes: 0 = all checks pass, 1 = one or more failures

set -euo pipefail

OPERATOR_DIR=".claude-operator"
PASSES=0
FAILURES=0

pass() {
  echo "  PASS: $1"
  PASSES=$((PASSES + 1))
}

fail() {
  echo "  FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

# --- Check: .claude-operator/ exists ---
echo "=== Operator Directory ==="
if [ ! -d "$OPERATOR_DIR" ]; then
  fail ".claude-operator/ directory does not exist"
  echo ""
  echo "Validation FAILED: 0 passed, 1 failed"
  exit 1
fi
pass ".claude-operator/ directory exists"

# --- Check: state.json ---
echo ""
echo "=== state.json ==="
STATE_FILE="$OPERATOR_DIR/state.json"
if [ ! -f "$STATE_FILE" ]; then
  fail "state.json does not exist"
else
  # Valid JSON
  if python3 -c "import json; json.load(open('$STATE_FILE'))" 2>/dev/null; then
    pass "state.json is valid JSON"
  else
    fail "state.json is not valid JSON"
  fi

  # status enum
  STATUS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('status',''))" 2>/dev/null || echo "")
  if [[ "$STATUS" == "running" || "$STATUS" == "paused" ]]; then
    pass "status is valid: $STATUS"
  else
    fail "status is invalid: '$STATUS' (expected: running|paused)"
  fi

  # phase enum
  PHASE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('phase',''))" 2>/dev/null || echo "")
  VALID_PHASES="research propose collaborate execute update_memory"
  if echo "$VALID_PHASES" | grep -qw "$PHASE"; then
    pass "phase is valid: $PHASE"
  else
    fail "phase is invalid: '$PHASE' (expected: research|propose|collaborate|execute|update_memory)"
  fi

  # mode enum
  MODE=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('mode',''))" 2>/dev/null || echo "")
  if [[ "$MODE" == "default" || "$MODE" == "force" || "$MODE" == "auto" ]]; then
    pass "mode is valid: $MODE"
  else
    fail "mode is invalid: '$MODE' (expected: default|force|auto)"
  fi

  # cycle is positive integer
  CYCLE=$(python3 -c "import json; c=json.load(open('$STATE_FILE')).get('cycle',0); print(c if isinstance(c,int) and c>0 else 'INVALID')" 2>/dev/null || echo "INVALID")
  if [[ "$CYCLE" != "INVALID" ]]; then
    pass "cycle is valid positive integer: $CYCLE"
  else
    fail "cycle is not a valid positive integer"
  fi
fi

# --- Check: backlog.json ---
echo ""
echo "=== backlog.json ==="
BACKLOG_FILE="$OPERATOR_DIR/backlog.json"
if [ ! -f "$BACKLOG_FILE" ]; then
  fail "backlog.json does not exist"
else
  if python3 -c "import json; json.load(open('$BACKLOG_FILE'))" 2>/dev/null; then
    pass "backlog.json is valid JSON"
  else
    fail "backlog.json is not valid JSON"
  fi

  # Check items structure
  ITEM_ERRORS=$(python3 -c "
import json, sys
data = json.load(open('$BACKLOG_FILE'))
items = data.get('items', [])
errors = []
valid_statuses = {'queued', 'proposed', 'completed', 'rejected'}
for i, item in enumerate(items):
    missing = [f for f in ['id','idea','status','priority_score'] if f not in item]
    if missing:
        errors.append(f'Item {i}: missing fields: {missing}')
    if item.get('status') not in valid_statuses:
        errors.append(f'Item {i} ({item.get(\"id\",\"?\")}): invalid status \"{item.get(\"status\")}\"')
    score = item.get('priority_score', -1)
    if not isinstance(score, (int, float)) or score < 0 or score > 1:
        errors.append(f'Item {i} ({item.get(\"id\",\"?\")}): priority_score {score} not in 0.0-1.0')
print('\n'.join(errors) if errors else 'OK')
" 2>/dev/null || echo "PARSE_ERROR")

  if [[ "$ITEM_ERRORS" == "OK" ]]; then
    ITEM_COUNT=$(python3 -c "import json; print(len(json.load(open('$BACKLOG_FILE')).get('items',[])))" 2>/dev/null || echo "0")
    pass "all $ITEM_COUNT backlog items have valid structure"
  elif [[ "$ITEM_ERRORS" == "PARSE_ERROR" ]]; then
    fail "could not parse backlog items"
  else
    echo "$ITEM_ERRORS" | while read -r line; do
      fail "backlog: $line"
    done
  fi
fi

# --- Check: memory.json ---
echo ""
echo "=== memory.json ==="
MEMORY_FILE="$OPERATOR_DIR/memory.json"
if [ ! -f "$MEMORY_FILE" ]; then
  fail "memory.json does not exist"
else
  if python3 -c "import json; json.load(open('$MEMORY_FILE'))" 2>/dev/null; then
    pass "memory.json is valid JSON"
  else
    fail "memory.json is not valid JSON"
  fi

  # Required top-level keys
  MISSING_KEYS=$(python3 -c "
import json
data = json.load(open('$MEMORY_FILE'))
required = ['product', 'features', 'feature_history', 'past_decisions']
missing = [k for k in required if k not in data]
print(','.join(missing) if missing else 'OK')
" 2>/dev/null || echo "PARSE_ERROR")

  if [[ "$MISSING_KEYS" == "OK" ]]; then
    pass "memory.json has all required top-level keys"
  elif [[ "$MISSING_KEYS" == "PARSE_ERROR" ]]; then
    fail "could not parse memory.json keys"
  else
    fail "memory.json missing keys: $MISSING_KEYS"
  fi
fi

# --- Check: cycle logs ---
echo ""
echo "=== Cycle Logs ==="
LOGS_DIR="$OPERATOR_DIR/logs"
if [ ! -d "$LOGS_DIR" ]; then
  pass "logs/ directory does not exist (OK if no cycles completed yet)"
else
  LOG_COUNT=0
  LOG_ERRORS=0
  for logfile in "$LOGS_DIR"/cycle-*.json; do
    [ -f "$logfile" ] || continue
    LOG_COUNT=$((LOG_COUNT + 1))
    BASENAME=$(basename "$logfile")

    if ! python3 -c "import json; json.load(open('$logfile'))" 2>/dev/null; then
      fail "$BASENAME is not valid JSON"
      LOG_ERRORS=$((LOG_ERRORS + 1))
      continue
    fi

    MISSING=$(python3 -c "
import json
data = json.load(open('$logfile'))
required = ['cycle', 'timestamp', 'prd', 'execution_result']
missing = [k for k in required if k not in data]
print(','.join(missing) if missing else 'OK')
" 2>/dev/null || echo "PARSE_ERROR")

    if [[ "$MISSING" == "OK" ]]; then
      : # counted as pass below
    elif [[ "$MISSING" == "PARSE_ERROR" ]]; then
      fail "$BASENAME: could not check fields"
      LOG_ERRORS=$((LOG_ERRORS + 1))
    else
      fail "$BASENAME missing fields: $MISSING"
      LOG_ERRORS=$((LOG_ERRORS + 1))
    fi
  done

  if [[ "$LOG_COUNT" -eq 0 ]]; then
    pass "no cycle logs found (OK if no cycles completed yet)"
  elif [[ "$LOG_ERRORS" -eq 0 ]]; then
    pass "all $LOG_COUNT cycle logs are valid"
  fi
fi

# --- Check: cross-references ---
echo ""
echo "=== Cross-References ==="
if [ -f "$STATE_FILE" ]; then
  CURRENT_PRD=$(python3 -c "import json; v=json.load(open('$STATE_FILE')).get('current_prd'); print(v if v else '')" 2>/dev/null || echo "")
  if [[ -z "$CURRENT_PRD" ]]; then
    pass "current_prd is null (no active PRD)"
  elif [ -f "$OPERATOR_DIR/prds/$CURRENT_PRD" ]; then
    pass "current_prd '$CURRENT_PRD' exists in prds/"
  else
    fail "current_prd '$CURRENT_PRD' does not exist in prds/"
  fi
fi

# --- Summary ---
echo ""
echo "==============================="
TOTAL=$((PASSES + FAILURES))
if [[ "$FAILURES" -eq 0 ]]; then
  echo "Validation passed: $PASSES checks OK"
  exit 0
else
  echo "Validation FAILED: $PASSES passed, $FAILURES failed"
  exit 1
fi
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x skills/decide/scripts/validate.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n skills/decide/scripts/validate.sh
```

Expected: no output (syntax OK).

- [ ] **Step 4: Run it against current state**

```bash
bash skills/decide/scripts/validate.sh
```

Expected: all checks pass (state files have been maintained for 13 cycles), exit code 0.

- [ ] **Step 5: Commit**

```bash
git add skills/decide/scripts/validate.sh
git commit -m "feat: add operator state validation script (PRD-014)"
```
