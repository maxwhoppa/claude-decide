---
name: claude-operator
description: Use when the user runs 'claude decide' or asks the operator to analyze, research, plan, or autonomously improve a codebase. Continuously operates as an autonomous product builder.
---

# Claude Operator

Autonomous continuous product builder. Reads `.claude-operator/state.json` to determine the current phase and executes it.

## Phases

This skill is a state machine. On each invocation, read the state and execute the matching phase.

(Full coordinator logic will be added in Task 9.)
