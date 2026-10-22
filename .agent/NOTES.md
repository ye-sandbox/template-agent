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

## Active Contracts

### 1. Active Storage & Port Invariants

- **Persistence Policy:** Named volumes for databases/high-write engines (VictoriaLogs, Postgres, SQLite); read-only bind mounts (`:ro`) for configuration files.
- **Host Port Mapping:** Must match allocation in `.agent/SERVICES.md`.

### 2. Multi-Agent Collaboration Roles (Optional)

> For infrastructure or homelab environments operating with multiple AI agents. If single-agent, leave as default.

- **Planner:** Manages `.agent/TASK.md` and coordinates service deployment tasks.
- **Operator (Developer):** Authors Compose files, Dockerfiles, and IaC manifests strictly within task scope.
- **Auditor:** Verifies resource boundaries, non-root users, healthchecks, and strict zero `-v` in teardown commands.

---

## Gotchas and Quirks

- **Host UID on bind mounts:** Non-root container users (1000, 65534) require compatible host permissions. Named volumes for databases/logs bypass this issue — remember the strict `down -v` prohibition in `AGENTS.md`.
- **Host port binding:** Check `SERVICES.md` before mapping `ports:`; collisions manifest as `bind: address already in use`.

---

## Assumed Technical Debt

| Debt | Decision Rationale | Revisit When |
|---|---|---|
| `[e.g.: Single-node without replication]` | `[Simplified single-node homelab setup]` | `[When reaching scale limits]` |
