# TASK.md — Tarefa Atual e Roadmap do Projeto

> Define O QUE precisa ser feito. Reescrito/atualizado no início de cada nova tarefa.
> Se o pedido do usuário na conversa conflitar com este arquivo, o pedido do usuário
> tem precedência — mas o agente deve reportar a divergência antes de agir.
>
> **Regra de ouro deste arquivo:** ele guarda O QUE FAZER, não O QUE JÁ FOI FEITO.
> Detalhes de implementação de tarefas concluídas vivem no `git log`, não aqui.
> Ver seção "Como manter este arquivo enxuto" no final.

---

## Tarefa Ativa

### 📌 Tarefa [03.2]: Formalizar Protocolo de Higiene e Sanitização Pós-Release nos Templates

- **Descrição:** Documentar e formalizar o Protocolo de Higiene e Sanitização Pós-Release (gatilho de Tag/Versão) no AGENTS.md, TASK.md e ARCHIVE.md em todas as branches (main, greenfield, brownfield, blackbox e infra), garantindo arquivamento sistemático por versão e limpeza de memória do agente sem atrelamento rígido à fase 99.
- **Sistema(s) Envolvido(s):** `[hub]`, `[main]`, `[greenfield]`, `[brownfield]`, `[blackbox]`, `[infra]`
- **Tipo de Ação:**
  - [x] Somente leitura / Documentação
  - [ ] Escrita de código-fonte
- **Status:** EM EXECUÇÃO

### Critérios de Aceite
- [ ] `AGENTS.md` de todas as 5 branches atualizado com o Protocolo de Higiene e Sanitização Pós-Release baseado em evento.
- [ ] `.agent/TASK.md` de todas as 5 branches atualizado com a regra de arquivamento por lote de release.
- [ ] `.agent/ARCHIVE.md` de todas as 5 branches estruturado com modelo canônico de agrupamento por tag de versão (`## [vX.Y.Z] - AAAA-MM-DD`).
- [ ] Todas as branches testadas e sincronizadas com o repositório remoto.

---

## Log de Tarefas Concluídas

> Uma linha por tarefa. Nada de "critérios verificados" repetidos aqui — isso já está
> no commit. Use `git log --oneline --grep="Tarefa XX"` ou `git show <hash>` para
> recuperar o detalhe quando precisar.

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

> Quando esta tabela passar de ~15-20 linhas, mova as mais antigas para
> `.agent/ARCHIVE.md` (ou simplesmente apague — o Git já é a fonte da verdade).

---

## Backlog (Próximas, em ordem)

> Uma linha por item. Só vira uma seção detalhada com "Descrição" e "Critérios de
> Aceite" completos quando se tornar a Tarefa Ativa.

- [ ] **[02.2]** [Criar suite de testes de integração e mocks para a branch blackbox no CI] — `[hub]`

---

## Backlog Futuro / Ideias (não priorizadas)

> Itens de escopo maior ou ainda não maduros o suficiente para entrar no backlog
> ordenado. Uma linha cada — se crescer detalhe aqui, é sinal de que deveria virar
> uma issue no tracker do projeto (GitHub Issues, Linear, etc.) em vez de inchar
> este arquivo.

- [ ] [Ideia / feature futura 1]
- [ ] [Ideia / feature futura 2]

---

## Como manter este arquivo enxuto

1. **Detalhe vive na tarefa ativa, não no histórico.** Assim que uma tarefa é concluída,
   reduza-a a uma linha na tabela de log (título + hash do commit) e promova a próxima
   do backlog para "Tarefa Ativa" com o detalhe completo.
2. **Backlog é lista de títulos, não de specs.** Escreva a especificação completa só
   quando o item vira a tarefa ativa — evita manter duas fontes de verdade desatualizadas.
3. **Prefira issues/tracker externo para escopo grande.** Se uma ideia do "Backlog Futuro"
   cresce e ganha critérios de aceite, sub-tarefas etc., mova para o sistema de issues do
   projeto e deixe aqui só um link/referência.
4. **Arquive por release e lote, não acumule.** Ao cortar uma release/tag Git (ou quando o log passar de ~15 linhas), mova as tarefas concluídas desse marco para `.agent/ARCHIVE.md` agrupadas por versão (ex: `## [v0.1.0] - AAAA-MM-DD`). O `git log` já preserva o histórico integral.
5. **Nunca duplique o commit message aqui.** Se a mensagem de commit já segue Conventional
   Commits (`feat(module): ...`), ela já documenta o que mudou. Este arquivo só precisa
   apontar pra ela.
6. **Instrua o agente a consultar o Git quando precisar de contexto histórico**, em vez de
   reler um TASK.md longo. Ex: "para entender decisões passadas, rode `git log --oneline`
   ou consulte `.agent/NOTES.md` para decisões arquiteturais que não são óbvias a partir
   do diff."
7. **Use a numeração semântica [XX.Y]:** Siga estritamente a convenção de fases e regras de ouro descritas no `AGENTS.md`.