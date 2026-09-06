# TASK.md — Tarefa Atual e Roadmap do Projeto

> Define O QUE precisa ser feito. Reescrito/atualizado no início de cada nova tarefa.
> Se o pedido do usuário na conversa conflitar com este arquivo, o pedido do usuário
> tem precedência — mas o agente deve reportar a divergência antes de agir.
>
> **Regra de ouro deste arquivo:** ele guarda O QUE FAZER, não O QUE JÁ FOI FEITO.
> Detalhes de implementação de tarefas concluídas vivem no `git log`, não aqui.

---

## Tarefa Ativa

### 📌 Tarefa [04.2]: Suite de testes herméticos para a branch blackbox no CI

- **Descrição:** O job `test-installers` só afirma que o `init.sh` da `blackbox` gera
  arquivos. Falta validar o ciclo caixa-preta no CI: fixture mockada, parser contra
  o mock (sem rede) e ausência de segredos em fixtures de exemplo.
- **Sistema(s) Envolvido(s):** `ci`, `branch-blackbox`, `hub`
- **Tipo de Ação:**
  - [ ] Somente leitura / Documentação
  - [x] Escrita de código-fonte
- **Status:** PRONTO PARA PLANEJAMENTO
  *(Fluxo: `PRONTO PARA PLANEJAMENTO` → `EM PLANEJAMENTO` ao apresentar plano → aprovação → `EM EXECUÇÃO`)*

### Critérios de Aceite
- [ ] CI executa pelo menos um teste hermético (fixture local, sem HTTP ao vivo) no projeto gerado pela `blackbox`
- [ ] Falha se fixture de exemplo contiver cookie/token/PII óbvios
- [ ] Job continua hermético (`TEMPLATE_REPO_URL="$GITHUB_WORKSPACE"`), sem `git merge` entre branches

---

## Log de Tarefas Concluídas

> Uma linha por tarefa. Use `git log --oneline` ou `git show <hash>` para o detalhe.

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [00.1] | [Setup inicial da arquitetura e template do repositório] | [`0000000`] | [AAAA-MM-DD] |
| [00.2] | Refinar Template Core/Greenfield com Suporte a MCPs e Skills | [`031e7a6`] | 2026-09-03 |
| [00.3] | Criar Template Brownfield para Projetos Existentes | [`dc842f7`] | 2026-09-03 |
| [00.4] | Reorganizar Templates em Branches (main, greenfield, brownfield) | [`6df1e01`] | 2026-09-03 |
| [01.1] | Corrigir Execução Remota via `curl \| bash` no `install.sh` | [`7a0fd03`] | 2026-09-03 |
| [01.2] | Adicionar Exemplos Práticos de Skills de Projeto | [`2a0f61a`] | 2026-09-03 |
| [01.3] | Criar Script de Inicialização Rápida (One-Liner) para Greenfield | [`df6876e`] | 2026-09-03 |
| [01.4] | Configurar CI com GitHub Actions para Validação de Templates | [`dbbcc1c`] | 2026-09-03 |
| [01.5] | Documentar Protocolo de Sincronização e Suporte a Forks | [`e0513d0`] | 2026-09-03 |
| [02.1] | Padronizar Numeração de Tarefas e Criar Branch Blackbox | [`67b59fc`] | 2026-09-04 |
| [02.2] | Equalizar Commits Atômicos, Conventional Commits e Numeração [XX.Y] | [`387471a`] | 2026-09-04 |
| [03.1] | Criar Branch Especializada de Infraestrutura e Serviços (`infra`) | [`9f4de15`, `2e100f6`] | 2026-09-04 |
| [03.2] | Formalizar Protocolo de Higiene e Sanitização Pós-Release nos Templates | [`0a87934`, `1107c67`, `1abbfd6`, `fd0cf01`, `33df53d`] | 2026-09-04 |
| [03.3] | Padronizar Reset de Numeração por Release e Âncora [99.1] no Backlog Futuro | [`c310997`, `bab484d`, `efb6a89`, `a2da17c`, `abdb522`] | 2026-09-05 |
| [04.1] | Enxugar guardrails e corrigir incoerências de contexto | [`b25715e`, `d615950`, `254a3ef`, `2bdd0eb`, `2ea2d63`, `0231b5e`, `58a1fc3`, `376adbc`, `ae7c529`, `4c6c90c`, `6b2a7e4`] | 2026-09-06 |

> Quando esta tabela passar de ~15-20 linhas, mova as mais antigas para `.agent/ARCHIVE.md`.

---

## Backlog (Próximas, em ordem)

*(vazio — próxima entrega é a tarefa ativa [04.2])*

---

## Backlog Futuro / Ideias (não priorizadas)

- [ ] **[99.1]** Preparar Release (Tag Git) e Sanitizar Contexto (Apenas executar com permissão explícita do usuário)

---

## Como manter este arquivo enxuto

1. Detalhe só na tarefa ativa. Concluída → uma linha no log (título + hash) e promover o backlog.
2. Backlog é lista de títulos. Spec completa só quando o item vira tarefa ativa.
3. Escopo grande → issue no tracker; aqui só o link.
4. Numeração, arquivo pós-release e âncora `[99.1]`: ver `AGENTS.md`. Não duplique o protocolo aqui.
5. Não cole a mensagem de commit neste arquivo. Histórico profundo: `git log` / `.agent/NOTES.md`.
