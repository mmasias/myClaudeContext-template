#!/bin/bash
# bootstrap.sh
# Full setup for a new machine: clones repos from the manifest, creates symlinks,
# and syncs memory. Run once, before the first Claude Code launch.

REPO=~/misRepos/myClaudeContext
MANIFEST="$REPO/manifiesto.txt"

if [[ "$(uname)" == "Darwin" ]]; then
    SETUP="$REPO/macos/setup-claude-symlinks.sh"
    PULL="$REPO/macos/pull-claude-context.sh"
else
    SETUP="$REPO/linux/setup-claude-symlinks.sh"
    PULL="$REPO/linux/pull-claude-context.sh"
fi

echo "======================================"
echo "  Claude Context — Bootstrap"
echo "======================================"

# ── 1. Clone repos from manifest ──────────────────────
echo ""
echo "=== Cloning repos from manifest ==="

while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    url=$(echo "$line" | awk '{print $1}')
    ruta=$(echo "$line" | awk '{print $2}')
    local_path=~/misRepos/"$ruta"

    if [ -d "$local_path" ]; then
        echo "[OK]   Already exists: $ruta"
    else
        echo "Cloning $ruta ..."
        git clone "$url" "$local_path"
        if [ $? -ne 0 ]; then
            echo "[WARN] Clone failed for $ruta — check access and clone manually."
        else
            echo "[OK]   Cloned: $ruta"
        fi
    fi
done < "$MANIFEST"

# ── 2. Set up symlinks ────────────────────────────────
echo ""
echo "=== Setting up symlinks ==="
chmod +x "$SETUP"
"$SETUP"

# ── 3. Sync memory ────────────────────────────────────
echo ""
echo "=== Syncing memory ==="
chmod +x "$PULL"
"$PULL"

echo ""
echo "======================================"
echo "  Bootstrap complete."
echo "  Launch Claude Code."
echo "======================================"
