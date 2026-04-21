# Rituals

Operational reference for the context system. Each ritual covers a moment in the lifecycle.

---

## 1. New machine

Once, before the first Claude Code launch:

```bash
git clone https://github.com/<user>/myClaudeContext ~/misRepos/myClaudeContext
chmod +x ~/misRepos/myClaudeContext/bootstrap.sh
~/misRepos/myClaudeContext/bootstrap.sh
```

`bootstrap.sh` handles everything: cloning repos from the manifest, creating symlinks (Claude Code and Gemini CLI), and syncing memory. When done, launch Claude Code or Gemini CLI.

> **Critical:** Claude Code must not be launched before bootstrap finishes. If it starts first, it creates `~/.claude/projects/` as a real directory and the symlinks end up broken. Fix: run `setup-claude-symlinks.sh` again.

---

## 2. Session start

```bash
memory-pull
```

Verifies minimum integrity (symlinks, remote state) before syncing. Aborts with a clear message if something is wrong.

> **If the script fails:** run `memory-bootstrap`. Bootstrap reconstructs the correct state from scratch and is safe to run at any time — it does not overwrite what is already correct.

---

## 3. Session end with Claude active

Claude generates the commit, the semantic tag, and pushes:

```bash
# Claude runs:
git add <modified files>
git commit -m "type(scope): semantic description"
git tag "stable-<verb-subject-kebab-case>"
git push
git push origin "refs/tags/stable-<description>" --force
```

The tag reflects the dominant topic of the session. Examples:
- `stable-setting-up-environment`
- `stable-updating-project-memory`
- `stable-adding-new-project`

Format: kebab-case, 50 characters maximum.

---

## 4. Session end without Claude

```bash
memory-push
```

Generates a generic commit (`sync: session state YYYY-MM-DD HH:MM`) and a date tag (`memory-stable-YYYY-MM-DD`) as a fallback. Less semantic but guarantees memory is synced.

---

## 5. Integrity validation

```bash
memory-check
```

Output is `[OK]` / `[WARN]` / `[ERROR]` per check. Exit code = number of errors.

When to run it: after a problem, after a reinstall, or when something behaves unexpectedly.

**Fix based on what it reports:**

| Error | Action |
|---|---|
| Broken or mispointed symlink (Claude or Gemini) | `./linux/setup-claude-symlinks.sh` (or `macos/`) |
| Repo missing from manifest | The check outputs the exact `git clone` command |
| Broken reference in MEMORY.md | Manual file edit |
| `.jsonl/.json/.txt` files tracked in git | `git rm --cached <file>` |
| Repo diverged from remote | Manual git conflict resolution |

---

## 6. Memory recovery

View the history of stable states:

```bash
cd ~/misRepos/myClaudeContext
git tag -l "stable-*" | sort
git tag -l "memory-stable-*" | sort
```

Inspect a past state:

```bash
git show <tag>:projects/<project>/memory/MEMORY.md
```

Restore a project's memory to a previous point:

```bash
git checkout <tag> -- projects/<project>/memory/
git commit -m "fix(memory): restore state from <tag>"
git push
```

---

## 7. Periodic audit

When the system accumulates inactive repos:

```bash
memory-audit
```

Evaluates repos with memory in `projects/` and issues a verdict for each:

| Verdict | Meaning |
|---|---|
| `ARCHIVE` | No real memory; delete the directory from `projects/` |
| `REVIEW` | Has memory but inactive for >90 days |
| `ACTIVE` | Recent usage |

---

## 8. Adding a new repo to the system

```bash
~/misRepos/myClaudeContext/add-repo.sh https://github.com/user/new-repo.git
```

Clones the repo into `~/misRepos/proyectos/<name>`, adds it to the manifest, and regenerates symlinks. Then close the session normally (ritual 3 or 4) to sync the manifest.

On other machines: `memory-pull` + `./linux/setup-claude-symlinks.sh` (or `macos/`).
