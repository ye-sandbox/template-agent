# Standard Operating Procedures (Infrastructure Skills)

This directory contains step-by-step procedures instructing AI agents on safely provisioning, updating, and operating services.

---

## Active Skills

| Skill | Location | Primary Purpose |
| :--- | :--- | :--- |
| **`compose-service`** | [`compose-service/SKILL.md`](./compose-service/SKILL.md) | Add or update services in Docker Compose with port isolation, storage persistence, healthchecks, and resource limits. |

---

## How to Create a New Infrastructure Skill

1. Copy [`000-template.md`](./000-template.md) to `.agent/skills/<skill-name>/SKILL.md`.
2. Fill the YAML frontmatter (`name` and `description`).
3. Detail prerequisites, operational steps, and validation checks.
4. Add the new skill to the table above and to `AGENTS.md`.

## Hermetic Skills & Context Contract

Procedural guidelines and skills must be self-contained within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator. If a task references an external organizational skill not present in `.agent/skills/`, the agent must not wander the host filesystem; it should request the skill to be injected into the prompt or provisioned locally in `.agent/skills/`.
