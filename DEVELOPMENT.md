# Development

## Workflow

This repo is the source of truth for the `decide` and `decide-loop` skills. After making changes:

```bash
bash install.sh        # copies skills/ to ~/.claude/skills/
```

Do NOT manually copy files to `~/.claude/skills/` during development. Use `install.sh` to sync.

## Structure

- `skills/` — skill source files (copied to `~/.claude/skills/` by install.sh)
- `.claude-operator/` — per-project operator state (not part of the skill itself)
- `docs/superpowers/` — design specs and implementation plans
- `install.sh` — idempotent installer

## Running

```bash
/decide              # interactive mode (in Claude Code)
/decide force        # autonomous single cycle
/decide-loop         # continuous autonomous loop
```
