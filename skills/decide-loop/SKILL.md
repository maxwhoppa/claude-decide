---
name: decide-loop
description: Continuously run the decide operator in force mode, auto-restarting after each cycle. Use when the user wants to run /decide in a loop without manual re-invocation.
---

# Decide Loop

Runs the Claude Operator (`/decide force`) in a continuous loop within a single Claude Code session. After each cycle completes, it automatically starts the next one.

## Usage

```
/decide-loop              # run until stopped (default max: 50 cycles)
/decide-loop 10           # run 10 cycles then stop
/decide-loop edit         # review backlog before starting loop
/decide-loop 5 edit       # review backlog, then run 5 cycles
```

## How It Works

This skill wraps the `/decide` skill's phase router. Instead of exiting after each phase and waiting for re-invocation, it loops: execute phase → update state → check stop conditions → execute next phase.

## Execution

### Step 1: Parse Args

Read the args. If a number is provided, use it as `max_cycles`. Otherwise default to 50. If "edit" is present, set `edit_mode` to true.

### Step 2: Load the Decide Skill

Read the full decide skill from `/Users/maxwellnewman/.claude/skills/decide/SKILL.md`. This is your playbook — all phase logic, guardrails, and constraints apply exactly as documented there.

### Step 3: Initialize

If `.claude-operator/` does not exist, run the **Onboarding Phase** from the decide skill (including the user interview — this is the one interactive part). Set mode to "force" during initialization.

If `.claude-operator/state.json` exists, set its `mode` to "force".

Set a cycle counter to 0.

Output:
```
Starting decide loop (force mode, max cycles: [N]).
Touch .claude-operator/stop to halt after the current cycle.
```

### Step 3b: Backlog Review (edit mode only)

If `edit_mode` is false, skip this step entirely.

Read `.claude-operator/backlog.json`. Filter to items with `status: "queued"`, sorted by `priority_score` descending.

If no queued items exist, output: "No queued backlog items to review. The loop will run research to discover new work." and skip to Step 4.

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

### Step 4: Loop

Repeat the following until a stop condition is met:

1. **Check stop conditions** (in order):
   - If cycle counter >= max_cycles → output "Max cycles ([N]) reached. Loop stopped." and exit.
   - If `.claude-operator/stop` exists → remove the file, output "Stop signal detected. Loop stopped." and exit.
   - If `.claude-operator/stuck.json` exists → enter **Stuck Recovery Phase** from the decide skill (present the stuck report to the user and handle their response). After resolution, continue the loop. If the user chooses "stop", exit the loop.
   - If `state.json` status is "paused" → output "Operator is paused." and exit.

2. **Execute one cycle:**
   - Increment cycle counter.
   - Output: `--- Cycle [N] of [max] ---`
   - Read `state.json` to determine the current phase.
   - Execute that phase using the exact logic from the decide skill's phase router, with one modification: **do not exit after phase transitions**. Instead of "Exit. The next cycle picks up execution," continue directly to the next phase in the same iteration.
   - A full cycle is: research → propose → execute → update memory. Run all of these phases sequentially within a single loop iteration (don't stop between them).
   - After the Update Memory phase completes (state is reset to "research" and cycle is incremented), that counts as one completed cycle.

3. **Loop back to step 1.**

### CRITICAL: Never Stop Mid-Cycle

The Execute Phase invokes three superpowers skills in sequence via the Skill tool:
1. `superpowers:brainstorming`
2. `superpowers:writing-plans`
3. `superpowers:executing-plans`

Each skill invocation loads a prompt, you follow it, and then **control returns to you**. When control returns, you MUST immediately continue to the next step — your very next action must be the next skill invocation or phase step. Do NOT:
- Stop and wait for user input after a skill returns
- Treat a skill's completion as a natural stopping point
- Say "proceeding to X" without actually doing X in the same response
- Ask the user which execution approach they want (always use inline execution in the loop)
- Summarize what just happened and then stop — summarize AND continue in the same response

**This is the #1 failure mode of the decide-loop.** In practice, the model tends to pause after `writing-plans` returns (before invoking `executing-plans`) and after `executing-plans` returns (before starting Update Memory). You MUST power through these transitions without stopping. If you find yourself about to end a response after a skill completes, you are doing it wrong — invoke the next skill immediately.

The same applies between phases. After Execute completes, immediately run Update Memory. After Update Memory completes, immediately loop back and start the next cycle's Research Phase. The ONLY valid stopping points are:
- A stop condition from Step 4.1 (max cycles, stop file, stuck, paused)
- The user interrupts

If a skill's instructions say "wait for user approval", "ask the user", or "offer execution choice" — skip those steps. You are in force mode. Resolve autonomously and continue.

### Operational Rules

- **Commit format**: All operator cycle commits must use `Cycle N -- [short description] (PRD-NNN)`. One commit per cycle, including .claude-operator/ state files.
- **No manual file copies**: After committing changes to `skills/` in the repo, use `bash install.sh` to sync to `~/.claude/skills/`. Never use raw `cp` commands.
- **install.sh for syncing**: The repo's `install.sh` handles copying skills to the user's Claude skills directory. Always use it instead of manual copies.

### Important Differences from `/decide`

- **No exit between phases**: The normal `/decide` skill exits after certain phase transitions and expects re-invocation. This loop runs all phases of a cycle sequentially without stopping.
- **Force mode always**: PRDs are auto-approved, collaboration is skipped, open questions are resolved by subagent (per the decide skill's Step 3 in the Propose Phase).
- **Stuck = interactive pause, not full stop**: When stuck, the loop pauses to let the user help debug (since they're in-session), then continues. Only an explicit "stop" from the user ends the loop.
- **All other behavior is identical**: Guardrails, research agents, PRD generation, critic, execution, memory updates — all follow the decide skill exactly.
