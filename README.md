# Claude Decide

Autonomous product operator for Claude Code -- researches your codebase, generates PRDs, and builds improvements in continuous cycles.

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

## Quick Start

Open Claude Code in any project directory and run:

```
/decide
```

On first run, the operator analyzes your repo and walks you through a short onboarding interview to understand your product, priorities, and constraints. After that, it begins its first research cycle.

## Invocation Modes

### `/decide` -- Interactive (default)

Runs one operator cycle at a time. You review and approve PRDs before execution, and re-invoke `/decide` between cycles.

```
/decide
```

### `/decide force` -- Autonomous

Runs one full cycle without user interaction. PRDs are auto-approved, open questions are resolved by a subagent, and the collaboration phase is skipped.

```
/decide force
```

You can also run force mode from the terminal using the launcher script:

```bash
bash skills/decide/scripts/launcher.sh --force
bash skills/decide/scripts/launcher.sh --force --max-cycles 10
```

### `/decide-loop` -- Continuous

Runs `/decide force` in a continuous loop within a single Claude Code session. Cycles run back-to-back until a stop condition is met.

```
/decide-loop              # run until stopped (default max: 50 cycles)
/decide-loop 10           # run 10 cycles then stop
```

To stop gracefully between cycles:

```bash
touch .claude-operator/stop
```

## Operator Cycle Phases

Each cycle moves through these phases sequentially:

| Phase | What happens |
|-------|-------------|
| **Research** | Dispatches 7+ parallel subagents to audit code quality, find product gaps, check security, analyze market fit, and more. Synthesizes findings into a prioritized backlog. |
| **Propose** | Generates a full PRD for the highest-priority backlog item, then runs it through a 5-lens self-critique. |
| **Collaborate** | (Interactive mode only) Presents the PRD for your review. You can approve, request changes, reject, redirect, or ask for more research. |
| **Execute** | Dispatches a subagent to implement the PRD -- writes code, runs tests, and commits. Creates a `stuck.json` report if it can't resolve after 10 attempts. |
| **Update Memory** | Records results in `memory.json`, updates the backlog, writes a cycle log, and commits all state changes. |

In force mode, the Collaborate phase is skipped and PRDs are auto-approved.

## Project Structure

```
claude-decide/
  install.sh                          # copies skills to ~/.claude/skills/
  skills/
    decide/
      SKILL.md                        # full phase router and operator logic
      prompts/                        # prompt templates for subagents
        execution.md                  # execution subagent prompt
        onboarding-repo-analysis.md   # repo analysis prompt
        prd-template.md               # PRD generation template
        prd-critic.md                 # 5-lens PRD critique
        research-*.md                 # research agent prompts (7 standard)
        state-templates.md            # JSON schemas for state files
      scripts/
        launcher.sh                   # terminal launcher for force mode
    decide-loop/
      SKILL.md                        # continuous loop skill definition
```

When the operator runs in a target project, it creates a `.claude-operator/` directory:

```
your-project/
  .claude-operator/
    state.json       # current phase, cycle number, mode
    memory.json      # product context, features, constraints, decisions
    backlog.json     # prioritized improvement ideas
    prds/            # generated PRD documents
    logs/            # per-cycle result logs
    inputs/          # drop customer feedback, research, etc. here
    agents/          # custom .md research agent prompts
    experiments/     # experiment tracking
```

## Customization

**Custom research agents**: Add `.md` files to `.claude-operator/agents/` in your target project. Each file is used as a prompt template and dispatched alongside the 7 standard research agents during the Research phase.

**User inputs**: Drop any files (markdown, text, JSON) into `.claude-operator/inputs/` to feed external context -- customer feedback, competitor analysis, user interviews -- into the research phase.

## Stopping the Operator

- **Interactive mode**: Simply stop re-invoking `/decide`.
- **Force mode / Loop**: Run `touch .claude-operator/stop` from another terminal. The operator finishes the current cycle and exits.
- **Ctrl+C**: Stops the launcher immediately (force mode via terminal only).
- **Stuck**: If the execution subagent fails after 10 attempts, the operator pauses and waits for you to unblock it.

## License

See repository for license details.
