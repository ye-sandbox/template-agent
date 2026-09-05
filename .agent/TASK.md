# TASK.md — Tarefa Atual e Roadmap do Projeto (Blackbox)

> Define O QUE precisa ser feito. Reescrito/atualizado no início de cada nova tarefa.
> Se o pedido do usuário na conversa conflitar com este arquivo, o pedido do usuário
> tem precedência — mas o agente deve reportar a divergência antes de agir.
>
> **Regra de ouro deste arquivo:** ele guarda O QUE FAZER, não O QUE JÁ FOI FEITO.
> Detalhes de implementação de tarefas concluídas vivem no `git log`, não aqui.

---

## Tarefa Ativa

### 📌 Tarefa [00.1]: Setup de Ambiente e Mapeamento de Autenticação/Sessão

- **Descrição:** Realizar a auditoria inicial do sistema-alvo, isolar o mecanismo de autenticação/cookies de sessão, definir as variáveis de ambiente necessárias no `.env` e documentar as particularidades globais no `.agent/ENDPOINTS.md`.
- **Sistema(s) Envolvido(s):** `[auth]`, `[env]`, `[endpoints]`
- **Tipo de Ação:**
  - [x] Somente leitura / Documentação
  - [ ] Escrita de código-fonte
- **Status:** PRONTO PARA PLANEJAMENTO
  *(Fluxo: Definido como `PRONTO PARA PLANEJAMENTO` -> Agente assume como `EM PLANEJAMENTO` ao apresentar plano -> Usuário aprova -> Agente altera para `EM EXECUÇÃO` ao codificar)*

### Critérios de Aceite
- [ ] Mecanismo de autenticação e ciclo de vida de sessão identificados (cookies, tokens CSRF, cabeçalhos obrigatórios).
- [ ] Arquivo `.env.example` preenchido com as variáveis de conexão e credenciais necessárias.
- [ ] Seção 1 (Contexto Global) do `.agent/ENDPOINTS.md` preenchida com as particularidades do sistema.
- [ ] Chamada cURL mínima reproduzível de login ou validação de sessão testada com sucesso.

---

## Log de Tarefas Concluídas

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [00.0] | Inicialização do Repositório Blackbox (ADD) | [`0000000`] | 2026-09-04 |

---

## Backlog (Próximas, em ordem)

- [ ] **[00.2]** Mapear e dissecar o primeiro endpoint de negócio no `.agent/ENDPOINTS.md` — `[endpoints]`
- [ ] **[01.1]** Implementar cliente HTTP resiliente com sessão, retry e backoff — `[client]`
- [ ] **[01.2]** Criar fixtures mockadas e suite de testes automatizados herméticos — `[tests]`
- [ ] **[02.1]** Implementar fluxo de extração de dados e parser DOM/JSON — `[parser]`

---

## Backlog Futuro / Ideias (não priorizadas)

- [ ] Cache em memória/Redis de sessões válidas
- [ ] Proxy rotation e evasão de rate-limit
- [ ] Exportação de dados para PostgreSQL ou fila de mensagens

---

## Como manter este arquivo enxuto

1. **Detalhe vive na tarefa ativa, não no histórico.** Assim que uma tarefa é concluída, reduza-a a uma linha na tabela de log e promova a próxima do backlog.
2. **Arquive por release e lote, não acumule.** Ao cortar uma release/tag Git (ou quando o log passar de ~15 linhas), mova as tarefas concluídas desse marco para `.agent/ARCHIVE.md` agrupadas por versão (ex: `## [v0.1.0] - AAAA-MM-DD`).
3. **Backlog é lista de títulos, não de specs.** Escreva a especificação completa só quando o item virar a tarefa ativa.
4. **Use a numeração semântica [XX.Y]:** Siga a convenção de fases e regras de ouro descritas no `AGENTS.md`.
