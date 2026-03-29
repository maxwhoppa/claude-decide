# Claude Operator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code skill that autonomously researches, proposes, and executes improvements to any codebase via a self-restarting cycle with on-disk state.

**Architecture:** A lightweight SKILL.md coordinator reads phase from `.claude-operator/state.json` and dispatches the appropriate action (onboarding, research, PRD generation, collaboration, or execution). Prompt templates in `prompts/` define each subagent's role. A launcher shell script manages the restart loop between cycles.

**Tech Stack:** Claude Code skill (Markdown), shell script (Bash), JSON state files.

---

## File Structure

```
claude-decide/
  .claude-plugin/
    plugin.json                              # Plugin manifest
  skills/
    claude-operator/
      SKILL.md                               # Main coordinator — reads state, routes to phase
      prompts/
        onboarding-repo-analysis.md          # Subagent: scan codebase, generate hypothesis
        research-code-auditor.md             # Subagent: find TODOs, incomplete features, tech debt
        research-product-gap.md              # Subagent: find missing workflows, UX gaps
        research-security.md                 # Subagent: find vulnerabilities, auth issues
        research-market.md                   # Subagent: competitor analysis, trends
        research-customer-value.md           # Subagent: revenue impact, user pain points
        research-experimentation.md          # Subagent: A/B test opportunities, hypotheses
        research-analytics.md               # Subagent: missing instrumentation, tracking gaps
        prd-critic.md                        # Instructions for 5-lens PRD self-critique
        execution.md                         # Subagent: implement PRD via superpowers pipeline
      scripts/
        launcher.sh                          # Restart loop with signal handling
  docs/
    superpowers/
      specs/
        2026-03-28-claude-operator-design.md # (already exists)
      plans/
        2026-03-28-claude-operator.md        # (this file)
```

---

### Task 1: Plugin Scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `skills/claude-operator/SKILL.md` (skeleton only)
- Create: `skills/claude-operator/prompts/` (empty directory)
- Create: `skills/claude-operator/scripts/` (empty directory)

- [ ] **Step 1: Create plugin manifest**

```json
{
  "name": "claude-decide",
  "description": "Claude Operator — an autonomous continuous product builder that researches, plans, and executes improvements to any codebase.",
  "version": "0.1.0",
  "skills": "./skills/"
}
```

Write to `.claude-plugin/plugin.json`.

- [ ] **Step 2: Create SKILL.md skeleton**

```markdown
---
name: claude-operator
description: Use when the user runs 'claude decide' or asks the operator to analyze, research, plan, or autonomously improve a codebase. Continuously operates as an autonomous product builder.
---

# Claude Operator

Autonomous continuous product builder. Reads `.claude-operator/state.json` to determine the current phase and executes it.

## Phases

This skill is a state machine. On each invocation, read the state and execute the matching phase.

(Full coordinator logic will be added in Task 9.)
```

Write to `skills/claude-operator/SKILL.md`.

- [ ] **Step 3: Create directory structure**

```bash
mkdir -p skills/claude-operator/prompts
mkdir -p skills/claude-operator/scripts
```

- [ ] **Step 4: Verify structure**

```bash
find . -not -path './docs/*' -not -path './.git/*' | head -20
```

Expected output should show `.claude-plugin/plugin.json`, `skills/claude-operator/SKILL.md`, and the `prompts/` and `scripts/` directories.

- [ ] **Step 5: Commit**

```bash
git init
git add .claude-plugin/plugin.json skills/claude-operator/SKILL.md
git commit -m "feat: scaffold claude-decide plugin with claude-operator skill skeleton"
```

---

### Task 2: Launcher Script

**Files:**
- Create: `skills/claude-operator/scripts/launcher.sh`

- [ ] **Step 1: Write the launcher script**

```bash
#!/bin/bash
# Claude Operator Launcher
# Manages the self-restart loop between operator cycles.
# Usage: bash launcher.sh [--force]

set -euo pipefail

MODE="default"
if [[ "${1:-}" == "--force" ]]; then
  MODE="force"
fi

# Trap signals so Ctrl+C kills the whole loop, not just the inner process
trap "echo ''; echo 'Operator stopped.'; exit 0" SIGINT SIGTERM

echo "Claude Operator starting in ${MODE} mode..."
echo "Press Ctrl+C to stop immediately."
echo "Run 'touch .claude-operator/stop' from another terminal to stop after the current cycle."
echo ""

while true; do
  # Check for graceful stop signal
  if [ -f .claude-operator/stop ]; then
    echo "Stop signal detected. Operator stopped gracefully."
    rm -f .claude-operator/stop
    exit 0
  fi

  # Check if operator is stuck
  if [ -f .claude-operator/stuck.json ]; then
    echo ""
    echo "============================================"
    echo "  OPERATOR IS STUCK"
    echo "  Run 'claude decide' to review and unblock."
    echo "============================================"
    echo ""
    # Wait until stuck.json is removed
    while [ -f .claude-operator/stuck.json ]; do
      sleep 5
      # Also check for stop signal while waiting
      if [ -f .claude-operator/stop ]; then
        echo "Stop signal detected while stuck. Operator stopped."
        rm -f .claude-operator/stop
        exit 0
      fi
    done
    echo "Unblocked. Resuming operator loop..."
    continue
  fi

  # Run one operator cycle
  if [[ "$MODE" == "force" ]]; then
    claude -p "You are Claude Operator. Read .claude-operator/state.json and execute the current phase. Mode: force (auto-approve PRDs, skip user collaboration). When the phase is complete, update state.json and exit."
  else
    claude -p "You are Claude Operator. Read .claude-operator/state.json and execute the current phase. Mode: default (pause for user collaboration at PRD stage). When the phase is complete, update state.json and exit."
  fi

  echo ""
  echo "Cycle complete. Starting next cycle..."
  echo ""
done
```

Write to `skills/claude-operator/scripts/launcher.sh`.

- [ ] **Step 2: Make it executable**

```bash
chmod +x skills/claude-operator/scripts/launcher.sh
```

- [ ] **Step 3: Verify syntax**

```bash
bash -n skills/claude-operator/scripts/launcher.sh
```

Expected: no output (no syntax errors).

- [ ] **Step 4: Commit**

```bash
git add skills/claude-operator/scripts/launcher.sh
git commit -m "feat: add operator launcher script with signal handling and stuck detection"
```

---

### Task 3: State File Templates

**Files:**
- Create: `skills/claude-operator/prompts/state-templates.md`

This file contains the JSON templates the operator uses to initialize `.claude-operator/` during onboarding. The SKILL.md will reference this file.

- [ ] **Step 1: Write state templates**

```markdown
# State File Templates

These are the initial JSON structures the operator writes during onboarding.

## state.json

Written after onboarding completes. Marks the first research cycle.

\```json
{
  "status": "running",
  "phase": "research",
  "cycle": 1,
  "mode": "default",
  "current_prd": null,
  "last_completed": null
}
\```

Fields:
- `status`: "running" | "paused"
- `phase`: "onboarding" | "research" | "propose" | "collaborate" | "execute" | "validate" | "update_memory"
- `cycle`: integer, increments after each complete cycle
- `mode`: "default" | "force"
- `current_prd`: filename of the PRD being executed (e.g., "003-rate-limiting.md"), or null
- `last_completed`: ISO timestamp of the last completed cycle

## memory.json

Written during onboarding from repo analysis + user interview.

\```json
{
  "product": {
    "name": "",
    "description": "",
    "stage": "",
    "customer": "",
    "problem": "",
    "revenue_model": ""
  },
  "features": [],
  "feature_history": [],
  "constraints": [],
  "assumptions": [],
  "known_gaps": [],
  "past_decisions": [],
  "experiments": []
}
\```

Fields:
- `product`: core product info from user interview
- `features`: list of strings — detected + confirmed features
- `feature_history`: array of `{ "feature": string, "source": string, "cycle": int }`
- `constraints`: things the operator must NOT do or must respect
- `assumptions`: things the operator believes but hasn't confirmed
- `known_gaps`: identified deficiencies in the codebase
- `past_decisions`: array of `{ "cycle": int, "decision": string, "prd": string }`
- `experiments`: array of experiment records

## backlog.json

Seeded during onboarding from user wishlist + detected gaps.

\```json
{
  "items": []
}
\```

Each item:
\```json
{
  "id": "BL-001",
  "idea": "Description of the idea",
  "source": "onboarding-wishlist | onboarding-detected | research-<agent-name> | user-redirect",
  "cycle_added": 0,
  "priority_score": 0.0,
  "status": "queued",
  "notes": null
}
\```

Statuses: "queued" | "proposed" | "completed" | "rejected"

## stuck.json

Written by the execution subagent when it cannot resolve after 10+ attempts.

\```json
{
  "cycle": 0,
  "prd": "",
  "attempts": 0,
  "last_error": "",
  "what_was_tried": [],
  "files_changed_so_far": [],
  "committed": false
}
\```

## Cycle Log (logs/cycle-NNN.json)

Written at the end of each cycle.

\```json
{
  "cycle": 0,
  "timestamp": "",
  "research_findings": {},
  "proposed_idea": "",
  "user_feedback": "",
  "prd": "",
  "execution_result": "success",
  "files_changed": [],
  "tests_added": 0,
  "commit": "",
  "validation_notes": "",
  "memory_updates": []
}
\```
```

Write to `skills/claude-operator/prompts/state-templates.md`.

Note: The `\``` ` above represents fenced code blocks inside the markdown file. When writing the actual file, use standard triple backticks.

- [ ] **Step 2: Commit**

```bash
git add skills/claude-operator/prompts/state-templates.md
git commit -m "feat: add state file templates for operator initialization"
```

---

### Task 4: Onboarding Repo Analysis Prompt

**Files:**
- Create: `skills/claude-operator/prompts/onboarding-repo-analysis.md`

- [ ] **Step 1: Write the repo analysis prompt**

```markdown
# Repo Analysis Subagent

You are analyzing a codebase to generate a product hypothesis for Claude Operator.

## Your Job

Scan this codebase thoroughly and produce a structured understanding of what this product is, what it does, and what state it's in.

## What to Scan

1. **Project structure** — run `find . -type f | head -200` and `ls -la` at root. Identify the framework, language, and organization pattern.
2. **Package files** — read `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml`, or equivalent. Note all dependencies.
3. **README and docs** — read `README.md` and any files in `docs/`. Extract product description, setup instructions, and stated goals.
4. **API routes / endpoints** — search for route definitions (`app.get`, `router.post`, `@app.route`, handler functions, etc.). List all endpoints found.
5. **Database schema / models** — search for schema definitions, migrations, model files, Prisma schema, SQLAlchemy models, etc. List all entities.
6. **Recent git history** — run `git log --oneline -50` to understand recent activity and development patterns.
7. **CI/CD config** — check for `.github/workflows/`, `Dockerfile`, `docker-compose.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.
8. **Test coverage** — look for test directories, test files, test configuration. Assess how much of the codebase is tested.
9. **TODOs and FIXMEs** — grep for `TODO`, `FIXME`, `HACK`, `XXX` across the codebase. These indicate known gaps.

## Output Format

Output a single JSON object:

```json
{
  "product_hypothesis": "One sentence describing what this product appears to be",
  "detected_features": ["feature 1", "feature 2"],
  "tech_stack": ["framework", "language", "database", "etc"],
  "architecture": "Brief description of how the code is organized",
  "detected_gaps": ["gap 1", "gap 2"],
  "maturity": "Brief assessment of code quality, test coverage, completeness",
  "todos_found": ["TODO: description (file:line)", "..."],
  "api_endpoints": ["GET /api/users", "POST /api/auth/login", "..."],
  "entities": ["User", "Project", "Task", "..."]
}
```

## Rules

- Be specific. Reference actual files and directories you found.
- Don't guess about things you can't find — only report what you observe.
- The `detected_features` list should describe user-facing capabilities, not technical components.
- The `detected_gaps` list should focus on things that appear incomplete, broken, or missing.
```

Write to `skills/claude-operator/prompts/onboarding-repo-analysis.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/claude-operator/prompts/onboarding-repo-analysis.md
git commit -m "feat: add onboarding repo analysis subagent prompt"
```

---

### Task 5: Research Agent Prompts

**Files:**
- Create: `skills/claude-operator/prompts/research-code-auditor.md`
- Create: `skills/claude-operator/prompts/research-product-gap.md`
- Create: `skills/claude-operator/prompts/research-security.md`
- Create: `skills/claude-operator/prompts/research-market.md`
- Create: `skills/claude-operator/prompts/research-customer-value.md`
- Create: `skills/claude-operator/prompts/research-experimentation.md`
- Create: `skills/claude-operator/prompts/research-analytics.md`

All 7 prompts share a common structure. Each receives product context and backlog as injected variables (marked with `{{variable}}`). The SKILL.md coordinator will read these templates and substitute the variables before dispatching.

- [ ] **Step 1: Write research-code-auditor.md**

```markdown
# Code Auditor Research Agent

You are a senior software engineer auditing a codebase for quality issues, incomplete implementations, and technical debt.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Analyze the codebase and find:

1. **Incomplete features** — code that starts something but doesn't finish it (half-built UIs, stubbed endpoints, commented-out logic)
2. **TODOs and FIXMEs** — grep for these markers and assess which ones represent real missing functionality
3. **Dead code** — unused functions, unreachable branches, deprecated modules still in the codebase
4. **Weak implementations** — code that works but is fragile, poorly structured, or will break under load
5. **Tech debt** — outdated dependencies, inconsistent patterns, duplicated logic, missing abstractions

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Be specific — reference actual file paths, function names, and line numbers
- Rank findings by impact (how much does this hurt the product or slow development?)
- Focus on things that matter to users or developers, not cosmetic issues

## Output

Return a JSON object:

```json
{
  "agent": "code-auditor",
  "findings": [
    {
      "title": "Short description",
      "detail": "What you found, with file:line references",
      "impact": "high | medium | low",
      "category": "incomplete | todo | dead_code | weak_impl | tech_debt"
    }
  ],
  "suggestions": [
    {
      "idea": "What should be done about it",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-code-auditor.md`.

- [ ] **Step 2: Write research-product-gap.md**

```markdown
# Product Gap Analyzer Research Agent

You are a product designer analyzing a codebase for missing user workflows, UX gaps, and incomplete user journeys.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Analyze the codebase from a user's perspective and find:

1. **Missing workflows** — actions a user would expect to do but can't (e.g., can create but not delete, can sign up but not reset password)
2. **Incomplete journeys** — flows that start but don't have proper completion, confirmation, or error states
3. **UX gaps** — missing loading states, no empty states, no pagination, poor mobile support
4. **Missing CRUD operations** — entities that have create but not update/delete, or vice versa
5. **Onboarding gaps** — is there a first-run experience? Does the user know what to do?

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Think like a user, not a developer — what would frustrate someone using this product?
- Be specific — reference the actual UI components, pages, or API endpoints involved
- Rank findings by user impact

## Output

Return a JSON object:

```json
{
  "agent": "product-gap-analyzer",
  "findings": [
    {
      "title": "Short description",
      "detail": "What's missing and where, with file references",
      "impact": "high | medium | low",
      "category": "missing_workflow | incomplete_journey | ux_gap | missing_crud | onboarding"
    }
  ],
  "suggestions": [
    {
      "idea": "What should be built",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-product-gap.md`.

- [ ] **Step 3: Write research-security.md**

```markdown
# Security Auditor Research Agent

You are a security engineer auditing a codebase for vulnerabilities, auth issues, and security best practice violations.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Analyze the codebase for security issues:

1. **Authentication weaknesses** — insecure password handling, missing session management, no MFA support, weak token generation
2. **Authorization gaps** — missing access controls, routes without auth middleware, privilege escalation paths
3. **Injection vulnerabilities** — SQL injection, XSS, command injection, path traversal
4. **Exposed secrets** — API keys, passwords, tokens in code or config files not in .gitignore
5. **OWASP Top 10** — check for common vulnerabilities: broken access control, cryptographic failures, insecure design, security misconfiguration, vulnerable components, etc.
6. **Rate limiting** — are there any protections against brute force or abuse?
7. **Data exposure** — are API responses leaking sensitive fields? Are errors exposing internals?

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Be specific — reference actual file paths, function names, and line numbers
- Rank by severity (how exploitable is this, and what's the blast radius?)
- Distinguish between critical (fix now) and advisory (fix eventually)

## Output

Return a JSON object:

```json
{
  "agent": "security-auditor",
  "findings": [
    {
      "title": "Short description",
      "detail": "What the vulnerability is, with file:line references",
      "severity": "critical | high | medium | low",
      "category": "auth | authz | injection | secrets | owasp | rate_limit | data_exposure"
    }
  ],
  "suggestions": [
    {
      "idea": "How to fix it",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-security.md`.

- [ ] **Step 4: Write research-market.md**

```markdown
# Market Research Agent

You are a market analyst researching the competitive landscape for a software product.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Research the market this product operates in:

1. **Competitors** — identify direct and indirect competitors. What do they offer that this product doesn't?
2. **Table-stakes features** — what features are considered baseline in this space? Does this product have them all?
3. **Differentiators** — what could this product do differently or better than competitors?
4. **Industry trends** — what new capabilities are emerging in this space? (AI features, collaboration, mobile-first, etc.)
5. **Pricing models** — how do competitors monetize? Does this product's revenue model align with market expectations?

Use web search to gather current information about competitors and trends.

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Ground suggestions in the product's current stage — don't suggest enterprise features for a pre-launch MVP
- Be specific about which competitor has which feature
- Rank suggestions by competitive impact

## Output

Return a JSON object:

```json
{
  "agent": "market-research",
  "findings": [
    {
      "title": "Short description",
      "detail": "What you found — competitor names, feature comparisons, trend analysis",
      "impact": "high | medium | low",
      "category": "competitor_gap | table_stakes | differentiator | trend | pricing"
    }
  ],
  "suggestions": [
    {
      "idea": "What this product should consider building or changing",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-market.md`.

- [ ] **Step 5: Write research-customer-value.md**

```markdown
# Customer Value Research Agent

You are a business analyst evaluating a product for customer value and revenue impact opportunities.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Analyze the product for high-leverage improvements:

1. **Revenue impact** — which features or improvements would most directly drive revenue? (conversion, retention, upsell)
2. **User pain points** — based on the product's state and target customer, what are the most likely frustrations?
3. **Retention drivers** — what would make users come back? What's missing that would reduce churn?
4. **Activation gaps** — is there a clear path from signup to value? What might cause users to drop off?
5. **Highest-value features** — which existing features are likely most valuable? Are they fully built out?

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Tie every suggestion back to a business outcome (revenue, retention, activation, etc.)
- Consider the product's stage — a pre-launch product needs different things than a scaling product
- Be specific about which user segment benefits and how

## Output

Return a JSON object:

```json
{
  "agent": "customer-value",
  "findings": [
    {
      "title": "Short description",
      "detail": "What opportunity you identified and why it matters",
      "impact": "high | medium | low",
      "category": "revenue | pain_point | retention | activation | feature_depth"
    }
  ],
  "suggestions": [
    {
      "idea": "What should be built or improved",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-customer-value.md`.

- [ ] **Step 6: Write research-experimentation.md**

```markdown
# Experimentation Research Agent

You are a growth engineer identifying opportunities for experiments, A/B tests, and hypothesis-driven development.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Identify experimentation opportunities:

1. **A/B test candidates** — features or flows where two variations could be tested (e.g., different onboarding flows, pricing page layouts, CTA copy)
2. **Behavioral hypotheses** — testable beliefs about user behavior (e.g., "users who complete profile setup are 2x more likely to return")
3. **Feature variations** — existing features that could be tested in different configurations
4. **Funnel experiments** — points in the user journey where a small change could measurably improve conversion
5. **Kill candidates** — features that might not be adding value and could be tested by removing them

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Every suggestion must include a clear hypothesis and how to measure the outcome
- Focus on experiments that are feasible given the current codebase
- Prefer small, fast experiments over large, slow ones

## Output

Return a JSON object:

```json
{
  "agent": "experimentation",
  "findings": [
    {
      "title": "Short description",
      "detail": "The experiment opportunity and what it would test",
      "impact": "high | medium | low",
      "category": "ab_test | hypothesis | feature_variation | funnel | kill_candidate"
    }
  ],
  "suggestions": [
    {
      "idea": "The experiment to run",
      "hypothesis": "If we [change], then [metric] will [improve/decrease] because [reason]",
      "measurement": "How to measure the outcome",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-experimentation.md`.

- [ ] **Step 7: Write research-analytics.md**

```markdown
# Analytics Research Agent

You are an analytics engineer identifying missing instrumentation, tracking gaps, and feedback loops in a product.

## Product Context

{{memory_json}}

## Current Backlog (DO NOT duplicate these)

{{backlog_json}}

## Your Job

Analyze the codebase for analytics and observability gaps:

1. **Missing event tracking** — key user actions that aren't being tracked (signups, feature usage, errors, conversions)
2. **No analytics infrastructure** — does the product have any analytics library integrated? If not, what should be added?
3. **Blind spots** — critical flows with no visibility (payment processing, API errors, background jobs)
4. **Missing dashboards** — what metrics should the team be watching that they can't currently see?
5. **Feedback loops** — is there any mechanism for users to provide feedback? Are errors being reported?
6. **Performance monitoring** — are response times, error rates, and resource usage being tracked?

## Rules

- DO NOT suggest anything already listed in the backlog or completed features
- Be specific about which events, metrics, or dashboards are missing
- Reference actual user flows and code paths that lack instrumentation
- Prioritize tracking that would inform product decisions

## Output

Return a JSON object:

```json
{
  "agent": "analytics",
  "findings": [
    {
      "title": "Short description",
      "detail": "What tracking is missing and where",
      "impact": "high | medium | low",
      "category": "event_tracking | infrastructure | blind_spot | dashboard | feedback | performance"
    }
  ],
  "suggestions": [
    {
      "idea": "What instrumentation to add",
      "effort": "small | medium | large",
      "impact": "high | medium | low"
    }
  ]
}
```
```

Write to `skills/claude-operator/prompts/research-analytics.md`.

- [ ] **Step 8: Commit all research prompts**

```bash
git add skills/claude-operator/prompts/research-*.md
git commit -m "feat: add all 7 research agent prompt templates"
```

---

### Task 6: PRD Critic Prompt

**Files:**
- Create: `skills/claude-operator/prompts/prd-critic.md`

- [ ] **Step 1: Write the PRD critic prompt**

```markdown
# PRD Self-Critique Instructions

After generating a PRD, run it through these 5 critique lenses in sequence. Each lens can modify the PRD. Track all changes made.

## Lens 1: Product Critic

Ask yourself:
- Is this actually necessary? Would the product suffer without it?
- Is the value claim honest and specific, or vague ("improves user experience")?
- Does this solve a real user problem or is it an engineering exercise?
- Is this the right priority given the product's current stage?

If the answer to any question is concerning, revise the relevant PRD sections.

## Lens 2: Scope Optimizer

Ask yourself:
- Is this truly the smallest useful version? Can any requirement be cut while still delivering value?
- Are there requirements that are "nice to have" masquerading as "must have"?
- Could we ship something simpler first and iterate?
- Does the "Out of Scope" section exist and is it specific?

Remove anything that isn't essential for V1. Move cut items to "Out of Scope" with a note about why.

## Lens 3: Risk Analyzer

Ask yourself:
- What could break in the existing codebase when we add this?
- Are there dependencies that might not be available or compatible?
- What are the second-order effects? (e.g., adding a feature creates a support burden)
- What's the rollback plan if this doesn't work?
- Could this introduce security vulnerabilities?

Add any new risks to the Risks section. If a risk is serious enough, revise the Technical Approach.

## Lens 4: Feasibility Check

Ask yourself:
- Does the Technical Approach actually align with the codebase's patterns?
- Are there existing utilities, components, or patterns we should reuse?
- Does this depend on infrastructure that doesn't exist yet?
- Can the requirements be implemented as described, or are any technically impossible?

Revise the Technical Approach to match reality. If a requirement is infeasible, flag it as an Open Question.

## Lens 5: Experimentation Enhancer

Ask yourself:
- Is there a testable hypothesis embedded in this feature?
- Can we measure whether this actually works after shipping?
- Could this be structured as an experiment (A/B test, feature flag, gradual rollout)?
- What does success look like in measurable terms?

Add or refine the Experiment Plan section. If the feature can't be measured, note that as a risk.

## Output

After all 5 passes, produce a summary of changes:

```json
{
  "prd_version": "vN",
  "iterations": [
    { "lens": "product_critic", "change": "description of what changed" },
    { "lens": "scope_optimizer", "change": "description of what changed" },
    { "lens": "risk_analyzer", "change": "description of what changed" },
    { "lens": "feasibility", "change": "description of what changed" },
    { "lens": "experimentation", "change": "description of what changed" }
  ]
}
```

If a lens found no issues, omit it from the iterations array.
```

Write to `skills/claude-operator/prompts/prd-critic.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/claude-operator/prompts/prd-critic.md
git commit -m "feat: add PRD self-critique prompt with 5 lenses"
```

---

### Task 7: Execution Prompt

**Files:**
- Create: `skills/claude-operator/prompts/execution.md`

- [ ] **Step 1: Write the execution subagent prompt**

```markdown
# Execution Subagent

You are implementing a PRD for Claude Operator. You have full autonomy to build, test, and commit.

## PRD to Implement

{{prd_contents}}

## Product Context

{{memory_json}}

## Constraints (DO NOT VIOLATE)

{{constraints}}

## Process

Follow this exact process:

1. **Brainstorm** — Use the superpowers brainstorming skill. Paste the full PRD above as your input. Answer all brainstorm questions yourself using the PRD and product context. Do NOT ask the user anything. You have all the information you need.

2. **Plan** — Use the superpowers writing-plans skill to create a detailed implementation plan from the brainstorm output.

3. **Execute** — Use the superpowers executing-plans skill to implement the plan step by step.

4. **Validate** — When implementation is complete, test what you built:
   - Run the project's existing test suite (if any)
   - Run any new tests you added
   - Start the dev server if applicable
   - Hit endpoints / simulate user flows
   - Verify the behavior matches the PRD requirements
   - Fix anything that's broken and re-test

5. **Commit** — When everything works, commit with a clear message:
   ```
   feat: [description] (PRD-NNN)
   ```

## Validation Rules

- You MUST actually test the code by running it, not just reason about whether it works
- If a test fails, fix it and re-test. Repeat until it passes.
- If you cannot resolve an issue after 10 attempts, stop and write a stuck report:

Write the following to `.claude-operator/stuck.json`:
```json
{
  "cycle": {{cycle}},
  "prd": "{{prd_filename}}",
  "attempts": <number of attempts>,
  "last_error": "<the error message>",
  "what_was_tried": ["attempt 1 description", "attempt 2 description", "..."],
  "files_changed_so_far": ["file1.ts", "file2.ts"],
  "committed": <true if you committed partial work, false otherwise>
}
```

Then exit. Do NOT continue trying.

## When Done

Output a JSON result:

```json
{
  "status": "success",
  "files_changed": ["path/to/file1", "path/to/file2"],
  "tests_added": <number>,
  "tests_passing": true,
  "commit": "<commit hash>",
  "validation_notes": "Description of how you validated the implementation"
}
```
```

Write to `skills/claude-operator/prompts/execution.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/claude-operator/prompts/execution.md
git commit -m "feat: add execution subagent prompt with validation and stuck detection"
```

---

### Task 8: PRD Template

**Files:**
- Create: `skills/claude-operator/prompts/prd-template.md`

- [ ] **Step 1: Write the PRD template**

```markdown
# PRD Template

Use this exact template when generating PRDs. Fill in every section. Do not leave any section empty or with placeholder text.

---

# PRD-{{number}}: {{title}}

## Objective

{{One paragraph: what we're building and why it matters right now.}}

## User Problem

{{The specific pain point, risk, or gap this addresses. Be concrete — "users can't X" not "improve the X experience".}}

## Target User

{{Who benefits from this. Be specific — "new users in their first session" not "all users".}}

## Value

{{Why this matters now, tied to the product's current priorities and stage. Reference the user's stated priorities from memory.json.}}

## Scope (V1)

{{Exactly what gets built. Bulleted list. Ruthlessly minimal — if it's not essential for the core value, it doesn't belong here.}}

## Out of Scope

{{What we're explicitly NOT doing in V1. Include things that were considered but cut, with brief reasoning.}}

## Requirements

{{Numbered list of concrete, testable requirements. Each requirement should be verifiable — "the endpoint returns 429 after 100 requests per minute" not "add rate limiting".}}

## Technical Approach

{{High-level implementation direction. Which files to modify, which patterns to follow, which libraries to use. Enough detail for Claude Code to execute without ambiguity.}}

## Risks

{{What could go wrong. Include technical risks, user impact risks, and integration risks.}}

## Open Questions

{{Anything unresolved that must be answered before execution. These MUST be resolved during the collaboration phase — execution cannot proceed with open questions.}}

## Experiment Plan

{{If applicable: what hypothesis this tests, what metric to watch, how to measure success. If not applicable, write "N/A — this is a baseline feature, not an experiment."}}

## Backlog Reference

- Source: {{backlog item ID or "new research finding"}}
- Research agents that flagged this: {{list of agents}}
- Priority score: {{0.00-1.00}}
```

Write to `skills/claude-operator/prompts/prd-template.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/claude-operator/prompts/prd-template.md
git commit -m "feat: add PRD template for operator-generated product specs"
```

---

### Task 9: SKILL.md Coordinator (Full Implementation)

**Files:**
- Modify: `skills/claude-operator/SKILL.md`

This is the core of the operator — the state machine coordinator that reads the current phase and executes it.

- [ ] **Step 1: Write the complete SKILL.md**

Replace the skeleton with the full coordinator:

```markdown
---
name: claude-operator
description: Use when the user runs 'claude decide' or asks the operator to analyze, research, plan, or autonomously improve a codebase. Continuously operates as an autonomous product builder that researches, generates PRDs, and executes improvements.
---

# Claude Operator

Autonomous continuous product builder. Each invocation executes one phase of the operator cycle, updates state, and exits.

## Quick Reference

```
ONBOARDING (first run) → RESEARCH → PROPOSE → COLLABORATE → EXECUTE → UPDATE MEMORY → EXIT → (restart)
```

## Phase Router

On every invocation:

1. Check if `.claude-operator/` exists. If not → **Onboarding Phase**.
2. Check if `.claude-operator/stuck.json` exists. If so → **Stuck Recovery Phase**.
3. Read `.claude-operator/state.json`. Execute the phase specified in `state.json.phase`.

---

## Onboarding Phase

Triggered when `.claude-operator/` directory does not exist.

### Step 1: Repo Analysis

Dispatch a subagent using the Agent tool:
- Read `skills/claude-operator/prompts/onboarding-repo-analysis.md` for the prompt
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

Read `skills/claude-operator/prompts/state-templates.md` for the JSON schemas.

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
- Read the corresponding prompt file from `skills/claude-operator/prompts/research-*.md`
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

Read `skills/claude-operator/prompts/prd-template.md` for the template.

Determine the next PRD number by counting existing files in `.claude-operator/prds/`.

Write a complete PRD for the candidate idea. Fill in every section using:
- The research findings from this cycle
- Product context from memory.json
- The backlog item details

Save to `.claude-operator/prds/NNN-feature-name.md`.

### Step 2: Self-Critique

Read `skills/claude-operator/prompts/prd-critic.md` for instructions.

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

Read `skills/claude-operator/prompts/execution.md` for the prompt template.

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
```

Write the complete content above to `skills/claude-operator/SKILL.md`, replacing the skeleton.

- [ ] **Step 2: Verify the file was written correctly**

```bash
wc -l skills/claude-operator/SKILL.md
```

Expected: approximately 250-300 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/claude-operator/SKILL.md
git commit -m "feat: implement full SKILL.md coordinator with all phases, state routing, and guardrails"
```

---

### Task 10: Integration Verification

**Files:**
- All files created in Tasks 1-9

- [ ] **Step 1: Verify complete file structure**

```bash
find . -not -path './.git/*' -not -path './docs/*' | sort
```

Expected:
```
.
./.claude-plugin
./.claude-plugin/plugin.json
./skills
./skills/claude-operator
./skills/claude-operator/SKILL.md
./skills/claude-operator/prompts
./skills/claude-operator/prompts/execution.md
./skills/claude-operator/prompts/onboarding-repo-analysis.md
./skills/claude-operator/prompts/prd-critic.md
./skills/claude-operator/prompts/prd-template.md
./skills/claude-operator/prompts/research-analytics.md
./skills/claude-operator/prompts/research-code-auditor.md
./skills/claude-operator/prompts/research-customer-value.md
./skills/claude-operator/prompts/research-experimentation.md
./skills/claude-operator/prompts/research-market.md
./skills/claude-operator/prompts/research-product-gap.md
./skills/claude-operator/prompts/research-security.md
./skills/claude-operator/prompts/state-templates.md
./skills/claude-operator/scripts
./skills/claude-operator/scripts/launcher.sh
```

- [ ] **Step 2: Verify all prompt templates have correct variable placeholders**

```bash
grep -r "{{" skills/claude-operator/prompts/ | grep -v "^Binary"
```

Expected: `{{memory_json}}`, `{{backlog_json}}`, `{{prd_contents}}`, `{{constraints}}`, `{{cycle}}`, `{{prd_filename}}`, `{{number}}`, `{{title}}` should appear in the appropriate files.

- [ ] **Step 3: Verify SKILL.md references all prompt files**

```bash
grep -c "prompts/" skills/claude-operator/SKILL.md
```

Expected: at least 10 references (one per prompt file).

- [ ] **Step 4: Verify launcher script is executable and syntactically valid**

```bash
bash -n skills/claude-operator/scripts/launcher.sh && echo "Syntax OK"
ls -la skills/claude-operator/scripts/launcher.sh | awk '{print $1}'
```

Expected: "Syntax OK" and permissions showing executable bit (`-rwxr-xr-x`).

- [ ] **Step 5: Verify plugin.json is valid JSON**

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json')); print('Valid JSON')"
```

Expected: "Valid JSON"

- [ ] **Step 6: Final commit**

```bash
git add -A
git status
```

If there are any uncommitted files, commit them:

```bash
git commit -m "chore: ensure all operator files are committed"
```

If everything is already committed, skip.
