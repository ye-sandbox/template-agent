# TASK.md — Tasks and Roadmap for Legacy Codebase

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> For Brownfield projects, this file begins with the **Discovery Protocol (Task 00.1)**
> so the agent audits the codebase before undertaking development.

---

## Active Task

### 📌 Task [00.1]: Project Discovery and Context Mapping (Discovery)

- **Description:** Audit the existing repository to map the real stack, build/run scripts, test suite, application entrypoints, and environment variables, populating `AGENTS.md` with accurate data.
- **Systems Involved:** `discovery`, `docs`, `setup`
- **Action Type:**
  - [x] Read-only / Documentation
  - [ ] Source code changes
- **Status:** READY FOR PLANNING
  *(Workflow: `READY FOR PLANNING` → `PLANNING` on presenting plan → approval → `RUNNING`)*

### Acceptance Criteria
- [ ] Inspect dependency manifests (`package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, etc.) and update `AGENTS.md` with languages, versions, and official package managers.
- [ ] Identify and verify actual validation commands (local test runner, linter, build) and record them in `AGENTS.md`.
- [ ] Inspect test suite status (whether existing tests pass 100% or have known failures).
- [ ] Map primary application entrypoints (HTTP routes, queue workers, CLI scripts, or schedulers).
- [ ] Audit environment variables and verify that `.env.example` aligns with references in source code.
- [ ] Document initial quirks or invariants discovered in `.agent/INVARIANTS.md`.

---

## Completed Tasks Log

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| [00.0] | Injected brownfield template into legacy codebase | [`0000000`] | [YYYY-MM-DD] |

---

## Backlog (Upcoming, in priority order)

- [ ] **[01.1]** [First business task, bugfix, or feature in legacy] — `[module]`
- [ ] **[01.2]** [Subsequent task] — `[module]`

---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

- [ ] [Map priority technical debt for characterization test coverage]
- [ ] [Expand test coverage across critical legacy modules]

---

## How to Keep this File Lean

1. Detail only in the active task. When complete $\rightarrow$ log one line and promote the next task.
2. Backlog is a list of titles. Next ID = last ID in log (or active task). Cycle wrap-up and `[99.1]`: see `AGENTS.md`.
