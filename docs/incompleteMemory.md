# Incomplete memory: where the human stops being optional

## Why?

The previous two problems are variants of the same category: incorrect signal in context. Contaminated memory brings signal from another project. Stale memory brings signal from the right project but outdated. In both cases there is something in memory that should not be there, or that should be different. The problem is one of quality.

This third problem is different in nature. There is no incorrect signal. There is an absence of signal. And the absence is not perceived as absence.

## What?

### The model doesn't know what it doesn't know

Claude Code builds its context from what is written in its memory files. What was never written simply does not exist for it. Not as missing data, not as NULL, not as a marked unknown. As nothing.

The distinction matters. In a database, an empty field is visible: there is a cell, it is empty, it can be detected. In Claude Code memory, what was never documented leaves no empty cell. The schema has no column for it because no one knew to add one.

The model operates with perfect coherence within what it knows. It does not experience incompleteness as a problem. Hence the qualifier: **comfortably** incomplete. The system works, gives reasoned answers, appears to know what it is doing. The absence is invisible from within.

### Why it happens

Claude Code memory is built incrementally, from what the user decides to document and from what the model notes during sessions. That process has structural biases:

- What gets documented is what gets worked on, not what exists.
- What gets noted is what changes, not what stays stable.
- Decisions made get recorded; decisions pending rarely do.
- What everyone knows and nobody says never gets written down.

The result is memory that can be coherent, up to date, and still represent only a fraction of the real project. The model has no way to know this.

### The difference from the other two problems

|| Problem origin | Model can detect it |
|-|-|-|
| Contaminated | Signal from another project | No |
| Stale | Outdated signal | No |
| Incomplete | Absent signal | No, by definition |

All three share that the model generates no alarm signal. But the first two are detectable from outside with tools: paths, dates, `git log`. Incomplete memory leaves no trace because what is missing left no trace when it was not written.

## What for?

The failure modes are invisible until someone external notices the discrepancy.

**The model designs without knowing a constraint that exists.** A team decides that all external data access goes through a cache layer. Nobody writes it in memory because it is a recent decision, obvious to everyone who was in the meeting. The model proposes direct access. The proposal is technically correct, architecturally incompatible.

**The model ignores an entire subsystem.** An audit module was added six months ago. It was never documented in the Claude Code context. The model makes changes to the authentication system without considering its effects on auditing. Not because it cannot reason about side effects, but because for it that module does not exist.

**The model doesn't know part of the team.** Two new people have been in the project for months. Their areas of responsibility, their decisions, their code conventions: none of that is in memory. The model keeps assigning tasks to who it remembers, ignoring who it does not know.

In all these cases the behavior is internally coherent. The problem is that the real world is larger than the world the model knows, and the model does not know it.

## How?

Honesty is required about the limits: there is no technical solution that eliminates this problem. Mitigations reduce the surface area of exposure. They do not close it.

### Explicit onboarding as a practice

When starting work on a project with Claude Code, the natural tendency is to go straight to the task. A more robust practice is to spend initial time describing what exists, not just what will be done:

```
Before we start: this project has these modules, these critical dependencies,
these non-negotiable constraints, these people and their areas. Write it down.
```

That onboarding does not happen automatically. It requires the user to decide and execute it.

### Templates with required sections

A blank `CLAUDE.md` invites writing what comes to mind. A template with fixed sections forces thinking about what might be missing:

```markdown
## Team and responsibilities
## Non-negotiable constraints
## External integrations
## Pending decisions
## What this project does NOT do
```

The last section is especially useful: documenting negative scope reduces the risk of the model proposing solutions outside it.

### Asking the model what it assumes

The model cannot report what it doesn't know, but it can report what it assumes. Periodically:

```
List the assumptions you are making about this project that are not
explicitly documented in your context.
```

The response is not exhaustive — unconscious assumptions will not surface — but conscious ones will. And a listed assumption is one that can be verified or corrected.

### The limit of all these mitigations

None of these practices solves the root problem. All depend on the user knowing what information is missing and taking the initiative to provide it. But if the user knows what is missing, the problem is already partially solved. The genuinely hard case is the one the user also doesn't identify as a gap.

There is no technical mitigation available for that.

## What now?

The three problems described in this series form a complete taxonomy of Claude Code memory failure modes:

| Problem | Nature | Solution |
|-|-|-|
| Contaminated | Wrong identity | Technical: paths + git |
| Stale | Wrong temporality | Process: date + review + prune |
| Incomplete | Absent signal | Human: irreducible |

The escalation is not accidental. Each problem is harder than the last. Each solution requires more from the human. The third takes that escalation to its logical conclusion: there is something the system cannot give itself, and that something can only come from someone who knows the project from outside the memory.

This provides a concrete answer to a question that AI tool debates usually leave abstract: where the human fits in. Not as a supervisor who detects errors — that is a review role, partially automatable. As a **source of signal the system cannot generate for itself**.

This is not a limitation of the model's intelligence. It is an epistemological constraint: you cannot describe the contents of a void you do not perceive as a void. ***The human is not the safety net. The human is an architectural component of the system***.
