#!/bin/bash

REPO=~/misRepos/myClaudeContext
PROYECTOS_DIR=~/misRepos/proyectos

# Asegurar que ~/.claude existe antes de crear symlinks
mkdir -p ~/.claude

# Global — Claude Code
ln -sf $REPO/global/CLAUDE.md ~/.claude/CLAUDE.md

# Global — Gemini CLI
mkdir -p ~/.gemini
if [ -L ~/.gemini/GEMINI.md ]; then
    rm ~/.gemini/GEMINI.md
elif [ -f ~/.gemini/GEMINI.md ]; then
    mv ~/.gemini/GEMINI.md ~/.gemini/GEMINI.md.bak
    echo "Backup de ~/.gemini/GEMINI.md existente → GEMINI.md.bak"
elif [ -d ~/.gemini/GEMINI.md ]; then
    echo "[ERROR] ~/.gemini/GEMINI.md es un directorio — resolución manual necesaria"
    exit 1
fi
ln -sf $REPO/global/CLAUDE.md ~/.gemini/GEMINI.md

# Proyectos y memoria interna de Claude Code
if [ -L ~/.claude/projects ]; then
    rm ~/.claude/projects
elif [ -d ~/.claude/projects ]; then
    rm -rf ~/.claude/projects
    echo "Eliminado ~/.claude/projects (directorio real) — reemplazado por symlink"
fi
ln -sf $REPO/projects ~/.claude/projects

# CLAUDE.md compartido para todos los proyectos
if [ -d "$PROYECTOS_DIR" ]; then
    ln -sf $REPO/proyectos/CLAUDE.md "$PROYECTOS_DIR/CLAUDE.md"
fi

# Por cada directorio en proyectos/
for dir in "$PROYECTOS_DIR"/*/; do
    [ -d "$dir" ] || continue
    proyecto=$(basename "$dir")

    # Asegurar que .claude/ está en .gitignore
    if [ -f "$dir/.gitignore" ]; then
        if ! grep -q "\.claude" "$dir/.gitignore"; then
            echo ".claude/" >> "$dir/.gitignore"
            echo "Añadido .claude/ a $proyecto/.gitignore"
        fi
    else
        echo ".claude/" > "$dir/.gitignore"
        echo "Creado .gitignore en $proyecto"
    fi

    # Crear carpeta y CLAUDE.md vacío en el repo si no existe
    if [ ! -f "$REPO/proyectos/$proyecto/CLAUDE.md" ]; then
        mkdir -p "$REPO/proyectos/$proyecto"
        touch "$REPO/proyectos/$proyecto/CLAUDE.md"
        echo "Creado CLAUDE.md vacío para $proyecto en myClaudeContext"
    fi

    # Asegurar que GEMINI.md está en .gitignore
    if ! grep -qx "GEMINI.md" "$dir/.gitignore" 2>/dev/null; then
        [ -s "$dir/.gitignore" ] && [ "$(tail -c1 "$dir/.gitignore" | wc -l)" -eq 0 ] && echo "" >> "$dir/.gitignore"
        echo "GEMINI.md" >> "$dir/.gitignore"
        echo "Añadido GEMINI.md a $proyecto/.gitignore"
    fi

    # Crear symlinks — Claude y Gemini apuntan al mismo archivo
    mkdir -p "$dir/.claude"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md \
           "$dir/.claude/CLAUDE.md"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md \
           "$dir/GEMINI.md"
done

# Permisos de ejecución a los scripts de sync
chmod +x $REPO/linux/pull-claude-context.sh
chmod +x $REPO/linux/push-claude-context.sh
chmod +x $REPO/check-claude-integrity.sh
chmod +x $REPO/bootstrap.sh

# Symlinks en ~/.local/bin para acceso global
mkdir -p ~/.local/bin
ln -sf $REPO/linux/pull-claude-context.sh  ~/.local/bin/memory-pull
ln -sf $REPO/linux/push-claude-context.sh  ~/.local/bin/memory-push
ln -sf $REPO/check-claude-integrity.sh     ~/.local/bin/memory-check
ln -sf $REPO/bootstrap.sh                  ~/.local/bin/memory-bootstrap
ln -sf $REPO/memory-audit.sh               ~/.local/bin/memory-audit

echo "Symlinks creados y scripts con permisos de ejecución."
