# Stale memory: the problem git doesn't solve

## Why?

The article on contaminated memory describes a problem of **wrong identity**: Claude Code thinks it is in one project when it is actually in another. The solution — git plus symlinks — fixes that. But there is a second problem, more silent, that persists even with the sync system perfectly configured.

Claude Code accumulates memory. It never prunes it. And it makes no distinction between what it wrote yesterday and what it wrote two years ago.

## What?

### How memory ages

Each entry Claude Code writes in its project `*.md` files reflects the state of the system at that moment: architecture decisions, agreed conventions, the status of a task, the name of the person responsible for a module, a technical constraint that existed then.

Over time, those entries become outdated. The architecture changes. The constraints disappear. The responsible person leaves. The task marked "in progress" has been done for months.

The native Claude Code system has no mechanism to detect this:

- There are no timestamps on memory entries.
- There is no TTL or automatic invalidation.
- There is no distinction between recent and old memory.

The model reads all accumulated context at the start of each session, with equal confidence, regardless of when it was written.

### The difference from contaminated memory

Contaminated memory is a problem of **identity**: the model operates on memories from a different project.

Stale memory is a problem of **temporality**: the model operates on memories from the right project, but ones that are no longer true.

They are orthogonal problems. The sync system solves the first. It does not touch the second.

### The specific failure mode

What makes stale memory especially hard to detect is that the model acts with **well-founded but outdated confidence**. It is not inventing. It is not confusing projects. It is correctly remembering something that stopped being true.

The user has no signal distinguishing "fresh memory" from "stale memory". Both arrive in context the same way, with the same authority.

## What for?

||
|-|
|<sub>An example that occurred during the development of this system. In the [pySigHor](https://github.com/mmasias/pySigHor) project, an explicit memory strategy was adopted from the start: a `conversation-log.md` file that chronologically recorded each Claude Code session — decisions made, project state, instructions for the next session. The intent was correct: solving the problem of the model starting each session with no memory of previous ones. The result, after 49 conversations, was a file of over 4,500 lines that the model had to read in full at the start of each session to extract the current state. The last recorded instruction literally said: *"Read conversation-log.md (Conversation 49)"*. The file had to be manually split into two — [`conversation-log-001.md`](https://github.com/mmasias/pySigHor/blob/main/conversation-log-001.md) and [`conversation-log.md`](https://github.com/mmasias/pySigHor/blob/main/conversation-log.md) — when the growth made the system unmanageable. The solution to the incompleteness problem had turned into a massive staleness problem. And splitting into two files introduced a new risk: a session that only read the current file would miss the first 49. All three problems in this series, in a single real case.</sub>|

Understanding this dynamic changes how certain Claude Code behaviors are diagnosed:

**When the model proposes anachronistic solutions.** If memory records that "the database doesn't support transactions", the model will avoid proposing transactions even if the system has supported them for a year. Not ignorance: stale memory.

**When the model assigns responsibilities to people who are no longer around.** If memory says "the payments module is Ana's", the model will keep assuming Ana is the point of contact. The memory doesn't know Ana left.

**When the model avoids paths that are no longer blocked.** Technical constraints documented as temporary workarounds stay in memory indefinitely. The model respects them as if they were still in force.

In all these cases, the model's behavior is internally coherent. The problem is in the input data, not the reasoning.

## How?

Git provides traceability. That helps *diagnose* stale memory — `git log` on `projects/` shows when each entry changed — but does not help *prevent* it. The model does not consult git history before reading its context.

The solution must operate at a different level: in the content of the memory files themselves.

### Dating entries

The minimum intervention is to add explicit dates to the sections that age fastest:

```markdown
## Session state
_Updated: 2025-11-14_

- The memory constraint in the export module is still active (issue #312)
- The payments module is Ana's responsibility
```

A dated entry is an entry that can be evaluated. An undated entry is timeless by default, which in practice means the model treats it as always true.

### Distinguishing memory types by decay rate

Not all memory ages the same. It helps to separate it:

| Type | Examples | Decay |
|-|-|-|
| Architectural | code conventions, project structure | slow |
| Operational | task status, active constraints, ownership | fast |
| Historical | decisions made, discarded alternatives | does not decay |

Operational memory needs the most periodic review. Historical memory is paradoxically the most durable because it records *why* something was decided, not *how something currently is*.

### Periodic review as a discipline

The model does not clean up automatically, but the user can delegate the task to the model itself. A review session with an explicit instruction:

```
Read the CLAUDE.md for this project and mark as [stale?] any entry
you cannot verify by reading the current code.
```

That does not guarantee the model will catch everything that has decayed, but it introduces friction where there was none before. An entry marked `[stale?]` is visible; a silently false entry is not.

### What doesn't help

Adding more memory is not the solution. If state A is recorded and then state B is added without removing A, the context contains two contradictory truths. The model will try to reconcile them. Sometimes it does well; sometimes the result is noise.

The discipline of cleanup matters as much as the discipline of writing.

## What now?

Contaminated memory and stale memory share a structure: both are problems of **incorrect signal in context**, not of defective model reasoning. The difference is in the origin of the incorrect signal.

The sync system described in this repository solves contamination. Staleness requires editorial discipline: dating, classifying, reviewing, and pruning. None of that happens automatically with current tools.

There remains an open problem that neither of these approaches solves: ***the model doesn't know what it doesn't know***. If memory states something false with sufficient confidence, the model has no incentive to question it. The only detection mechanism available today is external: the user who notices the discrepancy between what the model assumes and what the code says.

That third problem has a different nature. And its solution too: [Incomplete memory: where the human stops being optional](incompleteMemory.md).
