# NOTES.md — Infrastructure Decisions, Context, and Contracts

> Stores the WHY, not the WHAT or HOW.
> Records infrastructure architectural decisions, network/volume trade-offs, and discovered gotchas.

---

## How to Use this File (for the Agent)

1. **Read before planning any task:** Recorded decisions prevent regressions or host-level port/storage collisions.
2. **Add an entry when:**
   - A structural decision is made (e.g., choice between Docker Compose vs Nomad/K3s, Traefik vs Caddy).
   - An atypical container behavior is uncovered (e.g. non-root UID requirements on bind mounts).
   - Retention or backup policies are adjusted.

---

## Technical Decisions and Context

### [YYYY-MM-DD] [Named Volumes vs Bind Mounts Strategy]
- **Context:** Ensuring high I/O throughput and safe backup handling without user permission friction between host and container.
- **Decision:** Use **Named Volumes** for databases and high-write storage engines (VictoriaLogs, Postgres, SQLite in Uptime Kuma), and strict **Bind Mounts** (`:ro`) for configuration files tracked in Git.
- **Consequences:** Avoids recurring write permission errors (`Permission denied`) on mapped host directories.

---

## Gotchas and Quirks

- **Host UID on bind mounts:** Non-root container users (1000, 65534) require compatible host permissions. Named volumes for databases/logs bypass this issue — remember the strict `down -v` prohibition in `AGENTS.md`.
- **Host port binding:** Check `SERVICES.md` before mapping `ports:`; collisions manifest as `bind: address already in use`.

---

## Assumed Technical Debt

| Debt | Decision Rationale | Revisit When |
|---|---|---|
| `[e.g.: Single-node without replication]` | `[Simplified single-node homelab setup]` | `[When reaching scale limits]` |
