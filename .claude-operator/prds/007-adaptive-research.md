# PRD-007: Adaptive Research Agent Selection

## Objective

Dispatch only the research agents relevant to the current codebase and product stage, reducing from 7 mandatory agents to 3-5 per cycle, cutting cost and improving signal-to-noise.

## User Problem

Every research cycle dispatches all 7 agents regardless of context. A CLI tool gets security, CRUD, and mobile research that returns no useful findings. This wastes tokens and dilutes the signal from agents that are actually relevant.

## Target User

All users, especially those running multiple cycles where cumulative research cost adds up.

## Value

40-60% cost reduction per research cycle without quality loss. Better signal-to-noise ratio means higher quality backlog items. Directly addresses the code auditor and experimentation research findings.

## Scope (V1)

- During research, select 3-5 agents based on product stage and tech stack from memory.json
- Always include: code-auditor, product-gap (these are universally relevant)
- Conditionally include based on signals:
  - security: if the project has auth, user data, or API endpoints
  - market: if stage is "pre-launch" or "scaling"
  - customer-value: if stage is "live with users" or "scaling"
  - experimentation: if the project has feature flags, A/B testing, or analytics
  - analytics: if the project has event tracking or monitoring
- User inputs agent and custom agents are always dispatched if they have content (unchanged)
- Log which agents were selected and why in the cycle log

## Out of Scope

- User-configurable agent selection
- Dynamic agent creation
- Changing agent prompts based on context
- Removing any built-in agents

## Requirements

1. The Research Phase in SKILL.md selects agents based on memory.json product stage and tech stack
2. code-auditor and product-gap are always dispatched
3. Other agents are dispatched only if their relevance criteria match the current project
4. The selection logic is documented in SKILL.md with clear criteria per agent
5. The cycle log records which agents were dispatched and the selection rationale
6. User inputs agent and custom agents are unaffected by the selection logic
7. At least 3 agents are always dispatched (code-auditor + product-gap + at least 1 conditional)

## Technical Approach

Modify the Research Phase Step 2 in `SKILL.md`. Replace the "dispatch ALL research agents" instruction with a conditional selection step that reads memory.json and picks agents based on criteria.

## Risks

- Excluding an agent might miss important findings. Mitigation: always include the 2 most general agents, and the criteria for conditional agents are broad enough to include when in doubt.
- Selection logic could become stale as the product evolves. Mitigation: selection runs every cycle using current memory.json, so it adapts automatically.

## Open Questions

None.

## Experiment Plan

N/A — baseline efficiency improvement. Success metric: fewer agents dispatched per cycle without reducing the rate of actionable findings.

## Backlog Reference

- Source: BL-027
- Research agents that flagged this: code-auditor, experimentation
- Priority score: 0.72

## Outcome (Cycle 7)

- **Status**: completed
- **Requirements**: 7 of 7 passed
- **Approach deviations**: None
- **Lessons learned**: None
