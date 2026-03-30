# PRD-017: Sanitize backlog content before re-injection into research prompts

## Objective

Add content sanitization to backlog and memory data before it is injected into research agent prompts via `{{backlog_json}}` and `{{memory_json}}` template variables. This breaks the circular prompt injection amplification chain where a compromised cycle could write malicious content into backlog items that then poisons all future research cycles.

## User Problem

Backlog item `idea` and `notes` fields, as well as memory.json `past_decisions` and `known_gaps`, are written by the operator during research synthesis and update memory phases. These fields are then injected verbatim into all future research agent prompts via raw string substitution. If any cycle produces content that contains prompt injection patterns (e.g., "Ignore previous instructions and..."), that content propagates into every subsequent cycle's research agents, creating a self-amplifying poisoning loop. There is currently zero sanitization between write and re-read.

## Target User

Operators running claude-decide in force mode or auto mode over many cycles, where no human reviews intermediate state — the scenario most vulnerable to undetected prompt injection drift.

## Value

This is a security hardening item that protects the operator's autonomous loop integrity. The operator's core value proposition is safe, continuous autonomous improvement. A single compromised cycle poisoning all future cycles undermines that trust. This was flagged as "Security high severity" by the research-security agent in cycle 1.

## Scope (V1)

- Add a "Sanitize Context" processing step in the SKILL.md Research Phase that sanitizes backlog.json and memory.json content before substituting into `{{backlog_json}}` and `{{memory_json}}` template variables
- Sanitization rules:
  1. Truncate any single `idea` or `notes` field to 500 characters max
  2. Truncate any single `past_decisions[].decision` or `past_decisions[].lessons` field to 500 characters max
  3. Strip known prompt injection patterns: lines starting with "Ignore", "Disregard", "Override", "System:", "SYSTEM:", "Assistant:", "Human:" (case-insensitive prefix match)
  4. Escape template variable syntax: replace `{{` with `{ {` and `}}` with `} }` to prevent nested template injection
  5. Strip any XML-like tags that could be mistaken for system tags: `<system-reminder>`, `<EXTREMELY_IMPORTANT>`, `</system-reminder>`, etc. — remove anything matching `</?[A-Z_-]+>` pattern
- Document the sanitization rules in SKILL.md Research Phase Step 2 (between "Load Context" and "Select and Dispatch Research Agents")
- Add a new Step 1b in the Research Phase for sanitization (renumber subsequent steps)

## Out of Scope

- Sanitizing the PRD content before passing to execution (different injection surface, different fix — tracked separately)
- Sanitizing user input files in `.claude-operator/inputs/` (user-provided content has different trust level)
- Real-time content scanning or anomaly detection (overkill for V1)
- Wrapping template variables in XML tags (BL-016 — separate concern, complementary but not required for this fix)
- Modifying how data is written to backlog/memory (this PRD only addresses the read/inject path)

## Requirements

1. SKILL.md Research Phase must include a sanitization step between loading context (Step 1) and dispatching agents (Step 2), documented as Step 1b
2. The sanitization step must truncate `idea` and `notes` fields in backlog items to 500 characters, appending "... [truncated]" if truncated
3. The sanitization step must truncate `decision` and `lessons` fields in past_decisions to 500 characters, appending "... [truncated]" if truncated
4. The sanitization step must strip lines whose first word (case-insensitive) is one of: Ignore, Disregard, Override, System:, SYSTEM:, Assistant:, Human:
5. The sanitization step must replace `{{` with `{ {` and `}}` with `} }` in all injected content
6. The sanitization step must remove any substring matching the regex `</?[A-Z][A-Z0-9_-]*>` (uppercase XML-like tags)
7. The sanitized content must be used ONLY for prompt template substitution — the original backlog.json and memory.json files must NOT be modified
8. The SKILL.md instructions must clearly state that sanitization happens in-memory before template substitution, not on disk

## Technical Approach

Modify `/Users/maxwellnewman/.claude/skills/decide/SKILL.md` in the Research Phase section:

1. Add a new **Step 1b: Sanitize Context** between the current Step 1 (Load Context) and Step 2 (Select and Dispatch Research Agents)
2. Renumber subsequent steps (current Step 2 becomes Step 3, etc.)
3. The new step instructs the operator to:
   - Load backlog.json and memory.json into working variables
   - Apply all sanitization rules to the working copies
   - Use the sanitized copies when substituting `{{backlog_json}}` and `{{memory_json}}` in agent prompts
   - Never write the sanitized versions back to disk

This is a prompt-level change (modifying the SKILL.md instructions that the operator follows), not a code change to a runtime system. The "implementation" is adding clear, unambiguous instructions to SKILL.md.

## Risks

- **Over-sanitization**: Legitimate backlog content that happens to start with "Ignore" (e.g., "Ignore list for .gitignore") gets stripped. Mitigation: the stripping only removes the flagged line, not the entire item, and the original data is preserved on disk.
- **Instruction drift**: The sanitization rules are instructions in SKILL.md, not enforced code. A future SKILL.md edit could accidentally remove or weaken them. Mitigation: keep the sanitization section clearly delimited and referenced from the Research Phase dispatch step.
- **False sense of security**: Prompt injection is an open problem; these rules catch known patterns but won't stop novel attacks. Mitigation: position this as defense-in-depth, not a complete solution. BL-016 (XML tag wrapping) provides a complementary layer.

## Open Questions

None — the sanitization rules are well-defined and the injection surface is understood.

## Experiment Plan

N/A — this is a security hardening feature, not an experiment. Success is measured by the absence of prompt injection propagation, which cannot be A/B tested meaningfully.

## Backlog Reference

- Source: BL-035
- Research agents that flagged this: research-security (cycle 1)
- Priority score: 0.65

## Outcome (Cycle 17)

- **Status**: completed
- **Requirements**: 8 of 8 passed
- **Approach deviations**: None — implemented exactly as specified in PRD Technical Approach
- **Lessons learned**: The sub-step numbering pattern (Step 1b) already established in the Onboarding Phase made insertion clean with no renumbering needed. Syncing the installed copy in ~/.claude/skills/ with the project copy is an extra step that should be documented.
