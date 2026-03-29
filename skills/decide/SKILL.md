---
name: decide
description: Use when the user wants to decide what to build next, run the autonomous operator, improve a codebase, or asks 'what should we build'. Researches, generates PRDs, and executes improvements autonomously.
---

# Claude Operator

Autonomous continuous product builder. Each invocation executes one phase of the operator cycle, updates state, and exits.

## Usage

**Default mode (interactive):** Run `/decide` in Claude Code.

You'll interact during onboarding and PRD approval. Re-invoke between cycles.

**Force mode (fully autonomous):** Run `/decide force` in Claude Code, or from terminal:
```bash
bash skills/decide/scripts/launcher.sh --force
```

## Quick Reference

```
ONBOARDING (first run) → RESEARCH → PROPOSE → COLLABORATE → EXECUTE → UPDATE MEMORY → EXIT → (restart)
```

## Phase Router

On every invocation:

0. Check if args contain "force" → if `.claude-operator/state.json` exists, set its `mode` to "force" for this cycle. If state doesn't exist yet, remember to set mode to "force" during onboarding initialization.
1. Check if `.claude-operator/` exists. If not → **Onboarding Phase**.
2. Check if `.claude-operator/stuck.json` exists. If so → **Stuck Recovery Phase**.
3. Read `.claude-operator/state.json`. Execute the phase specified in `state.json.phase`.

---

## Onboarding Phase

Triggered when `.claude-operator/` directory does not exist.

### Step 1: Repo Analysis

Dispatch a subagent using the Agent tool:
- Read `skills/decide/prompts/onboarding-repo-analysis.md` for the prompt
- Dispatch as a `general-purpose` subagent
- Collect the JSON output (product hypothesis)

### Step 2: Present Hypothesis

Show the user what you found:

```
I've analyzed this codebase. Here's what I think this project is:

**[product_hypothesis]**

Detected features: [list]
Tech stack: [list]
Gaps I noticed: [list]
```

### Step 3: User Interview

Ask these questions ONE AT A TIME. Wait for an answer before asking the next.

Core questions (always ask all):
1. "Is my analysis correct? What did I get wrong?"
2. "Who is your target customer?"
3. "What core problem does this solve for them?"
4. "How do you (or will you) make money?"
5. "What stage is the product at? (pre-launch / live with users / scaling)"
6. "What are your top 1-3 priorities right now?"
7. "Are there any hard technical constraints I should know about?"
8. "What areas of the codebase are you most concerned about?"
9. "Is there anything I should NOT touch?"
10. "What features or improvements are on your wishlist that haven't been built yet?"
11. "Should `.claude-operator/` be tracked in git?"

Adaptive follow-ups (ask based on answers):
- If stage is "live with users": "What's your most common user complaint?"
- If stage is "pre-launch": "What's blocking launch?"
- If revenue exists: "What's your highest-value feature?"
- If constraints mentioned: probe deeper on each constraint

### Step 4: Initialize State

Create the `.claude-operator/` directory structure:

```bash
mkdir -p .claude-operator/prds .claude-operator/experiments .claude-operator/logs
```

Read `skills/decide/prompts/state-templates.md` for the JSON schemas.

Write these files using information gathered from repo analysis + interview:
- `.claude-operator/memory.json` — fill in product info, features, constraints, known_gaps
- `.claude-operator/backlog.json` — seed with user's wishlist items + detected gaps from repo analysis. Assign each an initial priority score based on alignment with user's stated priorities.
- `.claude-operator/state.json` — set phase to "research", cycle to 1, mode to "default" (or "force" if operator was started with --force)

If user said `.claude-operator/` should be git-tracked, do NOT add it to `.gitignore`. Otherwise, add `.claude-operator/` to `.gitignore`.

### Step 5: Exit

Tell the user: "Onboarding complete. I'll start researching improvements now."

Update `state.json` phase to "research" and exit. The launcher will restart for the first research cycle.

---

## Research Phase

Read `state.json` — phase must be "research".

### Step 1: Load Context

Read `.claude-operator/memory.json` and `.claude-operator/backlog.json`.

### Step 2: Dispatch Research Agents

Dispatch ALL 7 research agents IN PARALLEL using the Agent tool. For each agent:
- Read the corresponding prompt file from `skills/decide/prompts/research-*.md`
- Replace `{{memory_json}}` with the contents of `memory.json`
- Replace `{{backlog_json}}` with the contents of `backlog.json`
- Dispatch as a `general-purpose` subagent

The 7 agents:
1. `research-code-auditor.md`
2. `research-product-gap.md`
3. `research-security.md`
4. `research-market.md`
5. `research-customer-value.md`
6. `research-experimentation.md`
7. `research-analytics.md`

### Step 3: Synthesize Results

After all 7 agents return:

1. **Deduplicate** — merge findings that describe the same issue across agents
2. **Filter** — remove anything that matches an existing backlog item or a completed feature in memory.json
3. **Score** — for each new finding, assign a priority score (0.0-1.0) based on:
   - How many agents flagged it (convergence = higher score)
   - Alignment with user's stated priorities in memory.json
   - Estimated effort vs. impact
   - Whether it unblocks other backlog items
4. **Update backlog** — add new items to `backlog.json` with status "queued"
5. **Pick candidate** — select the highest-priority queued item as this cycle's candidate

### Step 4: Check for Stagnation

Read the last 3 cycle logs from `.claude-operator/logs/`. If all 3 cycles produced zero new backlog items, enter **meta-research mode**:
- Dispatch a single subagent: "You are a meta-researcher. The operator has run 3 cycles without finding new ideas. Here is the current backlog: [backlog]. Here is the product context: [memory]. Suggest new research angles, different ways to analyze the codebase, or recommend the operator pause. Output as JSON with `new_strategies` and `operator_improvements` arrays."
- If the meta-researcher recommends pausing, write a message to the user and set state to "paused". Exit.

### Step 5: Transition

Update `state.json`: set phase to "propose", and store the candidate backlog item ID.

Continue to the Propose Phase (same session).

---

## Propose Phase

### Step 1: Generate PRD

Read `skills/decide/prompts/prd-template.md` for the template.

Determine the next PRD number by counting existing files in `.claude-operator/prds/`.

Write a complete PRD for the candidate idea. Fill in every section using:
- The research findings from this cycle
- Product context from memory.json
- The backlog item details

Save to `.claude-operator/prds/NNN-feature-name.md`.

### Step 2: Self-Critique

Read `skills/decide/prompts/prd-critic.md` for instructions.

Run the PRD through all 5 critique lenses. Modify the PRD file in place. Track changes.

### Step 3: Transition

If mode is "force":
- Update `state.json`: set phase to "execute", set `current_prd` to the PRD filename.
- Exit. The next cycle will pick up execution.

If mode is "default":
- Update `state.json`: set phase to "collaborate".
- Continue to Collaborate Phase (same session).

---

## Collaborate Phase

### Step 1: Present the PRD

Read the PRD file from `.claude-operator/prds/`. Present it conversationally:

```
Hey — I ran research across your codebase and here's what I think we should build next:

**[PRD title]**

[2-3 sentence summary of what it does and why]

Here's why this ranked highest:
- [reason 1 — which agents flagged it]
- [reason 2 — alignment with priorities]
- [reason 3 — effort vs impact]

The full PRD is at .claude-operator/prds/[filename]

What do you think?
```

### Step 2: Handle User Response

This is a CONVERSATION, not a yes/no gate. Stay in this phase until you get a clear signal.

**If user approves ("yes", "go for it", "looks good"):**
- Update `state.json`: phase → "execute", set `current_prd`
- Exit. Next cycle picks up execution.

**If user approves with changes ("yes but change X"):**
- Update the PRD with requested changes
- Confirm the changes with the user
- Then proceed as above (phase → "execute", exit)

**If user rejects ("no", "not now"):**
- Update the backlog item: lower priority score
- Pick the next highest-priority queued item
- Generate a new PRD for that item (run propose phase again in this session)
- Present the new PRD

**If user redirects ("work on X instead"):**
- Add X to backlog (or promote if already there) with high priority
- Generate a new PRD for X (run propose phase in this session)
- Present the new PRD

**If user wants more research ("do more research", "look in X direction"):**
- If direction specified, note it for next research cycle
- Update `state.json`: phase → "research"
- Exit. Next cycle re-researches.

**If user asks questions ("tell me more", "why this?"):**
- Answer using research findings, backlog context, and reasoning
- Stay in the collaboration phase

---

## Execute Phase

Read `state.json` — phase must be "execute". Read `current_prd` to get the PRD filename.

### Step 1: Dispatch Execution Subagent

Read `skills/decide/prompts/execution.md` for the prompt template.

Replace template variables:
- `{{prd_contents}}` — full contents of the PRD file
- `{{memory_json}}` — contents of memory.json
- `{{constraints}}` — the constraints array from memory.json, formatted as a bulleted list
- `{{cycle}}` — current cycle number from state.json
- `{{prd_filename}}` — the PRD filename

Dispatch as a `general-purpose` subagent. This subagent will:
- Run the superpowers brainstorm → plan → execute pipeline
- Validate by actually testing the code
- Commit when done
- Write stuck.json if it can't resolve after 10 attempts

### Step 2: Process Result

If the subagent returns a success result:
- Proceed to Update Memory phase (same session)

If `.claude-operator/stuck.json` was created:
- The launcher will detect this and pause. Exit.

---

## Update Memory Phase

### Step 1: Update memory.json

Based on the execution result:
- Add the new feature to `features` array
- Add to `feature_history` with source and cycle
- Remove relevant items from `known_gaps`
- Add to `past_decisions`
- Update any experiments

### Step 2: Update backlog.json

- Mark the completed item as "completed"
- If the execution surfaced new concerns, add them as new backlog items

### Step 3: Write Cycle Log

Write a summary to `.claude-operator/logs/cycle-NNN.json` with:
- cycle number, timestamp
- research findings summary
- proposed idea
- user feedback (from collaborate phase)
- PRD filename
- execution result
- files changed, tests added
- commit hash
- validation notes
- memory updates made

### Step 4: Reset and Exit

Update `state.json`:
- Increment `cycle`
- Set `phase` to "research"
- Clear `current_prd`
- Set `last_completed` to current ISO timestamp

Output to the user: "Cycle N complete. Run /decide to start the next cycle." (where N is the cycle number that just finished).

Exit. The launcher starts the next cycle.

---

## Stuck Recovery Phase

Triggered when `.claude-operator/stuck.json` exists.

Read the stuck report. Present it to the user conversationally:

```
I got stuck while implementing [PRD title].

Here's what happened:
- Error: [last_error]
- I tried [N] times: [summary of what_was_tried]
- Files I changed so far: [list]

How would you like to proceed?
1. Help me debug this (we work on it together)
2. Skip this PRD and move on to the next idea
3. Stop the operator
```

**If user helps debug:**
- Work with the user to resolve the issue
- Once resolved, remove `stuck.json`
- Resume from the execute phase

**If user skips:**
- Mark the backlog item as "rejected" with a note about why
- Remove `stuck.json`
- Reset `state.json` phase to "research"
- Exit. Next cycle starts fresh research.

**If user stops:**
- Write `.claude-operator/stop`
- Remove `stuck.json`
- Exit.

---

## Guardrails

These rules apply to ALL phases:

1. **No duplicates** — always check backlog.json and memory.json features before proposing anything
2. **No thrashing** — finish the current PRD before starting a new one
3. **No overbuilding** — enforce V1 scope ruthlessly
4. **Respect constraints** — never touch anything listed in memory.json constraints
5. **No mid-execution pivots** — once execute phase starts, it runs to completion (or stuck)
