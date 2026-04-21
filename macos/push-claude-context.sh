#!/bin/bash

REPO=~/misRepos/myClaudeContext
REPO_PROJECTS=$REPO/projects
LOCAL_PROJECTS=~/.claude/projects
LINUX_USER=$(whoami)
MACOS_USER=$(whoami)

# ── Copy macOS dirs (local) -> Linux dirs (repo) ──────
for macos_dir in "$LOCAL_PROJECTS"/-Users-"$MACOS_USER"-*/; do
    [ -d "$macos_dir" ] || continue

    dirname=$(basename "$macos_dir")
    linux_dirname="${dirname/-Users-$MACOS_USER-/-home-$LINUX_USER-}"
    linux_dir="$REPO_PROJECTS/$linux_dirname"

    cp -r "$macos_dir" "$linux_dir"
    echo "Copied: $dirname -> $linux_dirname"
done

# ── Commit and push ────────────────────────────────────
cd "$REPO"
git add -A
git commit -m "sync: session state $(date '+%Y-%m-%d %H:%M')"
git push
push_status=$?

if [ $push_status -ne 0 ]; then
    echo "Push failed — repo may be in an inconsistent state. Check manually."
    exit 1
fi

# Stable state tag (fallback when Claude is not active)
TAG="memory-stable-$(date +%Y-%m-%d)"
git tag -f "$TAG"
git push origin "refs/tags/$TAG" --force
echo "Tag created: $TAG"
