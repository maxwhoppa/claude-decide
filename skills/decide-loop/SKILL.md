---
name: decide-loop
description: Continuously run the decide operator in force mode, auto-restarting after each cycle. Use when the user wants to run /decide in a loop without manual re-invocation.
---

# Decide Loop

Runs the Claude Operator (`/decide force`) in a continuous loop. Each cycle executes in a **fresh Claude session** via `claude -p`, ensuring full superpowers skill access (brainstorming, writing-plans, executing-plans) on every cycle.

## Usage

```
/decide-loop              # run until stopped (default max: 50 cycles)
/decide-loop 10           # run 10 cycles then stop
/decide-loop edit         # review backlog before starting loop
/decide-loop 5 edit       # review backlog, then run 5 cycles
```

## How It Works

This skill manages the loop — checking stop conditions, handling stuck recovery, and optionally reviewing the backlog. The actual cycle execution is delegated to a fresh `claude -p "/decide force"` session each time, so every cycle gets clean context and full skill access.

## Execution

### Step 1: Parse Args

Read the args. If a number is provided, use it as `max_cycles`. Otherwise default to 50. If "edit" is present, set `edit_mode` to true.

### Step 2: Initialize

If `.claude-operator/` does not exist, run the **Onboarding Phase** from the decide skill (read `/Users/maxwellnewman/.claude/skills/decide/SKILL.md` for the onboarding instructions — this is the one interactive part). Set mode to "force" during initialization.

If `.claude-operator/state.json` exists, set its `mode` to "force".

Set a cycle counter to 0.

Output:
```
Starting decide loop (force mode, max cycles: [N]).
Touch .claude-operator/stop to halt after the current cycle.
```

### Step 2b: Backlog Review (edit mode only)

If `edit_mode` is false, skip this step entirely.

Read `.claude-operator/backlog.json`. Filter to items with `status: "queued"`, sorted by `priority_score` descending.

If no queued items exist, output: "No queued backlog items to review. The loop will run research to discover new work." and skip to Step 3.

Present the full queued backlog as a numbered table:

```
Backlog review — [N] queued items (sorted by priority):

| # | ID | Priority | Idea |
|---|-----|----------|------|
| 1 | BL-031 | 0.68 | /decide rollback command |
| 2 | BL-008 | 0.65 | Backlog inspection commands |
| ... | ... | ... | ... |

For each item, respond with:
  approve  — keep as-is, will be built in priority order
  reject   — remove from queue (won't be built)
  bump N   — change priority to N (0.0-1.0)
  skip     — leave as-is, move to next

Or use bulk commands:
  approve all        — approve all remaining items
  reject [#,#,...]   — reject specific items by number
  bump [#] [score]   — change priority of specific item

Review items now:
```

Wait for the user to respond. Process their feedback:

- **approve** / **approve all**: No changes needed, items stay queued.
- **reject [items]**: Set status to "rejected" with note "Rejected during backlog review before decide-loop". Remove from queue.
- **bump [item] [score]**: Update the item's `priority_score` to the new value.
- **skip**: Move to the next item or finish review.

After the user has reviewed all items (or used a bulk command), write the updated `backlog.json`.

Output: "Backlog review complete. [N] items approved, [M] rejected, [P] reprioritized. Starting loop..."

### Step 3: Loop

Repeat the following until a stop condition is met:

1. **Check stop conditions** (in order):
   - If cycle counter >= max_cycles → output "Max cycles ([N]) reached. Loop stopped." and exit.
   - If `.claude-operator/stop` exists → remove the file, output "Stop signal detected. Loop stopped." and exit.
   - If `.claude-operator/stuck.json` exists → enter **Stuck Recovery Phase** (read the stuck report from the file and present it to the user conversationally, then handle their response: debug together, skip, or stop). After resolution, continue the loop. If the user chooses "stop", exit the loop.
   - If `state.json` status is "paused" → output "Operator is paused." and exit.

2. **Execute one cycle via fresh session:**
   - Increment cycle counter.
   - Output: `--- Cycle [N] of [max] ---`
   - Run the following command using the Bash tool:
     ```bash
     claude -p "You are Claude Operator running in force mode. Read skills/decide/SKILL.md for your full instructions. Read .claude-operator/state.json for current state. Execute the phase router: run ALL phases of one complete cycle (research → propose → execute → update memory) without stopping between phases. Set mode to force. Follow ALL guardrails. CRITICAL: During the Execute Phase, you MUST invoke these three superpowers skills in order via the Skill tool: (1) superpowers:brainstorming, (2) superpowers:writing-plans, (3) superpowers:executing-plans. Do NOT skip any of these — they are a hard requirement in SKILL.md. Do NOT implement changes directly without going through all three skills. When the cycle is complete (state reset to research, cycle incremented), exit." --dangerously-skip-permissions
     ```
   - The `--dangerously-skip-permissions` flag allows the session to use tools without interactive prompts.
   - This launches a **fresh Claude session** with full skill access. It will invoke superpowers:brainstorming, superpowers:writing-plans, and superpowers:executing-plans as specified in SKILL.md's Execute Phase.
   - Wait for the command to complete.
   - Output: `Cycle [N] complete.`

3. **Loop back to step 1.**

### Why Fresh Sessions

Each cycle runs in a fresh `claude -p` session because:
- **Full skill access**: Subagents (Agent tool) don't have access to the Skill tool. Only top-level sessions can invoke superpowers skills. A fresh session ensures brainstorming, writing-plans, and executing-plans are all available.
- **Clean context**: Each cycle gets a full context window instead of competing with accumulated context from previous cycles.
- **Quality preservation**: In-session loops degrade after cycle 1 — the model starts shortcutting (skipping superpowers, editing files directly). Fresh sessions don't have this problem.

The tradeoff is that each cycle takes longer to start (session initialization), but the quality of each cycle is significantly higher.

### Operational Rules

- **Commit format**: All operator cycle commits must use `Cycle N -- [short description] (PRD-NNN)`. One commit per cycle, including .claude-operator/ state files.
- **No manual file copies**: After committing changes to `skills/` in the repo, use `bash install.sh` to sync to `~/.claude/skills/`. Never use raw `cp` commands.
- **install.sh for syncing**: The repo's `install.sh` handles copying skills to the user's Claude skills directory. Always use it instead of manual copies.

### Important Differences from `/decide`

- **Fresh session per cycle**: Each cycle gets a clean Claude session via `claude -p`, not inline execution.
- **Force mode always**: PRDs are auto-approved, collaboration is skipped, open questions are resolved autonomously.
- **Stuck = interactive pause**: When stuck, the loop (running in the parent session) pauses to let the user help debug, then continues.
- **Backlog review (edit mode)**: The parent session handles interactive backlog review before starting the loop.
- **All other behavior is identical**: Guardrails, research agents, PRD generation, critic, execution, memory updates — all follow the decide skill exactly, enforced by each fresh session reading SKILL.md.
