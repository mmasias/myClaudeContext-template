#!/bin/bash

REPO=~/misRepos/myClaudeContext
PROYECTOS_DIR=~/misRepos/proyectos

# Ensure ~/.claude exists
mkdir -p ~/.claude

# projects: must be a real directory (not a symlink) on macOS
if [ -L ~/.claude/projects ]; then
    rm ~/.claude/projects
    echo "Removed symlink ~/.claude/projects"
elif [ -d ~/.claude/projects ]; then
    rm -rf ~/.claude/projects
    echo "Removed ~/.claude/projects (real directory)"
fi
mkdir -p ~/.claude/projects
echo "Created ~/.claude/projects as a real directory"

# Global — Claude Code
ln -sf $REPO/global/CLAUDE.md ~/.claude/CLAUDE.md

# Global — Gemini CLI
mkdir -p ~/.gemini
if [ -L ~/.gemini/GEMINI.md ]; then
    rm ~/.gemini/GEMINI.md
elif [ -f ~/.gemini/GEMINI.md ]; then
    mv ~/.gemini/GEMINI.md ~/.gemini/GEMINI.md.bak
    echo "Backed up existing ~/.gemini/GEMINI.md -> GEMINI.md.bak"
elif [ -d ~/.gemini/GEMINI.md ]; then
    echo "[ERROR] ~/.gemini/GEMINI.md is a directory — manual resolution required"
    exit 1
fi
ln -sf $REPO/global/CLAUDE.md ~/.gemini/GEMINI.md

# Shared CLAUDE.md for all projects
if [ -d "$PROYECTOS_DIR" ]; then
    ln -sf $REPO/proyectos/CLAUDE.md "$PROYECTOS_DIR/CLAUDE.md"
fi

# For each directory in proyectos/
for dir in "$PROYECTOS_DIR"/*/; do
    [ -d "$dir" ] || continue
    proyecto=$(basename "$dir")

    # Ensure .claude/ is in .gitignore
    if [ -f "$dir/.gitignore" ]; then
        if ! grep -q "\.claude" "$dir/.gitignore"; then
            echo ".claude/" >> "$dir/.gitignore"
            echo "Added .claude/ to $proyecto/.gitignore"
        fi
    else
        echo ".claude/" > "$dir/.gitignore"
        echo "Created .gitignore in $proyecto"
    fi

    # Create folder and empty CLAUDE.md in repo if it doesn't exist
    if [ ! -f "$REPO/proyectos/$proyecto/CLAUDE.md" ]; then
        mkdir -p "$REPO/proyectos/$proyecto"
        touch "$REPO/proyectos/$proyecto/CLAUDE.md"
        echo "Created empty CLAUDE.md for $proyecto in myClaudeContext"
    fi

    # Ensure GEMINI.md is in .gitignore
    if ! grep -qx "GEMINI.md" "$dir/.gitignore" 2>/dev/null; then
        [ -s "$dir/.gitignore" ] && [ "$(tail -c1 "$dir/.gitignore" | wc -l)" -eq 0 ] && echo "" >> "$dir/.gitignore"
        echo "GEMINI.md" >> "$dir/.gitignore"
        echo "Added GEMINI.md to $proyecto/.gitignore"
    fi

    # Create symlinks — Claude and Gemini point to the same file
    mkdir -p "$dir/.claude"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md \
           "$dir/.claude/CLAUDE.md"
    ln -sf $REPO/proyectos/$proyecto/CLAUDE.md \
           "$dir/GEMINI.md"
done

# Execution permissions for sync scripts
chmod +x $REPO/macos/pull-claude-context.sh
chmod +x $REPO/macos/push-claude-context.sh
chmod +x $REPO/check-claude-integrity.sh
chmod +x $REPO/bootstrap.sh

# Symlinks in ~/.local/bin for global access
mkdir -p ~/.local/bin
ln -sf $REPO/macos/pull-claude-context.sh  ~/.local/bin/memory-pull
ln -sf $REPO/macos/push-claude-context.sh  ~/.local/bin/memory-push
ln -sf $REPO/check-claude-integrity.sh     ~/.local/bin/memory-check
ln -sf $REPO/bootstrap.sh                  ~/.local/bin/memory-bootstrap
ln -sf $REPO/memory-audit.sh               ~/.local/bin/memory-audit

echo "Setup complete."
