#!/bin/bash

REPO=~/misRepos/myClaudeContext

cd "$REPO"

# Staging explícito — solo memoria intencional, no archivos de sesión
git add proyectos/ global/

if git diff --cached --quiet; then
    echo "Sin cambios en memoria. Nada que pushear."
    exit 0
fi

git commit -m "sync: estado sesión $(date '+%Y-%m-%d %H:%M')"
git push

# Tag de fecha como punto de recuperación
TAG="memory-stable-$(date +%Y-%m-%d)"
git tag -f "$TAG"
git push origin "refs/tags/$TAG" --force

echo "Sync completado. Tag: $TAG"
