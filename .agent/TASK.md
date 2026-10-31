# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[01.1]` Adjust Circuit Breaker Fail-Stop Threshold to 3 Consecutive Attempts on General Starters
- **Status:** RUNNING
- **Scope:**
  - Atualizar o limite do Fail-Stop Protocol de 2 para 3 tentativas consecutivas com a mesma causa raiz em templates gerais (`main`, `greenfield`, `brownfield`).
  - Preservar o limite estrito de 2 tentativas em `blackbox` (anti-ban), `infra` (daemon/containers) e `baremetal` (host/kernel).
- **Target Branches:** `main`, `greenfield`, `brownfield`

---

## Completed Tasks Log

> Cycles 00–09 archived in `.agent/ARCHIVE.md` (up to `[v1.1.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|

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
