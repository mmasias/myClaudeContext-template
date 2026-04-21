#!/bin/bash
# add-repo.sh <github-url>
# Clones a repo into ~/misRepos/proyectos/<name>, adds it to the manifest,
# and updates symlinks. Run memory-push afterwards.

REPO=~/misRepos/myClaudeContext
MANIFEST="$REPO/manifiesto.txt"
PROYECTOS_DIR=~/misRepos/proyectos

if [ -z "$1" ]; then
    echo "Usage: $0 <github-url>"
    echo "Example: $0 https://github.com/user/new-project.git"
    exit 1
fi

URL="$1"
NOMBRE=$(basename "$URL" .git)
LOCAL_PATH="$PROYECTOS_DIR/$NOMBRE"
MANIFEST_ENTRY="proyectos/$NOMBRE"

# ── Validations ────────────────────────────────────────

if grep -q "$MANIFEST_ENTRY" "$MANIFEST" 2>/dev/null; then
    echo "[WARN] $MANIFEST_ENTRY is already in the manifest — aborting."
    exit 1
fi

if [ -d "$LOCAL_PATH" ]; then
    echo "[WARN] $LOCAL_PATH already exists on disk — aborting."
    exit 1
fi

# ── Clone ──────────────────────────────────────────────

mkdir -p "$PROYECTOS_DIR"
echo "Cloning $URL -> $LOCAL_PATH ..."
git clone "$URL" "$LOCAL_PATH"
if [ $? -ne 0 ]; then
    echo "[ERROR] Clone failed — aborting."
    exit 1
fi

# ── Add to manifest ────────────────────────────────────

printf "%-55s %s\n" "$URL" "$MANIFEST_ENTRY" >> "$MANIFEST"
echo "[OK] Added to manifest: $MANIFEST_ENTRY"

# ── Update symlinks ────────────────────────────────────

if [[ "$(uname)" == "Darwin" ]]; then
    SETUP="$REPO/macos/setup-claude-symlinks.sh"
else
    SETUP="$REPO/linux/setup-claude-symlinks.sh"
fi

chmod +x "$SETUP"
"$SETUP"

# ── Final instruction ──────────────────────────────────

echo ""
echo "Repo '$NOMBRE' added. Run memory-push to sync the manifest."
