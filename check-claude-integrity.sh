#!/bin/bash

# ============================================================
# CONFIGURACIÓN — debe coincidir con setup-claude-symlinks.sh
# ============================================================
REPO=~/misRepos/myClaudeContext
PROYECTOS_DIR=~/misRepos/proyectos
# ============================================================

ERRORS=0
WARNINGS=0

ok()   { echo "[OK]    $1"; }
warn() { echo "[WARN]  $1"; WARNINGS=$((WARNINGS + 1)); }
err()  { echo "[ERROR] $1"; ERRORS=$((ERRORS + 1)); }

echo "======================================"
echo "  Context Integrity Check"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "======================================"

# ── Symlinks globales ──────────────────────────────────────
echo ""
echo "=== Symlinks globales ==="

# ~/.claude/CLAUDE.md
if [ -L ~/.claude/CLAUDE.md ] && [ -f ~/.claude/CLAUDE.md ]; then
    ok "~/.claude/CLAUDE.md es symlink válido"
elif [ -L ~/.claude/CLAUDE.md ]; then
    err "~/.claude/CLAUDE.md es symlink ROTO → $(readlink ~/.claude/CLAUDE.md)"
else
    err "~/.claude/CLAUDE.md no es symlink — ejecutar setup-claude-symlinks.sh"
fi

# ~/.claude/projects
if [ -L ~/.claude/projects ] && [ -d ~/.claude/projects ]; then
    actual=$(readlink -f ~/.claude/projects)
    expected=$(readlink -f "$REPO/projects")
    if [ "$actual" = "$expected" ]; then
        ok "~/.claude/projects es symlink válido"
    else
        err "~/.claude/projects apunta a lugar inesperado: $actual"
    fi
elif [ -L ~/.claude/projects ]; then
    err "~/.claude/projects es symlink ROTO → $(readlink ~/.claude/projects)"
elif [ -d ~/.claude/projects ]; then
    err "~/.claude/projects es directorio real (debería ser symlink) — ejecutar setup-claude-symlinks.sh"
else
    err "~/.claude/projects no existe"
fi

# ~/.gemini/GEMINI.md
if [ -L ~/.gemini/GEMINI.md ] && [ -f ~/.gemini/GEMINI.md ]; then
    actual=$(readlink -f ~/.gemini/GEMINI.md)
    expected=$(readlink -f "$REPO/global/CLAUDE.md")
    if [ "$actual" = "$expected" ]; then
        ok "~/.gemini/GEMINI.md es symlink válido"
    else
        err "~/.gemini/GEMINI.md apunta a lugar inesperado: $actual"
    fi
elif [ -L ~/.gemini/GEMINI.md ]; then
    err "~/.gemini/GEMINI.md es symlink ROTO → $(readlink ~/.gemini/GEMINI.md)"
elif [ -f ~/.gemini/GEMINI.md ]; then
    warn "~/.gemini/GEMINI.md es archivo real (debería ser symlink) — ejecutar setup-claude-symlinks.sh"
else
    warn "~/.gemini/GEMINI.md no existe — ejecutar setup-claude-symlinks.sh"
fi

# ── Estado del repo ────────────────────────────────────────
echo ""
echo "=== Estado del repo ==="

git -C "$REPO" fetch --quiet 2>/dev/null
local_ref=$(git -C "$REPO" rev-parse @ 2>/dev/null)
remote_ref=$(git -C "$REPO" rev-parse @{u} 2>/dev/null)
base_ref=$(git -C "$REPO" merge-base @ @{u} 2>/dev/null)

if [ "$local_ref" = "$remote_ref" ]; then
    ok "Repo sincronizado con remote"
elif [ "$local_ref" = "$base_ref" ]; then
    warn "Repo por DETRÁS del remote — hacer pull antes de continuar"
elif [ "$remote_ref" = "$base_ref" ]; then
    warn "Repo por DELANTE del remote — hay commits sin pushear"
else
    err "Repo DIVERGIDO del remote — resolución manual necesaria"
fi

# ── Proyectos ──────────────────────────────────────────────
echo ""
echo "=== Proyectos ==="

if [ -d "$PROYECTOS_DIR" ]; then
    for dir in "$PROYECTOS_DIR"/*/; do
        [ -d "$dir" ] || continue
        proyecto=$(basename "$dir")

        # Claude: .claude/CLAUDE.md
        claude_link="$dir/.claude/CLAUDE.md"
        if [ -L "$claude_link" ] && [ -f "$claude_link" ]; then
            ok "[$proyecto] .claude/CLAUDE.md symlink válido"
        elif [ -L "$claude_link" ]; then
            err "[$proyecto] .claude/CLAUDE.md symlink ROTO → $(readlink "$claude_link")"
        else
            warn "[$proyecto] .claude/CLAUDE.md sin symlink — ejecutar setup-claude-symlinks.sh"
        fi

        # Gemini: GEMINI.md
        gemini_link="$dir/GEMINI.md"
        if [ -L "$gemini_link" ] && [ -f "$gemini_link" ]; then
            ok "[$proyecto] GEMINI.md symlink válido"
        elif [ -L "$gemini_link" ]; then
            err "[$proyecto] GEMINI.md symlink ROTO → $(readlink "$gemini_link")"
        else
            warn "[$proyecto] GEMINI.md sin symlink — ejecutar setup-claude-symlinks.sh"
        fi

        # GEMINI.md en .gitignore
        if git -C "$dir" check-ignore -q GEMINI.md 2>/dev/null; then
            ok "[$proyecto] GEMINI.md en .gitignore"
        else
            warn "[$proyecto] GEMINI.md NO está en .gitignore — riesgo de exponer ruta local"
        fi
    done
else
    warn "$PROYECTOS_DIR no existe — checks de proyectos omitidos"
fi

# ── Integridad de memoria ──────────────────────────────────
echo ""
echo "=== Integridad de memoria ==="

found_any=false
for memory_file in "$REPO"/projects/*/memory/MEMORY.md; do
    [ -f "$memory_file" ] || continue
    found_any=true
    memory_dir=$(dirname "$memory_file")
    project=$(basename "$(dirname "$memory_dir")")
    project_errors=0

    while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        if [ ! -f "$memory_dir/$ref" ]; then
            err "[$project] MEMORY.md referencia archivo inexistente: $ref"
            project_errors=$((project_errors + 1))
        fi
    done < <(grep -oP ']\(\K[^)]+\.md(?=\))' "$memory_file" 2>/dev/null)

    for md_file in "$memory_dir"/*.md; do
        [ -f "$md_file" ] || continue
        fname=$(basename "$md_file")
        [ "$fname" = "MEMORY.md" ] && continue
        if ! grep -q "$fname" "$memory_file"; then
            warn "[$project] Archivo no indexado en MEMORY.md: $fname"
            project_errors=$((project_errors + 1))
        fi
    done

    [ $project_errors -eq 0 ] && ok "[$project] MEMORY.md íntegro"
done
$found_any || ok "Sin proyectos con memoria indexada aún"

# ── Resumen ────────────────────────────────────────────────
echo ""
echo "======================================"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "  Todo OK"
elif [ "$ERRORS" -eq 0 ]; then
    echo "  $WARNINGS aviso(s) — 0 errores"
else
    echo "  $ERRORS error(es) — $WARNINGS aviso(s)"
fi
echo "======================================"

exit "$ERRORS"
