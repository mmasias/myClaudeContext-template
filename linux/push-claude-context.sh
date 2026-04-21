#!/bin/bash

REPO=~/misRepos/myClaudeContext

cd "$REPO"
git add -A
git commit -m "sync: estado sesión $(date '+%Y-%m-%d %H:%M')"
git push
push_status=$?

if [ $push_status -ne 0 ]; then
    echo "Push fallido — el repo puede estar en estado inconsistente. Revisar manualmente."
    exit 1
fi

# Tag de estado estable (fallback sin Claude activo)
TAG="memory-stable-$(date +%Y-%m-%d)"
git tag -f "$TAG"
git push origin "refs/tags/$TAG" --force
echo "Tag creado: $TAG"
