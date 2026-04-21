#!/bin/bash

REPO=~/misRepos/myClaudeContext

# ── Check mínimo antes de sincronizar ─────────────────
echo "Verificando integridad previa al pull..."

# ~/.claude/projects debe ser symlink válido
if [ -L ~/.claude/projects ] && [ -d ~/.claude/projects ]; then
    echo "[OK] ~/.claude/projects es symlink válido"
elif [ -d ~/.claude/projects ] && [ ! -L ~/.claude/projects ]; then
    echo "[ERROR] ~/.claude/projects es directorio real — memoria fuera del repo."
    echo "        Ejecutar setup-claude-symlinks.sh antes de continuar."
    exit 1
else
    echo "[ERROR] ~/.claude/projects no existe o está roto."
    echo "        Ejecutar setup-claude-symlinks.sh."
    exit 1
fi

# Estado del remote
git -C "$REPO" fetch --quiet
local_ref=$(git -C "$REPO" rev-parse @ 2>/dev/null)
remote_ref=$(git -C "$REPO" rev-parse @{u} 2>/dev/null)
base_ref=$(git -C "$REPO" merge-base @ @{u} 2>/dev/null)

if [ "$local_ref" = "$remote_ref" ]; then
    echo "[OK] Repo ya sincronizado — nada que bajar."
    exit 0
elif [ "$local_ref" != "$base_ref" ] && [ "$remote_ref" != "$base_ref" ]; then
    echo "[ERROR] Repo divergido del remote — resolución manual necesaria."
    exit 1
fi

echo "[OK] Actualizando..."
git -C "$REPO" merge --ff-only
