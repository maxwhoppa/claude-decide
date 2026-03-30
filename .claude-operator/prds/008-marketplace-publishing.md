# PRD-008: Marketplace-Ready Plugin Metadata and Installation

## Objective

Make claude-decide fully discoverable and installable via the Claude Code plugin system by enhancing plugin metadata, adding a self-hosted marketplace manifest, and updating documentation to promote the native `/plugin install` workflow over the legacy `install.sh` copy script.

## User Problem

Users cannot discover or install claude-decide through Claude Code's built-in plugin discovery mechanisms. The only installation path is cloning the repo and running a bash script, which bypasses version tracking, automatic updates, and marketplace browsing. This limits reach to users who already know about the project.

## Target User

Engineers and vibe coders who browse Claude Code marketplaces or search for productivity/automation plugins but haven't heard of claude-decide yet.

## Value

The product is pre-launch and open source with no revenue model — growth depends entirely on discoverability. Claude Code's plugin marketplace is the primary discovery channel. Without presence there, the tool is invisible to its target audience. This directly supports the product's pre-launch stage where adoption is the top priority.

## Scope (V1)

- Enhance `.claude-plugin/plugin.json` with `author`, `repository`, and `homepage` fields
- Create `.claude-plugin/marketplace.json` to enable self-hosted marketplace registration
- Update `README.md` installation section to lead with `/plugin install` and keep `install.sh` as an alternative
- Add a `keywords` field to `plugin.json` for search discoverability

## Out of Scope

- Submitting to `anthropics/claude-plugins-official` (manual process, not automatable via code)
- Adding plugin icons or screenshots (no visual assets exist yet)
- Deprecating or removing `install.sh` (still useful for development workflows)
- Auto-update mechanism beyond what the plugin system provides natively

## Requirements

1. `.claude-plugin/plugin.json` must contain `name`, `description`, `version`, `skills`, `author` (with `name` field), `repository` (with `type` and `url`), and `keywords` (array of strings)
2. `.claude-plugin/marketplace.json` must be valid and contain a `plugins` array with one entry for `claude-decide` including `name`, `source`, `description`, `version`, and `author`
3. `README.md` Installation section must list `/plugin install` as the primary method, with `install.sh` as an alternative
4. Running `/plugin install` from the repo root must work (verify `plugin.json` is valid by checking it parses as JSON with all required fields)
5. The `keywords` array must include at least: "autonomous", "operator", "prd", "product", "research"

## Technical Approach

1. **Edit `.claude-plugin/plugin.json`**: Add `author`, `repository`, `homepage`, and `keywords` fields to the existing JSON. Keep existing `name`, `description`, `version`, `skills` fields unchanged.

2. **Create `.claude-plugin/marketplace.json`**: New file following the marketplace schema with a single plugin entry referencing the current repo.

3. **Edit `README.md`**: Restructure the Installation section to lead with:
   ```
   /plugin install maxwhoppa/claude-decide
   ```
   Then keep the manual clone+install.sh as "Alternative: Manual Installation".

## Risks

- `marketplace.json` schema may have changed since research — verify against current Claude Code docs
- The GitHub username in installation commands must match the actual repo owner (confirmed: `maxwhoppa`)
- Plugin system may not support all metadata fields — non-standard fields are typically ignored gracefully

## Open Questions

None — resolved during propose phase:
- GitHub repo is `maxwhoppa/claude-decide` (confirmed via `git remote -v`)
- `marketplace.json` will omit `owner.email` for privacy — only `owner.name` is required

## Experiment Plan

N/A — this is a baseline distribution feature, not an experiment. Success can be measured post-publish by checking if the plugin appears in marketplace search results.

## Backlog Reference

- Source: BL-024
- Research agents that flagged this: research-market
- Priority score: 0.78

## Outcome (Cycle 8)

- **Status**: completed
- **Requirements**: 5 of 5 passed
- **Approach deviations**: None
- **Lessons learned**: None — straightforward metadata/docs change
