# Skills in this Hub

Branch `main` is **not** the organization playbook library. Cross-cutting procedures (UI, QA, host infrastructure) live in [`ye-sandbox/agent-skills`](https://github.com/ye-sandbox/agent-skills) (`skills/<name>/` + `./install.sh` → `~/.cursor/skills`).

In this branch and folder, there are no product `SKILL.md` files. **Starter template skills** (shipped inside the starter) live exclusively in their respective template branches:

| Branch | Starter Skills |
| :--- | :--- |
| `greenfield` | `database-migration`, `api-endpoint` |
| `blackbox` | `reverse-engineering` |
| `infra` | `compose-service` |

`brownfield` injects governance; it does not duplicate the organizational playbook.

Do not list playbooks in `AGENTS.md` of this hub. New organizational skill $\rightarrow$ `agent-skills`. New starter skill $\rightarrow$ that starter's template branch.
