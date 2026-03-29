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
