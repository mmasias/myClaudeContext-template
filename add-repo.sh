#!/bin/bash
# add-repo.sh <github-url>
# Clona un repo en ~/misRepos/proyectos/<nombre>, lo añade al manifiesto
# y actualiza los symlinks. Ejecutar memory-push después.

REPO=~/misRepos/myClaudeContext
MANIFEST="$REPO/manifiesto.txt"
PROYECTOS_DIR=~/misRepos/proyectos

if [ -z "$1" ]; then
    echo "Uso: $0 <github-url>"
    echo "Ejemplo: $0 https://github.com/usuario/nuevo-proyecto.git"
    exit 1
fi

URL="$1"
NOMBRE=$(basename "$URL" .git)
LOCAL_PATH="$PROYECTOS_DIR/$NOMBRE"
MANIFEST_ENTRY="proyectos/$NOMBRE"

# ── Validaciones ───────────────────────────────────────

if grep -q "$MANIFEST_ENTRY" "$MANIFEST" 2>/dev/null; then
    echo "[WARN] $MANIFEST_ENTRY ya está en el manifiesto — abortando."
    exit 1
fi

if [ -d "$LOCAL_PATH" ]; then
    echo "[WARN] $LOCAL_PATH ya existe en disco — abortando."
    exit 1
fi

# ── Clonar ─────────────────────────────────────────────

mkdir -p "$PROYECTOS_DIR"
echo "Clonando $URL → $LOCAL_PATH ..."
git clone "$URL" "$LOCAL_PATH"
if [ $? -ne 0 ]; then
    echo "[ERROR] El clone falló — abortando."
    exit 1
fi

# ── Añadir al manifiesto ───────────────────────────────

printf "%-55s %s\n" "$URL" "$MANIFEST_ENTRY" >> "$MANIFEST"
echo "[OK] Añadido al manifiesto: $MANIFEST_ENTRY"

# ── Actualizar symlinks ────────────────────────────────

if [[ "$(uname)" == "Darwin" ]]; then
    SETUP="$REPO/macos/setup-claude-symlinks.sh"
else
    SETUP="$REPO/linux/setup-claude-symlinks.sh"
fi

chmod +x "$SETUP"
"$SETUP"

# ── Instrucción final ──────────────────────────────────

echo ""
echo "Repo '$NOMBRE' añadido. Ejecuta memory-push para sincronizar el manifiesto."
