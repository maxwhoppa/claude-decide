# Post-Execution Satisfaction Signal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 1-5 satisfaction rating prompt to the Update Memory phase for default/auto modes, with data stored in cycle logs and memory.json.

**Architecture:** Two markdown files modified — SKILL.md gets a new Step 5b in the Update Memory Phase, state-templates.md gets satisfaction fields added to the cycle log and memory.json schemas.

**Tech Stack:** Markdown (instruction files)

---

### Task 1: Update state-templates.md Schema Documentation

**Files:**
- Modify: `skills/decide/prompts/state-templates.md:49-51` (memory.json template)
- Modify: `skills/decide/prompts/state-templates.md:108-122` (cycle log template)

- [ ] **Step 1: Add satisfaction_history to memory.json template**

In `skills/decide/prompts/state-templates.md`, in the memory.json JSON template block (around line 49), add `satisfaction_history` after `experiments`:

Replace:
```json
  "experiments": []
}
```

With:
```json
  "experiments": [],
  "satisfaction_history": []
}
```

- [ ] **Step 2: Add satisfaction_history to memory.json field docs**

In `skills/decide/prompts/state-templates.md`, after the line documenting `experiments` (around line 61), add:

After:
```markdown
- `experiments`: array of experiment records
```

Add:
```markdown
- `satisfaction_history`: array of `{ "cycle": int, "rating": int|null, "prd": string }` — tracks user satisfaction ratings per cycle
```

- [ ] **Step 3: Add satisfaction field to cycle log JSON template**

In `skills/decide/prompts/state-templates.md`, in the cycle log JSON template block (around line 121), add `satisfaction` after `memory_updates`:

Replace:
```json
  "memory_updates": []
}
```

With:
```json
  "memory_updates": [],
  "satisfaction": {
    "rating": null,
    "comment": null
  }
}
```

- [ ] **Step 4: Verify the changes**

Read `skills/decide/prompts/state-templates.md` and confirm:
- memory.json template includes `satisfaction_history: []`
- memory.json fields section documents `satisfaction_history`
- Cycle log template includes `satisfaction` object with `rating` and `comment`

- [ ] **Step 5: Commit**

```bash
git add skills/decide/prompts/state-templates.md
git commit -m "feat: add satisfaction schema to state-templates.md"
```

---

### Task 2: Add Step 5b to SKILL.md Update Memory Phase

**Files:**
- Modify: `skills/decide/SKILL.md:497-511` (between Step 5 and Step 6 of Update Memory Phase)

- [ ] **Step 1: Insert Step 5b between Step 5 and Step 6**

In `skills/decide/SKILL.md`, find the end of Step 5 (the line reading "If the execution subagent already committed code changes, amend that commit to also include `.claude-operator/` and use the correct message format. Every cycle MUST produce exactly one commit with this format.") and before Step 6 ("### Step 6: Reset and Exit"), insert the following:

```markdown

### Step 5b: Satisfaction Signal

If mode is "default" or "auto":
- Output: "Rate this cycle's output (1-5, or skip): "
- Wait for user input.
- Accept: integer 1-5, "skip", or empty input (treated as skip).
- If invalid input, re-prompt once: "Please enter 1-5 or skip: ". If still invalid, treat as skip.
- If a rating is provided, ask: "Any comment? (Enter to skip): "
- Store in the cycle log's `satisfaction` field: `{ "rating": N, "comment": "user's comment or null" }`
- Append to `memory.json`'s `satisfaction_history` array: `{ "cycle": N, "rating": N, "prd": "prd-filename" }`
- Amend the cycle commit to include the updated cycle log and memory.json.

If mode is "force" (or running in decide-loop):
- Do NOT prompt the user. Automatically store in the cycle log: `{ "rating": null, "comment": "force mode — skipped" }`
- Append to `memory.json`'s `satisfaction_history`: `{ "cycle": N, "rating": null, "prd": "prd-filename" }`
- Amend the cycle commit to include the updated files.
```

- [ ] **Step 2: Verify the changes**

Read `skills/decide/SKILL.md` around the Update Memory Phase and confirm:
- Step 5b exists between Step 5 (Commit All Changes) and Step 6 (Reset and Exit)
- The step has two branches: default/auto (interactive prompt) and force (auto-skip)
- The prompt text matches requirement 1: "Rate this cycle's output (1-5, or skip): "
- Invalid input handling matches requirement 2: re-prompt once, then skip
- Data storage matches requirements 3 and 4: cycle log satisfaction object + memory.json satisfaction_history

- [ ] **Step 3: Commit**

```bash
git add skills/decide/SKILL.md
git commit -m "feat: add satisfaction signal step to Update Memory phase"
```

---

### Task 3: Verification — Check All 6 PRD Requirements

**Files:**
- Read: `skills/decide/SKILL.md`, `skills/decide/prompts/state-templates.md`

- [ ] **Step 1: Verify each requirement**

Read both modified files and check:

1. **Req 1** (satisfaction prompt in default/auto modes): SKILL.md Step 5b first branch outputs "Rate this cycle's output (1-5, or skip): "
2. **Req 2** (accept 1-5, skip, empty; re-prompt once): SKILL.md Step 5b has re-prompt and fallback logic
3. **Req 3** (store in cycle log): SKILL.md Step 5b stores in `satisfaction` field; state-templates.md has the schema
4. **Req 4** (satisfaction_history in memory.json): SKILL.md Step 5b appends to array; state-templates.md has schema and docs
5. **Req 5** (force mode auto-skips): SKILL.md Step 5b second branch auto-stores with "force mode — skipped"
6. **Req 6** (decide-loop skips): SKILL.md Step 5b second branch covers "running in decide-loop"

- [ ] **Step 2: Final commit if needed**

If individual commits were missed, stage all:

```bash
git add skills/decide/SKILL.md skills/decide/prompts/state-templates.md
git commit -m "feat: post-execution satisfaction signal (PRD-010)"
```
