#!/bin/bash
# bootstrap.sh
# Configura una máquina nueva: clona los repos del manifiesto, crea symlinks
# y sincroniza la memoria. Ejecutar una sola vez, antes del primer arranque
# de Claude Code.

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

# ── 1. Clonar repos del manifiesto ────────────────────
echo ""
echo "=== Clonando repos del manifiesto ==="

while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    url=$(echo "$line" | awk '{print $1}')
    ruta=$(echo "$line" | awk '{print $2}')
    local_path=~/misRepos/"$ruta"

    if [ -d "$local_path" ]; then
        echo "[OK]   Ya existe: $ruta"
    else
        echo "Clonando $ruta ..."
        git clone "$url" "$local_path"
        if [ $? -ne 0 ]; then
            echo "[WARN] Falló el clone de $ruta — revisar acceso y clonar manualmente."
        else
            echo "[OK]   Clonado: $ruta"
        fi
    fi
done < "$MANIFEST"

# ── 2. Setup de symlinks ───────────────────────────────
echo ""
echo "=== Configurando symlinks ==="
chmod +x "$SETUP"
"$SETUP"

# ── 3. Sincronizar memoria ─────────────────────────────
echo ""
echo "=== Sincronizando memoria ==="
chmod +x "$PULL"
"$PULL"

echo ""
echo "======================================"
echo "  Bootstrap completado."
echo "  Lanzar Claude Code."
echo "======================================"
