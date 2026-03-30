# PRD-003: Quick Onboarding Mode

## Objective

Reduce onboarding friction from 11 sequential questions to a repo-analysis-driven flow with 3-4 confirmations, so users can start their first cycle in under 2 minutes instead of 5-10.

## User Problem

Users must answer 11 mandatory questions before the operator does anything useful. Many answers can be inferred from the codebase (package.json, README, code structure). The sequential Q&A feels like a form, not a conversation, and is the biggest activation barrier.

## Target User

First-time users running `/decide` on an existing codebase.

## Value

The onboarding phase is the first impression. A slow, repetitive interview drives users away before they see value. This directly addresses the top activation barrier identified by the customer value and experimentation research agents. Priority: pre-launch — must ship before broader distribution.

## Scope (V1)

- Repo analysis subagent infers answers for all 11 questions (product name, customer, problem, revenue model, stage, priorities, constraints, concerns, no-touch areas, wishlist, git tracking)
- Present inferred answers as an editable summary instead of sequential questions
- User confirms or corrects the summary in a single conversational exchange
- Ask only 3-4 targeted follow-up questions for answers that couldn't be confidently inferred (low-confidence items)
- Fall back to full interview if repo analysis produces no usable signal (e.g., empty repo)

## Out of Scope

- Importing onboarding data from external files (covered by inputs/ folder)
- Multi-user onboarding or team context
- Re-onboarding / reset flow (separate backlog item BL-028)
- Changing the onboarding-repo-analysis.md agent prompt (reuse existing output)

## Requirements

1. The onboarding-repo-analysis subagent output is used to pre-fill all fields in memory.json that can be inferred
2. After repo analysis, the operator presents a structured summary showing each field and its inferred value, with a confidence indicator (high/medium/low) per field
3. Low-confidence fields (where the repo didn't provide enough signal) are explicitly marked and asked about as follow-up questions
4. The user can correct any field in the summary by responding conversationally ("customer is actually X, not Y")
5. The operator asks at most 4 follow-up questions (only for low-confidence or missing fields)
6. If the repo is empty or analysis returns no signal, fall back to the original 11-question flow
7. The final memory.json, backlog.json, and state.json are identical in structure to what the original flow produces
8. Total onboarding interaction is reduced to 2-3 exchanges (summary → corrections → confirmation) vs the original 11+ exchanges

## Technical Approach

Modify the **Onboarding Phase** in `SKILL.md`:
- Step 1 (Repo Analysis) stays the same
- Step 2 (Present Hypothesis) is expanded: instead of just showing the hypothesis, map each analysis output to the corresponding memory.json field and assign confidence
- Step 3 (User Interview) is replaced: present the full pre-filled summary, collect corrections, then ask only low-confidence follow-up questions
- Steps 4-5 stay the same

No changes to `onboarding-repo-analysis.md`, `state-templates.md`, or any other prompt files. This is purely a SKILL.md change to the onboarding flow.

## Risks

- Repo analysis may confidently infer wrong answers (e.g., guessing revenue model from a pricing page that's outdated). Mitigation: always show the summary for user confirmation.
- Users may skip reading the summary and confirm blindly. Mitigation: mark low-confidence items visually so they stand out.
- Edge case: repos with misleading signals (e.g., a fork where the README describes the upstream project). Mitigation: the user confirmation step catches this.

## Open Questions

None — the approach reuses existing repo analysis output and only changes the interview flow in SKILL.md.

## Experiment Plan

N/A — this is a baseline UX improvement, not an experiment. Success metric: onboarding completes in 3 or fewer user exchanges.

## Backlog Reference

- Source: BL-022
- Research agents that flagged this: customer-value, experimentation
- Priority score: 0.80

## Outcome (Cycle 3)

- **Status**: completed
- **Requirements**: 8 of 8 passed
- **Approach deviations**: None
- **Lessons learned**: The project has no test infrastructure — it's a pure prompt/skill definition repo with markdown and shell scripts only. The onboarding-repo-analysis.md agent output maps cleanly to all 11 onboarding fields, though some (like revenue model and git tracking preference) inherently have low confidence from repo analysis alone.
