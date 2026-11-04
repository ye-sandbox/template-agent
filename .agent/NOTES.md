# NOTES.md — Active Contracts and Discovered Gotchas

> Stores active legacy contracts (endpoints, queues, schemas) and critical gotchas.
> For rigid architectural constraints and legacy behaviors, see `.agent/INVARIANTS.md`.
> Cumulative architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md).

---

## How to Use this File (for the Agent)

1. **Read before planning any task.** Active contracts and invariants take precedence over assumptions.
2. **Keep this file lean:** Store only active data contracts, multi-agent collaboration boundaries (if applicable), open technical debt, and investigated gotchas.
3. **Substantive architectural decisions:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md). Do NOT accumulate historical decisions here to prevent context bloat.
4. **CRITICAL INVARIANT:** NEVER create task-specific headings (e.g., `## [Task XX.Y] Description` or `### [Task XX.Y]`) in `NOTES.md`. Task completion details live in `git log` and `.agent/ARCHIVE.md`. Architectural decisions live in `docs/adr/decisions.md`. In `NOTES.md`, maintain and update ONLY the live tables/lists of active contracts, interfaces, and topology.

---

## Active Contracts

### 1. Active Data & Interface Contracts

#### Critical Endpoints / Queues

| Channel / Route | Producer | Consumer | Schema / Notes |
|---|---|---|---|
| `[e.g.: POST /api/v1/orders]` | `[Legacy Frontend]` | `[Backend Worker]` | `[Must retain legacy fields]` |

### 2. Multi-Agent Collaboration Boundaries (Optional)

> For legacy environments operating with multiple AI agents. If single-agent, leave as default.

- **Planner:** Manages `.agent/TASK.md`, maps legacy blast radius, and defines task scope.
- **Developer:** Executes changes strictly inside `Systems Involved` defined in the active task.
- **Auditor:** Read-only audit of diff against task DoD, regression tests, and `AGENTS.md`.

---

## Assumed Technical Debt

| Debt | Legacy Rationale | Revisit When |
|---|---|---|
| `[e.g.: Manual validation without Zod/Pydantic]` | `[Module lacks full static typing]` | `[When complete test suite is available]` |
