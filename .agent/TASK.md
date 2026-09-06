# TASK.md — Tarefa Atual e Roadmap do Projeto

> Define O QUE precisa ser feito. Reescrito/atualizado no início de cada nova tarefa.
> Se o pedido do usuário na conversa conflitar com este arquivo, o pedido do usuário
> tem precedência — mas o agente deve reportar a divergência antes de agir.
>
> **Regra de ouro deste arquivo:** ele guarda O QUE FAZER, não O QUE JÁ FOI FEITO.
> Detalhes de implementação de tarefas concluídas vivem no `git log`, não aqui.

---

## Tarefa Ativa

### 📌 Tarefa [04.3]: Enxugar leftovers de contexto (arquivo, checklist, endpoints, gitignore, skills README)

- **Descrição:** Arquivar o log 00–03; o `init.sh` greenfield remove o checklist do
  `AGENTS.md` gerado; `ENDPOINTS.md` vira molde curto (SEI na skill); `.gitignore`
  núcleo curto; `skills/README.md` greenfield no tamanho da infra.
- **Sistema(s) Envolvido(s):** `docs`, `hub`, `ci`, `branch-greenfield`, `branch-brownfield`, `branch-blackbox`
- **Tipo de Ação:**
  - [x] Somente leitura / Documentação
  - [x] Escrita de código-fonte
- **Status:** EM EXECUÇÃO

### Critérios de Aceite
- [ ] `TASK.md` da `main` só com o ciclo 04.x; 00–03 no `ARCHIVE.md`
- [ ] Projeto gerado pelo `init.sh` greenfield **sem** seção Checklist; CI afirma isso
- [ ] `ENDPOINTS.md` blackbox é molde; exemplo SEI está na skill; `$TARGET_SESSION_COOKIE` permanece
- [ ] `.gitignore` de `main`/`greenfield`/`brownfield` é núcleo curto + blocos opcionais
- [ ] `skills/README.md` greenfield ~tamanho do da `infra` (catálogo + como criar)

---

## Log de Tarefas Concluídas

> Ciclos 00–03: `.agent/ARCHIVE.md`. Detalhe: `git log`.

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [04.1] | Enxugar guardrails e corrigir incoerências de contexto | [`b25715e`, `d615950`, `254a3ef`, `2bdd0eb`, `2ea2d63`, `0231b5e`, `58a1fc3`, `376adbc`, `ae7c529`, `4c6c90c`, `6b2a7e4`] | 2026-09-06 |
| [04.2] | Asserções de contrato no CI dos starters | [`c582fd1`, `0397624`, `e575ec0`] | 2026-09-06 |

---

## Backlog (Próximas, em ordem)

*(vazio)*

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
