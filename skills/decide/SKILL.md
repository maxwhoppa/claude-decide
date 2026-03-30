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
2. Ensure all expected subdirectories exist: `mkdir -p .claude-operator/prds .claude-operator/experiments .claude-operator/logs .claude-operator/inputs .claude-operator/agents` — this self-heals if directories were added in a newer version of the skill.
3. Check if `.claude-operator/stuck.json` exists. If so → **Stuck Recovery Phase**.
4. Read `.claude-operator/state.json`. Execute the phase specified in `state.json.phase`.

---

## Onboarding Phase

Triggered when `.claude-operator/` directory does not exist.

### Step 1: Repo Analysis

Dispatch a subagent using the Agent tool:
- Read `${CLAUDE_SKILL_DIR}/prompts/onboarding-repo-analysis.md` for the prompt
- Dispatch as a `general-purpose` subagent
- Collect the JSON output (product hypothesis)

### Step 1b: Pre-flight Check

Check if the following skills are available in your current session (they appear in the system reminders listing available skills):
- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:executing-plans`

If any are missing, output a warning:
```
Warning: Required superpowers skills not detected. The Execute Phase needs
brainstorming, writing-plans, and executing-plans. Install the superpowers
plugin before running your first cycle.
```

If all three are present, continue silently.

This check does NOT block onboarding — it warns and continues.

### Step 2: Map Analysis to Onboarding Fields

Take the repo analysis JSON output and map it to each of the 11 onboarding fields. For each field, assign a confidence level:

| Onboarding Field | Mapped From (repo analysis) | Confidence Rules |
|---|---|---|
| Product name | `product_hypothesis` (extract name) | **High** if package.json/README has a clear name; **Low** if inferred from directory name only |
| Target customer | `product_hypothesis` + README audience language | **High** if README explicitly states audience; **Medium** if inferred from product type; **Low** if no signal |
| Core problem | `product_hypothesis` + `detected_features` | **High** if README describes the problem; **Medium** if inferred from features; **Low** if no signal |
| Revenue model | README, detected pricing pages/config | **High** if pricing page or stripe/payment deps found; **Medium** if README mentions model; **Low** if no signal |
| Product stage | `maturity` + git history + `detected_gaps` | **High** if CI/CD and tests exist (live/scaling); **Medium** if partial signals; **Low** if ambiguous |
| Top priorities | `detected_gaps` + `todos_found` | **Medium** if clear gaps/TODOs; **Low** if no signal |
| Technical constraints | `tech_stack` + `architecture` | **Medium** if strong architectural patterns detected; **Low** if generic stack |
| Areas of concern | `detected_gaps` + `maturity` | **Medium** if gaps are concentrated in specific areas; **Low** if no clear signal |
| No-touch areas | Lock files, generated code, vendor dirs | **High** if clear generated/vendor dirs found; **Low** if no signal |
| Wishlist | `detected_gaps` + `todos_found` | **Medium** if TODOs/gaps found; **Low** if none |
| Git tracking | Presence of existing `.gitignore` patterns | **Low** always (this is a preference question) |

If the repo analysis returned no usable signal (e.g., empty repo — no `product_hypothesis`, empty `detected_features`, empty `tech_stack`), skip to **Step 2b: Fallback Interview** instead.

### Step 2b: Fallback Interview (only if repo analysis returned no signal)

If the repo is empty or analysis produced no usable output, fall back to the original sequential interview. Ask these questions ONE AT A TIME. Wait for an answer before asking the next.

1. "What is this product called?"
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

After collecting all answers, proceed to **Step 4: Initialize State**.

### Step 3: Present Summary and Collect Corrections

Present the pre-filled summary to the user in a single structured block. Mark each field with a confidence indicator so low-confidence items stand out:

```
I've analyzed this codebase and pre-filled your project profile. Please review — correct anything that's wrong, and I'll ask a few follow-ups for the items I'm less sure about.

| Field | Inferred Value | Confidence |
|---|---|---|
| Product name | [value] | [HIGH/MEDIUM/LOW] |
| Target customer | [value] | [HIGH/MEDIUM/LOW] |
| Core problem | [value] | [HIGH/MEDIUM/LOW] |
| Revenue model | [value] | [HIGH/MEDIUM/LOW] |
| Product stage | [value] | [HIGH/MEDIUM/LOW] |
| Top priorities | [value] | [HIGH/MEDIUM/LOW] |
| Technical constraints | [value] | [HIGH/MEDIUM/LOW] |
| Areas of concern | [value] | [HIGH/MEDIUM/LOW] |
| No-touch areas | [value] | [HIGH/MEDIUM/LOW] |
| Wishlist | [value] | [HIGH/MEDIUM/LOW] |
| Git tracking (.claude-operator/) | [value] | [LOW] |

Does this look right? Correct anything that's off — for example: "customer is actually X, not Y" or "we're live with users, not pre-launch".
```

After the user responds with corrections (or confirms), apply their corrections to the field values.

Then, for any fields still marked **LOW** confidence that the user did NOT explicitly correct or confirm, ask targeted follow-up questions. Ask at most 4 follow-up questions, bundled together in a single message (not one at a time). Prioritize the most important low-confidence fields:

1. Revenue model (if LOW)
2. Target customer (if LOW)
3. Top priorities (if LOW)
4. Git tracking preference (always LOW — always ask)

Example follow-up message:
```
A few things I couldn't confidently infer — quick answers for these:

1. How do you (or will you) make money? (I didn't find pricing or payment integrations)
2. What are your top 1-3 priorities right now?
3. Should `.claude-operator/` be tracked in git? (I'll add it to .gitignore if not)
```

After the user answers the follow-ups, all fields should be populated. Proceed to Step 4.

### Step 4: Initialize State

Create the `.claude-operator/` directory structure:

```bash
mkdir -p .claude-operator/prds .claude-operator/experiments .claude-operator/logs .claude-operator/inputs .claude-operator/agents
```

Read `${CLAUDE_SKILL_DIR}/prompts/state-templates.md` for the JSON schemas.

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

### Step 0: Check for Fast-Track

Output: "**Research Phase**"

Read `.claude-operator/backlog.json`. If there are ANY items with `status: "queued"`, skip the full research phase:
- Output: "Fast-tracking — backlog has [N] queued items."
- Pick the highest-priority queued item as this cycle's candidate.
- Jump directly to **Step 5: Transition** (set phase to "propose").

Research only runs when the backlog is empty (all items completed, rejected, or no items at all). This avoids burning 7+ research agent dispatches when there is already work to do.

### Step 1: Load Context

Read `.claude-operator/memory.json` and `.claude-operator/backlog.json`.

### Step 2: Select and Dispatch Research Agents

Select which research agents to dispatch based on the product context in `memory.json`. Read the `product.stage`, `features`, and `tech_stack` (from the original repo analysis or memory) to determine relevance.

**Always dispatch (core agents):**
1. `research-code-auditor.md` — always relevant
2. `research-product-gap.md` — always relevant

**Conditionally dispatch (include if criteria match):**
3. `research-security.md` — if the project has auth, user data handling, API endpoints, or database access
4. `research-market.md` — if stage is "pre-launch" or "scaling"
5. `research-customer-value.md` — if stage is "live with users" or "scaling"
6. `research-experimentation.md` — if the project has feature flags, A/B testing, analytics, or multiple user-facing variants
7. `research-analytics.md` — if the project has event tracking, monitoring, or observability infrastructure

**When in doubt, include the agent.** At least 3 agents must always be dispatched (the 2 core agents + at least 1 conditional). If no conditional agents match, include `customer-value` as a default third.

Count the selected agents + user inputs agent (if applicable) + custom agents.

Output: "Dispatching [N] research agents: [list of selected agent names]..."

Dispatch the selected agents IN PARALLEL using the Agent tool. For each agent:
- Read the corresponding prompt file from `${CLAUDE_SKILL_DIR}/prompts/research-*.md`
- Replace `{{memory_json}}` with the contents of `memory.json`
- Replace `{{backlog_json}}` with the contents of `backlog.json`
- Dispatch as a `general-purpose` subagent

**8th agent — User Inputs:**
Check if `.claude-operator/inputs/` exists and contains any files (ignore .gitkeep). If so:
- Read `${CLAUDE_SKILL_DIR}/prompts/research-user-inputs.md` for the prompt
- Replace `{{memory_json}}` and `{{backlog_json}}` as with other agents
- Replace `{{input_files}}` with the concatenated contents of ALL files in `.claude-operator/inputs/`, each prefixed with its filename
- Dispatch in parallel with the other 7 agents

The `.claude-operator/inputs/` folder is where the user drops customer feedback, market research, competitor analysis, user interviews, or any other external context relevant to product discovery. Files can be any format (markdown, text, JSON, etc.). The agent reads them all and extracts actionable product insights.

**Custom research agents:**
Check if `.claude-operator/agents/` contains any `.md` files (ignore README.md and .gitkeep). For each custom agent file found:
- Read the file as a prompt template
- Replace `{{memory_json}}` and `{{backlog_json}}` as with other agents
- Dispatch in parallel with all other agents

Custom agents let users add domain-specific research (e.g., accessibility auditor, performance analyzer, API design reviewer) without modifying the built-in agent set.

### Step 3: Synthesize Results

After all selected agents return:

1. **Deduplicate** — merge findings that describe the same issue across agents
2. **Filter** — remove anything that matches an existing backlog item or a completed feature in memory.json
3. **Score** — for each new finding, assign a priority score (0.0-1.0) based on:
   - How many agents flagged it (convergence = higher score)
   - Alignment with user's stated priorities in memory.json
   - Estimated effort vs. impact
   - Whether it unblocks other backlog items
4. **Update backlog** — add new items to `backlog.json` with status "queued"
5. **Pick candidate** — select the highest-priority queued item as this cycle's candidate

Output: "Research complete — [N] findings, [M] new backlog items"

### Step 4: Check for Stagnation

Read the last 3 cycle logs from `.claude-operator/logs/`. If all 3 cycles produced zero new backlog items, enter **meta-research mode**:
- Dispatch a single subagent: "You are a meta-researcher. The operator has run 3 cycles without finding new ideas. Here is the current backlog: [backlog]. Here is the product context: [memory]. Suggest new research angles, different ways to analyze the codebase, or recommend the operator pause. Output as JSON with `new_strategies` and `operator_improvements` arrays."
- If the meta-researcher recommends pausing, write a message to the user and set state to "paused". Exit.

### Step 5: Transition

Update `state.json`: set phase to "propose", and store the candidate backlog item ID.

Output: "Transitioning to Propose Phase..."

Continue to the Propose Phase (same session).

---

## Propose Phase

### Step 1: Generate PRD

Output: "**Propose Phase** — generating PRD for: [candidate idea title]"

Read `${CLAUDE_SKILL_DIR}/prompts/prd-template.md` for the template.

Determine the next PRD number by counting existing files in `.claude-operator/prds/`.

Write a complete PRD for the candidate idea. Fill in every section using:
- The research findings from this cycle
- Product context from memory.json
- The backlog item details

Save to `.claude-operator/prds/NNN-feature-name.md`.

### Step 2: Self-Critique

Read `${CLAUDE_SKILL_DIR}/prompts/prd-critic.md` for instructions.

Run the PRD through all 5 critique lenses. Modify the PRD file in place. Track changes.

### Step 3: Resolve Open Questions (Force Mode)

If mode is "force", check the PRD's "Open Questions" section. If it contains any unresolved questions (anything other than "None" or empty):
- Dispatch a subagent to resolve them: "You are resolving open questions for a PRD before execution. Read the codebase and product context to answer these questions. Here is the PRD: [prd_contents]. Here is the product context: [memory_json]. For each open question, provide a concrete answer or recommendation. Output as JSON: `{ "resolutions": [{ "question": "...", "answer": "...", "confidence": "high|medium|low" }] }`"
- Update the PRD's Open Questions section in place: replace each question with its resolution.
- If any resolution has `confidence: "low"`, add it to the Risks section instead and note the uncertainty.

This ensures the execution subagent never receives a PRD with unresolved questions, even when collaboration is skipped.

### Step 4: Transition

If mode is "force":
- Output: "Transitioning to Execute Phase..."
- Update `state.json`: set phase to "execute", set `current_prd` to the PRD filename.
- Exit. The next cycle will pick up execution.

If mode is "default":
- Output: "Transitioning to Collaborate Phase..."
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

Output: "**Execute Phase** — implementing [PRD title]..."

<HARD-GATE>
You MUST invoke all three superpowers skills below via the Skill tool, in order.
Do NOT skip any step, even for "simple" changes. Do NOT implement changes directly.
Every PRD goes through brainstorm → plan → execute. No exceptions.
</HARD-GATE>

### Step 1: Brainstorm

Invoke the `superpowers:brainstorming` skill (via the Skill tool). Feed it the PRD contents and product context from `memory.json` as the task description. This explores the design space, considers alternatives, and identifies edge cases before committing to an approach.

### Step 2: Write Plan

Invoke the `superpowers:writing-plans` skill (via the Skill tool). Feed it the PRD and the brainstorming output. This produces a structured implementation plan with files to change, verification steps, and dependencies.

### Step 3: Execute Plan

Invoke the `superpowers:executing-plans` skill (via the Skill tool). This handles incremental execution with review checkpoints.

Read `${CLAUDE_SKILL_DIR}/prompts/execution.md` for additional execution constraints — specifically the validation rules, commit format, and stuck report format. These constraints apply on top of the executing-plans skill:

- **Commit format**: `Cycle {{cycle}} -- [short description] (PRD-{{prd_number}})`
- **Stuck report**: If you cannot resolve an issue after 10 attempts, write `.claude-operator/stuck.json` (see execution.md for schema) and stop.
- **Validation**: After implementation, go through EACH numbered requirement in the PRD and verify PASS/FAIL with evidence. Run any existing test suite. All tests must pass before committing.
- **Scope**: Do NOT add features, refactoring, or improvements beyond what the PRD specifies.

### Step 4: Process Result

If execution succeeded (commit was made):
- Output: "Transitioning to Update Memory Phase..."
- Record the per-requirement verification results, approach deviations, and lessons learned for use in the Update Memory phase.
- Proceed to Update Memory phase (same session)

If `.claude-operator/stuck.json` was created:
- The launcher will detect this and pause. Exit.

---

## Update Memory Phase

Output: "**Update Memory** — recording cycle results"

### Step 1: Annotate the PRD with Outcome

Read the execution subagent's result (specifically `requirements_verification`, `approach_deviations`, and `lessons_learned`). Append an `## Outcome` section to the PRD file:

```markdown
## Outcome (Cycle N)

- **Status**: completed | partial | deviated
- **Requirements**: N of M passed
  - [For any descoped/failed requirements: "Req N: descoped/failed — reason"]
- **Approach deviations**: [from approach_deviations, or "None"]
- **Lessons learned**: [from lessons_learned, or "None"]
```

Use `completed` if all requirements passed. Use `partial` if any were descoped. Use `deviated` if the technical approach changed significantly.

This turns PRDs from planning-only documents into full lifecycle records.

### Step 2: Update memory.json

Based on the execution result:
- Add the new feature to `features` array
- Add to `feature_history` with source and cycle
- Remove relevant items from `known_gaps`
- Add to `past_decisions` — include a `lessons` field if `lessons_learned` was non-empty
- Update any experiments

### Step 3: Update backlog.json

- Mark the completed item as "completed"
- If the execution surfaced new concerns, add them as new backlog items

### Step 4: Write Cycle Log

Write a summary to `.claude-operator/logs/cycle-NNN.json` with:
- cycle number, timestamp
- research findings summary
- proposed idea
- user feedback (from collaborate phase)
- PRD filename
- execution result (include `requirements_verification`, `approach_deviations`, and `lessons_learned` from the subagent output)
- files changed, tests added
- commit hash
- validation notes
- memory updates made

### Step 5: Commit All Changes

Stage ALL changes — both code changes from execution AND `.claude-operator/` state files (memory, backlog, logs, PRDs). Commit with this exact format:

```
Cycle N -- [short description] (PRD-NNN)
```

Where N is the cycle number. Example: `Cycle 3 -- add progress indicators (PRD-003)`.

If the execution subagent already committed code changes, amend that commit to also include `.claude-operator/` and use the correct message format. Every cycle MUST produce exactly one commit with this format.

### Step 6: Reset and Exit

Update `state.json`:
- Increment `cycle`
- Set `phase` to "research"
- Clear `current_prd`
- Set `last_completed` to current ISO timestamp

Output to the user: "Cycle N complete. Run /decide to start the next cycle." (where N is the cycle number that just finished).

Output: "Transitioning to Research Phase..."

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
