# TASK.md — Tarefa Atual e Roadmap do Projeto

> Define O QUE precisa ser feito. Reescrito/atualizado no início de cada nova tarefa.
> Se o pedido do usuário na conversa conflitar com este arquivo, o pedido do usuário
> tem precedência — mas o agente deve reportar a divergência antes de agir.
>
> **Regra de ouro deste arquivo:** ele guarda O QUE FAZER, não O QUE JÁ FOI FEITO.
> Detalhes de implementação de tarefas concluídas vivem no `git log`, não aqui.

---

## Tarefa Ativa

### 📌 Tarefa [04.5]: Sucessão de IDs a partir do log, não do [99.1]

- **Descrição:** Documentar que o próximo `[XX.Y]` sai da Tarefa Ativa + Log do ciclo. Isolar a âncora de release para o agente não tratar `[99.1]` como próxima da fila.
- **Sistema(s) Envolvido(s):** `AGENTS.md` e `.agent/TASK.md` em `main`, `greenfield`, `brownfield`, `blackbox`, `infra`
- **Tipo de Ação:**
  - [x] Somente leitura / Documentação
  - [ ] Escrita de código-fonte
- **Status:** EM EXECUÇÃO
  *(Fluxo: `PRONTO PARA PLANEJAMENTO` → `EM PLANEJAMENTO` ao apresentar plano → aprovação → `EM EXECUÇÃO`)*

### Critérios de Aceite
- [ ] Bloco de numeração no `AGENTS.md` (cinco branches) define sucessão pelo log e proíbe usar Backlog Futuro / `99.x` como teto
- [ ] `TASK.md` não lista `[99.1]` como checkbox; aviso de encerramento separado
- [ ] Log `[04.5]` na `main` após os commits

---

## Log de Tarefas Concluídas

> Ciclos 00–03: `.agent/ARCHIVE.md`. Detalhe: `git log`.

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [04.1] | Enxugar guardrails e corrigir incoerências de contexto | [`b25715e`, `d615950`, `254a3ef`, `2bdd0eb`, `2ea2d63`, `0231b5e`, `58a1fc3`, `376adbc`, `ae7c529`, `4c6c90c`, `6b2a7e4`] | 2026-09-06 |
| [04.2] | Asserções de contrato no CI dos starters | [`c582fd1`, `0397624`, `e575ec0`] | 2026-09-06 |
| [04.3] | Enxugar leftovers de contexto | [`2621de4`, `c9acedd`, `9747f16`, `19d2c08`, `f0a0619`, `5172f7b`, `eadb9e9`, `dbdecb7`, `375407c`] | 2026-09-06 |
| [04.4] | Extrair asserções de contrato do CI para um script | [`06c3416`, `bb50e90`] | 2026-09-06 |

---

## Backlog (Próximas, em ordem)

*(vazio)*

---

## Encerramento de ciclo (não é a próxima tarefa)

Release/tag só com pedido explícito. Nessa hora o ID é `[99.1]`. Não numere feature, hygiene ou CI como `99.x`. Não calcule o próximo ID a partir desta seção.

---

## Backlog Futuro / Ideias (não priorizadas)

*(vazio)*

---

## Como manter este arquivo enxuto

1. Detalhe só na tarefa ativa. Concluída → uma linha no log (título + hash) e promover o backlog.
2. Backlog é lista de títulos. Spec completa só quando o item vira tarefa ativa.
3. Escopo grande → issue no tracker; aqui só o link.
4. Próximo ID = último do log (ou da ativa). Encerramento de ciclo e `[99.1]`: ver `AGENTS.md`.
5. Não cole a mensagem de commit neste arquivo. Histórico profundo: `git log` / `.agent/NOTES.md`.
