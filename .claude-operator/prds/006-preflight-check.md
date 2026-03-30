# PRD-006: Pre-flight Check for Superpowers Dependency

## Objective

Verify that the superpowers skills (brainstorming, writing-plans, executing-plans) are available before starting the first operator cycle, so execution doesn't silently fail.

## User Problem

The Execute Phase depends on three superpowers skills. If a user installs claude-decide without the superpowers plugin, onboarding succeeds but the first execution cycle fails silently or produces poor results. There's no warning during onboarding.

## Target User

First-time users installing claude-decide who may not have the superpowers plugin installed.

## Value

Prevents a confusing first experience where onboarding works fine but execution fails. Catches the problem at the earliest possible moment.

## Scope (V1)

- During onboarding (after repo analysis, before user interview), check if the three required superpowers skills exist
- If missing, warn the user and provide installation instructions
- Do not block onboarding — warn and continue (the user may install superpowers before the first execute phase)

## Out of Scope

- Checking for superpowers on every cycle (too noisy)
- Auto-installing superpowers
- Checking for other optional dependencies

## Requirements

1. During onboarding, before the user interview, the operator checks for the existence of the superpowers:brainstorming, superpowers:writing-plans, and superpowers:executing-plans skills
2. If any are missing, the operator outputs a warning: "Warning: superpowers skills not found. The Execute Phase requires brainstorming, writing-plans, and executing-plans. Install the superpowers plugin before running your first cycle."
3. If all are present, no output (silent success)
4. The check does not block onboarding — it warns and continues
5. The check is added to the Onboarding Phase in SKILL.md only (no new files)

## Technical Approach

Add a new Step 1b between Step 1 (Repo Analysis) and Step 2 (Map Analysis to Onboarding Fields) in the Onboarding Phase of `SKILL.md`. The check attempts to detect whether the superpowers skills are available by checking for their files in `~/.claude/skills/` or by checking the available skills list.

## Risks

- Skills may be installed in non-standard locations. Mitigation: check the standard path and note it may differ.
- False positive warnings if skills are installed but named differently. Mitigation: check exact skill names.

## Open Questions

None.

## Experiment Plan

N/A — baseline reliability improvement.

## Backlog Reference

- Source: BL-026
- Research agents that flagged this: code-auditor
- Priority score: 0.75

## Outcome (Cycle 6)

- **Status**: completed
- **Requirements**: 5 of 5 passed
- **Approach deviations**: Used instruction-based check (check available skills list in system context) instead of file system probing. Simpler, zero new code.
- **Lessons learned**: None
