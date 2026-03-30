#!/bin/bash
# Copies skill files from this repo into ~/.claude/skills/
# Run after cloning or pulling changes.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "Installing skills from $REPO_DIR to $SKILLS_DIR..."

# decide skill
mkdir -p "$SKILLS_DIR/decide/prompts" "$SKILLS_DIR/decide/scripts"
cp -R "$REPO_DIR/skills/decide/" "$SKILLS_DIR/decide/"

# decide-loop skill
mkdir -p "$SKILLS_DIR/decide-loop"
cp -R "$REPO_DIR/skills/decide-loop/" "$SKILLS_DIR/decide-loop/"

echo "Done. Skills installed:"
echo "  - decide"
echo "  - decide-loop"
