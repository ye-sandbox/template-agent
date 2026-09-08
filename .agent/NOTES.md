# NOTES.md — Decisões, Contexto e Contratos do Hub

> Guarda o PORQUÊ. O QUE fica no `git log` / `.agent/TASK.md`. Antes de escrever:
> isso explica uma decisão, ou só descreve uma mudança? Se for descrição, o commit basta.

---

## Como usar

1. Leia antes de planejar. Decisões aqui vencem a “forma óbvia”, salvo o usuário pedir para revisitar.
2. Registre: trade-off entre alternativas, contrato, armadilha, skill nova, débito consciente.
3. Não registre: lista de arquivos, changelog, testes passando.
4. Entrada longa demais → ADR em `.agent/adr/` e aqui só uma linha + link.

---

## Decisões (porquê — a regra vive no `AGENTS.md`)

| Data | Decisão | Por quê (não copiar a regra) |
|---|---|---|
| 2026-09-03 | Skills locais vs `AGENTS.md` | Procedimento repetitivo fora da constituição para não inflar tokens. Infra compartilhada (VictoriaLogs, Proxmox) é skill **global** do host. |
| 2026-09-03 | Brownfield ≠ greenfield | ADRs retroativas do legado são ficção; `INVARIANTS.md` + caracterização evitam refatoração cega. |
| 2026-09-03 | Branches como templates, não pastas `templates/` | Clone/`init.sh` entregam raiz limpa. **Nunca** `git merge` entre essas branches. |
| 2026-09-03 | `install.sh` local vs remoto + `/dev/tty` | `curl \| bash` consome stdin; confirmações no tty. `TEMPLATE_REPO_URL` para forks. |
| 2026-09-03 | `init.sh` `--depth 1` + `git init` | Evita herdar o histórico do hub. O script se apaga no projeto gerado. |
| 2026-09-03 | CI hermético com `TEMPLATE_REPO_URL="$GITHUB_WORKSPACE"` | Testa starters sem depender de commits já publicados no GitHub. |
| 2026-09-03 | Brownfield: commit local ok, **`git push` proibido** | Push em legado dispara CI/CD e deploy. Publicação é humana. |
| 2026-09-03 | Skills canônicas `database-migration` e `api-endpoint` | Template vazio não ensinava o rigor do procedimento. |
| 2026-09-04 | Branch `infra` | Templates de app não cobrem porta, volume, healthcheck nem `down -v`. |
| 2026-09-04 | Higiene dispara na **tag Git**, não na fase `99.x` | MVP/hotfix podem sair em qualquer ciclo. |
| 2026-09-05 | Reset do contador + âncora `[99.1]` trava humana | Evita IDs `[150.2]` e release autônoma por agente. |
| 2026-09-07 | Próximo ID pelo log, não pelo `[99.1]` | Checkbox `[99.1]` no backlog faz o modelo saltar para 99 sem pedido de release. |
| 2026-09-06 | Processo curto no `AGENTS.md`; starters sem memória do hub | Numeração/higiene em ensaio ocupavam ~40% do contexto always-on. |
| 2026-09-06 | CI afirma **contratos do molde**, não parser/app | Blackbox/greenfield não têm runtime. Âncoras curtas no artefato gerado pegam regressão de guardrail sem inflar o starter. |
| 2026-09-06 | Checklist greenfield só no template; `init.sh` apaga no projeto gerado | Evita constituir permanente de um item “apague ao terminar”. |
| 2026-09-06 | Contratos do CI em `.github/scripts/assert-starter-contracts.sh` | O YAML só orquestra o scaffold; âncoras ficam num arquivo rodável fora do Actions. |
| 2026-09-08 | Requisitos de UI = skill `ui-contract`, não branch | Gerar `.agent/INTERFACE.md` é procedimento transversal (como VictoriaLogs). Quinta branch só faria sentido se o produto fosse um starter de app com constituição própria. |

### Índice de ADRs formais

Nenhum ADR formal aberto neste hub. Template: `.agent/adr/000-template.md`.

---

## Armadilhas

- **`curl \| bash` no `install.sh`:** não leia confirmações do stdin; use `/dev/tty` ou `-y`.
- **Cherry-pick, nunca merge:** árvores de raiz diferentes; merge polui os starters.
- **CI dos starters:** o job na `main` faz `git show origin/<branch>:init.sh` — precisa de `fetch-depth: 0`.
- **Brownfield `install.sh`:** não copia `.gitignore` nem `.env.example` — o legado já os tem. O CI não deve exigir esses arquivos no destino da injeção.
