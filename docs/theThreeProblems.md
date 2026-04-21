# The three problems with Claude Code memory

This repository was born with a concrete goal: solving the problem of syncing Claude Code context across machines using Git, symlinks, a setup script — something fairly technical and well-defined.

But while documenting it, something unexpected emerged. Solving the sync problem required understanding how Claude Code memory actually works. And understanding how it works made it possible to identify not one but three distinct ways that memory can fail. Three problems with different natures, different diagnoses, and different solutions.

These problems originate in the architecture of Claude Code, not in git. They appear the same in any workflow: with or without version control, with or without cross-machine sync.

The third problem also allows addressing something that AI tool debates usually leave abstract: where the human fits in. The answer that emerges is not "supervisor" / "validator" / "safety net". It is more structural than that — and it requires understanding the three problems in order.

## The taxonomy

| Problem | The model operates with... | Solution |
|---|---|---|
| Contaminated memory | Memories from another project | Technical |
| Stale memory | Correct but outdated memories | Process |
| Incomplete memory | Absent signal not perceived as absent | Human |

## The three problems in one sentence each

**Contaminated memory** — Claude Code identifies each project by its absolute path on disk. If a working directory is deleted and another is created at the same path — or a different repository is cloned into that same location — the model inherits the previous project's memory without any warning.

**Stale memory** — Memory accumulates but is never pruned. The model makes no distinction between what it wrote yesterday and what it wrote two years ago. It operates with the same confidence on memories that may no longer be true.

**Incomplete memory** — What was never written does not exist for the model. Not as missing data: as nothing. The model does not experience incompleteness because it has no way to perceive the outline of what it does not know.

## Why order matters

The three articles are written to be read in sequence. Each one assumes the previous and builds on it. The escalation is deliberate: each problem is harder than the last, each solution requires more from the human, and the third takes that escalation to its conclusion.

1. [Contaminated memory: what Claude Code doesn't document about how it remembers](contaminatedMemory.md)
2. [Stale memory: the problem git doesn't solve](staleMemory.md)
3. [Incomplete memory: where the human stops being optional](incompleteMemory.md)
