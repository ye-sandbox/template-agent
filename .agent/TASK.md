# TASK.md — Current Task and Roadmap
 
> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

### 📌 Task [01.2]: Post-v1.0.0 Foundation & Starter Ecosystem Roadmap

- **Description:** Define next foundation tasks, starter enhancements, and guardrails following the v1.0.0 milestone.
- **Systems Involved:** `hub`, `docs`
- **Action Type:**
  - [x] Read-only / Documentation
  - [ ] Source code changes
- **Status:** READY FOR PLANNING
  *(Workflow: `READY FOR PLANNING` → `PLANNING` on presenting plan → approval → `RUNNING`)*

### Acceptance Criteria
- [ ] Review starter feedback and identify upcoming architectural milestones
- [ ] Formulate prioritized tasks in backlog

---

## Completed Tasks Log

> Cycles 00–20 archived in `.agent/ARCHIVE.md` (up to `[v1.0.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[01.1]` | Standardize In-Code Invariants across Starter Templates | `02270d7`, `d5a6a88`, `c1d8622`, `ba297fb`, `fc16dbd`, `8574f8b`, `873f942`, `58505d0` | 2026-10-19 |

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
