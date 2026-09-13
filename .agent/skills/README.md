# Skills neste hub

A branch `main` **não** é o livro de playbooks da org. Procedimento transversal (UI, QA, host) vive em [`ye-sandbox/agent-skills`](https://github.com/ye-sandbox/agent-skills) (`skills/<nome>/` + `./install.sh` → `~/.cursor/skills`).

Nesta pasta, nesta branch, não há `SKILL.md` de produto. Skills de **molde** (viajam com o starter) estão só nas branches de template:

| Branch | Skills do molde |
| :--- | :--- |
| `greenfield` | `database-migration`, `api-endpoint` |
| `blackbox` | `reverse-engineering` |
| `infra` | `compose-service` |

`brownfield` injeta governança; não copia o livro da org.

Não liste playbooks no `AGENTS.md` deste hub. Skill nova da org → `agent-skills`. Skill nova de um tipo de starter → a branch daquele molde.
