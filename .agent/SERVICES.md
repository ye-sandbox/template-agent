# Infrastructure Services Catalog and Topology (SERVICES.md)

> 🎯 **Purpose of this File:** Canonical living source of truth for topology, host port allocations, data persistence volumes, and network policies for services provisioned in this repository.
>
> ⚠️ **Mandatory Rule for the Agent:** NEVER bring up or modify containers in `compose.yaml` without first recording and verifying potential conflicts in the tables below.

---

## 1. Host Port Allocations

> Record all ports bound on the host to avoid binding collisions (`bind: address already in use`).

| Host Port | Protocol | Service | Container Port | Exposure | Purpose / Endpoint |
| :---: | :---: | :--- | :---: | :--- | :--- |
| `9428` | TCP | `victorialogs` | `9428` | `127.0.0.1` (Local) | VictoriaLogs HTTP ingestion and web UI |
| `3001` | TCP | `uptime-kuma` | `3001` | `0.0.0.0` (Public) | Monitoring dashboard and status pages |
| `80` | TCP | `reverse-proxy` | `80` | `0.0.0.0` (Public) | HTTP Gateway (Traefik / Nginx) |
| `443` | TCP | `reverse-proxy` | `443` | `0.0.0.0` (Public) | HTTPS Gateway |

*(Exposure types: `127.0.0.1` [local host only], `0.0.0.0` [public / external network], `Internal Network` [no host port, Docker DNS only])*

---

## 2. Volumes and Data Persistence Matrix

> Ensure no production data is kept ephemerally inside container layers, and document required permissions.

| Service | Type | Host Path / Volume | Container Path | UID:GID | Mandatory Backup? |
| :--- | :---: | :--- | :--- | :---: | :---: |
| `victorialogs` | Named Volume | `victorialogs_data` | `/vlogs-data` | `1000:1000` | Yes (daily) |
| `uptime-kuma` | Named Volume | `uptime_kuma_data` | `/app/data` | `1000:1000` | Yes (daily) |
| `reverse-proxy` | Bind Mount | `./config/traefik.yaml` | `/etc/traefik/traefik.yaml:ro` | `root:root` | No (git-versioned) |

*(Volume types: `Named Volume` [Docker-managed volume], `Bind Mount` [Host mapped directory])*

---

## 3. Docker Virtual Networks Matrix

> Segregate traffic for security containment and minimal blast radius.

| Network Name | Driver | Scope | Purpose and Connected Services |
| :--- | :---: | :---: | :--- |
| `proxy_public` | bridge | Internal | Ingress routing (Traefik, Uptime Kuma) |
| `monitoring_internal` | bridge | Isolated | Internal telemetry and logs (VictoriaLogs, scrapers) |
| `db_isolated` | bridge | Isolated | Exclusive database access for backends |

---

## 4. Services, Images, and Healthchecks Catalog

> Every service MUST use a pinned image tag (never plain `:latest`) and an explicit `healthcheck` block.

### 📌 `victorialogs`
- **Image:** `victoriametrics/victoria-logs:v1.1.0`
- **Description:** High-performance log ingestion and querying engine.
- **Networks:** `monitoring_internal`
- **Healthcheck:**
  - **Command:** `["CMD-SHELL", "wget -q --spider http://127.0.0.1:9428/health || exit 1"]`
  - **Interval:** `15s` | **Timeout:** `5s` | **Retries:** `3` | **Start Period:** `10s`
- **Resource Limits:** CPU: `1.0` | Memory: `512MB`

### 📌 `uptime-kuma`
- **Image:** `louislam/uptime-kuma:1.23.13-debian`
- **Description:** Self-hosted monitoring and status page dashboard.
- **Networks:** `proxy_public`
- **Healthcheck:**
  - **Command:** `["CMD-SHELL", "node extra/healthcheck.js || exit 1"]`
  - **Interval:** `30s` | **Timeout:** `10s` | **Retries:** `3` | **Start Period:** `15s`
- **Resource Limits:** CPU: `0.5` | Memory: `256MB`
