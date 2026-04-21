# myClaudeContext — template

<div align=right>

||
|-
|<sub><i>This repository is Claude Code's identity substrate:<br>the machine is replaceable, the context is not.<br>Like [SOMA](https://es.wikipedia.org/wiki/Soma_(videojuego)), but without the philosophical dilemma.<br></i></sub>

</div>

Template for syncing Claude Code and Gemini CLI context across multiple machines using symlinks and git. Once set up, both agents start with the same context on any machine.

> **Background.** This system was born from analyzing three structural problems with AI agent memory: contaminated memory, stale memory, and incomplete memory. If you want to understand the motivation before using the tool, the articles are in [`docs/`](docs/losTresProblemas.md).

---

## The problem it solves

Claude Code and Gemini CLI store their context in local files:

- `~/.claude/CLAUDE.md` / `~/.gemini/GEMINI.md` — global behavior instructions
- `~/.claude/projects/` — per-project memory (decisions, session state, notes)

By default, that context lives only on the local machine. When working across multiple machines, each one accumulates its own version that evolves independently. This repository fixes that divergence.

---

## Structure

```
myClaudeContext/
├── global/
│   └── CLAUDE.md              <- ~/.claude/CLAUDE.md and ~/.gemini/GEMINI.md
├── proyectos/
│   ├── CLAUDE.md              <- ~/misRepos/proyectos/CLAUDE.md
│   └── <project>/
│       └── CLAUDE.md          <- <project>/.claude/CLAUDE.md and <project>/GEMINI.md
├── projects/                  <- ~/.claude/projects/ (project memory)
├── linux/
│   ├── setup-claude-symlinks.sh
│   ├── pull-claude-context.sh
│   └── push-claude-context.sh
├── macos/
│   ├── setup-claude-symlinks.sh
│   ├── pull-claude-context.sh
│   └── push-claude-context.sh
├── bootstrap.sh               <- full setup for a new machine (cross-platform)
├── add-repo.sh                <- add a new project to the system (cross-platform)
├── check-claude-integrity.sh  <- integrity validation (cross-platform)
├── memory-audit.sh            <- audit inactive repos (cross-platform)
├── manifiesto.txt             <- repos that must exist in the system
├── RITUALS.md                 <- complete ritual reference
└── docs/                      <- motivation and system analysis
```

The actual files live in this repository. On each machine, symlinks point to them from the locations each tool expects.

Both agents share the same physical file per level. Sections marked `[Claude Code only]` and `[Gemini only]` in `global/CLAUDE.md` allow agent-specific instructions without duplicating files.

---

## Prerequisite: consistency across machines

This system depends on maintaining the same directory structure and username on all machines.

> *Want order? Be orderly.*

If on one machine projects live in `~/misRepos/proyectos/` and on another in `~/Documents/projects/`, symlinks will point to non-existent paths and the system will fail silently — no warnings, no obvious errors.

The structure must be decided before starting and kept consistent. Configure it by editing the two variables at the top of each script:

```bash
REPO=~/misRepos/myClaudeContext      # location of this repository
PROYECTOS_DIR=~/misRepos/proyectos   # location of your projects
```

---

## How to use it

### 1. Clone and adapt

```bash
git clone https://github.com/mmasias/myClaudeContext-template
cd myClaudeContext-template

# Point to your own private repository
git remote set-url origin https://github.com/<user>/myClaudeContext
```

The included `CLAUDE.md` files use **Ibuprofeno Fernández** as a placeholder character. Replace them with your actual context before using the system.

### 2. First time on a new machine

```bash
git clone https://github.com/<user>/myClaudeContext ~/misRepos/myClaudeContext
chmod +x ~/misRepos/myClaudeContext/bootstrap.sh
~/misRepos/myClaudeContext/bootstrap.sh
```

`bootstrap.sh` clones the repos from the manifest, creates symlinks, and syncs memory.

> **Critical:** Claude Code must not be launched before `bootstrap.sh` finishes. If it starts first, it creates `~/.claude/projects/` as a real directory and the symlinks end up broken. Fix: run `setup-claude-symlinks.sh` again.

### 3. Daily workflow

```bash
# When starting work
memory-pull

# When finishing (with Claude active — Claude handles the semantic close)
# When finishing (without Claude)
memory-push
```

---

## Global commands

After running `bootstrap.sh` or `setup-claude-symlinks.sh`, the following commands are available from any directory:

| Command | Equivalent to |
|---|---|
| `memory-pull` | `linux/pull-claude-context.sh` (or `macos/`) |
| `memory-push` | `linux/push-claude-context.sh` (or `macos/`) |
| `memory-check` | `check-claude-integrity.sh` |
| `memory-bootstrap` | `bootstrap.sh` |
| `memory-audit` | `memory-audit.sh` |

The scripts create symlinks in `~/.local/bin/` pointing to the correct platform version.

> **macOS:** verify that `~/.local/bin` is in `$PATH`. Homebrew does not add it by default. Add to `.zshrc`: `export PATH="$HOME/.local/bin:$PATH"`

---

## Integrity validation

```bash
memory-check
```

Verifies Claude and Gemini symlinks, remote state, indexed memory consistency, and Linux/macOS path correspondence. Output is `[OK]` / `[WARN]` / `[ERROR]` per check. Exit code = number of errors.

**When to run it:** after a problem, after installing on a new machine, or when something behaves unexpectedly.

**Fix based on what it reports:**

| Error | Action |
|---|---|
| Broken or mispointed symlink | `./linux/setup-claude-symlinks.sh` (or `macos/`) |
| `~/.claude/projects` is a real directory (Linux) | `./linux/setup-claude-symlinks.sh` |
| `~/.claude/projects` is a symlink (macOS) | `./macos/setup-claude-symlinks.sh` |
| Repo missing from manifest | The check outputs the exact `git clone` command |
| Broken reference in MEMORY.md | Manual file edit |
| Repo diverged from remote | Manual git conflict resolution |

---

## Adding a new project

```bash
./add-repo.sh https://github.com/user/new-project.git
```

Clones the repo into `~/misRepos/proyectos/<name>`, adds it to the manifest, and regenerates symlinks. Then run `memory-push` to sync.

---

## Auditing inactive repos

```bash
memory-audit
```

Evaluates repos with accumulated memory and issues a verdict for each:

| Verdict | Meaning |
|---|---|
| `ARCHIVE` | No real memory; delete the directory from `projects/` |
| `REVIEW` | Has memory but inactive for >90 days |
| `ACTIVE` | Recent usage |

---

## How the context cascade works

Each agent loads its instructions in order, from most general to most specific:

**Claude Code:**
```
~/.claude/CLAUDE.md                              -> global behavior
~/misRepos/proyectos/CLAUDE.md                   -> shared context for all projects
~/misRepos/proyectos/<project>/.claude/CLAUDE.md -> per-project context
```

**Gemini CLI:**
```
~/.gemini/GEMINI.md                              -> global behavior (same file as Claude)
~/misRepos/proyectos/<project>/GEMINI.md         -> per-project context (same file as Claude)
```

Project files are excluded via `.gitignore` (`.claude/` and `GEMINI.md`) so they are not published to GitHub.

---

## What gets synced and what doesn't

Inside `projects/`, only `*.md` files (intentional memory) are tracked in git:

| Type | What it is | In git |
|---|---|---|
| `*.md` | Intentional project memory | ✓ |
| `*.jsonl` | Session logs, continuous writes | ✗ |
| `*.json` | Session indexes and metadata | ✗ |
| `*.txt` | Tool results | ✗ |

---

## Architecture notes

**`~/.claude/` may exist before Claude Code.** VSCode plugins or other tools can create the directory. Scripts use `mkdir -p` to handle both cases without conflict.

**Project identity depends on the absolute path.** Claude Code generates each project's identifier from its absolute path on disk. If that path differs between machines, memory is not shared even if the repository content is identical. This is why path consistency is a non-negotiable requirement of the system.

**Linux vs macOS: different behavior for `~/.claude/projects/`.** On Linux, `projects/` is a direct symlink to the repo — Claude Code writes straight into git. On macOS, `projects/` must be a real directory; the `pull` and `push` scripts handle copying directories and translating paths between platforms.

**Git as a safety net.** Even if context is lost in a session due to a badly resolved conflict, `git log` and `memory-stable-YYYY-MM-DD` tags allow recovery of any previous state of the `*.md` files.

**Conflict management.** If you work on two machines without syncing and both modify the same file, git will generate a conflict on push. Resolve it manually: fix the conflict, push from one machine, then pull from the other before continuing.

---

> Complete operational reference: [RITUALS.md](RITUALES.md)
