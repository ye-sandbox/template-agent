# Skills in this Hub

Branch `main` is **not** the organization playbook library. Cross-cutting procedures (UI, QA, host infrastructure) live in the organization playbook catalog (`agent-skills`) and are loaded into your AI agent environment (e.g., local project `.agent/skills/` or user-level skills directory across Cursor, Antigravity, Claude Code, Windsurf, etc.).

In this branch and folder, there are no product `SKILL.md` files. **Starter template skills** (shipped inside the starter) live exclusively in their respective template branches:

| Branch | Starter Skills |
| :--- | :--- |
| `greenfield` | *(none — language-agnostic template baseline)* |
| `blackbox` | `reverse-engineering` |
| `infra` | `compose-service` |
| `baremetal` | `baremetal-tuning` |

`brownfield` injects governance; it does not duplicate the organizational playbook.

Do not list playbooks in `AGENTS.md` of this hub. New organizational skill $\rightarrow$ `agent-skills`. New starter skill $\rightarrow$ that starter's template branch.

## Hermetic Skills & Context Contract

Procedural guidelines and skills must be self-contained within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator. If a task references an external organizational skill not present in `.agent/skills/`, the agent must not wander the host filesystem; it should request the skill to be injected into the prompt or provisioned locally in `.agent/skills/`.
