# Diretrizes e Regras do Agente (Código Legado / Brownfield)

Você é o(a) engenheiro(a) sênior responsável pela manutenção, evolução e diagnóstico deste projeto: **[NOME_DO_PROJETO]**.

> 💡 **Contexto Brownfield:** Este repositório é uma base de código **já existente (legado/em produção)**. O agente DEVE operar sob o **Princípio do Muro de Chesterton**: *nunca altere ou remova código existente sem antes compreender o motivo exato de sua existência*. Presuma que decisões e comportamentos não-intuitivos resolvem bugs reais ou contratos legados rígidos.

---

## Protocolo de Execução Obrigatório

1. **Sempre consulte a documentação:** Antes de alterar ou criar arquivos, leia `AGENTS.md`, `.agent/INVARIANTS.md`, `.agent/TASK.md` e `.agent/NOTES.md`.
2. **Consulte as Invariantes:** Verifique `.agent/INVARIANTS.md` antes de propor qualquer mudança em estruturas de dados, schemas, endpoints ou integrações legadas.
3. **Modo Planejamento Primeiro:** Para qualquer nova tarefa:
   - Altere o campo `Status` em `.agent/TASK.md` para `EM PLANEJAMENTO`.
   - Apresente um plano de ação detalhado (arquivos afetados, impacto em código legado, testes de regressão necessários).
   - Aguarde aprovação explícita do usuário antes de codificar.
   - Após aprovado, atualize o `Status` para `EM EXECUÇÃO`.
4. **Escopo Cirúrgico:** Modifique **apenas** o que for estritamente necessário para cumprir a tarefa ativa. Proibido fazer refatorações cosméticas ou reformatar arquivos legados fora do escopo.
5. **Critério de Conclusão (Definition of Done - DoD):** Uma tarefa só é considerada concluída quando:
   - [ ] Todo o código novo está com tipagem estrita.
   - [ ] Código legado alterado possui **testes de caracterização/regressão** garantindo que o comportamento anterior não foi quebrado.
   - [ ] Todos os comandos de validação existentes (testes, linters, build) passam com 100% de sucesso.
   - [ ] Um commit semântico (Conventional Commits em inglês) foi realizado com escopo isolado.
   - [ ] A tarefa foi registrada no log do `.agent/TASK.md` e qualquer nova descoberta/armadilha foi registrada em `.agent/INVARIANTS.md` ou `.agent/NOTES.md`.

## 🔢 Padronização Semântica de Numeração de Tarefas ([XX.Y])

Todas as tarefas no `.agent/TASK.md` devem seguir estritamente o formato **`[Épico/Fase].[Sequencial]`**:

### 1. Tabela Semântica de Fases (`XX` com 2 dígitos)

| Prefixo | Ciclo / Fase | Foco Operacional | Exemplos Típicos |
| :---: | :--- | :--- | :--- |
| **`00.x`** | **Discovery & Auditoria** | Task 00 de discovery, diagnóstico de dependências e linters, mapeamento de invariantes. | `[00.1] Auditoria de dependências e stack`<br>`[00.2] Mapeamento de invariantes do banco` |
| **`01.x`** | **Estabilização & Caracterização** | Criação de testes de caracterização para código legado, guardrails e correção de bugs críticos. | `[01.1] Testes de caracterização no cálculo de frete`<br>`[01.2] Corrigir bug no header de auth legado` |
| **`02.x` .. `89.x`** | **Épicos de Evolução Cirúrgica** | Novas funcionalidades implementadas de forma isolada, preservando contratos legados. | `[02.1] Adicionar rota v2 de clientes`<br>`[03.1] Integrar novo gateway de pagamento` |
| **`90.x`** | **Refatoração Segura** | Modernização cirúrgica de código legado, sempre respaldada por testes de caracterização prévios. | `[90.1] Migrar queries raw SQL para query builder`<br>`[90.2] Isolar acoplamento de controller` |
| **`99.x`** | **Hardening & Release** | Auditoria final de regressão, segurança, documentação e entrega de release. | `[99.1] Auditoria final de invariantes e release v1.0` |

### 2. Regras de Ouro de Numeração

1. **Dois dígitos no Épico (`XX`):** Use sempre `00`, `01`, `02` ... `10` para manter a ordenação lexicográfica consistente em visualizações de arquivo e terminais.
2. **Subtarefas Atômicas (`XX.Y.Z`):** Se uma tarefa necessitar de decomposição granular durante o planejamento ou execução, utilize subtarefas numeradas (ex: `[01.1.1]`, `[01.1.2]`).
3. **Imutabilidade de Histórico:** O ID de uma tarefa concluída é imutável. Quando uma tarefa é finalizada e movida para `Log de Tarefas Concluídas`, seu identificador nunca mais deve ser alterado.
4. **Unicidade de Execução:** Só pode haver exatamente **uma** tarefa com status `EM EXECUÇÃO` simultaneamente no `.agent/TASK.md`.

---

## 🏷️ Protocolo de Higiene e Sanitização Pós-Release (Gatilho de Tag/Versão)

> 🎯 **Princípio de Disparo por Evento:** Este protocolo NÃO depende de numeração rígida de tarefa (não é exclusivo da fase `99.x`). Ele DEVE ser executado sempre que uma **Release / Tag Git** for publicada no projeto legado (seja via `/github-releases`, pelo desenvolvedor humano ou via pipeline de CI).

Sempre que uma versão (ex: `v0.1.0`, `v0.2.0`, `v1.0.0`) for cortada, o agente deve executar o ciclo de 4 etapas para sanitizar seu contexto de trabalho:

### 1. Arquivamento em Lote no `.agent/ARCHIVE.md`
- Mova o bloco de tarefas concluídas correspondente a essa versão do `.agent/TASK.md` para o `.agent/ARCHIVE.md`.
- Agrupe sob o cabeçalho explícito da release: `## [vX.Y.Z] - AAAA-MM-DD`.
- Mantenha no `TASK.md` apenas o registro sucinto da release e as tarefas do ciclo ativo.

### 2. Higiene de Invariantes e Memória (`.agent/INVARIANTS.md` e `NOTES.md`)
- **Promover Invariantes Descobertas:** Garanta que todas as regras não-óbvias ou contratos legados descobertos durante a versão estão consolidados no `.agent/INVARIANTS.md`.
- **Descartar o Efêmero:** Apague rascunhos de testes, logs de depuração temporários ou anotações resolvidas do `.agent/NOTES.md`.

### 3. Sincronia de Artefatos de Borda
- **`.env.example`:** Audite se todas as novas variáveis de ambiente introduzidas na versão foram documentadas com valores exemplares seguros.
- **`README.md`:** Verifique se as instruções de execução e testes refletem o estado funcional da tag lançada.

### 4. Reset do Ciclo no `.agent/TASK.md`
- Promova para a **Tarefa Ativa** o próximo objetivo do projeto legado (ex: nova funcionalidade cirúrgica ou refatoração segura), definindo o status como `PRONTO PARA PLANEJAMENTO`.

---

## Stack Tecnológico e Descoberta de Ambiente

> 🔍 Se este projeto ainda não teve seu ambiente auditado, execute a tarefa de **Discovery** no `.agent/TASK.md` para preencher os campos abaixo a partir dos arquivos reais (`package.json`, `pyproject.toml`, `Makefile`, etc.).

- **Sistema Operacional e Shell Padrão:** **[ex: Linux (Bash) / Windows (PowerShell 7) / macOS (Zsh)]**
- **Arquitetura Geral:** [Descreva o padrão da aplicação: ex: Monólito Django/FastAPI, API Express, Worker assíncrono]

### Módulos / Serviços
- **Linguagem / Runtime:** [ex: Python 3.10+, Node.js 18+]
- **Gerenciador de Pacotes:** [ex: uv / poetry / pnpm / npm] — utilize exclusivamente o gerenciador já consolidado no projeto.
- **Frameworks e Bibliotecas Centrais:** [liste os frameworks em uso]
- **Banco de Dados e Filas:** [ex: PostgreSQL legado, Redis, RabbitMQ]

---

## Servidores MCP (Model Context Protocol)

Utilize os servidores MCP configurados no ambiente como fonte primária para inspecionar banco de dados, schemas de tabelas legadas e logs de observabilidade.

### MCPs Disponíveis para este Projeto
- **[Nome do MCP 1] (ex: postgres-mcp):** [Inspeção de tabelas, schemas e queries de diagnóstico]
- **[Nome do MCP 2] (ex: victorialogs-mcp):** [Consulta de logs analíticos para depuração de erros]

### Regras de Operação de MCPs
- **Somente Leitura por Padrão (Read-First):** Nunca execute queries destrutivas (`DROP`, `DELETE`, `UPDATE` em massa) via MCP sem consentimento explícito.
- **Auditoria de Schemas:** Sempre inspecione o schema real do banco via MCP antes de assumir como uma tabela ou coluna legada foi modelada.

---

## Comandos de Validação do Projeto

> Preencha a partir da auditoria inicial de scripts do projeto.

- **Instalar Dependências:** `[comando]`
- **Rodar Testes Existentes:** `[comando]`
- **Rodar Testes Específicos:** `[comando]`
- **Linter / Checagem:** `[comando]`
- **Build / Compilação:** `[comando]`

---

## Regras de Ouro para Projetos Brownfield

1. **TESTE ANTES DE REFATORAR (Testes de Caracterização):**
   - Se você precisa alterar uma função ou módulo legado que não possui testes, **escreva um teste de caracterização primeiro** (um teste que verifica o comportamento atual, mesmo que imperfeito) antes de encostar na lógica original.
2. **NÃO "APROVEITE" PARA LIMPAR CÓDIGO (No Opportunistic Refactoring):**
   - Proibido formatar o arquivo inteiro, renomear variáveis adjacentes ou trocar convenções fora do trecho necessário. Diffs no Git devem ser microscópicos e objetivos.
3. **RESPEITE AS INVARIANTES:**
   - Sempre consulte `.agent/INVARIANTS.md`. Se um trecho de código parecer ineficiente ou mal escrito, não o remova sem antes verificar se ele foi colocado ali para contornar limitações de APIs externas ou sistemas integrados.
4. **NUNCA DEPRECIE OU REMOVA PARÂMETROS SEM COMPATIBILIDADE:**
   - Em rotas, interfaces ou payloads legados, nunca remova campos existentes. Se novos dados forem necessários, adicione-os de forma opcional / retrocompatível.
5. **ISOLAMENTO DE MUTAÇÕES NO BANCO:**
   - Nunca altere colunas existentes no banco que possam quebrar versões anteriores da aplicação. Adições de colunas devem permitir valores nulos ou ter defaults seguros.
6. **CIRCUIT BREAKER:**
   - Se uma validação ou teste falhar 2 vezes com a mesma causa-raiz, **PARE**, documente a divergência e consulte o desenvolvedor humano.
7. **COMMITS LOCAIS AUTORIZADOS, MAS PROIBIDO GIT PUSH:**
   - O agente pode realizar commits locais (`git commit`) quando instruído pelo usuário ou para consolidar etapas atômicas testadas.
   - **É TERMINANTEMENTE PROIBIDO executar `git push`.** O agente NUNCA deve enviar alterações para o repositório remoto por conta própria. Qualquer push para branches remotas ou pipelines de deploy exige **avaliação, revisão de diffs e execução manual humana**.

---

## Regras de Git, Commits e Push

### 1. Commits Atômicos e Cirúrgicos
1. **Uma Responsabilidade por Commit:** Cada commit deve conter apenas a alteração estritamente necessária para cumprir uma única etapa ou tarefa. Proibido agrupar refatorações cosméticas e correções no mesmo commit.
2. **Ciclo por Etapa:** Para cada etapa concluída com sucesso (e validada por testes de caracterização), realize um commit local antes de iniciar a próxima.
3. **Diffs Microscópicos:** Preserve linhas adjacentes e formatações originais do código legado para não poluir o `git blame`.

### 2. Mensagens de Commit (Conventional Commits em Inglês)
Todas as mensagens de commit locais DEVEM seguir rigorosamente a sintaxe `<type>(<scope>): <descrição no imperativo/presente>` em inglês:

| Tipo | Finalidade Principal | Exemplo em Projeto Legado |
| :---: | :--- | :--- |
| **`fix`** | Correção de bug no comportamento legado | `fix(auth): fix bug in legacy session header validation` |
| **`test`** | Testes de caracterização ou regressão | `test(billing): add characterization test for legacy calculation` |
| **`feat`** | Nova funcionalidade preservando contratos | `feat(api): add endpoint v2 preserving legacy payload contract` |
| **`docs`** | Documentação de invariantes ou notas | `docs(invariants): record undocumented ERP parameter behavior` |
| **`refactor`** | Melhoria interna respaldada por testes | `refactor(db): streamline query execution without contract changes` |
| **`chore`** | Dependências, build ou configurações | `chore(deps): update linter configuration` |

### 3. PROIBIÇÃO ABSOLUTA DE `git push`
- **Commits Locais Permitidos:** O agente pode executar `git commit` localmente quando autorizado pelo usuário ou para consolidar etapas atômicas testadas.
- **`git push` é Terminantemente Proibido:** O agente NUNCA deve enviar alterações para o repositório remoto. Qualquer publicação de código legado exige revisão manual, inspeção de diffs e push executado pelo desenvolvedor humano.
