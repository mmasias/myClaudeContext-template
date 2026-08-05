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

Claude generates the commit, the semantic tag, runs the secret scan, and pushes:

```bash
# Claude runs:
git add <modified files>
git commit -m "type(scope): semantic description"
git tag "stable-<verb-subject-kebab-case>"
./check-claude-integrity.sh   # check the "Secret scan" section — if it reports a finding, stop and fix it before pushing
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

---

## 9. Maturity evaluation (biannual)

Different from the periodic audit (ritual 7, which evaluates activity per repo): this evaluates the whole system — memory content and tooling — with fresh eyes. Dedicated session, not mixed with other work.

1. Standard startup + `memory-check`.
2. Inventory of `projects/*/memory/` across the whole repo (not just the active project): files by age, pruning candidates.
3. Tooling inventory (`memory-push`, `memory-pull`, `memory-audit`, `check-claude-integrity.sh`, `linux/`/`macos/` wrappers): real usage, whether their logic still fits the current repo structure, documentation up to date.
4. If it hasn't run this quarter, run `memory-audit` (ritual 7); if already recent, reference its result.
5. Contrast with the previous evaluation, kept in a memory file dedicated to this evaluation's own history — not folded into an architecture/evolution document that belongs to a different subsystem. Did its weaknesses get resolved? Does its continuity verdict still hold?
6. New strengths and weaknesses: growth, recurring errors, gaps between what's documented and what's actually used.
7. Verdict and prioritized action plan, same format as the previous evaluation.
8. Persist as a new dated section in that dedicated memory file, and close with ritual 3.

> **Lesson:** if the file from step 5 ever ends up covering an unrelated subsystem's own architecture decisions (an orchestration layer's evolution, say), split them apart. A ritual instruction that points at a file scoped to a since-retired architectural premise will silently misfile every future evaluation, because nobody thinks to re-check ritual instructions when an architecture decision changes elsewhere. When a premise gets retired, grep its name across `RITUALES.md` and the scripts before moving on.

First run: informal, before this ritual existed. Cadence from then on: every six months.
