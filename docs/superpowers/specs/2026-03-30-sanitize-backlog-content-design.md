# Design: Sanitize Backlog Content Before Research Prompt Injection

**Date:** 2026-03-30
**PRD:** PRD-017
**Backlog:** BL-035

## Problem

Research agent prompts receive raw `{{backlog_json}}` and `{{memory_json}}` via string substitution. Malicious content in backlog items or memory fields propagates into all future research cycles, creating a circular prompt injection amplification chain.

## Approach

Add a "Sanitize Context" instruction step (Step 1b) to the SKILL.md Research Phase, between "Load Context" (Step 1) and "Select and Dispatch Research Agents" (Step 2). The operator creates sanitized in-memory copies of the data before template substitution.

This is an instruction-level change, not a code change. The operator (Claude) follows these rules when preparing agent prompts.

## Sanitization Rules

Applied to in-memory copies only. Original files are never modified.

1. **Field truncation**: Truncate `idea`, `notes`, `decision`, and `lessons` fields to 500 characters. Append "... [truncated]" if truncated.
2. **Injection pattern stripping**: Remove lines whose first word (case-insensitive) matches: Ignore, Disregard, Override, System:, SYSTEM:, Assistant:, Human:
3. **Template escape**: Replace `{{` with `{ {` and `}}` with `} }` to prevent nested template variable expansion.
4. **System tag removal**: Remove substrings matching `</?[A-Z][A-Z0-9_-]*>` (uppercase XML-like tags that could be mistaken for system directives).
5. **Application scope**: Apply rules to ALL injected content in Steps 2 through 4, including the meta-researcher prompt in the stagnation check.

## Injection Points Covered

- Step 2: All research agent dispatches (`{{backlog_json}}`, `{{memory_json}}`)
- Step 2: User inputs agent (`{{backlog_json}}`, `{{memory_json}}`)
- Step 2: Custom agents (`{{backlog_json}}`, `{{memory_json}}`)
- Step 4: Meta-researcher subagent (`[backlog]`, `[memory]`)

## Files to Modify

1. `/Users/maxwellnewman/.claude/skills/decide/SKILL.md` — Research Phase section only
   - Insert Step 1b between Step 1 and Step 2
   - Renumber Steps 2-5 to Steps 3-6
   - Update Step 3 (formerly Step 2) to reference sanitized copies
   - Update Step 5 (formerly Step 4, stagnation check) to reference sanitized copies

## Not Covered

- PRD content injection to execution agents (different surface)
- User input files in `.claude-operator/inputs/` (different trust level)
- XML tag wrapping (BL-016, complementary)

## Risks

- Over-sanitization of legitimate content starting with "Ignore" — mitigated by line-level granularity and disk preservation
- Instruction drift — mitigated by clear section delimitation
- Novel injection patterns — mitigated by defense-in-depth philosophy (this is one layer)
