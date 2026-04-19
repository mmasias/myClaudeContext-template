#!/bin/bash

REPO=~/misRepos/myClaudeContext

# Verificar symlink antes de sincronizar
if [ ! -L ~/.claude/CLAUDE.md ] || [ ! -f ~/.claude/CLAUDE.md ]; then
    echo "[ERROR] ~/.claude/CLAUDE.md no es un symlink válido."
    echo "Ejecutar setup-claude-symlinks.sh antes de continuar."
    exit 1
fi

# Comprobar estado del remote
git -C "$REPO" fetch --quiet 2>/dev/null
local_ref=$(git -C "$REPO" rev-parse @ 2>/dev/null)
remote_ref=$(git -C "$REPO" rev-parse @{u} 2>/dev/null)
base_ref=$(git -C "$REPO" merge-base @ @{u} 2>/dev/null)

if [ "$local_ref" = "$remote_ref" ]; then
    echo "Ya sincronizado. Sin cambios remotos."
    exit 0
elif [ "$remote_ref" = "$base_ref" ]; then
    echo "Repo local por delante del remote — nada que bajar."
    exit 0
elif [ "$local_ref" != "$base_ref" ]; then
    echo "[ERROR] Repo divergido del remote — resolución manual necesaria."
    exit 1
fi

git -C "$REPO" merge --ff-only
