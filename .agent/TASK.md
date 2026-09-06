# TASK.md — Tarefa Atual e Roadmap de Infraestrutura

> Define O QUE precisa ser feito na infraestrutura. Reescrito/atualizado no início de cada nova tarefa.
> Se o pedido do usuário na conversa conflitar com este arquivo, o pedido do usuário
> tem precedência — mas o agente deve reportar a divergência antes de agir.
>
> **Regra de ouro deste arquivo:** ele guarda O QUE FAZER, não O QUE JÁ FOI FEITO.
> Detalhes de implementação vivem no `git log`.
> Ver seção "Como manter este arquivo enxuto" no final.

---

## Tarefa Ativa

### 📌 Tarefa [00.1]: Mapear Topologia e Provisionar Serviços Base

- **Descrição:** Mapear os requisitos de infraestrutura do projeto, configurar as variáveis
  canônicas em `.env.example`, registrar portas e volumes em `.agent/SERVICES.md` e
  estruturar os primeiros serviços no `compose.yaml` (ex: VictoriaLogs, Uptime Kuma, proxy).
- **Sistema(s) Envolvido(s):** `infra`, `docker-compose`, `services`
- **Tipo de Ação:**
  - [x] Somente leitura / Documentação
  - [x] Escrita de código-fonte
- **Status:** PRONTO PARA PLANEJAMENTO
  *(Fluxo: `PRONTO PARA PLANEJAMENTO` → `EM PLANEJAMENTO` ao apresentar plano → aprovação → `EM EXECUÇÃO`)*

### Critérios de Aceite
- [ ] Arquivo `compose.yaml` criado e validado com `docker compose config`
- [ ] Portas registradas sem colisão no `.agent/SERVICES.md`
- [ ] Volumes de persistência definidos com permissões e diretórios adequados
- [ ] Healthcheck configurado em todos os contêineres provisionados
- [ ] Limites de memória e CPU aplicados no compose
- [ ] Variáveis sensíveis e de portas documentadas no `.env.example`

---

## Log de Tarefas Concluídas

> Uma linha por tarefa. Nada de detalhes repetidos aqui — isso já está no commit.
> Quando esta tabela passar de ~15-20 linhas (ou ao cortar uma release/tag Git), arquive em `.agent/ARCHIVE.md`.

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| `[00.0]` | Scaffolding inicial do template de infraestrutura | [`0000000`] | `AAAA-MM-DD` |

---

## Backlog (Próximas, em ordem)

- [ ] **[01.1]** Configurar reverse-proxy (Traefik ou Nginx) com terminação SSL automática
- [ ] **[01.2]** Implementar procedimento e rotina automatizada de backup de volumes persistentes

---

## Backlog Futuro / Ideias (não priorizadas)

- [ ] **[99.1]** Preparar Release (Tag Git) e Sanitizar Contexto (Apenas executar com permissão explícita do usuário)
- [ ] Integrar alertas de status do Uptime Kuma com webhook (Discord / Telegram)
- [ ] Adicionar dashboard unificado de observabilidade com Grafana e VictoriaMetrics

---

## Como manter este arquivo enxuto

1. Detalhe só na tarefa ativa. Concluída → uma linha no log e promover o backlog.
2. Numeração, arquivo pós-release e `[99.1]`: ver `AGENTS.md`.

