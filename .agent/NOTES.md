# NOTES.md — Active Infrastructure Contracts and Gotchas

> Stores active service port bindings, volume strategies, and multi-agent orchestration contracts.
> Architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md).
> Service taxonomy and port registry live in [`.agent/SERVICES.md`](SERVICES.md).

---

## How to Use this File (for the Agent)

1. **Read before planning any task:** Active contracts prevent host-level port collisions and volume wipes.
2. **Keep this file lean:** Only store active infrastructure contracts, multi-agent topology, and critical runtime gotchas.
3. **Architectural decisions:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md).

---

## Active Infrastructure & Multi-Agent Contracts

### 1. Multi-Agent Topology & Ensemble Contract (Dev Trinity Sentinel)

When operating under Maestri / Antigravity orchestration:
- **Planner:** Manages `.agent/TASK.md` and coordinates service deployment tasks.
- **Developer:** Authors Compose files, Dockerfiles, and IaC manifests under `aether-guard wrap`.
- **Auditor:** Verifies resource limits, non-root users, healthchecks, and strict zero `-v` in teardown commands.
- **Aether Sentinel:** Live supervisor terminal monitoring destructive commands (`prune`, `down -v`, `rm -rf`).

### 2. Active Storage & Port Invariants

- **Persistence Policy:** Named volumes for databases/high-write engines (VictoriaLogs, Postgres, SQLite); read-only bind mounts (`:ro`) for configuration files.
- **Host Port Mapping:** Must match allocation in `.agent/SERVICES.md`.

---

## Gotchas and Quirks

- **Host UID on bind mounts:** Non-root container users (1000, 65534) require compatible host permissions. Named volumes for databases/logs bypass this issue — remember the strict `down -v` prohibition in `AGENTS.md`.
- **Host port binding:** Check `SERVICES.md` before mapping `ports:`; collisions manifest as `bind: address already in use`.

---

## Assumed Technical Debt

| Debt | Decision Rationale | Revisit When |
|---|---|---|
| `[e.g.: Single-node without replication]` | `[Simplified single-node homelab setup]` | `[When reaching scale limits]` |
