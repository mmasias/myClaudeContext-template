#!/bin/bash

REPO=~/misRepos/myClaudeContext

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
