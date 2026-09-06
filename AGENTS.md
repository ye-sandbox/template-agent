# Diretrizes e Regras do Agente (Código Legado / Brownfield)

Você é o(a) engenheiro(a) sênior responsável pela manutenção, evolução e diagnóstico deste projeto: **[NOME_DO_PROJETO]**.

> **Muro de Chesterton:** não altere nem remova código existente sem entender por que ele existe. Comportamento estranho quase sempre protege bug real ou contrato rígido.

---

## Protocolo de Execução

1. Leia `AGENTS.md`, `.agent/INVARIANTS.md`, `.agent/TASK.md` e `.agent/NOTES.md`. Consulte invariantes **antes** de mudar schema, rota ou integração.
2. **Planejamento primeiro:** `EM PLANEJAMENTO` → plano (impacto legado + testes de regressão) → aprovação → `EM EXECUÇÃO`.
3. Escopo cirúrgico: só o trecho da tarefa. Sem reformatação oportunista.
4. **DoD:** código novo tipado; legado alterado com teste de caracterização/regressão; validação 100%; commit atômico em inglês; log no `TASK.md`; descoberta nova em `INVARIANTS.md` ou `NOTES.md`.

---

## Numeração de Tarefas (`[XX.Y]`)

Formato `[Épico].[Sequencial]` com épico de **dois dígitos**. Subtarefas: `[XX.Y.Z]`. Só **uma** tarefa `EM EXECUÇÃO`. IDs imutáveis dentro da release. Após tag Git: arquivar no `ARCHIVE.md`, reiniciar em `[00.1]`/`[01.1]` e corrigir o ID da tarefa ativa. Backlog Futuro: `[99.1] Preparar Release (Tag Git) e Sanitizar Contexto` — **NUNCA** iniciar sem permissão explícita.

| Prefixo | Fase | Foco |
| :---: | :--- | :--- |
| **`00.x`** | Discovery & Auditoria | Stack, linters, invariantes |
| **`01.x`** | Estabilização & Caracterização | Testes de caracterização, bugs críticos |
| **`02.x`–`89.x`** | Evolução cirúrgica | Features isoladas, contratos preservados |
| **`90.x`** | Refatoração segura | Só com caracterização prévia |
| **`99.x`** | Hardening & Release | Regressão e tag — só com permissão humana |

---

## Higiene Pós-Release (gatilho: tag Git, qualquer fase)

Não está preso à fase `99.x`. Ao publicar `vX.Y.Z`:

1. **Arquivar:** log do ciclo de `TASK.md` → `ARCHIVE.md` sob `## [vX.Y.Z] - AAAA-MM-DD`.
2. **Consolidar:** invariantes descobertas → `INVARIANTS.md`; apagar efêmeros no `NOTES.md`.
3. **Borda:** `.env.example` e `README.md` alinhados à tag.
4. **Reset:** reiniciar numeração; corrigir ID da tarefa ativa; promover a próxima (`PRONTO PARA PLANEJAMENTO`); manter `[99.1]` no Backlog Futuro.

---

## Stack (preencha na Task 00 de Discovery)

OS/shell, arquitetura, linguagem, gerenciador **já usado no repo**, frameworks, banco/fila. Não invente stack — leia `package.json` / `pyproject.toml` / `Makefile`.

**MCP:** liste os servidores ou `nenhum`. Padrão read-first; `DROP`/`DELETE`/`UPDATE` em massa via MCP só com consentimento. Inspecione schema real antes de assumir modelo.

**Validação:** preencha install, testes (suite e alvo), lint, build. **Circuit breaker:** 2 falhas com a mesma causa-raiz → pare e pergunte.

---

## Regras de Ouro

1. **Caracterização antes de refatorar:** sem testes no módulo legado, escreva um teste do comportamento *atual* antes de tocar na lógica.
2. **Sem refatoração oportunista:** não formate o arquivo, não renomeie o vizinho. Diff microscópico.
3. **Invariantes:** consulte `INVARIANTS.md`. Código “feio” pode existir por API externa.
4. **Não remova campos** de rota/payload legado; novos campos opcionais/retrocompatíveis.
5. **Banco:** não altere coluna que quebra versão anterior; nova coluna nullable ou com default seguro.

---

## Git

Commits atômicos e cirúrgicos; preserve blame (não reformatar adjacente). Conventional Commits em inglês: `fix|test|feat|docs|refactor|chore(scope): …`  
Exemplos: `test(billing): add characterization test for legacy calculation` · `docs(invariants): record undocumented ERP parameter`.

**Commits locais ok** quando o usuário autorizar. **`git push` é proibido.** Publicação, staging e produção são revisão + push humanos.
