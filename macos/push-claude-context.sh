#!/bin/bash

REPO=~/misRepos/myClaudeContext
REPO_PROJECTS=$REPO/projects
LOCAL_PROJECTS=~/.claude/projects
LINUX_USER=$(whoami)
MACOS_USER=$(whoami)

# ── Copiar dirs macOS (local) → dirs Linux (repo) ─────
for macos_dir in "$LOCAL_PROJECTS"/-Users-"$MACOS_USER"-*/; do
    [ -d "$macos_dir" ] || continue

    dirname=$(basename "$macos_dir")
    linux_dirname="${dirname/-Users-$MACOS_USER-/-home-$LINUX_USER-}"
    linux_dir="$REPO_PROJECTS/$linux_dirname"

    cp -r "$macos_dir" "$linux_dir"
    echo "Copiado: $dirname → $linux_dirname"
done

# ── Commit y push ──────────────────────────────────────
cd "$REPO"
git add -A
git commit -m "sync: estado sesión $(date '+%Y-%m-%d %H:%M')"
git push
push_status=$?

if [ $push_status -ne 0 ]; then
    echo "Push fallido — el repo puede estar en estado inconsistente. Revisar manualmente."
    exit 1
fi

# Tag de estado estable (fallback sin Claude activo)
TAG="memory-stable-$(date +%Y-%m-%d)"
git tag -f "$TAG"
git push origin "refs/tags/$TAG" --force
echo "Tag creado: $TAG"
