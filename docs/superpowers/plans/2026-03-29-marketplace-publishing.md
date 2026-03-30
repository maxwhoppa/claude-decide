# Marketplace Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make claude-decide fully discoverable and installable via the Claude Code plugin marketplace.

**Architecture:** Edit 2 existing files (plugin.json, README.md) and create 1 new file (marketplace.json). All changes are metadata/documentation — no code logic.

**Tech Stack:** JSON, Markdown

---

### Task 1: Enhance plugin.json with marketplace metadata

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Update plugin.json with all required fields**

Replace the entire file content with:

```json
{
  "name": "claude-decide",
  "description": "Claude Operator — an autonomous continuous product builder that researches, plans, and executes improvements to any codebase.",
  "version": "0.1.0",
  "skills": "./skills/",
  "author": {
    "name": "maxwhoppa"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/maxwhoppa/claude-decide.git"
  },
  "homepage": "https://github.com/maxwhoppa/claude-decide",
  "keywords": [
    "autonomous",
    "operator",
    "prd",
    "product",
    "research",
    "continuous-improvement",
    "code-audit"
  ]
}
```

- [ ] **Step 2: Validate JSON parses correctly**

Run: `python3 -c "import json; d=json.load(open('.claude-plugin/plugin.json')); assert 'author' in d and 'name' in d['author']; assert 'repository' in d and 'url' in d['repository']; assert 'keywords' in d and len(d['keywords']) >= 5; assert all(k in [kw for kw in d['keywords']] for k in ['autonomous','operator','prd','product','research']); print('PASS: all required fields present')"`

Expected: `PASS: all required fields present`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "feat: add marketplace metadata to plugin.json"
```

---

### Task 2: Create marketplace.json

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create the marketplace manifest**

Write `.claude-plugin/marketplace.json` with this content:

```json
{
  "name": "claude-decide-marketplace",
  "owner": {
    "name": "maxwhoppa"
  },
  "plugins": [
    {
      "name": "claude-decide",
      "source": ".",
      "description": "Claude Operator — an autonomous continuous product builder that researches, plans, and executes improvements to any codebase.",
      "version": "0.1.0",
      "author": {
        "name": "maxwhoppa"
      }
    }
  ]
}
```

- [ ] **Step 2: Validate JSON parses correctly**

Run: `python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); assert 'plugins' in d and len(d['plugins']) == 1; assert d['plugins'][0]['name'] == 'claude-decide'; print('PASS: marketplace.json valid')"`

Expected: `PASS: marketplace.json valid`

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat: add self-hosted marketplace manifest"
```

---

### Task 3: Update README installation section

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace the Installation section**

In `README.md`, replace the existing Installation section (lines 7-15) with:

```markdown
## Installation

In Claude Code, run:

```
/plugin install maxwhoppa/claude-decide
```

This installs the plugin with its skills (`decide` and `decide-loop`) directly into Claude Code.

### Alternative: Manual Installation

Clone the repo and run the install script to copy skills into `~/.claude/skills/`:

```bash
git clone https://github.com/maxwhoppa/claude-decide.git
cd claude-decide
bash install.sh
```
```

Keep all content after the original Installation section unchanged (Quick Start onwards).

- [ ] **Step 2: Verify README renders correctly**

Run: `head -30 README.md`

Expected: Installation section shows `/plugin install` as the primary method, followed by the manual alternative.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update installation to lead with plugin install"
```
