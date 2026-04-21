#!/bin/bash

REPO=~/misRepos/myClaudeContext
REPO_PROJECTS=$REPO/projects
LOCAL_PROJECTS=~/.claude/projects
LINUX_USER=$(whoami)
MACOS_USER=$(whoami)

# ── Check mínimo antes de sincronizar ─────────────────
echo "Verificando integridad previa al pull..."

# ~/.claude/projects debe ser directorio real (no symlink) en macOS
if [ -d "$LOCAL_PROJECTS" ] && [ ! -L "$LOCAL_PROJECTS" ]; then
    echo "[OK] ~/.claude/projects es directorio real"
elif [ -L "$LOCAL_PROJECTS" ]; then
    echo "[ERROR] ~/.claude/projects es symlink — en macOS debe ser directorio real."
    echo "        Ejecutar setup-claude-symlinks.sh antes de continuar."
    exit 1
else
    echo "[ERROR] ~/.claude/projects no existe."
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

# ── Copiar dirs Linux (repo) → dirs macOS (local) ─────
for linux_dir in "$REPO_PROJECTS"/-home-"$LINUX_USER"-*/; do
    [ -d "$linux_dir" ] || continue

    dirname=$(basename "$linux_dir")
    macos_dirname="${dirname/-home-$LINUX_USER-/-Users-$MACOS_USER-}"
    macos_dir="$LOCAL_PROJECTS/$macos_dirname"

    if [ -d "$macos_dir" ]; then
        read -p "Ya existe $macos_dirname. ¿Sobreescribir? [s/N] " respuesta
        if [[ "$respuesta" =~ ^[sS]$ ]]; then
            rm -rf "$macos_dir"
        else
            echo "Omitido $macos_dirname — resolución manual pendiente."
            continue
        fi
    fi

    cp -r "$linux_dir" "$macos_dir"
    echo "Copiado: $dirname → $macos_dirname"
done
