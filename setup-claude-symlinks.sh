#!/bin/bash

REPO=~/misRepos/myClaudeContext

# Asegurar que ~/.claude existe antes de crear symlinks
# (puede existir previamente creado por plugins de VSCode u otras herramientas)
mkdir -p ~/.claude

# Global
ln -sf $REPO/global/CLAUDE.md ~/.claude/CLAUDE.md

# Proyectos y memoria interna de Claude Code
ln -sf $REPO/projects ~/.claude/projects

# Contexto común de proyectos
ln -sf $REPO/proyectos/CLAUDE.md ~/misRepos/proyectos/CLAUDE.md

# Por cada directorio en ~/misRepos/proyectos/
for dir in ~/misRepos/proyectos/*/; do
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

    # Crear symlink
    mkdir -p "$dir/.claude"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md \
           "$dir/.claude/CLAUDE.md"
done

# Permisos de ejecución a los scripts de sync
chmod +x $REPO/push-claude-context.sh
chmod +x $REPO/pull-claude-context.sh

echo "Symlinks creados y scripts con permisos de ejecución."
