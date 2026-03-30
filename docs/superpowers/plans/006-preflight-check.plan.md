# Pre-flight Superpowers Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a pre-flight check during onboarding that warns if required superpowers skills are missing.

**Architecture:** Add a new Step 1b to the Onboarding Phase in SKILL.md, between repo analysis and field mapping.

**Tech Stack:** Markdown (SKILL.md instruction changes only)

---

### Task 1: Add Pre-flight Check to Onboarding Phase

**Files:**
- Modify: `skills/decide/SKILL.md` (Onboarding Phase, between Step 1 and Step 2)

- [ ] **Step 1: Read current SKILL.md onboarding section**

Read the Onboarding Phase in `skills/decide/SKILL.md` to identify the exact insertion point — after Step 1 (Repo Analysis) and before Step 2 (Map Analysis to Onboarding Fields).

- [ ] **Step 2: Add Step 1b — Pre-flight Check**

Insert after Step 1 and before Step 2:

```markdown
### Step 1b: Pre-flight Check

Check if the following skills are available in your current session (they appear in the system reminders listing available skills):
- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:executing-plans`

If any are missing, output a warning:
```
Warning: Required superpowers skills not detected. The Execute Phase needs
brainstorming, writing-plans, and executing-plans. Install the superpowers
plugin before running your first cycle.
```

If all three are present, continue silently.

This check does NOT block onboarding — it warns and continues.
```

- [ ] **Step 3: Verify the change**

Read the modified SKILL.md and confirm:
1. Step 1b exists between Step 1 (Repo Analysis) and Step 2 (Map Analysis)
2. It checks for exactly three skills
3. It warns but does not block
4. The warning text is under 100 characters per line

- [ ] **Step 4: Sync to live skills**

```bash
cp skills/decide/SKILL.md ~/.claude/skills/decide/SKILL.md
```

- [ ] **Step 5: Commit**

```bash
git add skills/decide/SKILL.md docs/superpowers/plans/006-preflight-check.plan.md
git commit -m "Cycle 6 -- pre-flight superpowers check (PRD-006)"
```
