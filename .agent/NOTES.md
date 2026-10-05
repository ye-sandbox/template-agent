# NOTES.md — Active Contracts and Discovered Gotchas

> Stores active legacy contracts (endpoints, queues, schemas) and critical gotchas.
> For rigid architectural constraints and legacy behaviors, see `.agent/INVARIANTS.md`.
> Cumulative architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md).

---

## How to Use this File (for the Agent)

1. **Read before planning any task.** Active contracts and invariants take precedence over assumptions.
2. **Keep this file lean:** Store only active data contracts, multi-agent topologies (e.g. `dev-trinity-sentinel`), open technical debt, and investigated gotchas.
3. **Substantive architectural decisions:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md). Do NOT accumulate historical decisions here to prevent context bloat.

---

## Active Runtime & Multi-Agent Contracts

### 1. Multi-Agent Topology & Ensemble Contract (Dev Trinity Sentinel)

When operating under Maestri / Antigravity orchestration, use the canonical **Dev Trinity Sentinel Ensemble**:
- **Planner:** Manages `.agent/TASK.md` and promotes tasks.
- **Developer:** Executes changes strictly inside `Systems Involved` under `aether-guard wrap`.
- **Auditor:** Read-only audit of diff against task DoD and `AGENTS.md`.
- **Aether Sentinel:** Live supervisor terminal monitoring command security.

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
