# Marketplace Publishing Design

## Summary

Make claude-decide discoverable via Claude Code plugin marketplace by enhancing plugin metadata, adding a self-hosted marketplace manifest, and updating installation docs.

## Approach

Approach B: Full metadata + marketplace.json, keep install.sh as alternative.

## Changes

### 1. `.claude-plugin/plugin.json`

Add these fields to existing JSON:
- `author`: `{ "name": "maxwhoppa" }`
- `repository`: `{ "type": "git", "url": "https://github.com/maxwhoppa/claude-decide.git" }`
- `homepage`: `"https://github.com/maxwhoppa/claude-decide"`
- `keywords`: `["autonomous", "operator", "prd", "product", "research", "continuous-improvement", "code-audit"]`

### 2. `.claude-plugin/marketplace.json` (new)

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
      "author": { "name": "maxwhoppa" }
    }
  ]
}
```

### 3. `README.md` Installation section

Restructure to lead with:
```
/plugin install maxwhoppa/claude-decide
```

Keep manual clone+install.sh as "Alternative: Manual Installation" subsection.

## Verification

- `plugin.json` parses as valid JSON with all required fields
- `marketplace.json` parses as valid JSON with correct schema
- README Installation section shows `/plugin install` first
