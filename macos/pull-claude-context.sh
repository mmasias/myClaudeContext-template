#!/bin/bash

REPO=~/misRepos/myClaudeContext
REPO_PROJECTS=$REPO/projects
LOCAL_PROJECTS=~/.claude/projects
LINUX_USER=$(whoami)
MACOS_USER=$(whoami)

# ── Minimum check before syncing ──────────────────────
echo "Checking integrity before pull..."

# ~/.claude/projects must be a real directory (not a symlink) on macOS
if [ -d "$LOCAL_PROJECTS" ] && [ ! -L "$LOCAL_PROJECTS" ]; then
    echo "[OK] ~/.claude/projects is a real directory"
elif [ -L "$LOCAL_PROJECTS" ]; then
    echo "[ERROR] ~/.claude/projects is a symlink — on macOS it must be a real directory."
    echo "        Run setup-claude-symlinks.sh before continuing."
    exit 1
else
    echo "[ERROR] ~/.claude/projects does not exist."
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

# ── Copy Linux dirs (repo) -> macOS dirs (local) ──────
for linux_dir in "$REPO_PROJECTS"/-home-"$LINUX_USER"-*/; do
    [ -d "$linux_dir" ] || continue

    dirname=$(basename "$linux_dir")
    macos_dirname="${dirname/-home-$LINUX_USER-/-Users-$MACOS_USER-}"
    macos_dir="$LOCAL_PROJECTS/$macos_dirname"

    if [ -d "$macos_dir" ]; then
        read -p "Already exists: $macos_dirname. Overwrite? [y/N] " answer
        if [[ "$answer" =~ ^[yY]$ ]]; then
            rm -rf "$macos_dir"
        else
            echo "Skipped $macos_dirname — manual resolution pending."
            continue
        fi
    fi

    cp -r "$linux_dir" "$macos_dir"
    echo "Copied: $dirname -> $macos_dirname"
done
