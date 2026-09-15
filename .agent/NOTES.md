# NOTES.md — Rapid Decisions and Legacy Contracts

> Stores the WHY of technical changes and discoveries.
> For rigid constraints and historical quirks, use `.agent/INVARIANTS.md`.
> This file tracks decisions made during active tasks and mappings of active contracts.

---

## How to Use this File (for the Agent)

1. **Read before planning any task.**
2. **Add a new entry when:**
   - A non-obvious behavior or gotcha is investigated/resolved.
   - A new data contract (schema/payload) is mapped or extended backward-compatibly.
   - Deliberate technical debt is assumed during a bugfix.
3. **Keep entries short and objective.**

---

## Recent Technical Decisions

### [YYYY-MM-DD] [Title of Decision or Legacy Fix]

- **Context:** [What problem or bug was being addressed]
- **Decision:** [What was implemented to preserve compatibility]
- **Alternatives Considered:** [Why larger refactoring was avoided in favor of surgical scope]
- **Consequences:** [Impact and characterization tests added]

---

## Active Data Contracts

### Critical Endpoints / Queues

| Channel / Route | Producer | Consumer | Schema / Notes |
|---|---|---|---|
| `[e.g.: POST /api/v1/orders]` | `[Legacy Frontend]` | `[Backend Worker]` | `[Must retain legacy fields]` |

---

## Assumed Technical Debt

| Debt | Legacy Rationale | Revisit When |
|---|---|---|
| `[e.g.: Manual validation without Zod/Pydantic]` | `[Module lacks full static typing]` | `[When complete test suite is available]` |
