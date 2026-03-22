#!/bin/bash

cd ~/misRepos/myClaudeContext
git add -A
git commit -m "sync: estado sesión $(date '+%Y-%m-%d %H:%M')"
git push
