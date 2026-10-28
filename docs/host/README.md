---
title: "Host Operations & Daemon Runbooks Index"
author_type: "agent"
author: "Antigravity"
reviewed_by: "Human Lead"
date: 2026-10-28
status: "approved"
type: "host-runbook"
---

# 🖥️ Host Operations & Daemon Runbooks Index

This directory archives operational runbooks (Tier 2 operational procedures) for host-level daemon administration, storage management, systemd maintenance, and network configuration supporting containerized services.

---

## 🧭 Operational Scope

| Scope | Typical Runbooks | Primary References |
| :--- | :--- | :--- |
| **Docker Daemon & Engine** | Garbage collection rules (`/etc/docker/daemon.json`), storage driver tuning, BuildKit cache pruning. | [`docs/README.md`](../README.md) |
| **Storage & Pruning** | Routine volume cleanup, dangling image pruning, log truncation procedures. | [`.agent/SERVICES.md`](../../.agent/SERVICES.md) |
| **Network & Firewall** | Host firewall ports, UFW rules, Docker bridge bindings, DNS resolution. | [`docs/architecture/000-template.md`](../architecture/000-template.md) |

---

## 🛠️ Runbook Authoring Conventions

1. **Deterministic Steps:** Runbooks must provide copy-pasteable commands with clear error verification.
2. **Metadata Header:** Maintain the standard YAML frontmatter header defined in [`docs/README.md`](../README.md).
3. **Rollback Guidance:** Every destructive or privileged command must specify an inverse rollback action.
