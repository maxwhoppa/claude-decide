# PRD-005: README.md with Installation and Usage Guide

## Objective

Add a README.md so users landing on the GitHub repo can understand what claude-decide is, install it, and start using it within 60 seconds.

## User Problem

The repo has no README. Users who discover the project (via GitHub, sharing, or marketplace) have no way to understand what it does, how to install it, or how to use it without reading the skill source code directly.

## Target User

Developers discovering claude-decide for the first time via GitHub.

## Value

A README is the absolute minimum for any open-source project. Without it, the repo is effectively invisible — no one will try a tool they can't understand at a glance. Critical for pre-launch.

## Scope (V1)

- Project title and one-line description
- What it does (2-3 sentence overview)
- Installation instructions (using install.sh)
- Quick start guide (first /decide invocation)
- Available commands (/decide, /decide force, /decide-loop)
- How the cycle works (research → propose → collaborate → execute → update)
- Force mode and launcher.sh usage
- Project structure overview
- License mention (if applicable)

## Out of Scope

- Contributing guide
- Detailed API documentation
- Changelog
- Badges/shields
- Screenshots or GIFs (no visual UI to capture)

## Requirements

1. README.md exists at the repo root
2. README includes a one-line project description suitable for GitHub
3. README includes installation instructions referencing install.sh
4. README includes a quick start section showing how to run /decide
5. README documents all three invocation modes: /decide (interactive), /decide force (autonomous), /decide-loop (continuous)
6. README includes a brief explanation of the operator cycle phases
7. README includes the project directory structure showing skills/ and .claude-operator/
8. README is under 200 lines — concise, not exhaustive

## Technical Approach

Create `README.md` at the repo root. Reference existing files for accurate details:
- `skills/decide/SKILL.md` for phase descriptions and commands
- `skills/decide-loop/SKILL.md` for loop usage
- `skills/decide/scripts/launcher.sh` for force mode CLI usage
- `install.sh` for installation steps

## Risks

- README could become stale as the skill evolves. Mitigation: keep it high-level, point to SKILL.md for details.

## Open Questions

None.

## Experiment Plan

N/A — baseline documentation.

## Backlog Reference

- Source: BL-002
- Research agents that flagged this: onboarding-detected
- Priority score: 0.75

## Outcome (Cycle 5)

- **Status**: completed
- **Requirements**: 8 of 8 passed
- **Approach deviations**: None
- **Lessons learned**: None
