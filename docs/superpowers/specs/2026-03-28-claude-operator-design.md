# Claude Operator: Autonomous Continuous Product Builder

## Overview

Claude Operator is a Claude Code skill + on-disk state machine that autonomously improves any codebase it's pointed at. It runs in cycles — researching the codebase, generating and refining PRDs, collaborating with the user on what to build, executing via the superpowers pipeline, validating the result, and restarting with fresh context.

It is a general-purpose tool. You install it, point it at any project, and it starts operating as an autonomous founder/operator — understanding the product, deciding what to build next, and executing improvements with minimal human interaction.

## Commands

- `claude decide` — start the operator loop (default mode, pauses for user approval at PRD stage)
- `claude decide --force` — fully autonomous mode (skips user collaboration, auto-approves PRDs)
- `claude decide --stop` — graceful stop after current cycle finishes

## System Architecture

```
skills/claude-operator/
  SKILL.md                    # entry point — reads state, decides phase, dispatches
  prompts/
    research-code-auditor.md
    research-product-gap.md
    research-security.md
    research-market.md
    research-customer-value.md
    research-experimentation.md
    research-analytics.md
    prd-critic.md
    execution.md

.claude-operator/             # created in target project
  state.json                  # current phase, cycle count, flags
  memory.json                 # product knowledge, features, history
  backlog.json                # ranked idea queue
  stop                        # presence = graceful stop signal
  prds/
    001-feature-name.md       # numbered, named PRDs
  experiments/
    001-experiment-name.json  # experiment definitions and results
  logs/
    cycle-001.json            # per-cycle summary logs
```

## Lifecycle

### First Run: Onboarding

Triggered when `.claude-operator/` does not exist.

**Phase 1: Repo Analysis (automated)**

A subagent scans the codebase:
- File tree and project structure
- Package files / dependencies
- README, docs, existing specs
- API routes / endpoints
- Database schema / models
- Recent git history (last ~50 commits)
- CI/CD config
- Test coverage

Output: a product hypothesis.

```json
{
  "product_hypothesis": "A SaaS project management tool built with Next.js and Postgres",
  "detected_features": ["user auth", "project CRUD", "task assignments"],
  "tech_stack": ["Next.js", "TypeScript", "Prisma", "Postgres"],
  "architecture": "monorepo, API routes + React frontend",
  "detected_gaps": ["no tests", "no rate limiting", "TODO comments in auth flow"],
  "maturity": "early — limited test coverage, several incomplete features"
}
```

**Phase 2: User Interview (interactive)**

The operator presents its hypothesis first, then asks 10-15 questions. Questions adapt based on the hypothesis and user answers.

Core questions (always asked):
1. Is my hypothesis correct? What did I get wrong?
2. Who is your target customer?
3. What core problem does this solve for them?
4. How do you (or will you) make money?
5. What stage is the product at? (pre-launch / live with users / scaling)
6. What are your top 1-3 priorities right now?
7. Are there any hard technical constraints I should know about?
8. What areas of the codebase are you most concerned about?
9. Is there anything I should NOT touch?
10. What features or improvements are on your wishlist that haven't been built yet?
11. Should `.claude-operator/` be git-tracked?

Adaptive follow-ups (based on answers):
- If live with users: "What's your most common user complaint?"
- If pre-launch: "What's blocking launch?"
- If revenue exists: "What's your highest-value feature?"
- If constraints mentioned: deeper probing on each

After interview: writes `memory.json`, `backlog.json` (seeded with user's wishlist + detected gaps), `state.json` (phase: `research`), creates directory structure, and exits. Next cycle starts first research phase with fresh context.

### Subsequent Runs: Operator Cycle

```
RESEARCH → PROPOSE → COLLABORATE → EXECUTE → VALIDATE → UPDATE MEMORY → EXIT
                         ↑    ↓
                      redirect/refine
                      (stays in phase)
```

After completing a cycle, the operator writes state to disk, exits, and the launcher re-invokes with fresh context.

## Self-Restart Mechanism

A launcher script wraps the operator:

```bash
#!/bin/bash
trap "echo 'Operator stopped.'; exit 0" SIGINT SIGTERM

while true; do
  if [ -f .claude-operator/stop ]; then
    echo "Operator stopped gracefully."
    rm .claude-operator/stop
    exit 0
  fi
  claude -p "You are Claude Operator. Read .claude-operator/state.json and execute the current phase."
done
```

- **Ctrl+C** — kills everything immediately via trap
- **`claude decide --stop`** — writes stop file, current cycle finishes, launcher exits
- Each cycle runs in a fresh Claude Code session with full context budget

## State Management

### state.json

```json
{
  "status": "running",
  "phase": "research",
  "cycle": 4,
  "mode": "default",
  "current_prd": null,
  "last_completed": "2026-03-28T21:30:00Z"
}
```

Phases: `onboarding` | `research` | `propose` | `collaborate` | `execute` | `validate` | `update_memory`

After each cycle: phase resets to `research`, cycle increments.

### memory.json

```json
{
  "product": {
    "name": "...",
    "description": "...",
    "stage": "...",
    "customer": "...",
    "problem": "...",
    "revenue_model": "..."
  },
  "features": ["auth system", "API endpoints"],
  "feature_history": [
    { "feature": "auth system", "source": "onboarding", "cycle": 0 }
  ],
  "constraints": ["must support postgres", "do not touch billing module"],
  "assumptions": [],
  "known_gaps": ["no rate limiting", "no email notifications"],
  "past_decisions": [
    { "cycle": 1, "decision": "built rate limiting", "prd": "001-rate-limiting.md" }
  ],
  "experiments": []
}
```

### backlog.json

```json
{
  "items": [
    {
      "id": "BL-001",
      "idea": "Add rate limiting to API endpoints",
      "source": "research-security-auditor",
      "cycle_added": 2,
      "priority_score": 0.82,
      "status": "queued",
      "notes": "User confirmed this is important during cycle 2 collab"
    }
  ]
}
```

Statuses: `queued` | `proposed` | `completed` | `rejected`

Sources: research agents, onboarding wishlist, user redirects during collaboration.

### Cycle Logs

Each cycle writes a summary to `logs/cycle-NNN.json`:

```json
{
  "cycle": 4,
  "timestamp": "2026-03-28T21:30:00Z",
  "research_findings": { "code_auditor": "...", "security": "..." },
  "proposed_idea": "...",
  "user_feedback": "approved with changes",
  "prd": "004-rate-limiting.md",
  "execution_result": "success",
  "files_changed": ["src/middleware/rate-limit.ts"],
  "tests_added": 3,
  "commit": "abc123f",
  "validation_notes": "rate limiting verified at 100 req/min via curl loop",
  "memory_updates": ["added feature: rate limiting", "closed gap: no rate limiting"]
}
```

## Research System

Each cycle dispatches 7 subagents in parallel, each a standalone Claude Code instance.

| Agent | Focus | Example Finding |
|-------|-------|-----------------|
| Code Auditor | Incomplete features, TODOs, dead code, weak implementations, tech debt | "auth flow has TODO for password reset — never implemented" |
| Product Gap Analyzer | Missing workflows, UX gaps, incomplete user journeys | "users can create projects but can't archive or delete them" |
| Security Auditor | Vulnerabilities, auth issues, exposed secrets, OWASP concerns | "API endpoints have no rate limiting" |
| Market Research | Competitors, feature comparisons, industry trends | "competitor X launched collaborative editing — table stakes" |
| Customer Value | Revenue impact, user pain points, highest-leverage improvements | "onboarding flow improvements would have highest retention impact" |
| Experimentation | Hypotheses to test, A/B test opportunities | "could A/B test simplified vs wizard signup flow" |
| Analytics | Missing instrumentation, tracking gaps, feedback loops | "no event tracking on core user actions" |

Each agent receives:
- Product context from `memory.json`
- Current backlog from `backlog.json`
- Specific research questions for its role
- Instruction to not suggest anything already in the backlog or completed features
- Instruction to be specific (reference files, functions, line numbers)
- Instruction to rank findings by impact

After all 7 return, the operator synthesizes:
1. Deduplicates across agents
2. Cross-references against backlog and completed features
3. Adds new findings to backlog with priority scores
4. Picks highest-impact item as candidate for this cycle's PRD

**Priority scoring** — the operator reasons about:
- How many agents flagged it (convergence signal)
- Alignment with user's stated priorities
- Estimated effort vs. impact
- Dependencies (does it unblock other backlog items?)

No algorithm — the operator assigns a 0-1 score based on judgment.

**Meta-research fallback:** If 3 consecutive cycles produce no new findings (all duplicates of existing backlog), the operator enters meta-research mode — a single subagent asks "how can we find better ideas?" and suggests new research angles, prompt improvements, or recommends pausing until the codebase changes.

## PRD Generation & Iteration

### Generation

The operator writes a PRD to `.claude-operator/prds/NNN-feature-name.md` using a fixed template:

```markdown
# PRD-NNN: Feature Name

## Objective
What we're building and why.

## User Problem
The specific pain point or risk this addresses.

## Target User
Who benefits.

## Value
Why this matters now — tied to product priorities.

## Scope (V1)
Exactly what gets built. Ruthlessly minimal.

## Out of Scope
What we're explicitly NOT doing.

## Requirements
Numbered list of concrete, testable requirements.

## Technical Approach
High-level implementation direction — enough for Claude Code
to execute without ambiguity.

## Risks
What could go wrong.

## Open Questions
Anything unresolved — must be answered during collaboration
before execution begins.

## Experiment Plan
If applicable — what hypothesis this tests, how to measure.

## Backlog Reference
- Source: BL-NNN
- Research agents that flagged this: [list]
- Priority score: N.NN
```

### Self-Critique (5 Lenses, Single Agent)

Before the user sees the PRD, the operator runs it through 5 critique passes in sequence:

1. **Product Critic** — Is this actually necessary? Is the value claim honest?
2. **Scope Optimizer** — Is this truly V1? Can anything be cut?
3. **Risk Analyzer** — Hidden risks? What could break? Second-order effects?
4. **Feasibility Check** — Does the technical approach work with this codebase?
5. **Experimentation Enhancer** — Can we make this more testable?

Each pass can modify the PRD. Changes are tracked:

```json
{
  "prd_version": "v3",
  "iterations": [
    { "lens": "scope_optimizer", "change": "removed webhook integration — not V1" },
    { "lens": "feasibility", "change": "switched to route-level — matches existing patterns" }
  ]
}
```

The user never sees v1. They see the refined version.

## Collaboration Phase

The operator presents the refined PRD conversationally:

```
Hey — I ran research across your codebase and here's what I think
we should build next:

**Rate Limiting for API Endpoints**

[conversational summary of the PRD]

Here's why this ranked highest:
- Security auditor and code auditor both flagged it
- Aligns with your priority of "harden before launch"
- Low effort, high impact

The full PRD is at .claude-operator/prds/005-rate-limiting.md

What do you think?
```

**User response handling:**

| User Says | Operator Does |
|-----------|--------------|
| "Yes, go for it" | Sets phase to `execute`, exits. Next cycle picks it up. |
| "Yes but change X" | Updates PRD, confirms change, proceeds to execute. |
| "No, not now" | Lowers priority in backlog, presents next highest item. |
| "No, work on X instead" | Adds/promotes X in backlog, generates PRD for X in this session. |
| "Do more research" | Marks findings as low-value, resets to research, exits. |
| "Tell me more about why" | Explains reasoning — research findings, trade-offs. |

The operator stays in this phase until it gets a clear approval or redirect. No timeout.

If redirected to a new idea, the operator generates and critiques a PRD for that idea within the same session — no restart needed.

Once approved: writes final PRD, sets `state.json` to execute phase with `current_prd`, exits. Next fresh-context cycle picks up execution.

**Force mode:** Skips collaboration entirely. Auto-approves after self-critique.

## Execution & Validation

The operator spawns a Claude Code subagent:

```
You have a PRD to implement. Here it is:

[full PRD contents]

Here is the product context:

[contents of memory.json]

Follow this process:
1. Use superpowers brainstorming — paste the full PRD in.
   Answer all brainstorm questions yourself using the PRD
   and product context. Do not ask the user anything.
2. Use superpowers writing-plans to create an implementation plan.
3. Use superpowers executing-plans to implement it.

When implementation is complete, test what you built.
Run the test suite, start the dev server if applicable,
hit the endpoints, verify the behavior works.
Fix anything that's broken. Repeat until it works.

When done, commit your work with a clear commit message
referencing the PRD number.
```

**Design decisions:**
- The execution subagent self-answers the brainstorm phase using the already-approved PRD. No user interaction.
- Full superpowers pipeline: brainstorm → write-plan → execute. No shortcuts.
- Validation is "test it" — the subagent decides how (run tests, curl endpoints, start the app). No custom validation framework.
- Fix loop: if validation fails, the subagent fixes and retests within the same session. It does not exit until the work is complete and validated.

**Execution result:**

```json
{
  "status": "success",
  "files_changed": ["src/middleware/rate-limit.ts", "src/routes/api.ts"],
  "tests_added": 3,
  "tests_passing": true,
  "commit": "abc123f",
  "validation_notes": "rate limiting verified at 100 req/min via curl loop"
}
```

There is no partial state. The subagent stays in its fix loop until done.

**Stuck detection:** If the subagent fails to resolve a validation issue after 10+ attempts, it stops and writes a detailed stuck report to `.claude-operator/stuck.json`:

```json
{
  "cycle": 4,
  "prd": "004-rate-limiting.md",
  "attempts": 12,
  "last_error": "connection refused on port 3000 — dev server won't start",
  "what_was_tried": ["reinstalled deps", "checked port conflicts", "..."],
  "files_changed_so_far": ["src/middleware/rate-limit.ts"],
  "committed": false
}
```

When the launcher detects `stuck.json`, it pauses the loop and waits for the user:

```bash
while true; do
  if [ -f .claude-operator/stop ]; then
    echo "Operator stopped gracefully."
    rm .claude-operator/stop
    exit 0
  fi
  if [ -f .claude-operator/stuck.json ]; then
    echo "Operator is stuck. Run 'claude decide' to review and unblock."
    # Wait until stuck.json is removed (user resolved it)
    while [ -f .claude-operator/stuck.json ]; do
      sleep 5
    done
    continue
  fi
  claude -p "..."
done
```

When the user re-engages, the operator presents the stuck report conversationally — what it tried, what failed, and where it needs help. Once the user helps resolve the blocker (or tells the operator to skip this PRD), the operator removes `stuck.json` and resumes the loop.

After execution, the operator:
1. Updates `memory.json` — adds new features, closes relevant gaps
2. Updates `backlog.json` — marks item as completed, adds any new concerns
3. Writes cycle log to `logs/cycle-NNN.json`
4. Resets `state.json` phase to `research`
5. Exits — launcher starts next cycle

## Guardrails

**Prevent duplicate work:**
- Every research finding is checked against `backlog.json` and `memory.json` features
- Every PRD candidate is checked against completed PRDs
- The execution subagent is told what already exists

**Prevent thrashing:**
- Finish the current PRD before starting a new one
- No mid-execution pivots — once execution starts, it runs to completion

**Prevent overbuilding:**
- Scope optimizer critique pass enforces V1 minimalism
- PRD template has explicit "Out of Scope" section
- Execution subagent builds exactly what's in the PRD, nothing more

**Prevent stale research:**
- Meta-research fallback after 3 consecutive cycles with no new findings
- Backlog items queued for 10+ cycles without being picked get flagged for review

**Respect forbidden areas:**
- Onboarding asks "Is there anything I should NOT touch?"
- Stored in `memory.json` constraints, passed to every subagent prompt

**Force mode safety:**
- `--force` skips collaboration but still runs full PRD critique loop
- Constraints are still enforced in force mode
