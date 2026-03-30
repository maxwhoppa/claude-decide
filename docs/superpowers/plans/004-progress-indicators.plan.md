# Plan: PRD-004 — Progress Indicators for Long-Running Phases

## Objective

Add visible output instructions to SKILL.md so operators print concise status messages at phase entry, research dispatch/completion, and transitions.

## Insertion Points

### 1. Research Phase — Entry + Fast-Track (Req 1)
- **Location**: Step 0 already has fast-track output (line 164). Verified sufficient.
- **Addition**: After Step 1 (Load Context), before Step 2 (Dispatch), add: `Output: "**Research Phase** — Dispatching N research agents..."`
  - N is computed as 7 standard + 1 if inputs exist + count of custom agents.

### 2. Research Phase — Completion Summary (Req 2)
- **Location**: After Step 3 (Synthesize Results), add a one-line summary output.
- **Addition**: `Output: "Research complete — N findings, M new backlog items"`

### 3. Propose Phase — Entry (Req 3)
- **Location**: Start of Propose Phase Step 1.
- **Addition**: `Output: "**Propose Phase** — generating PRD for: [idea title]"`

### 4. Execute Phase — Entry (Req 4)
- **Location**: Start of Execute Phase Step 1.
- **Addition**: `Output: "**Execute Phase** — implementing [PRD title]..."`

### 5. Update Memory Phase — Entry (Req 5)
- **Location**: Start of Update Memory Phase.
- **Addition**: `Output: "**Update Memory** — recording cycle results"`

### 6. Phase Transition Markers (Req 6)
- **Location**: Before each phase transition (Research->Propose, Propose->Execute/Collaborate, Execute->UpdateMemory, UpdateMemory->Research).
- **Addition**: `Output: "Transitioning to [Phase] Phase..."`

### 7. Conciseness (Req 7)
- All output lines must be under 100 characters. Verified by inspection.

## Implementation Steps

1. Add "**Research Phase**" output + agent count at Research Step 1/2 boundary.
2. Add research completion summary after Step 3.
3. Add "**Propose Phase**" output at Propose Step 1 start.
4. Add "**Execute Phase**" output at Execute Step 1 start.
5. Add "**Update Memory**" output at Update Memory start.
6. Add transition markers before each phase transition call.
7. Verify all output lines < 100 characters.
8. Copy SKILL.md to ~/.claude/skills/decide/SKILL.md.
9. Run `bash -n` on launcher.sh to verify no syntax issues.
