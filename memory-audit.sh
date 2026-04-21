#!/bin/bash
# Evalúa repos con memoria fuera de proyectos/ y propone acción.
# Ejecutar al inicio de cada cuatrimestre o cuando el sistema acumula repos inactivos.

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

    # Excluir memoria global (raíz de misRepos)
    [ "$dirname" = "-home-$(whoami)-misRepos" ] && continue
    [ "$dirname" = "-Users-$(whoami)-misRepos" ] && continue

    memory_dir="$project_dir/memory"
    [ -d "$memory_dir" ] || continue

    found=$((found + 1))

    repo_name=$(echo "$dirname" | sed "s/-home-$(whoami)-misRepos-//" | sed "s/-Users-$(whoami)-misRepos-//")

    memory_files=$(find "$memory_dir" -name "*.md" ! -name "MEMORY.md" | wc -l)

    # Compatibilidad Linux/macOS para obtener timestamp de modificación
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
        verdict="ARCHIVAR  — sin memoria real; eliminar directorio de projects/"
    elif [ "$days_ago" -gt 90 ]; then
        verdict="REVISAR   — tiene memoria pero lleva >90 días inactivo"
    else
        verdict="ACTIVO    — uso reciente"
    fi

    echo ""
    echo "--- $repo_name ---"
    echo "  Archivos de memoria : $memory_files"
    echo "  Última actividad    : hace $days_ago días"
    echo "  Veredicto           : $verdict"

    if [ "$memory_files" -gt 0 ]; then
        find "$memory_dir" -name "*.md" ! -name "MEMORY.md" | while read -r f; do
            echo "    - $(basename "$f")"
        done
    fi
done

if [ "$found" -eq 0 ]; then
    echo ""
    echo "No se encontraron repos con memoria en projects/."
fi

echo ""
echo "======================================"
