#!/bin/bash

REPO=~/misRepos/myClaudeContext
PROYECTOS_DIR=~/misRepos/proyectos
ERRORS=0
WARNINGS=0

ok()   { echo "[OK]    $1"; }
warn() { echo "[WARN]  $1"; WARNINGS=$((WARNINGS + 1)); }
err()  { echo "[ERROR] $1"; ERRORS=$((ERRORS + 1)); }

check_manifiesto() {
    echo ""
    echo "=== Manifiesto ==="
    local manifest="$REPO/manifiesto.txt"

    if [ ! -f "$manifest" ]; then
        warn "manifiesto.txt no encontrado en el repo"
        return
    fi

    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        url=$(echo "$line" | awk '{print $1}')
        ruta=$(echo "$line" | awk '{print $2}')
        local_path=~/misRepos/"$ruta"

        if [ -d "$local_path" ]; then
            ok "$ruta"
        else
            warn "$ruta no existe en disco — clonar: git clone $url ~/misRepos/$ruta"
        fi
    done < "$manifest"
}

check_common() {
    echo ""
    echo "=== Checks comunes ==="

    # ~/.claude/CLAUDE.md es symlink válido
    if [ -L ~/.claude/CLAUDE.md ] && [ -f ~/.claude/CLAUDE.md ]; then
        ok "~/.claude/CLAUDE.md es symlink válido"
    elif [ -L ~/.claude/CLAUDE.md ]; then
        err "~/.claude/CLAUDE.md es symlink ROTO → $(readlink ~/.claude/CLAUDE.md)"
    else
        err "~/.claude/CLAUDE.md no es symlink"
    fi

    # ~/.gemini/GEMINI.md es symlink válido apuntando a global/CLAUDE.md
    if [ -L ~/.gemini/GEMINI.md ] && [ -f ~/.gemini/GEMINI.md ]; then
        actual_target=$(readlink -f ~/.gemini/GEMINI.md)
        expected_target=$(readlink -f "$REPO/global/CLAUDE.md")
        if [ "$actual_target" = "$expected_target" ]; then
            ok "~/.gemini/GEMINI.md es symlink válido → $actual_target"
        else
            err "~/.gemini/GEMINI.md apunta a lugar inesperado: $actual_target (esperado: $expected_target)"
        fi
    elif [ -L ~/.gemini/GEMINI.md ]; then
        err "~/.gemini/GEMINI.md es symlink ROTO → $(readlink ~/.gemini/GEMINI.md)"
    elif [ -f ~/.gemini/GEMINI.md ]; then
        warn "~/.gemini/GEMINI.md es archivo real (debería ser symlink) — ejecutar setup-claude-symlinks.sh"
    else
        warn "~/.gemini/GEMINI.md no existe — ejecutar setup-claude-symlinks.sh"
    fi

    # Archivos excluidos que no deberían estar en git
    tracked=$(git -C "$REPO" ls-files -- '*.jsonl' 'projects/**/*.json' 'projects/**/*.txt' 2>/dev/null)
    if [ -z "$tracked" ]; then
        ok "Sin archivos .jsonl/.json/.txt trackeados en git"
    else
        err "Archivos excluidos trackeados en git (usar git rm --cached):"
        echo "$tracked" | sed 's/^/         /'
    fi

    # Estado del repo vs remote
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

    # Integridad de MEMORY.md en todos los proyectos
    echo ""
    echo "=== Integridad de memoria por proyecto ==="
    found_any=false
    for memory_file in "$REPO"/projects/*/memory/MEMORY.md; do
        [ -f "$memory_file" ] || continue
        found_any=true
        memory_dir=$(dirname "$memory_file")
        project=$(basename "$(dirname "$memory_dir")")

        project_errors=0

        # Referencias en MEMORY.md que no existen en disco
        while IFS= read -r ref; do
            [ -z "$ref" ] && continue
            if [ ! -f "$memory_dir/$ref" ]; then
                err "[$project] MEMORY.md referencia archivo inexistente: $ref"
                project_errors=$((project_errors + 1))
            fi
        done < <(grep -oP ']\(\K[^)]+\.md(?=\))' "$memory_file" 2>/dev/null)

        # Archivos .md en memory/ no indexados en MEMORY.md
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
    $found_any || warn "No se encontró ningún MEMORY.md en projects/"
}

check_linux() {
    echo ""
    echo "=== Checks Linux ==="

    if [ -L ~/.claude/projects ] && [ -d ~/.claude/projects ]; then
        actual_target=$(readlink -f ~/.claude/projects)
        expected_target=$(readlink -f "$REPO/projects")
        if [ "$actual_target" = "$expected_target" ]; then
            ok "~/.claude/projects es symlink válido → $actual_target"
        else
            err "~/.claude/projects apunta a lugar inesperado: $actual_target (esperado: $expected_target)"
        fi
    elif [ -L ~/.claude/projects ]; then
        err "~/.claude/projects es symlink ROTO → $(readlink ~/.claude/projects)"
    elif [ -d ~/.claude/projects ]; then
        err "~/.claude/projects es directorio real (debería ser symlink) — memoria fuera del repo"
    else
        err "~/.claude/projects no existe"
    fi

    echo ""
    echo "=== Proyectos ==="
    if [ -d "$PROYECTOS_DIR" ]; then
        for dir in "$PROYECTOS_DIR"/*/; do
            [ -d "$dir" ] || continue
            proyecto=$(basename "$dir")
            link="$dir/.claude/CLAUDE.md"

            if [ -L "$link" ] && [ -f "$link" ]; then
                ok "[$proyecto] .claude/CLAUDE.md symlink válido"
            elif [ -L "$link" ]; then
                err "[$proyecto] .claude/CLAUDE.md symlink ROTO → $(readlink "$link")"
            else
                warn "[$proyecto] .claude/CLAUDE.md sin symlink — ejecutar setup-claude-symlinks.sh"
            fi

            if [ ! -d "$REPO/proyectos/$proyecto" ]; then
                warn "[$proyecto] sin carpeta en repo — ejecutar setup-claude-symlinks.sh"
            fi

            # Gemini: symlink GEMINI.md
            gemini_link="$dir/GEMINI.md"
            if [ -L "$gemini_link" ] && [ -f "$gemini_link" ]; then
                ok "[$proyecto] GEMINI.md symlink válido"
            elif [ -L "$gemini_link" ]; then
                err "[$proyecto] GEMINI.md symlink ROTO → $(readlink "$gemini_link")"
            else
                warn "[$proyecto] GEMINI.md sin symlink — ejecutar setup-claude-symlinks.sh"
            fi

            # Gemini: GEMINI.md en .gitignore
            if git -C "$dir" check-ignore -q GEMINI.md 2>/dev/null; then
                ok "[$proyecto] GEMINI.md en .gitignore"
            else
                warn "[$proyecto] GEMINI.md NO está en .gitignore — riesgo de exponer ruta local"
            fi
        done
    else
        warn "$PROYECTOS_DIR no existe — checks de proyectos omitidos"
    fi
}

check_macos() {
    echo ""
    echo "=== Checks macOS ==="
    local LOCAL_PROJECTS=~/.claude/projects
    local REPO_PROJECTS="$REPO/projects"
    local USER
    USER=$(whoami)

    if [ -d "$LOCAL_PROJECTS" ] && [ ! -L "$LOCAL_PROJECTS" ]; then
        ok "~/.claude/projects es directorio real"
    elif [ -L "$LOCAL_PROJECTS" ]; then
        err "~/.claude/projects es symlink (en macOS debe ser directorio real)"
    else
        err "~/.claude/projects no existe"
    fi

    echo ""
    echo "--- Correspondencia local ↔ repo ---"
    for macos_dir in "$LOCAL_PROJECTS"/-Users-"$USER"-*/; do
        [ -d "$macos_dir" ] || continue
        dirname=$(basename "$macos_dir")
        linux_dirname="${dirname/-Users-$USER-/-home-$USER-}"
        if [ -d "$REPO_PROJECTS/$linux_dirname" ]; then
            ok "$dirname ↔ $linux_dirname"
        else
            warn "$dirname existe local pero no en repo: $linux_dirname — hacer push"
        fi
    done

    for linux_dir in "$REPO_PROJECTS"/-home-"$USER"-*/; do
        [ -d "$linux_dir" ] || continue
        dirname=$(basename "$linux_dir")
        macos_dirname="${dirname/-home-$USER-/-Users-$USER-}"
        if [ ! -d "$LOCAL_PROJECTS/$macos_dirname" ]; then
            warn "$dirname en repo pero no local: $macos_dirname — hacer pull"
        fi
    done

    echo ""
    echo "=== Proyectos ==="
    if [ -d "$PROYECTOS_DIR" ]; then
        for dir in "$PROYECTOS_DIR"/*/; do
            [ -d "$dir" ] || continue
            proyecto=$(basename "$dir")
            link="$dir/.claude/CLAUDE.md"

            if [ -L "$link" ] && [ -f "$link" ]; then
                ok "[$proyecto] .claude/CLAUDE.md symlink válido"
            elif [ -L "$link" ]; then
                err "[$proyecto] .claude/CLAUDE.md symlink ROTO → $(readlink "$link")"
            else
                warn "[$proyecto] .claude/CLAUDE.md sin symlink — ejecutar setup-claude-symlinks.sh"
            fi

            # Gemini: symlink GEMINI.md
            gemini_link="$dir/GEMINI.md"
            if [ -L "$gemini_link" ] && [ -f "$gemini_link" ]; then
                ok "[$proyecto] GEMINI.md symlink válido"
            elif [ -L "$gemini_link" ]; then
                err "[$proyecto] GEMINI.md symlink ROTO → $(readlink "$gemini_link")"
            else
                warn "[$proyecto] GEMINI.md sin symlink — ejecutar setup-claude-symlinks.sh"
            fi

            # Gemini: GEMINI.md en .gitignore
            if git -C "$dir" check-ignore -q GEMINI.md 2>/dev/null; then
                ok "[$proyecto] GEMINI.md en .gitignore"
            else
                warn "[$proyecto] GEMINI.md NO está en .gitignore — riesgo de exponer ruta local"
            fi
        done
    else
        warn "$PROYECTOS_DIR no existe — checks de proyectos omitidos"
    fi
}

# ── Main ──────────────────────────────────────────────
echo "======================================"
echo "  Claude Context — Integrity Check"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "======================================"

check_manifiesto
check_common

if [[ "$(uname)" == "Darwin" ]]; then
    check_macos
else
    check_linux
fi

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
