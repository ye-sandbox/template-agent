# TASK.md — Tarefas e Roadmap para Código Legado

> Define O QUE precisa ser feito. Reescrito/atualizado no início de cada nova tarefa.
> Para projetos Brownfield, este arquivo inicia com o **Protocolo de Discovery (Task 00.1)**
> para que o agente audite a base de código antes de qualquer desenvolvimento.

---

## Tarefa Ativa

### 📌 Tarefa [00.1]: Auditoria e Mapeamento de Contexto (Discovery)

- **Descrição:** Varrer o repositório existente para mapear a stack real, scripts de execução, suíte de testes, pontos de entrada da aplicação e variáveis de ambiente, preenchendo o `AGENTS.md` com dados verídicos.
- **Sistema(s) Envolvido(s):** `discovery`, `docs`, `setup`
- **Tipo de Ação:**
  - [x] Somente leitura / Documentação
  - [ ] Escrita de código-fonte
- **Status:** PRONTO PARA PLANEJAMENTO
  *(Fluxo: Definido como `PRONTO PARA PLANEJAMENTO` -> Agente assume como `EM PLANEJAMENTO` ao apresentar plano -> Usuário aprova -> Agente altera para `EM EXECUÇÃO` ao codificar)*

### Critérios de Aceite
- [ ] Inspecionar arquivos de configuração de dependências (`package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, etc.) e atualizar o `AGENTS.md` com linguagens, versões e gerenciador de pacotes oficial.
- [ ] Identificar e testar os comandos reais de validação (como rodar testes locais, linters e build) e registrá-los em `AGENTS.md`.
- [ ] Verificar o estado atual da suíte de testes (se os testes existentes passam 100% ou se há falhas conhecidas).
- [ ] Mapear os principais pontos de entrada (rotas HTTP, workers de fila, scripts CLI ou schedulers).
- [ ] Auditar variáveis de ambiente necessárias e verificar se o `.env.example` está condizente com as referências no código.
- [ ] Registrar as primeiras armadilhas ou invariantes encontradas no `.agent/INVARIANTS.md`.

---

## Log de Tarefas Concluídas

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [00.0] | Injeção do template brownfield no repositório legado | [`0000000`] | [AAAA-MM-DD] |

---

## Backlog (Próximas, em ordem)

- [ ] **[01.1]** [Primeira tarefa real de negócio, bugfix ou feature no legado] — `[módulo]`
- [ ] **[01.2]** [Subsequente] — `[módulo]`

---

## Backlog Futuro / Ideias (não priorizadas)

- [ ] **[99.1]** Preparar Release (Tag Git) e Sanitizar Contexto (Apenas executar com permissão explícita do usuário)
- [ ] [Mapear débitos técnicos prioritários para refatoração segura com testes]
- [ ] [Aumentar cobertura de testes nos módulos críticos legados]

---

## Como manter este arquivo enxuto

1. **Detalhe vive na tarefa ativa, não no histórico.** Ao concluir uma tarefa, reduza-a a uma linha na tabela de log (com ID original e hash do commit) e promova a próxima do backlog.
2. **Arquive por release e lote, reiniciando o contador.** Ao cortar uma release/tag Git (ou quando o log passar de ~15 linhas), mova as tarefas concluídas desse marco para `.agent/ARCHIVE.md` agrupadas por versão (ex: `## [v0.1.0] - AAAA-MM-DD`). Em seguida, reinicie a numeração de tarefas a partir de `[00.1]` (ou `[01.1]`), reajustando a numeração de qualquer tarefa ativa remanescente.
3. **Backlog é lista de títulos, não de specs.** Mantenha apenas títulos e tags no backlog.
4. **Use a numeração semântica [XX.Y]:** Siga estritamente a convenção de fases e regras de ouro descritas no `AGENTS.md`.
