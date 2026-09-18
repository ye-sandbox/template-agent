# 📚 Engineering & Infrastructure Documentation Guidelines

This directory contains host administration manuals, infrastructure operating procedures, architectural designs, and incident postmortems that extend beyond single Docker Compose stacks.

---

## 🧭 Documentation Taxonomy

To maintain strict governance and prevent fragmentation between human operators and AI agents, all infrastructure documentation MUST follow the canonical taxonomy below:

| Directory / Location | Purpose | Target Audience | Example |
| :--- | :--- | :--- | :--- |
| **`docs/architecture/`** | Macro decisions, physical/logical network topologies, VLAN segmentation, traffic flows, and evolution roadmaps. | Human / Agent | System topology, DNS split-horizon strategy, reverse proxy flow. |
| **`docs/incidents/`** | Postmortems and Root Cause Analysis (RCA) narratives detailing real-world failures, symptom timelines, investigated hypotheses, root causes, remediation, and preventive actions. | Human / Agent | Outage RCA, storage exhaustion recovery, port collision investigation. |
| **`docs/host/`** | Host OS configuration manuals, system daemon tuning, user provisioning, and access policies. | Human / Agent | Restricted SSH setup, BuildKit GC policy in `/etc/docker/daemon.json`. |
| **`.agent/skills/`** | Deterministic, actionable runbooks (SOPs) consumed by the agent at runtime. | AI Agent | `compose-service`, `homelab-inspector`. |
| **`.agent/SERVICES.md`** | Canonical source of truth for host port allocation, virtual networks, volumes, and resource limits. | Human / Agent | Port matrix, active container catalog. |
| **`.agent/NOTES.md`** | Lean continuous memory of architectural decisions (rapid ADRs) and non-obvious gotchas. | AI Agent | BuildKit GC gotcha, non-root container UID permissions. |

---

## 🏷️ Mandatory Author Metadata Header

Every documentation file created or maintained under `docs/` MUST declare the following YAML frontmatter header at the top of the file:

```yaml
---
title: "Descriptive Document Title"
author_type: "agent"           # "agent" | "human" | "agent-assisted"
author: "Antigravity"          # Agent identifier or human engineer name
reviewed_by: "pending"         # Human reviewer username, or "pending"
date: YYYY-MM-DD
status: "draft"                # "draft" | "under-review" | "approved" | "deprecated"
type: "incident-rca"           # "architecture" | "incident-rca" | "host-runbook" | "guide"
---
```

### Rationale & Rules
1. **Transparency:** Identifies whether a document represents unvalidated AI reasoning (`author_type: agent` + `reviewed_by: pending`) or has been verified against live systems by a human engineer (`status: approved`).
2. **Review Cycle:** AI agents MUST author new documents with `status: "draft"` and `reviewed_by: "pending"` unless explicitly confirming human review during the active session.
3. **Immutability of History:** When revising an existing document, keep the original author and add update notes or increment dates.

---

## 🧭 Incident Graduation & Severity Tiers

To balance operational agility with architectural rigor, issues MUST be graduated into three distinct tiers:

1. **Tier 1 (Gotchas & Quirks):** Minor configuration friction, transient container restart, or non-disruptive UID/port adjustments. Documented directly in [`.agent/NOTES.md`](../.agent/NOTES.md) (3–5 lines).
2. **Tier 2 (Operational Runbooks):** Recurring operational procedures and disaster recovery steps (e.g. disk cleanup, container restart loop). Documented in [`docs/host/`](./host/) or specialized skills.
3. **Tier 3 (Critical Postmortems / RCA):** Outages, service degradation, data corruption risk, or hard-to-diagnose root causes. Documented as full postmortems under [`docs/incidents/`](./incidents/) using chronological filenames (`YYYY-MM-DD-<slug>.md`).

---

## 🗂️ Starter Templates & Hubs

- **[`docs/incidents/README.md`](./incidents/README.md):** Central Postmortems & Action Items Tracker hub.
- **[`docs/incidents/000-template.md`](./incidents/000-template.md):** Canonical template for postmortems and deep-dive troubleshooting with VictoriaLogs query anchors.
- **[`docs/architecture/000-template.md`](./architecture/000-template.md):** Canonical template for system design and topological decisions.
