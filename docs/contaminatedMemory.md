# Contaminated memory: what Claude Code doesn't document about how it remembers

## Why?

Claude Code has memory. Not in the metaphorical sense of "conversation context", but in a very concrete and very GNU/Linux sense: it saves files to disk that persist between sessions.

Digging into the architecture behind that memory reveals surprises that — if not managed properly — can lead to **contaminated memory**: the model operating with memories from a previous project that, through an architectural accident, shares an identity with the current one.

> ||
> |-|
> <sub>*An example that occurred while writing this article: the template repository [ibuprofenofernandez/myClaudeContext-template](https://github.com/ibuprofenofernandez/myClaudeContext-template) was cloned locally to work with it. Later a fork was made at [mmasias/myClaudeContext-template](https://github.com/mmasias/myClaudeContext-template), the original clone was deleted from disk, and the fork was cloned into the same path. Claude Code didn't notice the change. The path on disk was identical, so it kept using the same memory folder, with the same accumulated context, as if nothing had happened. Two different repositories, one single "memory".*</sub>

This has nothing to do with LLM hallucinations. The model is not inventing things. It is a problem derived from concrete architectural decisions Anthropic made to model persistence in Claude Code. Very GNU/Linux in its approach: robust in general, fragile at the edges.

And what was found while exploring it is a bit unsettling.

## What?

### Where Claude Code memory lives

Claude Code stores its context in two locations:

```
~/.claude/CLAUDE.md
~/.claude/projects/
```

The first is the global instructions file — behavior, style, conventions. The second is the per-project memory directory: decisions made, session state, notes accumulated during work.

Inside `~/.claude/projects/`, each project occupies a folder whose name is the absolute path of the project on disk, with `/` replaced by `-`:

```
~/.claude/projects/-home-user-misRepos-myProject/
```

Here lies the problem.

### A project's identity is its path

Claude Code does not identify a project by its content, its git remote, or any explicit identifier. It identifies it by the **absolute path on disk** of the active session.

This has non-obvious consequences:

**If a repo is deleted and another is cloned at the same path**, Claude Code reuses the previous one's memory. The "memories" of the old project are there, mixed in with the new one's. The model may operate with design decisions, conventions, or session state that belong to a completely different project.

**If the same repo is cloned at different paths across machines** (`~/misRepos/project` on one, `~/Documents/project` on another), Claude Code generates different identifiers and memory is not shared, even though the repository content is identical.

**If the username differs between machines** (`/home/alice/` vs `/home/bob/`), same result: different identities, no shared memory.

The system assumes path stability. It is a reasonable assumption for an organized developer in a controlled environment. It breaks easily in real-world scenarios.

## What for?

Understanding this architecture enables informed decisions about three things:

**Memory management across machines.** If you work on multiple computers and expect Claude Code to maintain context coherence, you need to actively sync `~/.claude/projects/`. It does not happen automatically.

**Stale memory cleanup.** Claude Code does not clean up automatically. Deleted projects leave orphaned folders in `~/.claude/projects/` that accumulate indefinitely. And if a path is reused, that orphaned memory reactivates.

**Diagnosing unexpected behavior.** When Claude Code "remembers" something it shouldn't, or ignores something it should remember, the first thing to investigate is project identity: is it pointing to the right folder?

## How?

### A practical solution: git as the sync substrate

The solution that emerges from this experiment is to treat `~/.claude/projects/` as what it is: a set of text files that should be versioned and synced like any other important data.

The concrete approach:

1. Create a private repository (`myClaudeContext`) that centralizes all Claude Code memory
2. Move `~/.claude/projects/` into that repository
3. Create a symlink `~/.claude/projects -> ~/misRepos/myClaudeContext/projects/`
4. Repeat the symlink on each machine
5. `git pull` when arriving, `git push` when leaving

```
myClaudeContext/
├── global/CLAUDE.md       <- ~/.claude/CLAUDE.md
├── projects/              <- ~/.claude/projects/
└── proyectos/             <- per-project CLAUDE.md files
```

Inside `projects/`, not everything belongs in git. The `*.jsonl`, `*.json`, and `*.txt` files are session logs and tool results: they change continuously and generate conflicts. Only `*.md` files contain intentional memory and are worth versioning.

```
# .gitignore
*.jsonl
projects/**/*.txt
projects/**/*.json
```

### The non-negotiable requirement

This system only works if paths are consistent across machines. Same username, same directory structure. This is not a limitation of the sync system: it is a limitation of Claude Code's architecture.

> *Want order? Be orderly.*

### What git adds that the filesystem doesn't

Beyond sync, git provides something the native Claude Code system lacks: **traceability**. Every change to memory is recorded with a date and author. If Claude Code starts behaving unexpectedly, `git log` on `projects/` lets you reconstruct what changed and when.

The difference between a system that fails and a system that fails but can be diagnosed.

### A side observation about `~/.claude/`

During this experiment it was discovered that `~/.claude/` can exist before the first Claude Code launch. VSCode plugins and other development tools create the directory as a side effect. The setup system must assume the directory may or may not exist, and use `mkdir -p` accordingly. The assumption that `~/.claude/` is only created by Claude Code CLI is false.

## What now?

The template repository with the described solution is available at:
[github.com/mmasias/myClaudeContext-template](https://github.com/mmasias/myClaudeContext-template)

It includes setup, push, and pull scripts, cascading `CLAUDE.md` examples, and complete system documentation.

Two aspects remain open as future work:

- **Desync detection**: alerting when there are projects with context but no local repo, or local repos with no registered context
- **`$PROYECTOS_DIR` validation**: failing setup with a clear message if the projects directory doesn't exist, rather than completing silently without doing anything useful

Both are documented as open issues in the repository.

The sync system solves contamination. But there is a second problem that persists even when git and symlinks work perfectly: correct memory that is no longer true. That is the next article: [Stale memory: the problem git doesn't solve](staleMemory.md).
