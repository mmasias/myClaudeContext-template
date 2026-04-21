#!/bin/bash
# Evaluates repos with memory in projects/ and suggests an action.
# Run periodically to keep the system clean.

REPO=~/misRepos/myClaudeContext
PROJECTS="$REPO/projects"

echo "======================================"
echo "  Memory Audit"
echo "  $(date '+%Y-%m-%d %H:%M')"
echo "======================================"

found=0

for project_dir in "$PROJECTS"/*/; do
    [ -d "$project_dir" ] || continue
    dirname=$(basename "$project_dir")

    # Exclude global memory (misRepos root)
    [ "$dirname" = "-home-$(whoami)-misRepos" ] && continue
    [ "$dirname" = "-Users-$(whoami)-misRepos" ] && continue

    memory_dir="$project_dir/memory"
    [ -d "$memory_dir" ] || continue

    found=$((found + 1))

    repo_name=$(echo "$dirname" | sed "s/-home-$(whoami)-misRepos-//" | sed "s/-Users-$(whoami)-misRepos-//")

    memory_files=$(find "$memory_dir" -name "*.md" ! -name "MEMORY.md" | wc -l)

    # Linux/macOS compatible timestamp
    if [[ "$(uname)" == "Darwin" ]]; then
        last_mod=$(find "$memory_dir" -name "*.md" -exec stat -f "%m" {} \; 2>/dev/null | sort -n | tail -1)
    else
        last_mod=$(find "$memory_dir" -name "*.md" -printf "%T@\n" 2>/dev/null | sort -n | tail -1)
    fi

    if [ -n "$last_mod" ]; then
        days_ago=$(( ( $(date +%s) - ${last_mod%.*} ) / 86400 ))
    else
        days_ago=9999
    fi

    if [ "$memory_files" -eq 0 ]; then
        verdict="ARCHIVE   — no real memory; delete directory from projects/"
    elif [ "$days_ago" -gt 90 ]; then
        verdict="REVIEW    — has memory but inactive for >90 days"
    else
        verdict="ACTIVE    — recent usage"
    fi

    echo ""
    echo "--- $repo_name ---"
    echo "  Memory files    : $memory_files"
    echo "  Last activity   : $days_ago days ago"
    echo "  Verdict         : $verdict"

    if [ "$memory_files" -gt 0 ]; then
        find "$memory_dir" -name "*.md" ! -name "MEMORY.md" | while read -r f; do
            echo "    - $(basename "$f")"
        done
    fi
done

if [ "$found" -eq 0 ]; then
    echo ""
    echo "No repos with memory found in projects/."
fi

echo ""
echo "======================================"
