# TASK.md — Current Infrastructure Task and Roadmap

> Defines WHAT needs to be done in infrastructure. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.

---

## Active Task

### [00.1] Map Topology and Provision Baseline Services

Map infrastructure requirements, configure environment variables in `.env.example`, record host ports and volumes in `.agent/SERVICES.md`, and author baseline services in `compose.yaml` (e.g. VictoriaLogs, Uptime Kuma, reverse proxy).

- [ ] `compose.yaml` created and validated with `docker compose config`.
- [ ] Ports recorded in `.agent/SERVICES.md` without collisions.
- [ ] Persistent storage volumes declared with appropriate permissions and host directories.
- [ ] Healthchecks configured across all provisioned containers.
- [ ] Memory and CPU limits specified in Compose service blocks.
- [ ] Ports and sensitive configuration parameters documented in `.env.example`.
- [ ] `README.md` and `README.pt-br.md` populated with real architecture (Mermaid), quickstart, configuration table (`.env.example`), and validation commands (zero heading emojis or unquantified buzzwords — see `readme-standard` skill).

---

## Completed Tasks Log

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[00.0]` | Initial infrastructure template scaffolding | [`0000000`] | `YYYY-MM-DD` |

---

## Backlog (Upcoming, in priority order)

- [ ] **[01.1]** Configure reverse proxy (Traefik or Nginx) with automated SSL termination
- [ ] **[01.2]** Implement automated backup routine for persistent volumes

---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

- [ ] Integrate Uptime Kuma alerts with webhooks (Discord / Telegram)
- [ ] Add unified observability dashboard with Grafana and VictoriaMetrics
