# TASK.md — Current Task and Roadmap (Blackbox)

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.

---

## Active Task

### 📌 Task [00.1]: Environment Setup and Authentication/Session Mapping

- **Description:** Perform initial reconnaissance on the target system, isolate the session/auth mechanism, define required environment variables in `.env`, and document global attributes in `.agent/ENDPOINTS.md`.
- **Systems Involved:** `[auth]`, `[env]`, `[endpoints]`
- **Action Type:**
  - [x] Read-only / Documentation
  - [ ] Source code changes
- **Status:** READY FOR PLANNING
  *(Workflow: `READY FOR PLANNING` → `PLANNING` on presenting plan → approval → `RUNNING`)*

### Acceptance Criteria
- [ ] Authentication mechanism and session lifecycle identified (cookies, CSRF tokens, required headers).
- [ ] `.env.example` populated with necessary credentials and connection endpoints.
- [ ] Section 1 (Global Context) of `.agent/ENDPOINTS.md` completed.
- [ ] Reproducible minimal cURL call for login or session verification tested successfully.

---

## Completed Tasks Log

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| [00.0] | Initialized Blackbox repository (ADD) | [`0000000`] | 2026-09-04 |

---

## Backlog (Upcoming, in priority order)

- [ ] **[00.2]** Map and dissect the first business endpoint in `.agent/ENDPOINTS.md` — `[endpoints]`
- [ ] **[01.1]** Implement resilient HTTP client with session, retry, and backoff — `[client]`
- [ ] **[01.2]** Create mocked fixtures and hermetic test suite — `[tests]`
- [ ] **[02.1]** Implement data extraction pipeline and DOM/JSON parser — `[parser]`

---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

- [ ] In-memory/Redis session caching
- [ ] Proxy rotation and rate-limit mitigation
- [ ] Export pipeline to PostgreSQL or message queue

---

## How to Keep this File Lean

1. Detail only in the active task. When complete $\rightarrow$ log one line and promote the next task.
2. Backlog is a list of titles. Next ID = last ID in log (or active task). Cycle wrap-up and `[99.1]`: see `AGENTS.md`.
