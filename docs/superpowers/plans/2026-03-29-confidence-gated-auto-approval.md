# Confidence-Gated Auto-Approval Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an "auto" mode that auto-approves PRDs above a user-defined priority threshold while routing lower-scored ones to collaboration.

**Architecture:** Three existing files modified — state-templates.md (schema docs), SKILL.md (phase router + propose logic), launcher.sh (CLI flag). No new files. All changes are additive alongside existing force/default patterns.

**Tech Stack:** Markdown (instruction files), Bash (launcher script)

---

### Task 1: Update state-templates.md Schema Documentation

**Files:**
- Modify: `skills/decide/prompts/state-templates.md:20-26`

- [ ] **Step 1: Add "auto" to mode enum and add auto_threshold field**

In `skills/decide/prompts/state-templates.md`, replace the state.json Fields section (lines 20-26):

Current:
```markdown
Fields:
- `status`: "running" | "paused"
- `phase`: "onboarding" | "research" | "propose" | "collaborate" | "execute" | "validate" | "update_memory"
- `cycle`: integer, increments after each complete cycle
- `mode`: "default" | "force"
- `current_prd`: filename of the PRD being executed (e.g., "003-rate-limiting.md"), or null
- `last_completed`: ISO timestamp of the last completed cycle
```

Replace with:
```markdown
Fields:
- `status`: "running" | "paused"
- `phase`: "onboarding" | "research" | "propose" | "collaborate" | "execute" | "validate" | "update_memory"
- `cycle`: integer, increments after each complete cycle
- `mode`: "default" | "force" | "auto"
- `auto_threshold`: float (0.0-1.0), default 0.75. Only used when mode is "auto". PRDs with backlog priority_score >= this value are auto-approved; below this value routes to collaboration.
- `current_prd`: filename of the PRD being executed (e.g., "003-rate-limiting.md"), or null
- `last_completed`: ISO timestamp of the last completed cycle
```

- [ ] **Step 2: Verify the change**

Read `skills/decide/prompts/state-templates.md` and confirm:
- Line containing `mode` now shows `"default" | "force" | "auto"`
- New `auto_threshold` field is documented between `mode` and `current_prd`

- [ ] **Step 3: Commit**

```bash
git add skills/decide/prompts/state-templates.md
git commit -m "feat: add auto mode and auto_threshold to state.json schema docs"
```

---

### Task 2: Update SKILL.md — Usage Section and Phase Router

**Files:**
- Modify: `skills/decide/SKILL.md:10-35`

- [ ] **Step 1: Add auto mode to Usage section**

In `skills/decide/SKILL.md`, replace lines 10-19 (the Usage section):

Current:
```markdown
## Usage

**Default mode (interactive):** Run `/decide` in Claude Code.

You'll interact during onboarding and PRD approval. Re-invoke between cycles.

**Force mode (fully autonomous):** Run `/decide force` in Claude Code, or from terminal:
```bash
bash skills/decide/scripts/launcher.sh --force
```
```

Replace with:
```markdown
## Usage

**Default mode (interactive):** Run `/decide` in Claude Code.

You'll interact during onboarding and PRD approval. Re-invoke between cycles.

**Force mode (fully autonomous):** Run `/decide force` in Claude Code, or from terminal:
```bash
bash skills/decide/scripts/launcher.sh --force
```

**Auto mode (confidence-gated):** Run `/decide auto` or `/decide auto 0.8` in Claude Code, or from terminal:
```bash
bash skills/decide/scripts/launcher.sh --auto          # threshold 0.75 (default)
bash skills/decide/scripts/launcher.sh --auto=0.8      # threshold 0.80
```

Auto mode auto-approves PRDs whose backlog priority score meets the threshold, and routes lower-scored PRDs to the interactive collaborate phase.
```

- [ ] **Step 2: Update Phase Router Step 0 for auto mode arg parsing**

In `skills/decide/SKILL.md`, replace line 30 (Phase Router Step 0):

Current:
```markdown
0. Check if args contain "force" → if `.claude-operator/state.json` exists, set its `mode` to "force" for this cycle. If state doesn't exist yet, remember to set mode to "force" during onboarding initialization.
```

Replace with:
```markdown
0. Check if args contain "force" → if `.claude-operator/state.json` exists, set its `mode` to "force" for this cycle. If state doesn't exist yet, remember to set mode to "force" during onboarding initialization.
   Check if args contain "auto" → set `mode` to "auto" in `state.json`. If the next argument is a number between 0.0 and 1.0, set `auto_threshold` to that value. Otherwise set `auto_threshold` to 0.75. If state doesn't exist yet, remember to set mode to "auto" during onboarding initialization.
```

- [ ] **Step 3: Verify the changes**

Read `skills/decide/SKILL.md` lines 10-40 and confirm:
- Usage section now has three modes documented (default, force, auto)
- Phase Router Step 0 has both "force" and "auto" arg checks

- [ ] **Step 4: Commit**

```bash
git add skills/decide/SKILL.md
git commit -m "feat: add auto mode to SKILL.md usage and phase router arg parsing"
```

---

### Task 3: Update SKILL.md — Propose Phase Transition Logic

**Files:**
- Modify: `skills/decide/SKILL.md:293-313`

- [ ] **Step 1: Update Propose Phase Step 3 to resolve open questions for auto mode**

In `skills/decide/SKILL.md`, replace the Step 3 header and first line (lines 293-294):

Current:
```markdown
### Step 3: Resolve Open Questions (Force Mode)

If mode is "force", check the PRD's "Open Questions" section. If it contains any unresolved questions (anything other than "None" or empty):
```

Replace with:
```markdown
### Step 3: Resolve Open Questions (Force/Auto Mode)

If mode is "force" or "auto", check the PRD's "Open Questions" section. If it contains any unresolved questions (anything other than "None" or empty):
```

- [ ] **Step 2: Update Propose Phase Step 4 with three-way branch**

In `skills/decide/SKILL.md`, replace lines 302-312 (Step 4: Transition):

Current:
```markdown
### Step 4: Transition

If mode is "force":
- Output: "Transitioning to Execute Phase..."
- Update `state.json`: set phase to "execute", set `current_prd` to the PRD filename.
- Exit. The next cycle will pick up execution.

If mode is "default":
- Output: "Transitioning to Collaborate Phase..."
- Update `state.json`: set phase to "collaborate".
- Continue to Collaborate Phase (same session).
```

Replace with:
```markdown
### Step 4: Transition

If mode is "force":
- Output: "Transitioning to Execute Phase..."
- Update `state.json`: set phase to "execute", set `current_prd` to the PRD filename.
- Exit. The next cycle will pick up execution.

If mode is "auto":
- Read the candidate backlog item's `priority_score` and `state.json`'s `auto_threshold` (default 0.75 if not set).
- If `priority_score >= auto_threshold`:
  - Output: "Auto-approved (priority [score] >= threshold [threshold]). Skipping collaboration."
  - Update `state.json`: set phase to "execute", set `current_prd` to the PRD filename.
  - Exit. The next cycle will pick up execution.
- If `priority_score < auto_threshold`:
  - Output: "Priority [score] < threshold [threshold]. Routing to collaboration."
  - Update `state.json`: set phase to "collaborate".
  - Continue to Collaborate Phase (same session).

If mode is "default":
- Output: "Transitioning to Collaborate Phase..."
- Update `state.json`: set phase to "collaborate".
- Continue to Collaborate Phase (same session).
```

- [ ] **Step 3: Verify the changes**

Read `skills/decide/SKILL.md` lines 290-330 and confirm:
- Step 3 title says "Force/Auto Mode" and condition checks for "force" or "auto"
- Step 4 has three branches: force → execute, auto → threshold check → execute or collaborate, default → collaborate
- Auto-approve output matches requirement 9: "Auto-approved (priority [score] >= threshold [threshold]). Skipping collaboration."
- Below-threshold output matches requirement 10: "Priority [score] < threshold [threshold]. Routing to collaboration."

- [ ] **Step 4: Commit**

```bash
git add skills/decide/SKILL.md
git commit -m "feat: add auto mode threshold routing to propose phase transition"
```

---

### Task 4: Update launcher.sh — Auto Mode Flag Parsing

**Files:**
- Modify: `skills/decide/scripts/launcher.sh`

- [ ] **Step 1: Add --auto flag parsing to argument parser**

In `skills/decide/scripts/launcher.sh`, replace lines 12-35 (argument parsing section):

Current:
```bash
# --- Argument Parsing ---
FORCE_MODE=false
MAX_CYCLES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_MODE=true
      shift
      ;;
    --max-cycles)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-cycles requires a positive integer argument."
        exit 1
      fi
      MAX_CYCLES="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done
```

Replace with:
```bash
# --- Argument Parsing ---
FORCE_MODE=false
AUTO_MODE=false
AUTO_THRESHOLD="0.75"
MAX_CYCLES=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_MODE=true
      shift
      ;;
    --auto)
      AUTO_MODE=true
      shift
      ;;
    --auto=*)
      AUTO_MODE=true
      AUTO_THRESHOLD="${1#--auto=}"
      if ! [[ "$AUTO_THRESHOLD" =~ ^0(\.[0-9]+)?$|^1(\.0+)?$ ]]; then
        echo "Error: --auto threshold must be a number between 0.0 and 1.0 (got: $AUTO_THRESHOLD)"
        exit 1
      fi
      shift
      ;;
    --max-cycles)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-cycles requires a positive integer argument."
        exit 1
      fi
      MAX_CYCLES="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done
```

- [ ] **Step 2: Update the mode gate to accept --auto alongside --force**

In `skills/decide/scripts/launcher.sh`, replace lines 37-51 (the mode gate):

Current:
```bash
if [[ "$FORCE_MODE" != "true" ]]; then
  echo "Claude Decide Launcher"
  echo ""
  echo "This launcher is for --force mode (fully autonomous, no user interaction)."
  echo ""
  echo "For default mode (interactive), run /decide in Claude Code."
  echo ""
  echo "Usage:"
  echo "  bash skills/decide/scripts/launcher.sh --force [--max-cycles N]"
  echo ""
  echo "Options:"
  echo "  --force           Run in fully autonomous mode (required)"
  echo "  --max-cycles N    Maximum number of cycles to run (default: 50)"
  exit 0
fi
```

Replace with:
```bash
if [[ "$FORCE_MODE" != "true" ]] && [[ "$AUTO_MODE" != "true" ]]; then
  echo "Claude Decide Launcher"
  echo ""
  echo "This launcher is for --force or --auto mode (no default/interactive mode)."
  echo ""
  echo "For default mode (interactive), run /decide in Claude Code."
  echo ""
  echo "Usage:"
  echo "  bash skills/decide/scripts/launcher.sh --force [--max-cycles N]"
  echo "  bash skills/decide/scripts/launcher.sh --auto[=THRESHOLD] [--max-cycles N]"
  echo ""
  echo "Options:"
  echo "  --force           Run in fully autonomous mode"
  echo "  --auto            Run in auto-approval mode (threshold 0.75)"
  echo "  --auto=N          Run in auto-approval mode with custom threshold (0.0-1.0)"
  echo "  --max-cycles N    Maximum number of cycles to run (default: 50)"
  exit 0
fi
```

- [ ] **Step 3: Update the prompt template to handle auto mode**

In `skills/decide/scripts/launcher.sh`, replace lines 66-81 (the prompt heredoc):

Current:
```bash
cat > "$PROMPT_FILE" <<'PROMPT_EOF'
You are Claude Operator running in force mode (fully autonomous, no user interaction).

Your instructions are in the file skills/decide/SKILL.md — read that file now for the full phase router, guardrails, and constraints.

Your current state is in .claude-operator/state.json — read that file now.

Execute the phase router exactly as documented in SKILL.md:
1. Check if .claude-operator/ exists. If not, run the Onboarding Phase (set mode to "force" during initialization).
2. Check if .claude-operator/stuck.json exists. If so, since this is force mode and there is no user to interact with, exit immediately so the launcher can handle it.
3. Read .claude-operator/state.json and execute the phase specified there.
4. Set mode to "force" in state.json for this cycle (auto-approve PRDs, skip user collaboration).
5. When the phase is complete, update state.json and exit.

IMPORTANT: Follow ALL guardrails from SKILL.md — no duplicates, no thrashing, no overbuilding, respect constraints, no mid-execution pivots. You have the same responsibilities as an interactive /decide force invocation.
PROMPT_EOF
```

Replace with:
```bash
if [[ "$AUTO_MODE" == "true" ]]; then
  PROMPT_MODE="auto"
  PROMPT_MODE_INSTRUCTION="Set mode to \"auto\" and auto_threshold to ${AUTO_THRESHOLD} in state.json for this cycle. PRDs with priority_score >= ${AUTO_THRESHOLD} are auto-approved; lower-scored PRDs route to collaboration (but since this is a non-interactive launcher, resolve collaboratively by auto-approving with a note)."
else
  PROMPT_MODE="force"
  PROMPT_MODE_INSTRUCTION="Set mode to \"force\" in state.json for this cycle (auto-approve PRDs, skip user collaboration)."
fi

cat > "$PROMPT_FILE" <<PROMPT_EOF
You are Claude Operator running in ${PROMPT_MODE} mode.

Your instructions are in the file skills/decide/SKILL.md — read that file now for the full phase router, guardrails, and constraints.

Your current state is in .claude-operator/state.json — read that file now.

Execute the phase router exactly as documented in SKILL.md:
1. Check if .claude-operator/ exists. If not, run the Onboarding Phase (set mode to "${PROMPT_MODE}" during initialization).
2. Check if .claude-operator/stuck.json exists. If so, since this is a non-interactive launcher, exit immediately so the launcher can handle it.
3. Read .claude-operator/state.json and execute the phase specified there.
4. ${PROMPT_MODE_INSTRUCTION}
5. When the phase is complete, update state.json and exit.

IMPORTANT: Follow ALL guardrails from SKILL.md — no duplicates, no thrashing, no overbuilding, respect constraints, no mid-execution pivots. You have the same responsibilities as an interactive /decide ${PROMPT_MODE} invocation.
PROMPT_EOF
```

- [ ] **Step 4: Update the startup output to show mode**

In `skills/decide/scripts/launcher.sh`, replace lines 83-87 (startup echo):

Current:
```bash
echo "Claude Operator starting in FORCE mode (fully autonomous)..."
echo "Max cycles: ${MAX_CYCLES}"
echo "Press Ctrl+C to stop immediately."
echo "Run 'touch .claude-operator/stop' from another terminal to stop after the current cycle."
echo ""
```

Replace with:
```bash
if [[ "$AUTO_MODE" == "true" ]]; then
  echo "Claude Operator starting in AUTO mode (threshold: ${AUTO_THRESHOLD})..."
else
  echo "Claude Operator starting in FORCE mode (fully autonomous)..."
fi
echo "Max cycles: ${MAX_CYCLES}"
echo "Press Ctrl+C to stop immediately."
echo "Run 'touch .claude-operator/stop' from another terminal to stop after the current cycle."
echo ""
```

- [ ] **Step 5: Verify launcher.sh syntax**

```bash
bash -n skills/decide/scripts/launcher.sh
```

Expected: no output (syntax OK).

- [ ] **Step 6: Commit**

```bash
git add skills/decide/scripts/launcher.sh
git commit -m "feat: add --auto and --auto=N flags to launcher.sh"
```

---

### Task 5: Verification — Check All 10 PRD Requirements

**Files:**
- Read: `skills/decide/SKILL.md`, `skills/decide/prompts/state-templates.md`, `skills/decide/scripts/launcher.sh`

- [ ] **Step 1: Verify each requirement**

Read all three modified files and check:

1. **Req 1** (state.json accepts mode "auto"): state-templates.md shows `"auto"` in mode enum ✓
2. **Req 2** (auto_threshold field, default 0.75): state-templates.md documents auto_threshold with default 0.75 ✓
3. **Req 3** (auto + score >= threshold → execute): SKILL.md Propose Step 4 auto branch, score >= threshold → execute ✓
4. **Req 4** (auto + score < threshold → collaborate): SKILL.md Propose Step 4 auto branch, score < threshold → collaborate ✓
5. **Req 5** (`/decide auto` sets mode auto, threshold 0.75): SKILL.md Phase Router Step 0 parses "auto", defaults to 0.75 ✓
6. **Req 6** (`/decide auto 0.8` sets threshold 0.80): SKILL.md Phase Router Step 0 parses next arg as float ✓
7. **Req 7** (launcher.sh --auto and --auto=N): launcher.sh argument parser handles both flags ✓
8. **Req 8** (state-templates.md documents auto mode): auto_threshold field documented ✓
9. **Req 9** (auto-approve output message): SKILL.md Step 4 output matches format ✓
10. **Req 10** (below-threshold output message): SKILL.md Step 4 output matches format ✓

- [ ] **Step 2: Final commit with all changes**

If any individual task commits were missed, stage all changes:

```bash
git add skills/decide/SKILL.md skills/decide/prompts/state-templates.md skills/decide/scripts/launcher.sh
git commit -m "feat: confidence-gated auto-approval mode (PRD-009)"
```
