# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[02.2]` Subagent Role Taxonomy & Delegation Specifications
- **Status:** RUNNING
- **Scope:** Define canonical subagent topology (lead, worker, reviewer), delegation contracts, and progressive context handoffs in template hub and starters.
- **Target Branches:** `main`, `greenfield`, `brownfield`

---

## Completed Tasks Log

> Cycles 00–01 archived in `.agent/ARCHIVE.md` (up to `[v1.2.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[02.1]` | Next Milestone / Epic Planning (Epic 02: Multi-Agent Orchestration) | `f948d2b` (main) | 2026-11-06 |

---

## Backlog (Upcoming, in priority order)

- `[02.3]` Isolated Worktree & Sandbox Runner Integration: Implement lightweight worktree isolation recipes (`git worktree`) for parallel task wave execution.
- `[02.4]` Micro-Contract & Parallel Wave Validation in CI: Add contract assertions for `run-wave.sh` micro-contracts (`Read:`, `Paths:`, `Verify:`) and parallel tags (`[PARALLEL: Wx]`) in starter contract checks.
- `[02.5]` Multi-Account Quota Failover Guidance & Starter Parity: Propagate and document multi-account quota routing conventions across starters.



---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

*(empty)*

---

## How to Keep this File Lean

1. Detail only in the active task. When complete $\rightarrow$ log one line (title + hash) and promote next task.
2. Backlog is a list of titles. Full spec only when an item becomes the active task.
3. Large scope $\rightarrow$ issue in tracker; link only here.
4. Next ID = last ID in log (or active task). Cycle wrap-up and `[99.1]`: see `AGENTS.md`.
5. Do not paste full commit messages into this file. Deep history: `git log` / `.agent/NOTES.md`.
