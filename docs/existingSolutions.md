# Existing solutions for syncing Claude Code context

The problem of syncing `~/.claude/` across machines has solutions — several, in fact. What follows is an inventory of active tools found, with their respective approaches.

Anthropic does not offer native synchronization. There is an [open feature request](https://github.com/anthropics/claude-code/issues/25739) from February 2026 with no official response.

---

## Available tools

| Tool | Approach | Complexity |
|---|---|---|
| [claude-brain](https://github.com/toroleapinc/claude-brain) | Git + hooks + LLM semantic merge | High |
| [claude-sync (renefichtmueller)](https://github.com/renefichtmueller/claude-sync) | Local encryption + cloud storage | Medium |
| [CCMS](https://github.com/miwidot/ccms) | rsync over SSH | Low |
| [claude-code-multi-machine-setup](https://github.com/Peter-Moriarty/claude-code-multi-machine-setup) | Git as source of truth + scripts | Medium |
| [claude-mem](https://github.com/thedotmack/claude-mem) | Automatic session capture + AI compression | High |
| [claude-cognitive](https://github.com/GMaN1911/claude-cognitive) | Working memory with attention + multi-instance coordination | High |
| [claude-code-context-sync](https://github.com/Claudate/claude-code-context-sync) | Save and restore context between windows | Low |
| [shaike1/claude-sync](https://github.com/shaike1/claude-sync) | GitHub as sync backend | Medium |

---

## Notes

**claude-brain** is the most complete solution: it syncs memory, skills, agents, rules, and settings. It uses semantic merging to deduplicate contradictory entries in multi-machine contexts. It is also the most opinionated.

**CCMS** and **claude-code-context-sync** are the lightest options. Suitable if the goal is simply moving files between machines without additional logic.

**claude-mem** attacks the problem from a different angle: instead of syncing state, it automatically captures what happens during each session and compresses it for injection into future sessions. Closer to a solution for the stale memory problem than pure synchronization.

None of these tools explicitly document or mitigate the [three memory failure modes](theThreeProblems.md). They solve transport; semantics remain the user's responsibility.
