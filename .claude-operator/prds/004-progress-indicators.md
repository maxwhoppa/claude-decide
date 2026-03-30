# PRD-004: Progress Indicators for Long-Running Phases

## Objective

Add visible output during research agent dispatch and execution so users know the operator is working, not frozen.

## User Problem

During the research phase (7+ parallel agents) and execution phase, there is zero output. Users see nothing for minutes and assume the tool is broken or hung. This erodes trust and causes premature cancellation.

## Target User

All users running `/decide` in default or force mode, especially first-time users unfamiliar with the operator's phases.

## Value

Progress indicators are table-stakes UX for any long-running process. Without them, the operator feels broken during its two longest phases. This directly addresses the product gap and customer value research findings. Critical for pre-launch — no user will wait through minutes of silence.

## Scope (V1)

- Output a phase banner when entering each phase (e.g., "**Research Phase** — dispatching 7 research agents...")
- Output per-agent status during research dispatch (e.g., "  Dispatching: code-auditor, product-gap, security, market, customer-value, experimentation, analytics")
- Output a summary line when research agents return (e.g., "Research complete — 12 findings, 3 new backlog items")
- Output execution progress markers (e.g., "**Execute Phase** — implementing PRD-004...", "Brainstorming...", "Writing plan...", "Executing plan...")
- Output phase transition markers (e.g., "Transitioning to Propose Phase...")

## Out of Scope

- Real-time streaming or progress bars (Claude Code output is message-based, not streaming)
- Per-agent result summaries during research (too verbose)
- Time estimates or ETA predictions
- Spinner animations or terminal control codes

## Requirements

1. When entering the Research phase, the operator outputs "**Research Phase**" and either "Fast-tracking — backlog has N queued items" or "Dispatching N research agents..."
2. When research agents complete, the operator outputs a one-line summary with finding count and new backlog item count
3. When entering the Propose phase, the operator outputs "**Propose Phase** — generating PRD for: [idea title]"
4. When entering the Execute phase, the operator outputs "**Execute Phase** — implementing [PRD title]..."
5. When entering the Update Memory phase, the operator outputs "**Update Memory** — recording cycle results"
6. Phase transition markers appear between phases (e.g., "Transitioning to Execute Phase...")
7. All progress output is concise — no line exceeds 100 characters

## Technical Approach

Add output instructions to each phase section in `SKILL.md`. These are plain text outputs (not code changes) — the operator simply needs to be told to print status messages at specific points in the phase router.

Specifically:
- Research Phase: add output after Step 0 (fast-track check) and after Step 3 (synthesis)
- Propose Phase: add output at the start of Step 1
- Execute Phase: add output at the start of Step 1
- Update Memory Phase: add output at the start
- Transitions: add output before each phase transition

## Risks

- Verbose output could clutter the conversation. Mitigation: strict 100-char limit, one line per event.
- Force mode via launcher pipes output to terminal — progress indicators work there too (stdout).

## Open Questions

None.

## Experiment Plan

N/A — this is baseline UX, not an experiment.

## Backlog Reference

- Source: BL-023
- Research agents that flagged this: product-gap, customer-value
- Priority score: 0.78

## Outcome (Cycle 4)

- **Status**: completed
- **Requirements**: 7 of 7 passed
- **Approach deviations**: None
- **Lessons learned**: None
