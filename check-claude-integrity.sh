#!/bin/bash

REPO=~/misRepos/myClaudeContext
PROYECTOS_DIR=~/misRepos/proyectos
ERRORS=0
WARNINGS=0

ok()   { echo "[OK]    $1"; }
warn() { echo "[WARN]  $1"; WARNINGS=$((WARNINGS + 1)); }
err()  { echo "[ERROR] $1"; ERRORS=$((ERRORS + 1)); }

check_manifest() {
    echo ""
    echo "=== Manifest ==="
    local manifest="$REPO/manifiesto.txt"

    if [ ! -f "$manifest" ]; then
        warn "manifiesto.txt not found in repo"
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
            warn "$ruta does not exist on disk — clone: git clone $url ~/misRepos/$ruta"
        fi
    done < "$manifest"
}

check_common() {
    echo ""
    echo "=== Common checks ==="

    # ~/.claude/CLAUDE.md is a valid symlink
    if [ -L ~/.claude/CLAUDE.md ] && [ -f ~/.claude/CLAUDE.md ]; then
        ok "~/.claude/CLAUDE.md is a valid symlink"
    elif [ -L ~/.claude/CLAUDE.md ]; then
        err "~/.claude/CLAUDE.md is a BROKEN symlink -> $(readlink ~/.claude/CLAUDE.md)"
    else
        err "~/.claude/CLAUDE.md is not a symlink"
    fi

    # ~/.gemini/GEMINI.md is a valid symlink pointing to global/CLAUDE.md
    if [ -L ~/.gemini/GEMINI.md ] && [ -f ~/.gemini/GEMINI.md ]; then
        actual_target=$(readlink -f ~/.gemini/GEMINI.md)
        expected_target=$(readlink -f "$REPO/global/CLAUDE.md")
        if [ "$actual_target" = "$expected_target" ]; then
            ok "~/.gemini/GEMINI.md is a valid symlink -> $actual_target"
        else
            err "~/.gemini/GEMINI.md points to unexpected location: $actual_target (expected: $expected_target)"
        fi
    elif [ -L ~/.gemini/GEMINI.md ]; then
        err "~/.gemini/GEMINI.md is a BROKEN symlink -> $(readlink ~/.gemini/GEMINI.md)"
    elif [ -f ~/.gemini/GEMINI.md ]; then
        warn "~/.gemini/GEMINI.md is a real file (should be a symlink) — run setup-claude-symlinks.sh"
    else
        warn "~/.gemini/GEMINI.md does not exist — run setup-claude-symlinks.sh"
    fi

    # Excluded files that should not be tracked in git
    tracked=$(git -C "$REPO" ls-files -- '*.jsonl' 'projects/**/*.json' 'projects/**/*.txt' 2>/dev/null)
    if [ -z "$tracked" ]; then
        ok "No .jsonl/.json/.txt files tracked in git"
    else
        err "Excluded files tracked in git (use git rm --cached):"
        echo "$tracked" | sed 's/^/         /'
    fi

    # Repo state vs remote
    git -C "$REPO" fetch --quiet 2>/dev/null
    local_ref=$(git -C "$REPO" rev-parse @ 2>/dev/null)
    remote_ref=$(git -C "$REPO" rev-parse @{u} 2>/dev/null)
    base_ref=$(git -C "$REPO" merge-base @ @{u} 2>/dev/null)

    if [ "$local_ref" = "$remote_ref" ]; then
        ok "Repo in sync with remote"
    elif [ "$local_ref" = "$base_ref" ]; then
        warn "Repo is BEHIND remote — pull before continuing"
    elif [ "$remote_ref" = "$base_ref" ]; then
        warn "Repo is AHEAD of remote — unpushed commits exist"
    else
        err "Repo DIVERGED from remote — manual resolution required"
    fi

    # MEMORY.md integrity for all projects
    echo ""
    echo "=== Memory integrity per project ==="
    found_any=false
    for memory_file in "$REPO"/projects/*/memory/MEMORY.md; do
        [ -f "$memory_file" ] || continue
        found_any=true
        memory_dir=$(dirname "$memory_file")
        project=$(basename "$(dirname "$memory_dir")")

        project_errors=0

        # References in MEMORY.md that don't exist on disk
        while IFS= read -r ref; do
            [ -z "$ref" ] && continue
            if [ ! -f "$memory_dir/$ref" ]; then
                err "[$project] MEMORY.md references non-existent file: $ref"
                project_errors=$((project_errors + 1))
            fi
        done < <(grep -oP ']\(\K[^)]+\.md(?=\))' "$memory_file" 2>/dev/null)

        # .md files in memory/ not indexed in MEMORY.md
        for md_file in "$memory_dir"/*.md; do
            [ -f "$md_file" ] || continue
            fname=$(basename "$md_file")
            [ "$fname" = "MEMORY.md" ] && continue
            if ! grep -q "$fname" "$memory_file"; then
                warn "[$project] File not indexed in MEMORY.md: $fname"
                project_errors=$((project_errors + 1))
            fi
        done
        [ $project_errors -eq 0 ] && ok "[$project] MEMORY.md is intact"
    done
    $found_any || warn "No MEMORY.md found in projects/"
}

check_linux() {
    echo ""
    echo "=== Linux checks ==="

    if [ -L ~/.claude/projects ] && [ -d ~/.claude/projects ]; then
        actual_target=$(readlink -f ~/.claude/projects)
        expected_target=$(readlink -f "$REPO/projects")
        if [ "$actual_target" = "$expected_target" ]; then
            ok "~/.claude/projects is a valid symlink -> $actual_target"
        else
            err "~/.claude/projects points to unexpected location: $actual_target (expected: $expected_target)"
        fi
    elif [ -L ~/.claude/projects ]; then
        err "~/.claude/projects is a BROKEN symlink -> $(readlink ~/.claude/projects)"
    elif [ -d ~/.claude/projects ]; then
        err "~/.claude/projects is a real directory (should be a symlink) — memory is outside the repo"
    else
        err "~/.claude/projects does not exist"
    fi

    echo ""
    echo "=== Projects ==="
    if [ -d "$PROYECTOS_DIR" ]; then
        for dir in "$PROYECTOS_DIR"/*/; do
            [ -d "$dir" ] || continue
            proyecto=$(basename "$dir")
            link="$dir/.claude/CLAUDE.md"

            if [ -L "$link" ] && [ -f "$link" ]; then
                ok "[$proyecto] .claude/CLAUDE.md valid symlink"
            elif [ -L "$link" ]; then
                err "[$proyecto] .claude/CLAUDE.md BROKEN symlink -> $(readlink "$link")"
            else
                warn "[$proyecto] .claude/CLAUDE.md missing symlink — run setup-claude-symlinks.sh"
            fi

            if [ ! -d "$REPO/proyectos/$proyecto" ]; then
                warn "[$proyecto] no folder in repo — run setup-claude-symlinks.sh"
            fi

            # Gemini: GEMINI.md symlink
            gemini_link="$dir/GEMINI.md"
            if [ -L "$gemini_link" ] && [ -f "$gemini_link" ]; then
                ok "[$proyecto] GEMINI.md valid symlink"
            elif [ -L "$gemini_link" ]; then
                err "[$proyecto] GEMINI.md BROKEN symlink -> $(readlink "$gemini_link")"
            else
                warn "[$proyecto] GEMINI.md missing symlink — run setup-claude-symlinks.sh"
            fi

            # Gemini: GEMINI.md in .gitignore
            if git -C "$dir" check-ignore -q GEMINI.md 2>/dev/null; then
                ok "[$proyecto] GEMINI.md in .gitignore"
            else
                warn "[$proyecto] GEMINI.md NOT in .gitignore — risk of exposing local path"
            fi
        done
    else
        warn "$PROYECTOS_DIR does not exist — project checks skipped"
    fi
}

check_macos() {
    echo ""
    echo "=== macOS checks ==="
    local LOCAL_PROJECTS=~/.claude/projects
    local REPO_PROJECTS="$REPO/projects"
    local USER
    USER=$(whoami)

    if [ -d "$LOCAL_PROJECTS" ] && [ ! -L "$LOCAL_PROJECTS" ]; then
        ok "~/.claude/projects is a real directory"
    elif [ -L "$LOCAL_PROJECTS" ]; then
        err "~/.claude/projects is a symlink (on macOS it must be a real directory)"
    else
        err "~/.claude/projects does not exist"
    fi

    echo ""
    echo "--- Local <-> repo correspondence ---"
    for macos_dir in "$LOCAL_PROJECTS"/-Users-"$USER"-*/; do
        [ -d "$macos_dir" ] || continue
        dirname=$(basename "$macos_dir")
        linux_dirname="${dirname/-Users-$USER-/-home-$USER-}"
        if [ -d "$REPO_PROJECTS/$linux_dirname" ]; then
            ok "$dirname <-> $linux_dirname"
        else
            warn "$dirname exists locally but not in repo: $linux_dirname — push needed"
        fi
    done

    for linux_dir in "$REPO_PROJECTS"/-home-"$USER"-*/; do
        [ -d "$linux_dir" ] || continue
        dirname=$(basename "$linux_dir")
        macos_dirname="${dirname/-home-$USER-/-Users-$USER-}"
        if [ ! -d "$LOCAL_PROJECTS/$macos_dirname" ]; then
            warn "$dirname in repo but not local: $macos_dirname — pull needed"
        fi
    done

    echo ""
    echo "=== Projects ==="
    if [ -d "$PROYECTOS_DIR" ]; then
        for dir in "$PROYECTOS_DIR"/*/; do
            [ -d "$dir" ] || continue
            proyecto=$(basename "$dir")
            link="$dir/.claude/CLAUDE.md"

            if [ -L "$link" ] && [ -f "$link" ]; then
                ok "[$proyecto] .claude/CLAUDE.md valid symlink"
            elif [ -L "$link" ]; then
                err "[$proyecto] .claude/CLAUDE.md BROKEN symlink -> $(readlink "$link")"
            else
                warn "[$proyecto] .claude/CLAUDE.md missing symlink — run setup-claude-symlinks.sh"
            fi

            # Gemini: GEMINI.md symlink
            gemini_link="$dir/GEMINI.md"
            if [ -L "$gemini_link" ] && [ -f "$gemini_link" ]; then
                ok "[$proyecto] GEMINI.md valid symlink"
            elif [ -L "$gemini_link" ]; then
                err "[$proyecto] GEMINI.md BROKEN symlink -> $(readlink "$gemini_link")"
            else
                warn "[$proyecto] GEMINI.md missing symlink — run setup-claude-symlinks.sh"
            fi

            # Gemini: GEMINI.md in .gitignore
            if git -C "$dir" check-ignore -q GEMINI.md 2>/dev/null; then
                ok "[$proyecto] GEMINI.md in .gitignore"
            else
                warn "[$proyecto] GEMINI.md NOT in .gitignore — risk of exposing local path"
            fi
        done
    else
        warn "$PROYECTOS_DIR does not exist — project checks skipped"
    fi
}

# ── Main ──────────────────────────────────────────────
echo "======================================"
echo "  Claude Context — Integrity Check"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "======================================"

check_manifest
check_common

if [[ "$(uname)" == "Darwin" ]]; then
    check_macos
else
    check_linux
fi

echo ""
echo "======================================"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "  All OK"
elif [ "$ERRORS" -eq 0 ]; then
    echo "  $WARNINGS warning(s) — 0 errors"
else
    echo "  $ERRORS error(s) — $WARNINGS warning(s)"
fi
echo "======================================"

exit "$ERRORS"
