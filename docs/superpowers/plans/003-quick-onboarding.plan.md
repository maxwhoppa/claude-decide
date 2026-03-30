# Plan: PRD-003 Quick Onboarding Mode

## Goal
Replace the 11-question sequential interview in SKILL.md's Onboarding Phase with a repo-analysis-driven flow that presents inferred answers as an editable summary, reducing onboarding to 2-3 user exchanges.

## Files to Change
1. `skills/decide/SKILL.md` — modify Steps 2-3 of the Onboarding Phase

## Files NOT Changed (per PRD scope)
- `skills/decide/prompts/onboarding-repo-analysis.md` — reuse existing output as-is
- `skills/decide/prompts/state-templates.md` — no schema changes
- No other prompt files

## Implementation Steps

### Step 1: Rewrite Step 2 (Present Hypothesis → Present Pre-filled Summary)
- After repo analysis completes, map each analysis output field to the corresponding memory.json fields
- Assign confidence levels (high/medium/low) per field based on signal quality
- Present a structured summary table showing all 11 onboarding fields with inferred values and confidence indicators

### Step 2: Rewrite Step 3 (User Interview → Confirm & Correct)
- Replace the 11 sequential questions with a single summary presentation
- Ask the user to review, confirm, or correct any fields
- For low-confidence or missing fields, ask targeted follow-up questions (max 4)
- Add fallback: if repo analysis returns no usable signal, fall back to original 11-question flow

### Step 3: Verify
- Read the modified SKILL.md and verify all 8 requirements are met
- Ensure Steps 1, 4, 5 of Onboarding remain unchanged
- Ensure no other phases are affected

### Step 4: Copy & Commit
- Copy SKILL.md to ~/.claude/skills/decide/SKILL.md
- Commit repo files only
