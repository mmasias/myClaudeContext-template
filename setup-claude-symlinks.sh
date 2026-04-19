#!/bin/bash

# ============================================================
# CONFIGURACIÓN — adaptar a cada usuario
# ============================================================
REPO=~/misRepos/myClaudeContext
PROYECTOS_DIR=~/misRepos/proyectos
# ============================================================

# Asegurar que ~/.claude existe antes de crear symlinks
mkdir -p ~/.claude

# Global — Claude Code
ln -sf $REPO/global/CLAUDE.md ~/.claude/CLAUDE.md

# Proyectos y memoria interna de Claude Code
# Lógica defensiva: si existe como directorio real, eliminarlo antes de crear el symlink
if [ -L ~/.claude/projects ]; then
    rm ~/.claude/projects
elif [ -d ~/.claude/projects ]; then
    rm -rf ~/.claude/projects
    echo "Eliminado ~/.claude/projects (directorio real) — reemplazado por symlink"
fi
ln -sf $REPO/projects ~/.claude/projects

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

# Contexto común de proyectos
ln -sf $REPO/proyectos/CLAUDE.md $PROYECTOS_DIR/CLAUDE.md

# Por cada directorio en PROYECTOS_DIR
for dir in $PROYECTOS_DIR/*/; do
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

    # Asegurar que GEMINI.md está en .gitignore
    if ! grep -qx "GEMINI.md" "$dir/.gitignore" 2>/dev/null; then
        # Asegurar newline antes de añadir para evitar concatenación con línea anterior
        [ -s "$dir/.gitignore" ] && [ "$(tail -c1 "$dir/.gitignore" | wc -l)" -eq 0 ] && echo "" >> "$dir/.gitignore"
        echo "GEMINI.md" >> "$dir/.gitignore"
        echo "Añadido GEMINI.md a $proyecto/.gitignore"
    fi

    # Crear carpeta y CLAUDE.md vacío en el repo si no existe
    if [ ! -f "$REPO/proyectos/$proyecto/CLAUDE.md" ]; then
        mkdir -p "$REPO/proyectos/$proyecto"
        touch "$REPO/proyectos/$proyecto/CLAUDE.md"
        echo "Creado CLAUDE.md vacío para $proyecto en myClaudeContext"
    fi

    # Crear symlinks — Claude y Gemini apuntan al mismo archivo
    mkdir -p "$dir/.claude"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md "$dir/.claude/CLAUDE.md"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md "$dir/GEMINI.md"
done

# Permisos de ejecución a los scripts de sync
chmod +x $REPO/push-claude-context.sh
chmod +x $REPO/pull-claude-context.sh

echo "Symlinks creados y scripts con permisos de ejecución."
