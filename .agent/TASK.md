# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[01.6]` Next Hub Evolution / Maintenance Task
- **Status:** READY FOR PLANNING
- **Scope:** Awaiting user direction for the next hub milestone or template enhancement.
- **Target Branches:** TBD

---

## Completed Tasks Log

> Cycles 00–09 archived in `.agent/ARCHIVE.md` (up to `[v1.1.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[01.1]` | Adjust circuit breaker threshold to 3 consecutive failures on general starters | `b7731e8` (main), `2b5128c` (greenfield), `e3f681c` (brownfield) | 2026-10-31 |
| `[01.2]` | Pre-Approved Task Fast-Track (`APPROVED`) & `task-queue` Skill Integration | `cdbec44` (main), `7fddee8` (greenfield), `7e5fc61` (brownfield), `9c520f5` (blackbox), `c4a92b7` (infra), `03f8e0e` (baremetal) | 2026-10-31 |
| `[01.3]` | Parallel Task Waves (`[PARALLEL: Wx]`) & Multi-Account Quota Routing in `task-queue` | `e8d74b4` (main), `a62c937` (greenfield), `5428136` (brownfield), `135cbd5` (blackbox), `c253b20` (infra), `6512f5b` (baremetal) | 2026-10-31 |
| `[01.4]` | Token-Efficient Wave Runner (`run-wave.sh`), `Read:/Paths:/Verify:` Micro-Contract, `gemini-3.8-flash-medium` Default & `.multigravity/` Ignore Invariant | `c18de50` (main), `046fec3` (greenfield), `c0b1139` (brownfield), `00328ea` (blackbox), `2737eb8` (infra), `5c093f2` (baremetal) | 2026-11-01 |
| `[01.5]` | Governance Hardening: ADR Canonicalization, NOTES.md Task Heading Ban & Knowledge DoD Guardrail | `88eddd8` (main), `68a968d` (greenfield), `e3890ac` (brownfield), `1c92cf3` (blackbox), `99c9de6` (infra), `e123f4a` (baremetal) | 2026-11-03 |

---

## Backlog (Upcoming, in priority order)

*(empty)*


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
