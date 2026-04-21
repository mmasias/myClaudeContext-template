#!/bin/bash

REPO=~/misRepos/myClaudeContext

# ── Minimum check before syncing ──────────────────────
echo "Checking integrity before pull..."

# ~/.claude/projects must be a valid symlink
if [ -L ~/.claude/projects ] && [ -d ~/.claude/projects ]; then
    echo "[OK] ~/.claude/projects is a valid symlink"
elif [ -d ~/.claude/projects ] && [ ! -L ~/.claude/projects ]; then
    echo "[ERROR] ~/.claude/projects is a real directory — memory is outside the repo."
    echo "        Run setup-claude-symlinks.sh before continuing."
    exit 1
else
    echo "[ERROR] ~/.claude/projects does not exist or is broken."
    echo "        Run setup-claude-symlinks.sh."
    exit 1
fi

# Remote state
git -C "$REPO" fetch --quiet
local_ref=$(git -C "$REPO" rev-parse @ 2>/dev/null)
remote_ref=$(git -C "$REPO" rev-parse @{u} 2>/dev/null)
base_ref=$(git -C "$REPO" merge-base @ @{u} 2>/dev/null)

if [ "$local_ref" = "$remote_ref" ]; then
    echo "[OK] Repo already in sync — nothing to pull."
    exit 0
elif [ "$local_ref" != "$base_ref" ] && [ "$remote_ref" != "$base_ref" ]; then
    echo "[ERROR] Repo diverged from remote — manual resolution required."
    exit 1
fi

echo "[OK] Updating..."
git -C "$REPO" merge --ff-only
